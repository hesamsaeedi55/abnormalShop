//
//  ambientBackground.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 4/2/25.
//

import SwiftUI
import UIKit

struct AnimatedAmbientBackgroundView: View {
    struct Blob: Identifiable {
        let id = UUID()
        var size: CGFloat
        var position: CGPoint
        var color: Color
    }
    
    // Beautiful blue color palette for dark background
    let blueTones: [Color] = [
        Color(hex: "#0A2463"),      // Deep navy blue
        Color(hex: "#1E3A8A"),      // Rich royal blue
        Color(hex: "#3B82F6"),      // Bright blue
        Color(hex: "#60A5FA"),      // Light blue
        Color(hex: "#2563EB"),      // Vibrant blue
        Color(hex: "#1E40AF"),      // Dark blue
        Color(hex: "#1D4ED8"),      // Medium blue
        Color(hex: "#3730A3"),      // Indigo blue
    ]
    
    @State private var floatingEffect: CGFloat = 10
    @State private var floatingEffecty: CGFloat = 100
    @State private var blurEffect: CGFloat = 10
    @State private var isBlurAtZero = false
    @State private var blobs: [Blob] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color(hex: "#0F172A")
                    .ignoresSafeArea()
                
                ForEach(blobs) { blob in
                    Circle()
                        .fill(blob.color.opacity(0.4))
                        .frame(width: blob.size, height: blob.size)
                        .position(blob.position)
                        .blur(radius: 50) // Increased blur for smoother effect
                }
            }
            .onAppear {
                setupBlobs(in: geometry.size)
                animateBlobs(in: geometry.size)
            }
        }
    }
    
    func startBlurAnimation() {
        // Start with blur at 0
        withAnimation(.easeIn(duration: 1.5)) {
            blurEffect = 0
            isBlurAtZero = true
        }
        
        // Hold at 0 for 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Transition to max blur
            withAnimation(.easeOut(duration: 5.5)) {
                blurEffect = 10
                isBlurAtZero = false
            }
            
            // Wait 1 second, then repeat
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startBlurAnimation()
            }
        }
    }
    
    func setupBlobs(in size: CGSize) {
        blobs = (0..<4).map { _ in
            Blob(
                size: CGFloat.random(in: 250...700), // Adjusted for better visibility
                position: randomPosition(in: size),
                color: blueTones.randomElement()!
            )
        }
    }
    
    func animateBlobs(in size: CGSize) {
        for i in blobs.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    blobs[i].position = randomPosition(in: size)
                }
            }
        }
    }
    
    func randomPosition(in size: CGSize) -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: 0...size.height)
        )
    }
}

#Preview {
    AnimatedAmbientBackgroundView()
}

struct ContentView3: View {
    let image = UIImage(named: "o1")!
    var body: some View {
        let color = image.averageColor() ?? UIColor.white
        let swiftUIColor = Color(color)
        ZStack {
            swiftUIColor.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
        }
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIImage {
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extent = inputImage.extent
        let context = CIContext()
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ])
        
        guard let outputImage = filter?.outputImage else { return nil }
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: 1)
    }
}

