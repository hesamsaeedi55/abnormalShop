//
//  ParallaxImageTab.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct ParallaxScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ParallaxImageTab: View {
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    @State var currentIndex = 0
    @State var isFullScreen = false
    @State var cachedImages: [UIImage] = []
    @State var scrollOffset: CGFloat = 0
    
    // Optional callback for when full screen is triggered
    var onFullScreenToggle: ((Bool) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // TabView with parallax effect - full width, no spacing
                    TabView(selection: $currentIndex) {
                        ForEach(cachedImages.indices, id: \.self) { idx in
                            Image(uiImage: cachedImages[idx])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: width, height: height * 0.4)
                                .clipped()
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isFullScreen = true
                                        onFullScreenToggle?(true)
                                    }
                                }
                                .disabled(isFullScreen)
                                .id("hero-\(idx)")
                                .scaleEffect(calculateScale(geometry: geometry))
                                .offset(y: calculateOffset(geometry: geometry))
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(key: ParallaxScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                                    }
                                )
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: height * 0.4)
                    
                    // Your content goes here
                    VStack(spacing: 20) {
                        Text("Your Content Here")
                            .font(.title)
                            .padding()
                        
                        ForEach(0..<20) { index in
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: 100)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.all, edges: .top)
            .onPreferenceChange(ParallaxScrollOffsetKey.self) { newOffset in
                scrollOffset = newOffset
            }
            .onAppear {
                loadImages()
            }
        }
    }
    
    // MARK: - Parallax Effect Calculations
    
    private func calculateScale(geometry: GeometryProxy) -> CGFloat {
        let scrollOffset = geometry.frame(in: .global).minY
        let maxScale: CGFloat = 1.2 // Maximum scale when pulled down
        let threshold: CGFloat = 100 // Scroll threshold for maximum effect
        
        // When pulling down (positive offset), increase scale
        if scrollOffset > 0 {
            let scaleFactor = min(scrollOffset / threshold, 1.0)
            return 1.0 + (scaleFactor * (maxScale - 1.0))
        }
        
        return 1.0
    }
    
    private func calculateOffset(geometry: GeometryProxy) -> CGFloat {
        let scrollOffset = geometry.frame(in: .global).minY
        
        // Parallax offset effect - move image up when pulling down
        // When pulling down (positive scrollOffset), move image up (negative offset)
        if scrollOffset > 0 {
            return -scrollOffset * 0.5 // Negative offset to move image up
        }
        
        return 0
    }
    
    // MARK: - Image Loading
    
    private func loadImages() {
        // Add your image loading logic here
        // For example:
        // cachedImages = [UIImage(named: "image1"), UIImage(named: "image2"), ...]
        
        // Sample implementation:
        if let image1 = UIImage(named: "o6"),
           let image2 = UIImage(named: "o1") {
            cachedImages = [image1, image2]
        }
    }
    
    // MARK: - Public Methods
    
    func setImages(_ images: [UIImage]) {
        cachedImages = images
    }
    
    func setCurrentIndex(_ index: Int) {
        currentIndex = index
    }
}

// MARK: - Preview
#Preview {
    ParallaxImageTab()
        .onAppear {
            // Add sample images for preview
        }
}