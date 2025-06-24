//
//  ContentView.swift
//  PatchMoji
//
//  Created by 王飞扬 on 2025/6/5.
//

import SwiftUI
import PhotosUI
import Vision
import CoreML
import CoreImage
import OSLog
import AVFoundation

// MARK: - Helper
// 日志输出
private let log = Logger(subsystem: "com.example.FERDemo", category: "Pipeline")

// label - emoji 映射
private let emojiDict: [String: [String]] = [
    "happy":    ["😊","😄","😁","😆","🙂","😸"],
    "sad":      ["😢","😭","🥺","🙁","😿"],
    "angry":    ["😠","😡","🤬","😤","👿"],
    "surprise": ["😮","😯","😲","🤯","😳"],
    "disgust":  ["🤢","🤮","😖","😫"],
    "fear":     ["😱","😨","😰","😧","😖"],
    "neutral":  ["😐","😑","🙂"]
]

private func randomEmoji(for label: String) -> String {
    let key = label.lowercased()
    return emojiDict[key, default: emojiDict["neutral"]!].randomElement()!
}

extension CGImagePropertyOrientation {
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up:            self = .up
        case .down:          self = .down
        case .left:          self = .left
        case .right:         self = .right
        case .upMirrored:    self = .upMirrored
        case .downMirrored:  self = .downMirrored
        case .leftMirrored:  self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    // UI state
    @State var isEditing: Bool = false
    @State private var showingSaveAlert = false
    @State private var selectedIndex: Int = 0
    @State private var selectedLabel: String? = nil
    
    // Data state
    @State private var pickerItem: PhotosPickerItem?
    @State private var uiImage: UIImage?
    @State private var faces: [VNFaceObservation] = []
    @State private var preds: [[(label: String, prob: Float)]] = []
    @State private var emojis: [String] = []
    @State private var elapsed: Double?
    
    // 加载表情识别 Core ML model
    private let ferModel: VNCoreMLModel = {
        let conf = MLModelConfiguration()
        conf.computeUnits = .all  // 使用 Neural Engine > GPU > CPU
        return try! VNCoreMLModel(for: FERResNet(configuration: conf).model)
    }()
    
    var body: some View {
        ZStack {
            Color.accentBackground
                .ignoresSafeArea()
            if (!isEditing) {
                homePage
                    .transition(.move(edge: .leading))
            } else {
                editpage
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.bouncy.speed(1.5), value: isEditing)
        .onChange(of: pickerItem) { loadImage() }
        .alert("已保存到相册", isPresented: $showingSaveAlert) {}
    }
    
    // MARK: - Pages
    var homePage: some View {
        VStack(spacing: 13) {
            Spacer()
            
            HStack(spacing: 0) {
                Text("Patch")
                    .foregroundStyle(.accentDarkBlack.shadow(.inner(radius: 2)))
                Text("Moji")
                    .foregroundStyle(.accent.shadow(.inner(radius: 2)))
            }
            .font(.system(size: 70, weight: .bold, design: .rounded))
            
            Spacer()
            
            PhotosPicker(selection: $pickerItem,
                         matching: .images,
                         photoLibrary: .shared()) {
                LargeButtonView(
                    labelText: "导入图片",
                    labelSystemName: "plus",
                    showShadow: true)
            }
            .padding(.horizontal, 20)
        }
        .animation(.smooth.speed(1.7))
    }
    
    var editpage: some View {
        VStack {
            // 照片与覆盖层
            if let img = uiImage {
                EmojiOverlay(
                    image: img,
                    faces: faces,
                    emojis: emojis,
                    selectedIndex: selectedIndex
                ) { idx in
                    self.selectedIndex = idx
                    self.selectedLabel = preds[idx].first?.label
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Pick a photo")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Label 选择栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(emojiDict.keys), id: \.self) { label in
                        Button {
                            self.selectedLabel = label
                        } label: {
                            Text(label.capitalized)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.67))
                                .padding(.horizontal, 3)
                                .frame(height: 27)
                                .background(selectedLabel == label ? .accentDark : .clear)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .transition(.move(edge: .trailing))
            
            // Emoji 选择栏
            if let label = selectedLabel {
                let emojiList = emojiDict[label]!
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(emojiList, id: \.self) { emoji in
                            Button {
                                emojis[selectedIndex] = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 50))
                                    .frame(width: 80, height: 80)
                                    .background(emojis[selectedIndex] == emoji ? .accentDark : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.move(edge: .trailing))
                .frame(minHeight: 110)
                .background(.accentDarkBlack)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal, 20)
            } else {
                ProgressView()
            }
            
            // 返回与保存按钮
            HStack {
                Button {
                    withAnimation {
                        isEditing = false
                    }
                } label: {
                    LargeButtonView(color: .accentDarkBlack, subcolor: .white.opacity(0.5), labelSystemName: "chevron.left")
                        .frame(width: 100)
                }
                
                Button {
                    if uiImage != nil {
                        saveFinalImage()
                    }
                } label: {
                    LargeButtonView(
                        labelText: "保存图片",
                        labelSystemName: "square.and.arrow.down")
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Pipeline functions
    // 1. 加载图片
    func loadImage() {
        Task {
            guard let data = try? await pickerItem?.loadTransferable(type: Data.self),
                  let img = UIImage(data: data) else {
                log.error("选图失败或无法解码 UIImage")
                return
            }
            log.info("图片加载完成，size: \(img.size.width, format: .fixed)×\(img.size.height, format: .fixed)")
            await MainActor.run {
                self.uiImage = img
                self.selectedIndex = 0  // 每次换图默认选第 0 张脸
                self.isEditing = true  // 进入编辑界面
                self.selectedLabel = nil  // 清空之前的识别结果
            }
            detectFaces(in: img)
        }
    }

    // 2. Vision 人脸检测
    func detectFaces(in image: UIImage) {
        guard let cg = image.cgImage else { return }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNDetectFaceRectanglesRequest { req, err in
            if let err { log.error("VNDetectFaceRectangles error: \(err.localizedDescription)") }
            let detected = (req.results as? [VNFaceObservation]) ?? []
            log.info("检测到人脸数量: \(detected.count)")
            Task { @MainActor in self.faces = detected }
            classifyAllFaces(detected, in: cg, orientation: orientation)
        }

        let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation)
        do { try handler.perform([request]) }
        catch { log.error("handler.perform(face) \(error.localizedDescription)") }
    }

    // 3. ResNet18 推理单个人脸（输入 Vision Crop 的 Observation）
    func classify(face obs: VNFaceObservation,
                      in cgImage: CGImage,
                  orientation: CGImagePropertyOrientation) -> [(label: String, prob: Float)]? {
        // 1. 计算像素级 ROI
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let rect = CGRect(x: obs.boundingBox.minX * w,
                          y: (1 - obs.boundingBox.maxY) * h,
                          width: obs.boundingBox.width  * w,
                          height: obs.boundingBox.height * h).integral

        guard let faceCrop = cgImage.cropping(to: rect) else {
            log.error("裁剪失败")
            return nil
        }

        // 2. 转灰度 (与训练分布一致)
        let ciFace = CIImage(cgImage: faceCrop)
            .applyingFilter("CIColorControls", parameters: ["inputSaturation": 0])
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgGray = context.createCGImage(ciFace, from: ciFace.extent) else {
            log.error("灰度转换失败")
            return nil
        }

        var outTop3: [(String, Float)] = []
        let request = VNCoreMLRequest(model: ferModel) { req, _ in
            if let obs = req.results as? [VNClassificationObservation] {
                outTop3 = obs.prefix(3).map { ($0.identifier, $0.confidence) }
            }
        }
        request.imageCropAndScaleOption = .scaleFit
        let handler = VNImageRequestHandler(cgImage: cgGray, orientation: orientation)
        try? handler.perform([request])
        return outTop3.isEmpty ? nil : outTop3
    }
    
    // 4. 逐个面部进行表情推理 结果存入 ContentView 成员变量
    func classifyAllFaces(_ faces: [VNFaceObservation],
                              in cgImage: CGImage,
                              orientation: CGImagePropertyOrientation) {
        Task {
            var results: [[(String, Float)]] = []
            var chosenEmoji: [String] = []
            let t0 = CACurrentMediaTime()
            for obs in faces {
                if let top = classify(face: obs, in: cgImage, orientation: orientation) {
                    results.append(top)
                    chosenEmoji.append(randomEmoji(for: top.first!.label))
                }
            }
            let ms = (CACurrentMediaTime() - t0) * 1000
            await MainActor.run {
                self.preds = results
                self.emojis = chosenEmoji
                self.selectedLabel = results.first?.first?.0
                self.elapsed = ms
            }
            log.info("完成所有人脸推理，共 \(faces.count) 张，耗时 \(ms, format: .fixed) ms")
        }
    }
    
    // 5. 渲染并保存含有 Emoji 覆盖的图片
    func saveFinalImage() {
        guard let base = uiImage else { return }
        let overlay = EmojiOverlay(
            image: base,
            faces: faces,
            emojis: emojis,
            selectedIndex: selectedIndex,
            onTap: { _ in },
            showSelection: false
        )
        let renderer = ImageRenderer(content: overlay)
        renderer.proposedSize = .init(base.size) // 输出与原图一致
        if let final = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(final, nil, nil, nil)
            showingSaveAlert = true
            log.info("已保存渲染结果，大小: \(final.size.width)×\(final.size.height)")
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
