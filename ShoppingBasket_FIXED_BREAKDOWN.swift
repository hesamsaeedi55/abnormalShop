//
// FIXED VERSION - Showing each issue and fix
//

@ViewBuilder
func basketRow(product: shoppingBasket) -> some View {
    ForEach(shoppingBasketVM.basket.items, id: \.id) { item in
        VStack(spacing: 0) {
            HStack {
                // ========== IMAGE SECTION ==========
                imageSection(item: item)
                
                // ========== DETAILS SECTION ==========
                detailsSection(item: item)
            }
            .frame(width: width/1, height: height/5)
            
            Spacer()
            Rectangle()
                .frame(height: 0.5)
                .opacity(0.4)
        }
        .task {
            // FIX #7: Safe unwrapping instead of force unwrap
            totalPrice += Double(item.quantity) * Double(item.product.priceToman ?? 0)
        }
    }
}

// ========== IMAGE SECTION ==========
@ViewBuilder
private func imageSection(item: CartItem) -> some View {
    HStack {
        VStack {
            Spacer()
            Image(uiImage: cachedImages[item.product.id] ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(width: width/3.2, height: width/3.2 * 4/3)
                .clipped()
                .padding(.horizontal, width/32)
            Spacer()
        }
        Spacer()
    }
    .task(id: item.product.id) {
        await loadImageForItem(item: item)
    }
}

// FIX #2: Proper optional handling for image loading
private func loadImageForItem(item: CartItem) async {
    let urlString: String
    
    // FIX #2: Safe unwrapping instead of force unwrap
    if let firstImage = item.product.images?.first?.image {
        urlString = firstImage
    } else if let variantImage = item.variant?.images?.first?.image {
        urlString = variantImage
    } else {
        cachedImages[item.product.id] = UIImage(systemName: "photo") ?? UIImage()
        return
    }
    
    let baseURL = "http://127.0.0.1:8000"
    let fullURLString = baseURL + urlString
    
    guard let imageURL = URL(string: fullURLString) else {
        print("❌ Invalid URL: \(fullURLString)")
        cachedImages[item.product.id] = UIImage(systemName: "photo") ?? UIImage()
        return
    }
    
    if let loadedImage = await ImageStore.shared.preloadSingleImage(
        url: imageURL,
        keyPrefix: "product-\(item.product.id)"
    ) {
        print("✅ Successfully loaded image for product \(item.product.id)")
        cachedImages[item.product.id] = loadedImage
    } else {
        print("❌ Failed to load image for product \(item.product.id)")
        cachedImages[item.product.id] = UIImage(systemName: "photo") ?? UIImage()
    }
}

// ========== DETAILS SECTION ==========
@ViewBuilder
private func detailsSection(item: CartItem) -> some View {
    VStack(alignment: .trailing, spacing: height/120) {
        Text(item.product.name)
            .font(.custom("DoranNoEn-Medium", size: 16, relativeTo: .body))
            .multilineTextAlignment(.center)
        
        HStack(spacing: 2) {
            Text("\(item.product.getFormattedPrice().persianDigits)")
                .font(.custom("DoranNoEn-Medium", size: 14, relativeTo: .body))
                .multilineTextAlignment(.center)
            Text("قیمت: ")
                .font(.custom("DoranNoEn-Medium", size: 14, relativeTo: .body))
                .multilineTextAlignment(.center)
        }
        
        // ========== ATTRIBUTES SECTION ==========
        attributesSection(item: item)
        
        // ========== ACTIONS SECTION ==========
        actionsSection(item: item)
        
        Spacer()
    }
    .padding(.trailing)
}

// ========== ATTRIBUTES SECTION ==========
@ViewBuilder
private func attributesSection(item: CartItem) -> some View {
    HStack(spacing: width/40) {
        // Quantity
        VStack {
            Text("تعداد")
                .font(.custom("DoranNoEn-Medium", size: 12))
            Text("\(item.quantity.persianDigits)")
                .font(.custom("DoranNoEn-Medium", size: 14))
        }
        
        divider()
        
        // First Attribute
        firstAttributeView(item: item)
        
        divider()
        
        // Second Attribute
        secondAttributeView(item: item)
    }
}

@ViewBuilder
private func divider() -> some View {
    Rectangle()
        .foregroundStyle(.black)
        .frame(width: 1, height: height/30)
        .padding(.horizontal, width/60)
}

// ========== FIRST ATTRIBUTE ==========
@ViewBuilder
private func firstAttributeView(item: CartItem) -> some View {
    VStack {
        if let variant = item.variant {
            // FIX #3: Check array bounds before accessing
            if variant.attributes.count > 0 {
                VStack {
                    Text(variant.attributes[0].display_name ?? "")
                        .font(.custom("DoranNoEn-Medium", size: 12))
                    Text(variant.attributes[0].value)
                        .font(.custom("DoranNoEn-Medium", size: 12))
                }
            }
        } else {
            // FIX #1 & #4: Fix operator precedence and handle missing function
            let attributeCount = item.product.attributes?.count ?? 0
            let hasAttributes = attributeCount > 0
            
            if hasAttributes, let firstAttribute = item.product.attributes?[0] {
                // If displayAttributeValue function exists, use it:
                // Text(displayAttributeValue(at: 0, from: item.product.attributes))
                // Otherwise use direct access:
                Text(firstAttribute.display_name ?? "")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Text(firstAttribute.value ?? "NOT")
                    .font(.custom("DoranNoEn-Medium", size: 12))
            } else {
                Text("NAH")
                    .font(.custom("DoranNoEn-Medium", size: 12))
            }
        }
    }
}

// ========== SECOND ATTRIBUTE ==========
@ViewBuilder
private func secondAttributeView(item: CartItem) -> some View {
    VStack {
        if let variant = item.variant {
            // FIX #3: Check array bounds before accessing
            if variant.attributes.count > 1 {
                VStack {
                    Text(variant.attributes[1].display_name ?? "")
                        .font(.custom("DoranNoEn-Medium", size: 12))
                    Text(variant.attributes[1].value)
                        .font(.custom("DoranNoEn-Medium", size: 12))
                }
            }
        } else {
            // FIX #1: Fix operator precedence
            let attributeCount = item.product.attributes?.count ?? 0
            let hasMultipleAttributes = attributeCount > 1
            
            if hasMultipleAttributes, let secondAttribute = item.product.attributes?[1] {
                Text(secondAttribute.display_name ?? "")
                    .font(.custom("DoranNoEn-Medium", size: 12))
                Text(secondAttribute.value ?? "")
                    .font(.custom("DoranNoEn-Medium", size: 12))
            }
        }
    }
}

// ========== ACTIONS SECTION ==========
@ViewBuilder
private func actionsSection(item: CartItem) -> some View {
    HStack {
        quantityControls()
        itemMenu(item: item)
    }
}

@ViewBuilder
private func quantityControls() -> some View {
    HStack(spacing: 0) {
        Button {
            // decrement action
        } label: {
            Text("-")
                .frame(width: width/18)
        }
        
        Rectangle()
            .frame(width: 1, height: width / 20)
            .foregroundStyle(.gray)
        
        Button {
            // increment action
        } label: {
            Text("+")
                .frame(width: width/18)
        }
    }
    .frame(height: height/30)
    .foregroundStyle(.black)
}

@ViewBuilder
private func itemMenu(item: CartItem) -> some View {
    Menu {
        Button {
            print("Edit tapped")
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            print("Delete tapped")
            cartManager.removeFromCart(itemId: item.id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        
        Button {
            print("Share tapped")
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    } label: {
        Image(systemName: "ellipsis")
            .rotationEffect(.degrees(90))
            .font(.headline)
            .frame(height: height/30)
    }
    .foregroundColor(.black)
}

