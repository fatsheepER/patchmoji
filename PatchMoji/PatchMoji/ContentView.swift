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
            if (!isEditing) {
                homePage
                    .transition(.move(edge: .leading))
            } else {
                editpage
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.bouncy.speed(1.5))
    }
    
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
            
            Button {
                withAnimation {
                    isEditing = true
                }
            } label: {
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
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .foregroundStyle(.accentDarkBlack.shadow(.inner(radius: 2)))
                
                Text("Edit view")
            }
            .padding(.horizontal, 20)
            .transition(.move(edge: .trailing))
            
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
                    withAnimation {
                        isEditing = true
                    }
                } label: {
                    LargeButtonView(
                        labelText: "导出图片",
                        labelSystemName: "square.and.arrow.up")
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
