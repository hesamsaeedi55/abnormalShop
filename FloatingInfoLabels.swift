//
//  FloatingInfoLabels.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct FloatingInfoLabels: View {
    
    @State private var expandedChip: InfoChipType? = nil
    
    // Product data
    let productPrice: String
    let productMaterial: String
    let shippingInfo: String
    
    enum InfoChipType: CaseIterable {
        case price, material, shipping
        
        var icon: String {
            switch self {
            case .price: return "dollarsign.circle"
            case .material: return "leaf"
            case .shipping: return "shippingbox"
            }
        }
        
        var color: Color {
            switch self {
            case .price: return .primary
            case .material: return .primary
            case .shipping: return .primary
            }
        }
        
        var title: String {
            switch self {
            case .price: return "قیمت"
            case .material: return "جنس"
            case .shipping: return "ارسال"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main floating chips
            VStack(spacing: 16) {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        FloatingChip(
                            type: .price,
                            value: productPrice,
                            isExpanded: expandedChip == .price,
                            onTap: { toggleChip(.price) }
                        )
                        
                        FloatingChip(
                            type: .material,
                            value: productMaterial,
                            isExpanded: expandedChip == .material,
                            onTap: { toggleChip(.material) }
                        )
                        
                        FloatingChip(
                            type: .shipping,
                            value: shippingInfo,
                            isExpanded: expandedChip == .shipping,
                            onTap: { toggleChip(.shipping) }
                        )
                    }
                    .padding(.trailing, 16)
                }
                
                Spacer()
            }
            
            // Expanded detail overlay
            if let expandedType = expandedChip {
                ExpandedDetailOverlay(
                    type: expandedType,
                    onDismiss: { dismissExpanded() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    private func toggleChip(_ type: InfoChipType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedChip == type {
                expandedChip = nil
            } else {
                expandedChip = type
            }
        }
    }
    
    private func dismissExpanded() {
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedChip = nil
        }
    }
}

struct FloatingChip: View {
    let type: FloatingInfoLabels.InfoChipType
    let value: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                if isExpanded {
                    Text(value)
                        .font(.custom("DoranNoEn-Light", size: 11))
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, isExpanded ? 12 : 8)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isExpanded ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExpandedDetailOverlay: View {
    let type: FloatingInfoLabels.InfoChipType
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Detail card
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(type.title)
                        .font(.custom("DoranNoEn-Bold", size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Content
                VStack(alignment: .trailing, spacing: 12) {
                    switch type {
                    case .price:
                        PriceDetailView()
                    case .material:
                        MaterialDetailView()
                    case .shipping:
                        ShippingDetailView()
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 32)
            .padding(.vertical, 80)
        }
    }
}

// MARK: - Detail Views

struct PriceDetailView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("قیمت اصلی:")
                    .font(.custom("DoranNoEn-Medium", size: 14))
                Spacer()
                Text("۲,۵۰۰,۰۰۰ تومان")
                    .font(.custom("DoranNoEn-Light", size: 14))
                    .strikethrough()
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("قیمت با تخفیف:")
                    .font(.custom("DoranNoEn-Bold", size: 16))
                    .foregroundColor(.primary)
                Spacer()
                Text("۱,۸۰۰,۰۰۰ تومان")
                    .font(.custom("DoranNoEn-ExtraBold", size: 16))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("درصد تخفیف:")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Spacer()
                Text("۲۸٪")
                    .font(.custom("DoranNoEn-Bold", size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

struct MaterialDetailView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("جنس اصلی:")
                    .font(.custom("DoranNoEn-Bold", size: 14))
                Spacer()
                Text("چرم طبیعی")
                    .font(.custom("DoranNoEn-Medium", size: 14))
            }
            
            HStack {
                Text("کشور سازنده:")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Spacer()
                Text("ایتالیا")
                    .font(.custom("DoranNoEn-Light", size: 12))
            }
            
            HStack {
                Text("رنگ‌بندی:")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Spacer()
                Text("قهوه‌ای، مشکی، قرمز")
                    .font(.custom("DoranNoEn-Light", size: 12))
            }
        }
    }
}

struct ShippingDetailView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("روش ارسال:")
                    .font(.custom("DoranNoEn-Bold", size: 14))
                Spacer()
                Text("پست پیشتاز")
                    .font(.custom("DoranNoEn-Medium", size: 14))
            }
            
            HStack {
                Text("زمان تحویل:")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Spacer()
                Text("۲-۳ روز کاری")
                    .font(.custom("DoranNoEn-Light", size: 12))
            }
            
            HStack {
                Text("هزینه ارسال:")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Spacer()
                Text("رایگان")
                    .font(.custom("DoranNoEn-Bold", size: 12))
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Sample product image background
        Image("o1")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
        
        FloatingInfoLabels(
            productPrice: "۱,۸۰۰,۰۰۰ تومان",
            productMaterial: "چرم طبیعی",
            shippingInfo: "ارسال رایگان"
        )
    }
}
