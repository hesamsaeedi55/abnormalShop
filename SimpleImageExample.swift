//
//  SimpleImageExample.swift
//  Example of using robust image loading for a single image
//

import SwiftUI

struct SimpleImageExample: View {
    let imageUrl = "https://picsum.photos/300/400"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Robust Image Loading Example")
                .font(.title)
                .padding()
            
            // Method 1: Using RobustImageView (recommended for simple cases)
            RobustImageView(
                urlString: imageUrl,
                placeholder: Image(systemName: "photo"),
                key: "example-image-1"
            )
            .frame(width: 300, height: 400)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Method 2: Manual loading with ImageStore
            ManualImageLoader(urlString: imageUrl, key: "example-image-2")
                .frame(width: 300, height: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
}

struct ManualImageLoader: View {
    let urlString: String
    let key: String
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if hasError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Failed to load")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Button("Retry") {
                        Task {
                            await loadImage()
                        }
                    }
                    .font(.caption)
                    .padding(.top, 4)
                }
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        hasError = false
        
        let loadedImage = await ImageStore.shared.loadImage(from: urlString, key: key)
        
        await MainActor.run {
            if let loadedImage = loadedImage {
                self.image = loadedImage
                self.hasError = false
            } else {
                self.hasError = true
            }
            self.isLoading = false
        }
    }
}

#Preview {
    SimpleImageExample()
}
