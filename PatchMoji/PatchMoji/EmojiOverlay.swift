//
//  EmojiOverlay.swift
//  ResNetModelDemo
//
//  Created by 王飞扬 on 2025/6/23.
//

import SwiftUI
import Vision
import AVFoundation

struct EmojiOverlay: View {
    let image: UIImage
    let faces: [VNFaceObservation]
    let emojis: [String]
    let selectedIndex: Int
    let onTap: (Int) -> Void
    var showSelection: Bool = true

    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .local)
            let imgRect = AVMakeRect(aspectRatio: image.size, insideRect: frame)

            ZStack {
                // 原图
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imgRect.width, height: imgRect.height)
                    .position(x: imgRect.midX, y: imgRect.midY)

                // Emoji 绘制
                Canvas { context, _ in
                    for (idx, obs) in faces.enumerated() {
                        guard idx < emojis.count else { continue }
                        let r = obs.boundingBox
                        let rect = CGRect(x: imgRect.minX + r.minX * imgRect.width,
                                          y: imgRect.maxY - r.maxY * imgRect.height,
                                          width: r.width * imgRect.width,
                                          height: r.height * imgRect.height)

                        // 计算直径，让圆形完全覆盖正方形 ROI
                        let diameter = max(rect.width, rect.height) * sqrt(2) * 1.05
                        let center = CGPoint(x: rect.midX, y: rect.midY)

                        let text = Text(emojis[idx]).font(.system(size: diameter))
                        let resolved = context.resolve(text)

                        // 旋转补偿（如果检测到了 roll 角）
                        if let roll = obs.roll?.doubleValue {
                            context.translateBy(x: center.x, y: center.y)
                            if let roll = obs.roll?.doubleValue {
                                context.rotate(by: .radians(roll))
                            }
                            context.translateBy(x: -center.x, y: -center.y)
                            context.draw(resolved, at: center)
                        }

                        context.draw(resolved, at: center, anchor: .center)

                        if showSelection && selectedIndex == idx {
                            // 虚线样式，圆头
                            let style = StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round,
                                dash: [12, 8]        // 你可微调 dash/gap
                            )

                            // 画圆
                            let outline = Path(ellipseIn: CGRect(
                                x: center.x - diameter/2 - 2,
                                y: center.y - diameter/2 - 2,
                                width: diameter + 4,
                                height: diameter + 4
                            ))
                            context.stroke(outline, with: .color(.accent), style: style)
                        }
                        context.drawLayer { _ in }
                    }
                }
            }
            .contentShape(Rectangle()) // 捕获点击
            .onTapGesture(coordinateSpace: .local) { loc in      // loc: CGPoint
                var nearest: Int? = nil
                var minDist = CGFloat.greatestFiniteMagnitude
                for (idx, obs) in faces.enumerated() {
                    let r = obs.boundingBox
                    let faceRect = CGRect(
                        x: imgRect.minX + r.minX * imgRect.width,
                        y: imgRect.maxY - r.maxY * imgRect.height,
                        width: r.width  * imgRect.width,
                        height: r.height * imgRect.height
                    )
                    if faceRect.contains(loc) { nearest = idx; break }
                    let d = hypot(faceRect.midX - loc.x, faceRect.midY - loc.y)
                    if d < minDist { minDist = d; nearest = idx }
                }
                if let m = nearest { onTap(m) }
            }
        }
    }
}
