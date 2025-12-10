//
//  PersianJustifiedText.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/16/25.
//

import SwiftUI

struct PersianJustifiedText: View {
    let text: String
    let lineWidth: CGFloat
    let font: Font
    let lineSpacing: CGFloat
    
    @State private var justifiedText: String = ""
    
    init(
        _ text: String,
        lineWidth: CGFloat,
        font: Font = .body,
        lineSpacing: CGFloat = 4
    ) {
        self.text = text
        self.lineWidth = lineWidth
        self.font = font
        self.lineSpacing = lineSpacing
    }
    
    var body: some View {
        VStack {
            // Debug info
            Text("Original: \(text.prefix(50))...")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Justified: \(justifiedText.prefix(50))...")
                .font(.caption)
                .foregroundColor(.blue)
            
            // Main justified text
            Text(justifiedText.isEmpty ? text : justifiedText)
                .font(font)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.trailing)
                .frame(width: lineWidth, alignment: .trailing)
                .background(Color.yellow.opacity(0.2)) // Debug background
        }
        .onAppear {
            print("PersianJustifiedText appeared with text: \(text)")
            justifyText()
            print("After justification: \(justifiedText)")
        }
        .onChange(of: text) { newText in
            print("Text changed to: \(newText)")
            justifyText()
            print("After justification: \(justifiedText)")
        }
        .onChange(of: lineWidth) { newWidth in
            print("Width changed to: \(newWidth)")
            justifyText()
        }
    }
    
    private func justifyText() {
        print("=== Starting justifyText ===")
        print("Input text: '\(text)'")
        
        // Split text by natural line breaks first
        let naturalLines = text.components(separatedBy: .newlines)
        print("Natural lines count: \(naturalLines.count)")
        print("Natural lines: \(naturalLines)")
        
        var justifiedLines: [String] = []
        
        for (index, line) in naturalLines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            print("Processing line \(index): '\(trimmedLine)'")
            
            if trimmedLine.isEmpty {
                justifiedLines.append("")
                continue
            }
            
            // For single line text, or if it's not the last line, apply justification
            if naturalLines.count == 1 || index < naturalLines.count - 1 {
                let justified = justifyLine(trimmedLine)
                print("Justified line \(index): '\(justified)'")
                justifiedLines.append(justified)
            } else {
                // Don't justify the last line of multi-line text
                print("Last line, no justification: '\(trimmedLine)'")
                justifiedLines.append(trimmedLine)
            }
        }
        
        justifiedText = justifiedLines.joined(separator: "\n")
        print("Final justified text: '\(justifiedText)'")
        print("=== End justifyText ===")
    }
    
    private func justifyLine(_ line: String) -> String {
        print("  justifyLine input: '\(line)'")
        let words = line.components(separatedBy: " ").filter { !$0.isEmpty }
        print("  words: \(words)")
        
        if words.count <= 1 {
            print("  single word, returning unchanged")
            return line
        }
        
        // Find words that can be extended with tatweels
        var extendablePositions: [(wordIndex: Int, positions: [Int])] = []
        
        for (wordIndex, word) in words.enumerated() {
            let positions = getExtendablePositions(in: word)
            print("  word '\(word)' has extendable positions: \(positions)")
            if !positions.isEmpty {
                extendablePositions.append((wordIndex, positions))
            }
        }
        
        print("  total extendable positions: \(extendablePositions)")
        
        if extendablePositions.isEmpty {
            // If no extendable positions, try to add extra spaces between words
            return addExtraSpaces(to: words)
        }
        
        // Calculate how many tatweels we need for full justification
        let totalExtendablePositions = extendablePositions.reduce(0) { $0 + $1.positions.count }
        
        // More aggressive justification - aim for fuller appearance
        let basetatweelsPerPosition = 2
        let totalTatweels = min(totalExtendablePositions * basetatweelsPerPosition, totalExtendablePositions * 4)
        
        var modifiedWords = words
        let tatweelsPerPosition = max(1, totalTatweels / totalExtendablePositions)
        let extraTatweels = totalTatweels % totalExtendablePositions
        
        var distributedExtra = 0
        for (wordIndex, positions) in extendablePositions {
            let word = words[wordIndex]
            let baseTatweelsForWord = positions.count * tatweelsPerPosition
            let extraForWord = distributedExtra < extraTatweels ? positions.count : 0
            let totalForWord = baseTatweelsForWord + extraForWord
            
            modifiedWords[wordIndex] = addTatweelsToWord(word, at: positions, count: totalForWord)
            
            if extraForWord > 0 {
                distributedExtra += positions.count
            }
        }
        
        return modifiedWords.joined(separator: " ")
    }
    
    private func addExtraSpaces(to words: [String]) -> String {
        // Add extra spaces between words when no tatweels can be added
        var result = ""
        for (index, word) in words.enumerated() {
            result += word
            if index < words.count - 1 {
                result += "  " // Double space for basic justification
            }
        }
        return result
    }
    
    private func getExtendablePositions(in word: String) -> [Int] {
        let characters = Array(word)
        var positions: [Int] = []
        
        for i in 0..<characters.count - 1 {
            let current = characters[i]
            let next = characters[i + 1]
            
            // Check if both characters are connecting Persian/Arabic letters
            if canConnect(current, to: next) {
                positions.append(i)
            }
        }
        
        return positions
    }
    
    private func canConnect(_ char1: Character, to char2: Character) -> Bool {
        // Characters that connect on both sides (can have tatweel between them)
        let connectingChars = Set<Character>([
            "ب", "پ", "ت", "ث", "ج", "چ", "ح", "خ", "س", "ش", "ص", "ض", 
            "ط", "ظ", "ع", "غ", "ف", "ق", "ک", "گ", "ل", "م", "ن", "ه", "ی"
        ])
        
        // Characters that don't connect to the next letter (right-connecting only)
        let rightConnectingOnly = Set<Character>([
            "ا", "آ", "د", "ذ", "ر", "ز", "ژ", "و"
        ])
        
        // char1 must be able to connect to the right
        let char1CanConnectRight = connectingChars.contains(char1)
        
        // char2 must be able to connect to the left  
        let char2CanConnectLeft = connectingChars.contains(char2)
        
        return char1CanConnectRight && char2CanConnectLeft
    }
    
    private func addTatweelsToWord(_ word: String, at positions: [Int], count: Int) -> String {
        let characters = Array(word)
        var result = ""
        var tatweelsAdded = 0
        
        for (index, char) in characters.enumerated() {
            result += String(char)
            
            // Add tatweel at this position if it's in our positions array and we haven't exceeded count
            if positions.contains(index) && tatweelsAdded < count {
                result += "ـ"
                tatweelsAdded += 1
            }
        }
        
        return result
    }
}

// MARK: - Preview and Example Usage
struct PersianJustifiedTextExample: View {
    let sampleText = """
سلام این محصول
یک ساعت
بسیار زیبا و با قیمتی اقتصادی
می باشد و برای ورزش
مناسب است
"""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Original Text:")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(sampleText)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Justified Text:")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    PersianJustifiedText(
                        sampleText,
                        lineWidth: UIScreen.main.bounds.width - 60,
                        font: .body,
                        lineSpacing: 4
                    )
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Smaller Width Example:")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    PersianJustifiedText(
                        sampleText,
                        lineWidth: 200,
                        font: .body,
                        lineSpacing: 4
                    )
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Persian Justified Text")
    }
}

#Preview {
    NavigationView {
        PersianJustifiedTextExample()
    }
}
