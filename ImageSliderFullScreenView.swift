import SwiftUI

struct ImageSliderFullScreenView: View {
    let product: ProductTest
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - this ensures full black coverage
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
                
                // Tab view for images - completely fills the layout
                TabView(selection: $currentIndex) {
                    ForEach(product.images.indices, id: \.self) { idx in
                        AsyncImageView(urlString: product.images[idx].url)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                
                // Overlay UI elements
                VStack {
                    // Top close button
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.white)
                                .opacity(0.8)
                        }
                        .padding()
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Bottom indicator
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(Array(product.images.enumerated()), id: \.element.id) { (idx, image) in
                                Rectangle()
                                    .frame(width: getDynamicWidth(for: idx), height: 2)
                                    .onTapGesture {
                                        withAnimation {
                                            currentIndex = idx
                                        }
                                    }
                                    .colorInvert()
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 30)
                        .background(Material.ultraThinMaterialDark)
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            currentIndex = startIndex
        }
    }
    
    private func getDynamicWidth(for index: Int) -> CGFloat {
        let baseWidth = width / 30
        let expandedWidth = width / 6
        
        return index == currentIndex ? expandedWidth : baseWidth
    }
    
    private let width = UIScreen.main.bounds.width
}

// Custom blur view component
struct CustomBlurView: UIViewRepresentable {
    let effect: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: effect))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: effect)
    }
}

// Async image view component
struct AsyncImageView: View {
    let urlString: String
    
    var body: some View {
        AsyncImage(url: URL(string: urlString)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
                .tint(.white)
        }
    }
}

// Fullscreen indicator component
struct FullscreenImageIndicator: View {
    let totalImages: Int
    @Binding var currentIndex: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<totalImages, id: \.self) { idx in
                    Rectangle()
                        .frame(width: idx == currentIndex ? 20 : 8, height: 2)
                        .onTapGesture {
                            withAnimation {
                                currentIndex = idx
                            }
                        }
                        .colorInvert()
                }
            }
            .padding(.horizontal)
            .frame(height: 30)
            .background(CustomBlurView(effect: .systemUltraThinMaterialDark))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding(.bottom, 40)
    }
}
