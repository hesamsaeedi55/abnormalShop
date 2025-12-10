//
//  ProductViewWithFloatingLabels.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct ProductViewWithFloatingLabels: View {
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    @State private var currentImageIndex = 0
    @State private var isFullScreen = false
    @State private var cachedImages: [UIImage] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main scrollable content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Product images with parallax effect
                        TabView(selection: $currentImageIndex) {
                            ForEach(cachedImages.indices, id: \.self) { idx in
                                Image(uiImage: cachedImages[idx])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: width, height: height * 0.5)
                                    .clipped()
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            isFullScreen = true
                                        }
                                    }
                                    .tag(idx)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: height * 0.5)
                        
                        // Product details section
                        VStack(alignment: .trailing, spacing: 20) {
                            // Product title and basic info
                            VStack(alignment: .trailing, spacing: 12) {
                                Text("ساعت مچی چرمی کلاسیک")
                                    .font(.custom("DoranNoEn-ExtraBold", size: 24))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.trailing)
                                
                                Text("ساعت مچی مردانه با طراحی کلاسیک و جنس چرم طبیعی")
                                    .font(.custom("DoranNoEn-Light", size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                                
                                HStack {
                                    Spacer()
                                    Text("برند: Rolex")
                                        .font(.custom("DoranNoEn-Medium", size: 14))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Action buttons
                            HStack(spacing: 15) {
                                Button(action: {
                                    // Add to favorites
                                }) {
                                    HStack {
                                        Image(systemName: "heart")
                                        Text("علاقه‌مندی")
                                    }
                                    .font(.custom("DoranNoEn-Medium", size: 16))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.red, lineWidth: 1)
                                    )
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Add to cart
                                }) {
                                    HStack {
                                        Image(systemName: "cart.fill")
                                        Text("افزودن به سبد")
                                    }
                                    .font(.custom("DoranNoEn-Bold", size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.blue)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Product specifications
                            VStack(alignment: .trailing, spacing: 15) {
                                Text("مشخصات محصول")
                                    .font(.custom("DoranNoEn-ExtraBold", size: 20))
                                    .foregroundColor(.primary)
                                
                                SpecificationRow(title: "ابعاد", value: "۴۲ × ۱۳ میلی‌متر")
                                SpecificationRow(title: "وزن", value: "۱۵۰ گرم")
                                SpecificationRow(title: "مقاومت آب", value: "۱۰۰ متر")
                                SpecificationRow(title: "نوع باتری", value: "خودکار")
                                SpecificationRow(title: "گارانتی", value: "۲ سال")
                            }
                            .padding(.horizontal, 20)
                            
                            // Reviews section
                            VStack(alignment: .trailing, spacing: 15) {
                                HStack {
                                    Text("نظرات کاربران")
                                        .font(.custom("DoranNoEn-ExtraBold", size: 20))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        ForEach(0..<5) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 12))
                                        }
                                        Text("(۴.۸)")
                                            .font(.custom("DoranNoEn-Medium", size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                ReviewCard(
                                    userName: "احمد محمدی",
                                    rating: 5,
                                    comment: "ساعت بسیار زیبا و با کیفیت. پیشنهاد می‌کنم."
                                )
                                
                                ReviewCard(
                                    userName: "فاطمه احمدی",
                                    rating: 4,
                                    comment: "طراحی کلاسیک و مناسب برای استفاده روزانه."
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100) // Space for floating labels
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                // Floating info labels overlay
                FloatingInfoLabels(
                    productPrice: "۱,۸۰۰,۰۰۰ تومان",
                    productMaterial: "چرم طبیعی",
                    shippingInfo: "ارسال رایگان"
                )
                
                // Navigation bar
                VStack {
                    HStack {
                        Button(action: {
                            // Back action
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Share action
                        }) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadProductImages()
        }
    }
    
    private func loadProductImages() {
        if let image1 = UIImage(named: "o1"),
           let image2 = UIImage(named: "o6") {
            cachedImages = [image1, image2]
        }
    }
}

struct SpecificationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(value)
                .font(.custom("DoranNoEn-Light", size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(title)
                .font(.custom("DoranNoEn-Medium", size: 14))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct ReviewCard: View {
    let userName: String
    let rating: Int
    let comment: String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(comment)
                    .font(.custom("DoranNoEn-Light", size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
                
                Spacer()
            }
            
            HStack {
                Text(userName)
                    .font(.custom("DoranNoEn-Medium", size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<rating) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

#Preview {
    ProductViewWithFloatingLabels()
}
