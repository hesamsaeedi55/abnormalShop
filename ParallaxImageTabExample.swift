//
//  ParallaxImageTabExample.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct ParallaxImageTabExample: View {
    
    @State private var images: [UIImage] = []
    @State private var isFullScreen = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Your parallax image tab
                ParallaxImageTab()
                    .onFullScreenToggle { isFullScreen in
                        self.isFullScreen = isFullScreen
                    }
                    .onAppear {
                        // Load your images
                        loadImages()
                    }
                
                // Rest of your content
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Your Content Here")
                            .font(.title)
                            .padding()
                        
                        ForEach(0..<10) { index in
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: 100)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Parallax Example")
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            // Your full screen image view
            FullScreenImageView()
        }
    }
    
    private func loadImages() {
        // Example: Load images from your data source
        // images = yourImageArray
        // You can then pass them to ParallaxImageTab using setImages()
    }
}

struct FullScreenImageView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
                
                Text("Full Screen Image View")
                    .foregroundColor(.white)
                    .font(.title)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ParallaxImageTabExample()
}
