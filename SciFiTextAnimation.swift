import SwiftUI

struct SciFiTextAnimation: View {
    let targetText: String
    @State private var displayText: String = ""
    @State private var animationTimer: Timer?
    @State private var isAnimating = false
    
    // Characters that will be used for the scrambling effect (including Persian)
    private let scrambleChars = "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی"
    
    init(targetText: String) {
        self.targetText = targetText
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(displayText)
                .font(.custom("DoranNoEn-Medium", size: 20, relativeTo: .body))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.1), value: displayText)
            
            Button(action: startAnimation) {
                Text("Decrypt Text")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isAnimating)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        
        isAnimating = true
        displayText = String(repeating: "?", count: targetText.count)
        
        // Start the scrambling animation
        var iteration = 0
        let totalIterations = 20 // Number of scrambling cycles
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if iteration < totalIterations {
                // Scramble the text
                displayText = scrambleText(targetText: targetText, progress: Double(iteration) / Double(totalIterations))
                iteration += 1
            } else {
                // Show final text
                displayText = targetText
                timer.invalidate()
                animationTimer = nil
                isAnimating = false
            }
        }
    }
    
    private func scrambleText(targetText: String, progress: Double) -> String {
        var scrambledText = ""
        
        // Check if text contains Persian characters (RTL)
        let hasPersianChars = targetText.contains { char in
            let scalar = char.unicodeScalars.first!
            return scalar.value >= 0x0600 && scalar.value <= 0x06FF // Persian/Arabic range
        }
        
        if hasPersianChars {
            // For Persian text, reveal from right to left (RTL)
            let characters = Array(targetText)
            for (index, char) in characters.enumerated() {
                if char == " " {
                    scrambledText += " "
                } else {
                    // Calculate how many characters should be revealed (from right to left)
                    let revealThreshold = 1.0 - progress
                    let shouldReveal = Double(characters.count - index - 1) / Double(characters.count) > revealThreshold
                    
                    if shouldReveal {
                        scrambledText += String(char)
                    } else {
                        // Generate random character
                        let randomIndex = scrambleChars.index(scrambleChars.startIndex, offsetBy: Int.random(in: 0..<scrambleChars.count))
                        scrambledText += String(scrambleChars[randomIndex])
                    }
                }
            }
        } else {
            // For English text, reveal from left to right (LTR)
            for (index, char) in targetText.enumerated() {
                if char == " " {
                    scrambledText += " "
                } else {
                    // Calculate how many characters should be revealed
                    let revealThreshold = 1.0 - progress
                    let shouldReveal = Double(index) / Double(targetText.count) > revealThreshold
                    
                    if shouldReveal {
                        scrambledText += String(char)
                    } else {
                        // Generate random character
                        let randomIndex = scrambleChars.index(scrambleChars.startIndex, offsetBy: Int.random(in: 0..<scrambleChars.count))
                        scrambledText += String(scrambleChars[randomIndex])
                    }
                }
            }
        }
        
        return scrambledText
    }
}

// Preview
struct SciFiTextAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                SciFiTextAnimation(targetText: "HELLO WORLD")
                
                SciFiTextAnimation(targetText: "ACCESS GRANTED")
                
                SciFiTextAnimation(targetText: "SYSTEM ONLINE")
            }
        }
    }
}
