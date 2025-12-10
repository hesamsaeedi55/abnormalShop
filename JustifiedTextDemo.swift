//
//  JustifiedTextDemo.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/16/25.
//

import SwiftUI

struct JustifiedTextDemo: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    // Your exact example
                    let originalText = """
سلام این محصول
یک ساعت
بسیار زیبا و با قیمتی اقتصادی
می باشد و برای ورزش
مناسب است
"""
                    
                    // Test the new problematic text
                    let problemText = "سلام خدمت شما عزیزان دل جیگر طلاهای لیونل مسی بهمراه این سرنگونی جمهوری اسلامی است و برای درست کردن"
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("متن اصلی:")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(originalText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("متن تراز شده (با حروف چسبان):")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        PersianJustifiedText(
                            originalText,
                            lineWidth: geometry.size.width - 80, // Leave room for padding
                            font: .body,
                            lineSpacing: 6
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            // Visual guide lines to show full width
                            VStack {
                                HStack {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 2, height: 20)
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 2, height: 20)
                                }
                                Spacer()
                            }
                            .padding()
                        )
                    }
                    
                    // Example showing what should and shouldn't connect
                    VStack(alignment: .leading, spacing: 15) {
                        Text("مثال‌های صحیح:")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("محصول")
                                    .foregroundColor(.red)
                                Text("→")
                                Text("محـصـول")
                                    .foregroundColor(.green)
                                Text("(صحیح - حروف چسبان)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("ساعت")
                                    .foregroundColor(.red)
                                Text("→")
                                Text("سـاعـت")
                                    .foregroundColor(.green)
                                Text("(صحیح - س و ع چسبان)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("این")
                                    .foregroundColor(.red)
                                Text("→")
                                Text("این")
                                    .foregroundColor(.orange)
                                Text("(بدون تغییر - ا و ی غیرچسبان)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Test the problematic text
                    VStack(alignment: .leading, spacing: 15) {
                        Text("تست متن مشکل‌دار:")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Original:")
                            .font(.headline)
                        Text(problemText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Justified:")
                            .font(.headline)
                        PersianJustifiedText(
                            problemText,
                            lineWidth: geometry.size.width - 80, // Leave room for padding
                            font: .body,
                            lineSpacing: 6
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.1))
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            // Visual guide lines to show full width
                            VStack {
                                HStack {
                                    Rectangle()
                                        .fill(Color.purple)
                                        .frame(width: 2, height: 20)
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.purple)
                                        .frame(width: 2, height: 20)
                                }
                                Spacer()
                            }
                            .padding()
                        )
                    }
                    
                    // Simple test version
                    VStack(alignment: .leading, spacing: 15) {
                        Text("نسخه ساده (تست):")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        SimplePersianJustified(text: originalText, lineWidth: geometry.size.width - 80)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("متن تراز شده فارسی")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        JustifiedTextDemo()
    }
}
