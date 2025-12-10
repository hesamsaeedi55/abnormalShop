//
//  RobustImageView.swift
//  Simple Image View with Retry Logic
//

import SwiftUI

struct RobustImageView: View {
    let urlString: String
    let placeholder: Image
    let key: String
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    init(urlString: String, placeholder: Image = Image(systemName: "photo"), key: String? = nil) {
        self.urlString = urlString
        self.placeholder = placeholder
        self.key = key ?? urlString
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if hasError {
                VStack {
                    placeholder
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                    
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
                    placeholder
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                    
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

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RobustImageView(
            urlString: "https://picsum.photos/200/300",
            placeholder: Image(systemName: "photo"),
            key: "preview-image"
        )
        .frame(width: 200, height: 300)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        
        RobustImageView(
            urlString: "https://invalid-url.com/image.jpg",
            placeholder: Image(systemName: "exclamationmark.triangle"),
            key: "error-image"
        )
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    .padding()
}
