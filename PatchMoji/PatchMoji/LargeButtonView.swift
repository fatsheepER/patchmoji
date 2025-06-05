//
//  LargeButtonView.swift
//  PatchMoji
//
//  Created by 王飞扬 on 2025/6/5.
//

import SwiftUI

struct LargeButtonView: View {
    let color: Color
    let subcolor: Color
    let labelText: String?
    let labelSystemName: String
    let showShadow: Bool
    let showText: Bool
    
    init(color: Color? = nil, subcolor: Color? = nil, labelText: String? = nil, labelSystemName: String, showShadow: Bool? = nil) {
        self.color = color ?? .accent
        self.subcolor = subcolor ?? .accentDark
        self.labelText = labelText
        self.labelSystemName = labelSystemName
        self.showShadow = showShadow ?? false
        self.showText = (labelText != nil) ? true : false
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 35)
                .foregroundStyle(color.shadow(.inner(color: .white, radius: 3, y: 1.25)))
                .shadow(color: color.opacity(showShadow ? 1.0 : 0), radius: 10, y: 2.25)
            if showText {
                Label(labelText!, systemImage: labelSystemName)
                    .foregroundStyle(subcolor)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            } else {
                Image(systemName: labelSystemName)
                    .foregroundStyle(subcolor)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }
                
            
                
        }
        .frame(maxHeight: 100)
    }
}

#Preview {
    ZStack {
        Color.accentBackground
            .ignoresSafeArea()
        
        HStack(spacing: 10) {
            LargeButtonView(labelText: "添加图片", labelSystemName: "plus", showShadow: true)
                
            LargeButtonView(color: .accentBackground, subcolor: .white.opacity(0.5), labelSystemName: "house")
                .frame(width: 100)
        }
        .padding(.horizontal, 20)
        
    }
}
