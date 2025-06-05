//
//  ContentView.swift
//  PatchMoji
//
//  Created by 王飞扬 on 2025/6/5.
//

import SwiftUI

struct ContentView: View {
    @State var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            Color.accentBackground
                .ignoresSafeArea()
            
            VStack(spacing: 13) {
                HStack(spacing: 0) {
                    Text("Patch")
                        .foregroundStyle(.accentDarkBlack.shadow(.inner(radius: 2)))
                    Text("Moji")
                        .foregroundStyle(.accent.shadow(.inner(radius: 2)))
                }
                .font(.system(size: 70, weight: .bold, design: .rounded))
                .animation(.smooth.speed(1))
                .zIndex(0)
                
                // Edit area
                if isEditing {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(.accentDarkBlack.shadow(.inner(radius: 2)))
                        
                        Text("Edit view")
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 500)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }
                
                HStack {
                    Button {
                        withAnimation {
                            isEditing = false
                        }
                    } label: {
                        LargeButtonView(color: .accentDarkBlack, subcolor: .white.opacity(0.5), labelSystemName: "chevron.left")
                            .frame(width: isEditing ? 100 : 0)
                    }
                    .opacity(isEditing ? 1 : 0)
                    
                    Button {
                        withAnimation {
                            isEditing = true
                        }
                    } label: {
                        LargeButtonView(
                            labelText: isEditing ? "导出图片" : "导入图片",
                            labelSystemName: isEditing ? "square.and.arrow.up" : "plus",
                            showShadow: !isEditing)
                    }
                    
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
                .zIndex(0)
            }
            .animation(.smooth.speed(1.7))
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
