//
//  ParallaxImageTabFixed.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct ParallaxImageTabFixed: View {
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    @State var currentIndex = 0
    @State var isFullScreen = false
    @State var cachedImages: [UIImage] = []
    @State var scrollOffset: CGFloat = 0
    
    // Optional callback for when full screen is triggered
    var onFullScreenToggle: ((Bool) -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // TabView with parallax effect - starts at absolute top
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
                            .scaleEffect(calculateScale())
                            .offset(y: calculateOffset())
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: height * 0.4)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                scrollOffset = geometry.frame(in: .global).minY
                            }
                            .onChange(of: geometry.frame(in: .global).minY) { newValue in
                                scrollOffset = newValue
                            }
                    }
                )
                
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
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .clipped()
        .onAppear {
            loadImages()
        }
    }
    
    // MARK: - Parallax Effect Calculations
    
    private func calculateScale() -> CGFloat {
        let maxScale: CGFloat = 1.2
        let threshold: CGFloat = 100
        
        if scrollOffset > 0 {
            let scaleFactor = min(scrollOffset / threshold, 1.0)
            return 1.0 + (scaleFactor * (maxScale - 1.0))
        }
        
        return 1.0
    }
    
    private func calculateOffset() -> CGFloat {
        if scrollOffset > 0 {
            return -scrollOffset * 0.5
        }
        
        return 0
    }
    
    // MARK: - Image Loading
    
    private func loadImages() {
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

#Preview {
    ParallaxImageTabFixed()
}
