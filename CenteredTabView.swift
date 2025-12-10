//
//  CenteredTabView.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CenteredTabView: View {
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    @State var currentIndex = 0
    @State var isFullScreen = false
    @State var cachedImages: [UIImage] = []
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(cachedImages.indices, id: \.self) { idx in
                GeometryReader { geometry in
                    Image(uiImage: cachedImages[idx])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isFullScreen = true
                            }
                        }
                        .disabled(isFullScreen)
                        .id("hero-\(idx)")
                        .blur(radius: geometry.frame(in: .global).minY <= 0 ? -geometry.frame(in: .global).minY/20 : 0)
                        .offset(y: geometry.frame(in: .global).minY <= geometry.frame(in: .global).minY ? 0 : -geometry.frame(in: .global).minY)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minX)
                            }
                        )
                        .clipped()
                }
                .tag(idx)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Add some sample images or load your images here
            loadSampleImages()
        }
    }
    
    private func loadSampleImages() {
        // Add your image loading logic here
        // For example:
        // cachedImages = [UIImage(named: "image1"), UIImage(named: "image2"), ...]
    }
}

#Preview {
    CenteredTabView()
}
