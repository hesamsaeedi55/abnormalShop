//
//  ShoppingBasket.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 7/27/25.
//


import SwiftUI

struct ShoppingBasket: View {


    @State private var cachedImages: [Int: UIImage] = [:]
    @State private var totalPrice: Double = 0
    @EnvironmentObject var navigationVM: NavigationStackManager
    @EnvironmentObject var shoppingBasketVM: shoppingBasketViewModel
    @EnvironmentObject var addressVM: AddressViewModel
    @State private var showOptions = false
    @State var sampleProducts: [AnyView] = []
    @State var isOverStocked: Bool = false
    @State var isDeleteButtonTapped: Bool = false
    @State var deleteItemId: Int = 0
    @State var isDeleting: Bool = false
    @State var errorMessage: String?
    @State var showErrorAlert: Bool = false
    @State var isAddressSelection : Bool = true
    @State var selectedAddressID: Int? = nil
    @State var createAddressSheet: Bool = false
    @State var isDeleteConfirmationPresented: Bool = false
    @State var addressToDelete:Address?
    @State var errorIsPresented: Bool = false
    @State private var previousSheetState: Bool = false
    
    //MARK: - width & height
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    private var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }

    var body: some View {
        
        
        ZStack {
            
            overStockBanner()

//            AnimatedAmbientBackgroundView()
//                .ignoresSafeArea()
//                .brightness(-0.3)
          
            
            
            VStack {
                navBar()
                    .onAppear {
                        Task {
                            guard !isPreview else { return }
                            do {
                                try await shoppingBasketVM.loadShoppingBasket()
                            } catch {
                                print("Failed to load shopping basket: \(error)")
                                // Gracefully handle error - don't crash
                            }
                        }
                    }
                    .onChange(of:isOverStocked) { newValue in
                        Task {
                            guard !isPreview else { return }
                            do {
                                try await shoppingBasketVM.loadShoppingBasket()
                            } catch {
                                print("Failed to load shopping basket: \(error)")
                                // Gracefully handle error - don't crash
                            }
                        }
                    }
                
                ScrollView {

                VStack {

                        if !shoppingBasketVM.basket.items.isEmpty {
                                VStack {
                                    basketRow(product: shoppingBasketVM.basket)
                                }.padding(.top,5)
                            }
                         
                    }
                   
                }
                // Floating NavBar (on top with blur)
                Spacer() // This pushes everything to the top
//                addressStack()
                
            }.ignoresSafeArea()
                .blur(radius: isDeleteButtonTapped || isAddressSelection ? 10 : 0)
                .allowsHitTesting(!isAddressSelection) // Block interactions when address selection is active
            checkoutSection()
                .blur(radius: isDeleteButtonTapped || isAddressSelection ? 10 : 0)
                .allowsHitTesting(!isAddressSelection) // Block interactions when address selection is active
            deleteAlert()
                .opacity(isDeleteButtonTapped ? 1 : 0)
            
            // Background tap area to dismiss address selection
            if isAddressSelection {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isAddressSelection = false
                        }
                    }
                    .zIndex(9) // Behind addressSelection but above other content
            }
            
            addressSelection()
                .zIndex(10) // On top of everything
        }
        .sheet(isPresented: $createAddressSheet) {
            AddressDetailView(
                address: Address(
                    id: 0,
                    label: "",
                    receiver_name: "",
                    country: "ایران",
                    state: "",
                    city: "",
                    street_address: "",
                    unit: "",
                    postal_code: "",
                    phone: ""
                ),
                showBackButton: false
            )
            .environmentObject(navigationVM)
            .environmentObject(addressVM)
        }
        .onChange(of: createAddressSheet) { newValue in
            // When sheet is dismissed (changes from true to false), reload addresses
            if previousSheetState == true && newValue == false {
                Task {
                    await addressVM.loadAddress(token: "Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")")
                }
            }
            previousSheetState = newValue
        }
        .alert("خطا", isPresented: $showErrorAlert) {
            Button("باشه", role: .cancel) {
                errorMessage = nil
                showErrorAlert = false
            }
        } message: {
            if let message = errorMessage {
                Text(message)
            }
        }
    }
    
    @ViewBuilder
    func checkoutSection() -> some View {
        VStack {
            Spacer()
            VStack {
                    
                    HStack {
                        Rectangle()
                            .frame(width:width/5,height:0.25)
                        Text("مجموع فاکتور")
                            .font(.custom("DoranNoEn-Medium", size: 20, relativeTo: .body))
                            .padding(3)
                        Spacer()
                        Rectangle()
                            .frame(height:0.25)
                    }
                
                Text(shoppingBasketVM.basket.total_price_toman.formattedPriceFA() + "   تومان")
                        .font(.custom("DoranNoEn-Medium", size: 20, relativeTo: .body))
                    
                    Rectangle()
                        .frame(height:0.25)
                    Button {
                        
                        navigationVM.pushView(checkoutView().environmentObject(navigationVM))
                        
                    }label:{
                    Text("انتخاب آدرس")
                            .font(.custom("AbarHighNoEn-Regular", size: 20, relativeTo: .body))
                        .foregroundStyle(.black)
                }
                
            }
            .padding(.vertical,height/20)

            .background(CustomBlurView(effect: .systemUltraThinMaterialDark)
                .frame(width: width*2)
                .padding(.bottom,-height/20)
                .brightness(0.2)
                .blur(radius: 20))
            
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    func addressStack() -> some View {
        if let addresses = addressVM.addressesArray {
            
            ForEach(addresses, id: \.id) { address in
                
                
                VStack(spacing:0) {
                    HStack {
                        
                        Button {
                            
                            let addressDetailView = AddressDetailView(address: address).environmentObject(navigationVM)
                            
                            navigationVM.pushView(addressDetailView)
                            
                        }label:{
                            
                            
                            Image("pencil")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding(.leading)
                            
                        }
                        Spacer()
                        
                        Text("عنوان: \(address.label)")
                            .font(.custom("DoranNoEn", size: 18))
                            .padding(12)
                            .foregroundStyle(.black)
                    }
                    VStack(spacing:0) {
                        HStack {
                            Spacer()
                            
                            Text("نام گیرنده: \(address.receiver_name)")
                                .font(.custom("DoranNoEn", size: 14))
                                .foregroundStyle(.black)
                                .shadow(radius: 3)
                                .padding(.trailing,12)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Spacer()
                            
                            Text("آدرس: \(address.street_address)")
                                .font(.custom("DoranNoEn", size: 14))
                                .foregroundStyle(.black)
                                .shadow(radius: 3)
                                .padding(.trailing,12)
                                .multilineTextAlignment(.trailing)
                            
                        }
                        HStack {
                            Spacer()
                            
                            Text("تلفن: \(address.phone.persianDigits)")
                                .font(.custom("DoranNoEn", size: 14))
                                .foregroundStyle(.black)
                                .shadow(radius: 3)
                                .padding(.trailing,12)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Spacer()
                            
                            Text("کدپستی: \(address.postal_code)")
                                .font(.custom("DoranNoEn", size: 14))
                                .foregroundStyle(.black)
                                .shadow(radius: 3)
                                .padding(.trailing,12)
                                .multilineTextAlignment(.trailing)
                                .padding(.bottom,12)
                            
                        }
                        
                    }
                    HStack {
                        Button {
                            
//                            addressToDelete = address
//                            isDeleteConfirmationPresented = true
                            
                            
                        }label:{
                            Text("حذف")
                                .font(.custom("DoranNoEn-Bold", size: 14))
                                .foregroundStyle(.red)
                                .shadow(radius: 3)
                                .padding(.leading,12)
                                .multilineTextAlignment(.trailing)
                                .padding(.bottom,12)
                                .clipped()
                                .frame(width:60)
                    }
                    Spacer()
                    }
                }
                .background(CustomBlurView(effect: .systemUltraThinMaterial))
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .padding(.horizontal)
                
                .onAppear {
                    if addresses.count == 3 {
                        print(addresses.count)
//                        addingAddressAllowed = false
                    }
                }
                .onChange(of: addresses.count) { newValue in
                    
                    if newValue <= 2 {
//                        addingAddressAllowed = true
                    }
                }
            }
        }
    }
    
    // EXTRA
    @ViewBuilder
    private func overStockBanner() -> some View {
        ZStack {
                   // Thin material background covering the whole screen
                   CustomBlurView(effect: .systemThinMaterial)
                       .ignoresSafeArea()
                   
                   // Your text centered on top
            
            
                   Text("تغییر در تعداد سفارش محصول اعمال شد")
                       .font(.custom("DoranNoEn-Bold", size: 16, relativeTo: .body))
                       .foregroundColor(.black)
                       .padding()
                       .background(CustomBlurView(effect: .systemUltraThinMaterial))
                       .cornerRadius(10)
            
               }
        
        .opacity(isOverStocked ? 1 : 0)
               .zIndex(15)
               .onChange(of: isOverStocked) { newValue in
                   if newValue {
                       Task {
                           try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                           withAnimation {
                               isOverStocked = false
                           }
                       }
                   }
               }
    }
  
    @ViewBuilder
    func basketRow(product: shoppingBasket) -> some View {
        
        ForEach(shoppingBasketVM.basket.items,id:\.id) { item in
            
            
            VStack(spacing: 0) {
                HStack {
            HStack {
                        VStack {
                            Spacer()
                            // Use variant ID as cache key if variant exists, otherwise use product ID
                            Image(uiImage: cachedImages[item.variant?.id ?? item.product.id] ?? UIImage())
                                .resizable()
                                .scaledToFill()
                                .frame(width: width/3.2, height: width/3.2 * 4/3)
                                .clipped()
                                .padding(.horizontal,width/32)
                            Spacer()
                            
                        }
                        Spacer()
                            .task(id: "\(item.product.id)-\(item.variant?.id ?? 0)") {
                                if isPreview { return }
                                var urls = ""
                                
                                // Priority 1: Use variant image if variant exists (EVEN IF product has images)
                                if let variant = item.variant,
                                   let variantImages = variant.images,
                                   !variantImages.isEmpty,
                                   let variantImage = variantImages.first,
                                   !variantImage.image.isEmpty {
                                    urls = variantImage.image
                                    print("📷 Using variant image for variant \(variant.id): \(urls)")
                                }
                                // Priority 2: Fallback to product image if no variant image
                                else if let productImages = item.product.images,
                                         !productImages.isEmpty,
                                         let productImage = productImages.first,
                                         !productImage.image.isEmpty {
                                    urls = productImage.image
                                    print("📷 Using product image as fallback: \(urls)")
                                }
                                // Priority 3: No images available
                                else {
                                    print("⚠️ No images found for item \(item.id)")
                                    // Use unique cache key that includes variant ID
                                    let cacheKey = item.variant != nil
                                        ? item.variant!.id
                                        : item.product.id
                                    cachedImages[cacheKey] = UIImage(systemName: "photo") ?? UIImage()
                                    return
                                }
                                
                                // Construct full URL - handle both absolute and relative URLs
                                let baseURL = "https://myshop-backend-an7h.onrender.com"
                                let fullURLString: String
                                if urls.hasPrefix("http://") || urls.hasPrefix("https://") {
                                    // URL is already absolute
                                    fullURLString = urls
                                } else {
                                    // URL is relative, prepend base URL
                                    fullURLString = baseURL + (urls.hasPrefix("/") ? urls : "/" + urls)
                                }
                                
                                print("📡 Full URL: \(fullURLString)")
                                
                                // Check if URL is valid
                                guard let imageURL = URL(string: fullURLString) else {
                                    print("❌ Invalid URL: \(fullURLString)")
                                    // Use unique cache key that includes variant ID
                                    let cacheKey = item.variant != nil
                                        ? item.variant!.id
                                        : item.product.id
                                    cachedImages[cacheKey] = UIImage(systemName: "photo") ?? UIImage()
                                    return
                                }
                                
                                print("📡 Attempting to load from URL: \(imageURL)")
                                
                                // Use variant ID in cache key prefix if variant exists
                                let keyPrefix = item.variant != nil
                                    ? "product-\(item.product.id)-variant-\(item.variant!.id)"
                                    : "product-\(item.product.id)"
                                
                                // Use variant ID as cache key to ensure different variants get different images
                                let cacheKey = item.variant != nil
                                    ? item.variant!.id  // Use variant ID as cache key for variants
                                    : item.product.id   // Use product ID for non-variant items
                                
                                // Note: preloadSingleImage returns nil on failure, doesn't throw
                                if let loadedImage = await ImageStore.shared.preloadSingleImage(url: imageURL, keyPrefix: keyPrefix) {
                                    print("✅ Successfully loaded image for item \(item.id), variant \(item.variant?.id ?? 0)")
                                    cachedImages[cacheKey] = loadedImage
                                } else {
                                    print("❌ Failed to load image for item \(item.id)")
                                    // Gracefully handle failure - show placeholder image
                                    cachedImages[cacheKey] = UIImage(systemName: "photo") ?? UIImage()
                                }
                            }
                    }
                    
                    VStack(alignment:.trailing,spacing: height/120) {
                        
                          
                        Text(item.product.name)
                            .font(.custom("DoranNoEn-Medium", size: 16, relativeTo: .body))
                            .multilineTextAlignment(.center)
                        HStack(spacing:2) {
                            
                            if item.variant != nil {
                                Text("\(item.variant!.price_toman!.getFormattedPrice())")
                                    .font(.custom("DoranNoEn-Medium", size: 14, relativeTo: .body))
                                    .multilineTextAlignment(.center)
                            }else{
                                Text("\(item.product.getFormattedPrice().persianDigits)")
                                    .font(.custom("DoranNoEn-Medium", size: 14, relativeTo: .body))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Text("قیمت: ")
                                .font(.custom("DoranNoEn-Medium", size: 14, relativeTo: .body))
                                .multilineTextAlignment(.center)
                        }
                    
                    HStack(spacing:width/40) {
                        VStack {
                            Text("تعداد")
                                .font(.custom("DoranNoEn-Medium", size: 12))
                                Text("\(item.quantity.persianDigits)")
                                .font(.custom("DoranNoEn-Medium", size: 14))
                        }
                        Rectangle()
                            .foregroundStyle(.black)
                            .frame(width:1,height:height/30)
                            .padding(.horizontal,width/60)
                        
                        VStack {
                            
                                if let new = item.variant {
                                    
                                    VStack {
                                        Text("\(new.attributes[0].display_name!)")
                                            .font(.custom("DoranNoEn-Medium", size: 12))
                                        
                                        Text("\(new.attributes[0].value.applyingPersianDigitsIfInteger())")
                                .font(.custom("DoranNoEn-Medium", size: 12))
                                        
                                        
                                    }
                                    
                                }else {
                                    
                                    Text(displayAttributeValue(at: 0, from: item.product.attributes))                                    .font(.custom("DoranNoEn-Medium", size: 12))
                                    Text(item.product.attributes?.count ?? 0 > 1 ? item.product.attributes?[0].value ?? "NOT" : "NAH")
                                .font(.custom("DoranNoEn-Medium", size: 12))
                                    
                                    
                                }
                                
                            
                        }
                        Rectangle()
                            .foregroundStyle(.black)
                            .frame(width:1,height:height/30)
                            .padding(.horizontal,width/60)
                        
                        VStack {
                                
                                if let new = item.variant {
                                    
                                    VStack {
                                        Text("\(new.attributes[1].display_name ?? "")")
                                            .font(.custom("DoranNoEn-Medium", size: 12))
                                        Text("\(new.attributes[1].value.applyingPersianDigitsIfInteger())")
                                            .font(.custom("DoranNoEn-Medium", size: 12))
                                        
                                        
                                    }
                                    
                                }else {
                                    
                                    
                                    Text(item.product.attributes?.count ?? 0 > 1 ? item.product.attributes?[1].display_name ?? "" : "")
                                .font(.custom("DoranNoEn-Medium", size: 12))
                                    Text(item.product.attributes?.count ?? 0 > 1 ? item.product.attributes?[1].value ?? "" : "")
                                .font(.custom("DoranNoEn-Medium", size: 12))

                                    
                                    
                                    
                                }
                                
                                 
                                
                                
                                
                            }
                    }
                    
                    
                    HStack {
                        HStack(spacing: 0) {
                            Button {
                                    Task {
                                        do {
                                            if try await shoppingBasketVM.deleteFromBasket(itemId: item.id, quantity: 1) {
                                                // Now this will run AFTER loadShoppingBasket() completes
                                                await MainActor.run {
                                                    isOverStocked = true
                                                }
                                            } else {
                                                print("didnt done")
                                            }
                                        } catch {
                                            print("Failed to delete item from basket: \(error)")
                                            // Gracefully handle error - don't crash
                                        }
                                    }
                                }label: {
                                Text("-")
                                    .frame(width: width/18)
                                        .onAppear {
                                            
                                            
                                            if let variant = item.variant {
                                                totalPrice += Double(item.quantity)
                                                *
                                                Double(variant.price_toman!)
                                            }else{
                                                totalPrice += Double(item.quantity)
                                                *
                                                Double(item.product.price_toman!)
                                            }
                                            
                                       
                                        }
                                }
                            
                            Rectangle() // vertical line between buttons
                                .frame(width:1,height:width / 20)
                                .foregroundStyle(.gray)
                            Button {
                                // increment action
                                    
                                    
                                    
                            } label: {
                                Text("+")
                                    .frame(width: width/18)
                            }
                        }.frame(height:height/30)
                        
                        .foregroundStyle(.black)
                        
                        Button {
                            deleteItemId = item.id
                            isDeleteButtonTapped = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                                .opacity(0.6)
                        }
                            
                        }
                        Spacer()
                        
                }.padding(.trailing)
                
            }
            }
            
            .frame(width:width/1,height:height/5)
            Spacer()
            
            Rectangle()
                .frame(height:0.5)
                .opacity(0.4)
              
            
        }
//        .id(shoppingBasketVM.basket.updated_at) // Force refresh when basket updates    }
    }
    
    @ViewBuilder
    func deleteAlert() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .frame(width: width/1.4, height: height/6)
                .background(CustomBlurView(effect: .systemUltraThinMaterialLight))
            VStack(spacing: 0) {
                Spacer()
                if isDeleting {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        Text("در حال حذف...")
                            .font(.custom("AbarHighNoEn-Regular", size: 18, relativeTo: .body))
                    }
                } else {
                    Text("محصول از سبد خرید حذف بشه؟")
                        .font(.custom("AbarHighNoEn-Regular", size: 20, relativeTo: .body))
                }

                Spacer()
                Divider()
                HStack {
                    Spacer()
                    
                    Button {
                        if !isDeleting {
                            withAnimation {
                                isDeleteButtonTapped = false
                                deleteItemId = 0
                                isDeleting = false
                            }
                        }
                    } label: {
                        Text("نه")
                            .font(.custom("AbarHighNoEn-Regular", size: 20, relativeTo: .body))
                            .foregroundStyle(isDeleting ? .gray : .black)
                    }
                    .disabled(isDeleting)
                    
                    Spacer()

                    Divider()
                    Spacer()

                    Button {
                        if !isDeleting && deleteItemId != 0 {
                            Task {
                                isDeleting = true
                                
                                // Add timeout wrapper
                                do {
                                    try await withTimeout(seconds: 10) {
                                        try await shoppingBasketVM.deleteFromBasket(itemId: deleteItemId, quantity: nil)
                                        do {
                                            try await shoppingBasketVM.loadShoppingBasket()
                                        } catch {
                                            print("Failed to reload basket after delete: \(error)")
                                            // Gracefully handle error - don't crash
                                        }
                                    }
                                } catch {
                                    print("❌ Failed to delete item: \(error)")
                                    print("❌ Error type: \(type(of: error))")
                                    
                                    // Show error message to user
                                    await MainActor.run {
                                        print("🔔 Setting error message in catch block")
                                        if error is TimeoutError {
                                            errorMessage = "عملیات حذف زمان بر شد. لطفا دوباره تلاش کنید."
                                        } else {
                                            errorMessage = "مشکل در حذف مورد از سبد خرید"
                                        }
                                        showErrorAlert = true
                                        print("🔔 errorMessage set to: \(errorMessage ?? "nil")")
                                        print("🔔 showErrorAlert set to: \(showErrorAlert)")
                                    }
                                    
                                    // Still reload basket in case of error
                                    do {
                                        try await shoppingBasketVM.loadShoppingBasket()
                                    } catch {
                                        print("Failed to reload basket after delete error: \(error)")
                                        // Gracefully handle error - don't crash
                                    }
                                }
                                
                                withAnimation {
                                    isDeleteButtonTapped = false
                                    deleteItemId = 0
                                    isDeleting = false
                                }
                            }
                        }
                    } label: {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text("آره")
                                .font(.custom("AbarHighNoEn-Regular", size: 20, relativeTo: .body))
                                .foregroundStyle(.black)
                        }
                    }
                    .disabled(isDeleting)
                 
                    Spacer()
                }
                .frame(height: height/14)
            }
        }
        .frame(width: width/1.4, height: height/6)
        .cornerRadius(20)
        .zIndex(20)
    }
    
    @ViewBuilder
    func MenuItems(_ id: Int) -> some View {
        
        Menu {
            Button {
                print("Edit tapped")
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                print("Delete tapped")
                Task {
                    do {
                        try await shoppingBasketVM.deleteFromBasket(itemId: id, quantity: nil)
                        // Basket will be automatically reloaded by the view model
                    } catch {
                        print("Failed to delete item: \(error)")
                    }
                }
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
                .frame(height:height/30)
        }
        .foregroundColor(.black)
    }
    
    @ViewBuilder
    private func navBar() -> some View {
        VStack {
            Spacer()
            
            HStack(alignment:.bottom) {
                
                Button{
                    
                    navigationVM.popView(from: navigationVM.currentTab)
                    
                }label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .frame(width: width/16, height: width/16)
                        .foregroundStyle(.black)
                }
                .padding(.bottom,10)
                .padding(.leading,width/18)
                
                Spacer()
                
                Text("سبد خرید")
                    .font(.custom("DoranNoEn-ExtraBold", size: 20, relativeTo: .body))
                
                Spacer()
                
                Button(action: {
                    // Use navigationManager to go back
                    navigationVM.popView(from: .review)
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .frame(width: width/16, height: width/16)
                        .foregroundStyle(.black)
                }
                .padding(.leading,width/18)
                .opacity(0)
               
            }
            .padding(.bottom,2)
        }
        .frame(height: height/9 )
        .background(CustomBlurView(effect: .systemThinMaterial))
                .zIndex(1)
        
    }
    
    func displayAttributeValue(at index: Int, from attribute: [basketAttribute]?) -> String {
        
        guard let attribute = attribute,
              index < attribute.count else {
            return ""
        }
        
        if !attribute[index].display_name.isEmpty {
            return attribute[index].display_name
        }else{
            return ""
        }
    }
}


//
//#Preview {
//    ShoppingBasket(product: shoppingBasket.basketSampleProducts )
//}



import SwiftUI

struct CheckoutBar: View {
    var totalPrice: Double
    var onCheckout: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider() // subtle top border
            
            HStack {
                // Total Price
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("$\(totalPrice, specifier: "%.2f")")
                        .font(.title3.bold())
                }
                
                
                // Checkout Button
                Button(action: onCheckout) {
                    Text("Continue to Checkout")
                        .font(.headline)
                        .frame(maxWidth: 180)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.blue)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                // iOS-style translucent blur
                VisualEffectBlur(effect: .systemMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

/// UIKit blur wrapper for SwiftUI
struct VisualEffectBlur: UIViewRepresentable {
    var effect: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: effect))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Animated Text Component
struct AnimatedText: View {
    let text: String
    @State private var displayText: String = ""
    @State private var animationTimer: Timer?
    @State private var isAnimating = false
    
    private let scrambleChars = "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی"
    
    var body: some View {
        Text(displayText.isEmpty ? text : displayText)
            .animation(.easeInOut(duration: 0.1), value: displayText)
            .onAppear {
                startAnimation(targetText: text)
            }
    }
    
    private func startAnimation(targetText: String) {
        guard !isAnimating else { return }
        
        isAnimating = true
        displayText = String(repeating: "?", count: targetText.count)
        
        // Start the scrambling animation
        var iteration = 0
        let totalIterations = 10 // Number of scrambling cycles
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if iteration < totalIterations {
                // Scramble the text
                self.displayText = scrambleText(targetText: targetText, progress: Double(iteration) / Double(totalIterations))
                iteration += 1
            } else {
                // Show final text
                self.displayText = targetText
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

#Preview {
    ShoppingBasket()
        .environmentObject(shoppingBasketViewModel())
        .environmentObject(NavigationStackManager())
        .environmentObject(AddressViewModel())
}


//#Preview {
//    // Create a mock view model with sample data
//    let mockViewModel = shoppingBasketViewModel()
//    let mockAddress = AddressViewModel()
//    
//    // Set up mock data for preview
//    mockViewModel.basket = shoppingBasket(
//        id: 1,
//        items: [
//            
//            basketItem(
//                id: 1,
//                product: basketProduct(
//                    id: 1,
//                    name: "Sample Product",
//                    price_toman: 150000.0,
//                    image_url: "/media/products/sample.jpg"
//                ),
//                quantity: 2,
//                total_price_toman: 300000,
//                total_price_usd: 10,
//                added_at: "2024-01-01T00:00:00Z"
//            ),
//            basketItem(
//                id: 2,
//                product: basketProduct(
//                    id: 2,
//                    name: "Another Product",
//                    price_toman: 200000.0,
//                    image_url: "/Downloads/New%20Folder%20With%20Items%2096/1.jpg"
//                ),
//                quantity: 1,
//                total_price_toman: 200000,
//                total_price_usd: 7,
//                added_at: "2024-01-01T00:00:00Z"
//            )
//        ],
//        total_items: 3,
//        total_price_toman: 500000.0,
//        total_price_usd: 17.0,
//        created_at: "2024-01-01T00:00:00Z",
//        updated_at: "2024-01-01T00:00:00Z"
//    )
//    
//    mockAddress.addressesArray = [
//        Address(label: "خانه", receiver_name: "سعیدی", country: "h", state: "تهران", city: "تهران", street_address: "خیابان شماره ۸۵", unit: "12", postal_code: "1475733123", phone: "09017903276")
//    ]
//    
//    
//    return ShoppingBasket()
//        .environmentObject(mockViewModel)
//        .environmentObject(mockAddress)
//        .environmentObject(NavigationStackManager())
//        .environmentObject(AddressViewModel())
//}

extension Double {
    func formattedPriceFA() -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fa_IR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// Conditionally apply Persian digits only if the string is an integer
extension String {
    func applyingPersianDigitsIfInteger() -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return self }
        // Check if all characters are digits (ASCII or Unicode digits)
        let allScalarsAreDigits = trimmed.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
        return allScalarsAreDigits ? self.persianDigits : self
    }
}

extension Double {
    func getFormattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "fa_IR") // Persian digits
        
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "۰"
        return "\(formatted) تومان"
    }
}

// MARK: - Timeout Helper
enum TimeoutError: Error {
    case timedOut
}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the main operation
        group.addTask {
            try await operation()
        }
        
        // Add a timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError.timedOut
        }
        
        // Wait for the first task to complete
        guard let result = try await group.next() else {
            throw TimeoutError.timedOut
        }
        
        // Cancel remaining tasks
        group.cancelAll()
        
        return result
    }
}

// MARK: - Order Submission Data Collection
struct OrderSubmissionData: Codable {
    // MARK: - Delivery Address Information
    /// **RECOMMENDED**: Use addressId if address already exists in database
    /// The API will fetch full address details using this ID
    /// If addressId is provided, individual address fields are ignored
    var addressId: Int?
    
    /// **ALTERNATIVE**: Individual address fields (only used if addressId is nil)
    /// These are required if creating a new address during checkout
    var receiverName: String
    var streetAddress: String
    var city: String
    var province: String?
    var unit: String?
    var phone: String
    var country: String
    var postalCode: String?
    var addressLabel: String?
    
    // MARK: - Delivery Options
    /// Delivery method selection (required)
    /// Options: "standard", "express", "pickup"
    var deliveryOption: String
    
    // MARK: - Payment Information
    /// Payment method selection (required)
    /// Options: "cod" (Cash on Delivery), "online", "bank_transfer"
    /// Payment processing happens on backend based on this value:
    /// - "cod": Order marked as paid (payment collected on delivery)
    /// - "online": Payment gateway integration required
    /// - "bank_transfer": Order marked as pending until payment confirmed
    var paymentMethod: String
    
    // MARK: - Discount & Promotions
    /// Discount/Promo code (optional)
    var discountCode: String?
    
    // MARK: - Additional Notes
    /// Special delivery instructions (optional)
    var deliveryNotes: String?
    
    // MARK: - IMPORTANT NOTES:
    /// 1. Cart Items: NOT sent in request - backend automatically gets them from user's cart
    ///    The API reads cart.items.all() from the database using your authentication token
    /// 
    /// 2. User Information: NOT sent in request - backend gets from authentication token
    ///    The API uses request.user from your JWT/token to get:
    ///    - user_id (from token)
    ///    - email (from token)
    ///    - first_name, last_name (from user model)
    
    enum CodingKeys: String, CodingKey {
        case addressId = "address_id"
        case receiverName = "receiver_name"
        case streetAddress = "street_address"
        case city
        case province
        case unit
        case phone
        case country
        case postalCode = "postal_code"
        case addressLabel = "address_label"
        case deliveryOption = "delivery_option"
        case paymentMethod = "payment_method"
        case discountCode = "discount_code"
        case deliveryNotes = "delivery_notes"
    }
    
    // MARK: - Validation
    /// Validates that all required fields are present
    func validate() -> (isValid: Bool, missingFields: [String]) {
        var missingFields: [String] = []
        
        if addressId == nil {
            // If no address_id, individual address fields are required
            if receiverName.isEmpty {
                missingFields.append("receiver_name")
            }
            if streetAddress.isEmpty {
                missingFields.append("street_address")
            }
            if city.isEmpty {
                missingFields.append("city")
            }
            if phone.isEmpty {
                missingFields.append("phone")
            }
        }
        
        if deliveryOption.isEmpty {
            missingFields.append("delivery_option")
        }
        
        if paymentMethod.isEmpty {
            missingFields.append("payment_method")
        }
        
        return (missingFields.isEmpty, missingFields)
    }
    
    // MARK: - API Request Format
    /// Converts to dictionary format for POST request JSON body
    /// This is what gets sent to: POST /checkout/
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Address: Use ID if available, otherwise send individual fields
        if let addressId = addressId {
            // RECOMMENDED: Just send address_id, backend fetches full address
            dict["address_id"] = addressId
        } else {
            // ALTERNATIVE: Send individual fields for new address
            dict["receiver_name"] = receiverName
            dict["street_address"] = streetAddress
            dict["city"] = city
            if let province = province {
                dict["province"] = province
            }
            if let unit = unit {
                dict["unit"] = unit
            }
            dict["phone"] = phone
            dict["country"] = country
            if let postalCode = postalCode {
                dict["postal_code"] = postalCode
            }
            if let addressLabel = addressLabel {
                dict["address_label"] = addressLabel
            }
        }
        
        // Required fields
        dict["delivery_option"] = deliveryOption
        dict["payment_method"] = paymentMethod
        
        // Optional fields
        if let discountCode = discountCode, !discountCode.isEmpty {
            dict["discount_code"] = discountCode
        }
        
        if let deliveryNotes = deliveryNotes, !deliveryNotes.isEmpty {
            dict["delivery_notes"] = deliveryNotes
        }
        
        // NOTE: Cart items and user info are NOT included here
        // Backend automatically gets them from:
        // - Cart: cart.items.all() (from authenticated user's cart)
        // - User: request.user (from JWT token)
        
        return dict
    }
    
    // MARK: - Example JSON Output
    /// Example of what gets sent to POST /checkout/
    /// 
    /// Scenario 1: Using existing address (RECOMMENDED)
    /// {
    ///   "address_id": 5,
    ///   "delivery_option": "standard",
    ///   "payment_method": "cod",
    ///   "discount_code": "SAVE10"
    /// }
    ///
    /// Scenario 2: Creating new address during checkout
    /// {
    ///   "receiver_name": "حسام سعیدی",
    ///   "street_address": "خیابان الهیه، پلاک 12، واحد 1",
    ///   "city": "تهران",
    ///   "province": "تهران",
    ///   "unit": "1",
    ///   "phone": "09121234567",
    ///   "country": "ایران",
    ///   "postal_code": "1234567890",
    ///   "address_label": "خانه",
    ///   "delivery_option": "express",
    ///   "payment_method": "online",
    ///   "delivery_notes": "لطفا قبل از 10 صبح تحویل دهید"
    /// }
    ///
    /// Backend Response (what you get back):
    /// {
    ///   "id": 123,
    ///   "order_number": "ORD-2025-001",
    ///   "customer": {
    ///     "id": 42,
    ///     "email": "user@example.com",
    ///     "first_name": "حسام",
    ///     "last_name": "سعیدی"
    ///   },
    ///   "delivery_address": {
    ///     "id": 5,
    ///     "receiver_name": "حسام سعیدی",
    ///     "street_address": "خیابان الهیه، پلاک 12",
    ///     ...
    ///   },
    ///   "items": [
    ///     {
    ///       "product_id": 1,
    ///       "variant_id": 5,
    ///       "product_name": "iPhone 15",
    ///       "quantity": 2,
    ///       "unit_price_toman": 5000000,
    ///       "total_price_toman": 10000000
    ///     }
    ///   ],
    ///   "subtotal_toman": 10000000,
    ///   "shipping_cost_toman": 25000,
    ///   "discount_amount_toman": 1000000,
    ///   "total_toman": 9025000,
    ///   "payment_method": "cod",
    ///   "payment_status": "pending",
    ///   "status": "pending",
    ///   "created_at": "2025-01-15T10:30:00Z"
    /// }
}

// MARK: - Order Item Data (for basket items)
struct OrderItemData: Codable {
    /// Product ID (required)
    let productId: Int
    
    /// Variant ID (optional, required if product has variants)
    let variantId: Int?
    
    /// Quantity (required, must be > 0)
    let quantity: Int
    
    /// Unit price in Toman (required)
    let priceToman: Double
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case variantId = "variant_id"
        case quantity
        case priceToman = "price_toman"
    }
}
