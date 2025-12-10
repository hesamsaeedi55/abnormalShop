//
//  SimplePersianJustified.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/16/25.
//

import SwiftUI

struct SimplePersianJustified: View {
    let text: String
    let lineWidth: CGFloat
    
    var body: some View {
        Text(justifiedText)
            .font(.body)
            .multilineTextAlignment(.trailing)
            .frame(width: lineWidth, alignment: .trailing)
            .background(Color.green.opacity(0.2))
    }
    
    var justifiedText: String {
        // Simple test: just add some tatweels to see if it works
        let words = text.components(separatedBy: " ")
        let modifiedWords = words.map { word in
            if word.contains("سلام") {
                return "سـلام"
            } else if word.contains("محصول") {
                return "محـصـول" 
            } else if word.contains("ساعت") {
                return "سـاعـت"
            } else if word.contains("بسیار") {
                return "بـسـیـار"
            } else if word.contains("زیبا") {
                return "زیـبـا"
            } else if word.contains("قیمتی") {
                return "قیـمـتـی"
            } else if word.contains("اقتصادی") {
                return "اقـتـصـادی"
            } else if word.contains("باشد") {
                return "بـاشـد"
            } else if word.contains("برای") {
                return "بـرای"
            } else if word.contains("ورزش") {
                return "ورزش" // و and ر don't connect
            } else if word.contains("مناسب") {
                return "مـنـاسـب"
            } else if word.contains("است") {
                return "اسـت"
            }
            return word
        }
        return modifiedWords.joined(separator: " ")
    }
}

#Preview {
    VStack(spacing: 20) {
        let testText = """
سلام این محصول
یک ساعت
بسیار زیبا و با قیمتی اقتصادی
می باشد و برای ورزش
مناسب است
"""
        
        Text("Original:")
            .font(.headline)
        Text(testText)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 300, alignment: .trailing)
            .background(Color.red.opacity(0.2))
        
        Text("Simple Justified:")
            .font(.headline)
        SimplePersianJustified(text: testText, lineWidth: 300)
    }
    .padding()
}
