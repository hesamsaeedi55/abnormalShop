Error saving product: Model instances passed to related filters must be saved.
//
//  PlacesView.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 6/18/23.
//

import SwiftUI
import Combine
import Kingfisher

struct PlacesView1: View {
    
    // MARK: - Constants
    let product: ProductTest
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    let images: [String] = ["o4", "o2", "o1", "o3", "o4"]
    let sizes: [String: Bool] = ["XS": false, "S": false, "M": true, "L": true, "XL": false]
    let sizeOrder = ["XS", "S", "M", "L", "XL"]
    
    var attributeImages : [String] = []
    
    // MARK: - Environment & Observed Objects
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var attVM: AttributeViewModel
    @EnvironmentObject var viewModel: ProductViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var catVM: CategoryViewModel
    
    // MARK: - UI States
    @State var isPresented = false
    @State var selectedImage: String = ""
    @State var blurAnimation: CGFloat = 0
    @State var saveButton = false
    @State private var isDeleteTapped = false
    @State var isFullScreen: Bool = false
    @State var isTapped: Bool = false
    @State private var isButtonDisabled = false
    @State var shimmerView = false
    @State var specialAttribute: String = ""
    @State var imagesOfDisplay: [String] = []
    @State var selectedColor = ""
    @State var selectedVariantId: Int = 0
    @State var isShowingPopup: Bool = false
    @State var dragOffsetPopup: CGFloat = 0
    
    // MARK: - Image States with Robust Caching
    @State private var cachedImages: [UIImage] = []
    @State private var isLoading = true
    @State private var currentIndex = 0
    @State private var onceDone: Bool = true
    @State private var imageLoadErrors: [Int: Bool] = [:] // Track which images failed to load
    
    // MARK: - Gesture & Animation States
    @State private var isLiked: Bool = false
    @State private var scale1: CGFloat = 1.0
    @State private var previousOffset: CGFloat = 0
    @State private var dragProgress: CGFloat = 0
    @State private var lastSwipeDirection: SwipeDirection = .none
    @State private var temp: CGFloat = 0
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
    @State private var newofffset: CGFloat = 0
    @State private var geoWatch: CGFloat = 0
    @State private var fullScreen: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var blurAmount: CGFloat = 0
    
    @State private var selectedUI: CategoryUI?
    @State private var isScrolledDown: Bool = false
    @State private var hasSetInitialGeo = true
    @State var initialGeo: CGFloat = 0

    @EnvironmentObject var navigationManager: NavigationStackManager

    let lastNavigation: NavigationStackManager.TabPage?
    
    // MARK: - Enums
    enum SwipeDirection {
        case none, left, right
    }
    
    enum CategoryUI {
        case watches, clothes
    }
    
    var uiStructure: Any {
        switch selectedUI {
        case .watches:
            return ["diving","oris","auth"]
        case .clothes:
            return ["1","1","1"]
        case .none:
            return ["1","1","1"]
        }
    }
 
    var body: some View {
        ZStack {
            removeFromWishList()
            addToWishList()
            
            VStack(spacing:0) {
                navBar()
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators:false) {
                        GeometryReader { geometry in
                            imageTab(geometry: geometry, proxy: proxy)
                           
                            VStack {
                                Spacer()
                                 
                                HStack {
                                    Spacer()
                                     
                                    Text(splitProductName(product.name))
                                        .font(.custom("AbarHighNoEn-SemiBold", size: 30, relativeTo: .body))
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(.white)
                                        .padding(.trailing,18)
                                        .padding(.bottom,10)
                                    
                                }   .background(CustomBlurView(effect: .systemUltraThinMaterialDark)
                                    .frame(width: width*2, height: height/6)
                                    .blur(radius: 20)
                                    .offset(y:10)
                                )
                            }.clipped()
                            
                            .onChange(of: currentIndex) { value in
                                if value != 1 {
                                    temp = 0
                                    onceDone = false
                                }
                            }
                           
                            .onChange(of:geometry.frame(in: .global).minY) { geo in
                                if  geo > 150 {
                                    isScrolledDown = true
                                }
                            }
                        }
                        .aspectRatio(4.0/6.0, contentMode: .fit)
                        .onAppear {
                            if let attrs = product.display_attributes {
                                print("Display attributes count: \(attrs.count)")
                                print("Display attributes: \(attrs)")
                            } else {
                                print("Display attributes is nil")
                            }
                        }
                   
                        VStack {
                            imageTabIndicator()
                            
                            HStack {
                                HStack(spacing: 0) {
                                    VStack(spacing:0) {
                                        ZStack {
                                            Image("textilemainicon")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: width/24, height: height/24)
                                        }.frame(width: width/16, height: height/16)
                                        
                                        // Safe access: check if array exists and has at least 1 element
                                        if let attrs = product.display_attributes, attrs.count > 0 {
                                            Text(attrs[0].value ?? "")
                                                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                                        } else {
                                            Text("")
                                                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                                        }
                                    }
                                    .frame(width: width/6)
                                    Divider()
                                    
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            ZStack {
                                                Image("shirtmainicon")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: width/20, height: height/20)
                                            }
                                            .frame(width: width/16, height: height/16)
                                        }
                                        // Safe access: check if array exists and has at least 2 elements
                                        if let attrs = product.display_attributes, attrs.count > 1 {
                                            Text(attrs[1].value ?? "")
                                                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                                        } else {
                                            Text("")
                                                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                                        }
                                    } .frame(width: width/6)
                                        
                                    Divider()
                                        .background(Color.white)
                                    
                                    VStack(spacing:0) {
                                        ZStack {
                                            Image("handsmainicon")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: width/16, height: width/16)
                                        }
                                        .frame(width: width/16, height: width/16)
                                        
                                        // Safe access: check if array exists and has at least 3 elements
                                        if let attrs = product.display_attributes, attrs.count > 2 {
                                            Text(attrs[2].value ?? "")
                                                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                                        } else {
                                            Text("")
                                                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                                        }
                                    }
                                    .frame(width: width/6)
                                }
                                .frame(width: width/2)
                                .padding(.bottom,50)
                                .scaleEffect(0.9)
                                
                                HStack {
                                    Spacer()
                                     
                                    VStack(alignment:.trailing) {
                                        Text("قیمت:  ")
                                            .font(.custom("DoranNoEn-Bold", size: width/28))
                                        + Text(product.getFormattedPrice().persianDigits)
                                            .font(.custom("DoranNoEn-Medium", size: width/28))
                                        
                                        Button {
                                            navigationManager.isMainTabBarHidden = true
                                            isShowingPopup = true
                                        } label: {
                                            Text("خرید")
                                                .font(.custom("DoranNoEn-Bold", size: width/28))
                                        }
                                    }
                                    .padding(.trailing,5)
                                }
                            }
                            
                            VariantSelectorView(product: product)
                        }
                        
                        DropDownMenu(text: product.description!, width: width, height: height/20, font: .custom("AbarHighNoEn-SemiBold", size: 16, relativeTo: .body), fontCaption: .custom("AbarHighNoEn-Regular", size: 14, relativeTo: .body))
                        
                        Divider()
                            .background(Color.white)
                        attributeSection()
                        description()
                        
                        HStack {
                            Spacer()
                            Text("Similar Items")
                                .font(.custom("Futura", size: width/16).bold())
                                .multilineTextAlignment(.center)
                                .padding(8)
                            Spacer()
                            Text("\(product.variants_count ?? 0)")
                                .font(.custom("Futura", size: width/16).bold())
                                .multilineTextAlignment(.center)
                                .padding(8)
                            Spacer()
                        }
                        .padding(.bottom,height/6)
                        
                        HStack {
                            ForEach(product.similar_products ?? [],id:\.id) { item in
                                // Similar products content
                            }
                        }
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            
            // MARK: - Robust Image Loading with Retry Logic
            .task(id: product.id) {
                print("🔄 Starting robust image preload for product \(product.id)")
                
                // Clear previous errors
                imageLoadErrors.removeAll()
                
                // Load images with retry logic
                let urls = product.images.compactMap { URL(string: $0.url) }
                cachedImages = await ImageStore.shared.preload(urls: urls, keyPrefix: "product-\(product.id)")
                
                // Check for failed images and retry individually if needed
                for (index, imageUrl) in product.images.enumerated() {
                    if index >= cachedImages.count || cachedImages[index] == nil {
                        print("⚠️ Image \(index) failed to load, attempting individual retry...")
                        imageLoadErrors[index] = true
                        
                        // Individual retry with longer timeout
                        if let url = URL(string: imageUrl.url) {
                            let retryImage = await ImageStore.shared.loadImage(url: url, key: "product-\(product.id)-\(index)-retry")
                            if let retryImage = retryImage, index < cachedImages.count {
                                cachedImages[index] = retryImage
                                imageLoadErrors[index] = false
                                print("✅ Retry successful for image \(index)")
                            }
                        }
                    }
                }
                
                isLoading = false
                print("✅ Robust image preload completed for product \(product.id)")
            }
            
            .onAppear {
                print(product.variants)
            }
            
            VStack {
                Spacer()
                HStack(spacing:3) {
                    Button {
                        isButtonDisabled = true
                        if isLiked {
                            Task {
                                if try await viewModel.removeFromWishlist(product) {
                                    isLiked = false
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        isDeleteTapped = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            isDeleteTapped = false
                                        }
                                        isButtonDisabled = false
                                    }
                                }else{
                                    isLiked = true
                                    isButtonDisabled = false
                                }
                            }
                        }else{
                            Task {
                                do {
                                    let response = try await viewModel.addToWishlist(product)
                                    
                                    if response.success {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            isLiked.toggle()
                                        }
                                        
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            scale1 = 1.2
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                scale1 = 1.0
                                            }
                                        }
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            isTapped = true
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                isTapped = false
                                            }
                                            isButtonDisabled = false
                                        }
                                    }
                                } catch {
                                    print("❌ Error: \(error)")
                                    isButtonDisabled = false
                                }
                            }
                        }
                    }label:{
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .scaleEffect(scale1)
                            .frame(width: width/8.0, height: width/10)
                            .font(.custom("DoranNoEn-Medium", size: 26, relativeTo: .body))
                            .foregroundStyle(isLiked ? .white : .white)
                            .background(.black)
                    }
                    .disabled(isButtonDisabled)

                    Button {
                         
                    }label:{
                        Text("افزودن به سبد خرید")
                            .frame(width:width/1.8,height: width/10)
                            .font(.custom("DoranNoEn-Medium", size: 20, relativeTo: .body))
                            .foregroundStyle(.white)
                            .background(.black)
                    }
                }
                .padding(.bottom,height/18)
                .opacity(isScrolledDown ? 1 : 0)
                .onChange(of:isFullScreen) { newValue in
                    if newValue {
                        navigationManager.isMainTabBarHidden = true
                    }else{
                        navigationManager.isMainTabBarHidden = false
                    }
                }
            }
            
            if isFullScreen {
                ZStack {
                    fullScreenImage()
                }
            }
            
            // MARK: - Size popup
            ZStack {
                GeometryReader { geo in
                    VStack {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isShowingPopup = false
                            }

                        Spacer()
                        popup(isShowingPopup, height: height)
                    }
                }
            }
            .offset(y: dragOffsetPopup)
            .opacity(isShowingPopup ? 1 : 0)
            .ignoresSafeArea()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffsetPopup = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 30 || value.predictedEndTranslation.height > 50 {
                            withAnimation(.easeOut(duration: 0.25)) {
                                isShowingPopup = false
                                dragOffsetPopup = 0
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.25)) {
                                dragOffsetPopup = 0
                            }
                        }
                    }
            )
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges:.top)
    }
    
    // MARK: - Image Tab with Error Handling
    @ViewBuilder
    private func imageTab(geometry:GeometryProxy,proxy:ScrollViewProxy) -> some View {
        VStack {
            ZStack {
                TabView(selection: $currentIndex) {
                    ForEach(cachedImages.indices, id: \.self) { idx in
                        GeometryReader { geometry in
                            Group {
                                if idx < cachedImages.count, let image = cachedImages[idx] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .clipped()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width,
                                            height: geometry.frame(in: .global).minY - initialGeo <= 0 ?
                                            geometry.size.height :
                                            geometry.size.height + geometry.frame(in: .global).minY - initialGeo)
                                } else {
                                    // Fallback for failed images
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        
                                        if imageLoadErrors[idx] == true {
                                            Button("Retry") {
                                                Task {
                                                    await retryImageLoad(at: idx)
                                                }
                                            }
                                            .font(.caption)
                                            .padding(.top, 4)
                                        }
                                    }
                                    .frame(width: geometry.size.width,
                                        height: geometry.frame(in: .global).minY - initialGeo <= 0 ?
                                        geometry.size.height :
                                        geometry.size.height + geometry.frame(in: .global).minY - initialGeo)
                                    .background(Color.gray.opacity(0.1))
                                }
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isFullScreen = true
                                }
                            }.disabled(isFullScreen)
                            .id("hero-\(idx)")
                            .background(Color.black)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minX)
                                }
                            )
                            .onAppear {
                                if hasSetInitialGeo {
                                    initialGeo = geometry.frame(in: .global).minY
                                    hasSetInitialGeo = false
                                }
                            }
                            .blur(radius: geometry.frame(in: .global).minY <= 0 ? -geometry.frame(in: .global).minY/20 : 0)
                        }
                        .tag(idx)
                        .clipped()
                    }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onPreferenceChange(ScrollOffsetKey.self) { newOffset in
            updateDragProgress(newOffset)
        }
    }
    
    @ViewBuilder
    private func fullScreenImage() -> some View {
        GeometryReader { geometry in
            ZStack {
                // TabView takes the full space
                TabView(selection: $currentIndex) {
                    ForEach(cachedImages.indices, id: \.self) { idx in
                        VStack {
                            Spacer()
                            Image(uiImage: cachedImages[idx])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isFullScreen = false
                                    }
                                }
                                .id("hero-\(idx)")
                                .clipped()
                            Spacer()
                        }
                        .tag(idx)
                    }
                }
                
                // Close button overlay
                VStack {
                    HStack {
                        Button {
                            withAnimation(.easeOut) {
                                isFullScreen = false
                            }
                        } label: {
                            Image(systemName:"xmark.circle.fill")
                                .resizable()
                                .frame(width: geometry.size.width/18, height: geometry.size.width/18)
                                .foregroundStyle(.white)
                                .opacity(0.80)
                        }
                        .padding(.leading, 20)
                        .padding(.top, height/20)
                        Spacer()
                    }

                    Spacer()
                    
                }
                HStack {
                    VStack(alignment:.leading,spacing: height/100) {
                        
                        HStack {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ForEach(Array(cachedImages.enumerated()), id: \.offset) { (idx, image) in
                                        Rectangle()
                                            .frame(width: getDynamicWidth(for: idx), height: 2)
                                            .onTapGesture {
                                                withAnimation {
                                                    currentIndex = idx
                                                }
                                            }
                                            .padding(.bottom, height/8)
                                    }
                                    Spacer()
                                }
                                .frame(width:400, height: height / 36)
                                
                            }
                        }
                  
                    }
                    
                    
                    .padding(.leading,width/50)
                    Spacer()
                    
                    
                    
                }
                .frame(width:width)
                    .colorInvert()

            }
        }
        .background(.black)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
    
    // MARK: - Individual Image Retry
    private func retryImageLoad(at index: Int) async {
        guard index < product.images.count else { return }
        
        let imageUrl = product.images[index]
        if let url = URL(string: imageUrl.url) {
            print("🔄 Retrying individual image load for index \(index)")
            
            let retryImage = await ImageStore.shared.loadImage(url: url, key: "product-\(product.id)-\(index)-manual-retry")
            
            await MainActor.run {
                if let retryImage = retryImage {
                    // Ensure we have enough space in the array
                    while cachedImages.count <= index {
                        cachedImages.append(UIImage())
                    }
                    cachedImages[index] = retryImage
                    imageLoadErrors[index] = false
                    print("✅ Manual retry successful for image \(index)")
                } else {
                    print("❌ Manual retry failed for image \(index)")
                }
            }
        }
    }
    
    // MARK: - Rest of your existing methods...
    // (I'll include the key methods, but you can copy the rest from your original file)
    
    @ViewBuilder
    private func imageTabIndicator() -> some View {
        HStack {
            VStack(alignment:.leading,spacing: height/100) {
                HStack {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ForEach(Array(product.images.enumerated()), id: \.element.id) { (idx, image) in
                                Rectangle()
                                    .frame(width: getDynamicWidth(for: idx), height: 2)
                                    .foregroundColor(imageLoadErrors[idx] == true ? .red : .white)
                                    .onTapGesture {
                                        withAnimation {
                                            currentIndex = idx
                                        }
                                    }
                                    .padding(.bottom, isFullScreen ? height/8 : 0)
                            }
                            Spacer()
                        }
                        .frame(width:400, height: height / 36)
                    }
                }
            }
            .padding(.leading,width/50)
            Spacer()
        }
        .frame(width:width)
    }
    
    @ViewBuilder
    private func navBar() -> some View {
        VStack {
            VStack {
                Spacer()
                
                HStack(alignment:.bottom) {
                    Button(action: {
                        Task {
                            ImageStore.shared.clear(prefix: "product-\(product.id)")
                        }
                        navigationManager.popView(from: lastNavigation)
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .frame(width: width/16, height: width/16)
                            .foregroundStyle(.black)
                    }
                    .padding(.bottom,10)
                    .padding(.leading,width/18)
                    
                    Spacer()
                     
                    Text("\(product.attributeValue(forKey: "brand") ?? "")")
                        .font(.custom("AbarHighNoEn-Black", size: 20, relativeTo: .body))

                    Spacer()
                        
                    Button(action: {
                        Task {
                            ImageStore.shared.clear(prefix: "product-\(product.id)")
                            await viewModel.changeCategory(attVM.categoryID!, brand: attVM.selectedValue)
                        }
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .frame(width: width/18, height: width/18)
                            .foregroundStyle(.black)
                    }
                    .padding(.leading,width/18)
                    .opacity(0)
                }
                .padding(.bottom,2)
            }
            .frame(height: height/9 )
            .background(CustomBlurView(effect: .systemThinMaterial))
            .opacity(isFullScreen ? 0 : 1)
        }
        .zIndex(1)
    }
    
    @ViewBuilder
    private func addToWishList() -> some View {
        ZStack {
            CustomBlurView(effect: .systemThinMaterial)
                .ignoresSafeArea()
            
            Text("به لیست دوست داشتنیا اضافه شد")
                .font(.custom("DoranNoEn-Bold", size: 16, relativeTo: .body))
                .foregroundColor(.black)
                .padding()
                .background(CustomBlurView(effect: .systemUltraThinMaterial))
                .cornerRadius(10)
        }
        .opacity(isTapped ? 1 : 0)
        .zIndex(15)
    }
    
    @ViewBuilder
    private func removeFromWishList() -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onAppear {
                    if catVM.selectedCatNAME == "ساعت" {
                        selectedUI = .watches
                    }
                    else if catVM.selectedCatNAME == "پارتی ترند" {
                        selectedUI = .clothes
                    }
                }
            
            VStack {
                Spacer()
                Text("از دوست داشتنیا حذف شد")
                    .font(.custom("DoranNoEn-Bold", size: 16, relativeTo: .body))
                    .foregroundColor(.black)
                    .padding()
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                Spacer()
            }
            .frame(height:width/2.4)
            .background(CustomBlurView(effect: .systemUltraThinMaterial))
            .cornerRadius(10)
        }
        .opacity(isDeleteTapped ? 1 : 0)
        .zIndex(15)
        .animation(.easeInOut(duration: 0.5), value: isDeleteTapped)
    }
    
    @ViewBuilder
    private func attributeSection() -> some View {
        HStack {
            Spacer()
            VStack(spacing:0) {
                ForEach(product.attributes!,id:\.self) { att in
                    HStack(spacing:0) {
                        Spacer()
                        Text("\(att.value)")
                            .font(.custom("AbarHighNoEn-SemiBold", size: 20, relativeTo: .body))
                            .lineLimit(nil)
                            .truncationMode(.tail)
                        Text(" :\(att.key)")
                            .font(.custom("AbarHighNoEn-SemiBold", size: 20, relativeTo: .body))
                            .lineLimit(nil)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.trailing)
                            .onAppear {
                                if att.key == "مقاوم در برابر آب" {
                                    specialAttribute = att.value
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, UIScreen.main.bounds.width / 22)
        }
        Divider()
    }
    
    @ViewBuilder
    private func description() -> some View {
        VStack(alignment: .trailing,spacing: 0) {
            Text("درباره محصول:")
                .font(.custom("AbarHighNoEn-SemiBold", size: 18, relativeTo: .body))
                .lineLimit(nil)
                .truncationMode(.tail)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .blur(radius: blurAmount )
                .padding(.horizontal, UIScreen.main.bounds.width / 22)
                .padding(.bottom,5)
            Text("\(String(describing: product.variants_count))")
                .font(.custom("AbarHighNoEn-SemiBold", size: 14, relativeTo: .body))
                .lineLimit(nil)
                .truncationMode(.tail)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .blur(radius: blurAmount )
                .padding(.horizontal, UIScreen.main.bounds.width / 22)
                .padding(.bottom,5)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation {
                        blurAmount = abs(value) - height/1.3
                    }
                }
                Divider()
                .task {
                    Task {
                        if try await viewModel.checkWishlistItem(product) {
                              await MainActor.run {
                                  isLiked = true
                              }
                          } else {
                              await MainActor.run {
                                  isLiked = false
                              }
                          }
                    }
                }
        }
    }
    
    private func getDynamicWidth(for index: Int) -> CGFloat {
        let baseWidth = width / 30
        let expandedWidth = width / 6
        let nextIndex = currentIndex + 1
        let previousIndex = currentIndex - 1

        func expanded(_ prog: CGFloat) -> CGFloat { expandedWidth - (expandedWidth * prog) }
        func nextInterpolated(_ prog: CGFloat) -> CGFloat { baseWidth + (expandedWidth * prog) }
 
        switch lastSwipeDirection {
        case .right:
            if index == currentIndex {
                return dragProgress < 0.5 ? expanded(dragProgress) : expandedWidth
            } else if index == nextIndex {
                return dragProgress < 0.5 ? nextInterpolated(dragProgress) : baseWidth
            } else {
                return baseWidth
            }

        case .left:
            if index == currentIndex {
                let prog = (temp < 0.5 && temp != 0) ? temp : dragProgress
                return prog < 0.5 ? expanded(prog) : expandedWidth
            } else if index == nextIndex {
                if temp < 0.5 {
                    if dragProgress < 0.5 { return baseWidth }
                    if dragProgress != 1 { return baseWidth + (expandedWidth * temp) }
                    return baseWidth
                }
                return baseWidth
            } else if index == previousIndex {
                if temp < 0.5 && temp != 0 { return baseWidth }
                return dragProgress < 0.5 ? nextInterpolated(dragProgress) : baseWidth
            } else {
                return baseWidth
            }

        case .none:
            return index == currentIndex ? expandedWidth : baseWidth
        }
    }

    private func updateDragProgress(_ newOffset: CGFloat) {
        let screenWidth = width
        let progress = newOffset.truncatingRemainder(dividingBy: screenWidth) / screenWidth
        
        if currentIndex == 1 && onceDone {
            temp = abs(-progress)
        }
        dragProgress = abs(min(max(0,1-progress),1+progress))
            
        let isNowSwipingRight = newOffset > 0
        let isNowSwipingLeft = newOffset < 0
 
        if isNowSwipingRight {
            lastSwipeDirection = .right
        } else if isNowSwipingLeft {
            lastSwipeDirection = .left
        }
    }
    
    @ViewBuilder
    func popup(_ isShowing: Bool, height: CGFloat) -> some View {
        VStack(alignment: .trailing) {
            VStack(alignment: .trailing) {
                Text(product.name)
                    .font(.custom("DoranNoEn-Bold", size: 16))
                    .foregroundStyle(.black)
                
                Text(selectedColor)
                    .font(.custom("DoranNoEn-Bold", size: 16))
                    .foregroundStyle(.black)
            }
            .padding(.trailing, 10)

            HStack {
                Spacer()
                Text("سایز مورد نظر رو انتخاب کنید")
                    .font(.custom("DoranNoEn-Bold", size: 16))
                    .foregroundStyle(.black)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                Spacer()
            }
            variantPopUp()
            
            Spacer()
        }
        .padding(.bottom, 60)
        .background(CustomBlurView(effect: .systemUltraThinMaterial))
        .offset(y: isShowing ? 0 : 200)
        .frame(height: height/5)
        .animation(.easeInOut(duration: 0.6), value: isShowing)
    }
    
    @ViewBuilder
    func variantPopUp() -> some View {
        // All sizes of the product
        let allSizes = Set(product.variants?.flatMap { variant in
            variant.attributes.filter {
                $0.isDistinctive == false
            }.map { $0.value }
        } ?? []).sorted(by: { size1, size2 in
            let sizeOrder = ["XS", "S", "M", "L", "XL", "XXL"]
            let index1 = sizeOrder.firstIndex(of: size1) ?? Int.max
            let index2 = sizeOrder.firstIndex(of: size2) ?? Int.max
            return index1 < index2
        })
        
        let stockSizes = product.variants?.flatMap { variant in
            let size = variant.attributes.first { $0.isDistinctive == false }?.value
            let color = variant.attributes.first { $0.isDistinctive == true }?.value
            
            if color == selectedColor && variant.stock_quantity == 0 {
                return size
            } else {
                return nil
            }
        } ?? []
        
        let availableSizes = product.variants?.flatMap { variant in
            let size = variant.attributes.first { $0.isDistinctive == false }?.value
            let color = variant.attributes.first { $0.isDistinctive == true }?.value
            
            if color == selectedColor {
                return size
            } else {
                return nil
            }
        } ?? []
        
        VStack {
            ForEach(allSizes, id: \.self) { size in
                let isAvailable = availableSizes.contains(size)
                let notStock = stockSizes.contains(size)
                Divider()

                Button {
                    isShowingPopup = false
                } label: {
                    HStack {
                        Text(size)
                            .opacity(isAvailable && !notStock ? 1 : 0.2)
                            .padding(.horizontal)
                        Spacer()
                        Text(!isAvailable ? "ندارد" : notStock ? "تمام شده" : "موجود")
                            .opacity(!notStock && isAvailable ? 1 : 0.2)
                            .padding(.horizontal)
                    }
                    .foregroundStyle(.black)
                }
            }
        }
        .padding(.bottom, height/12)
    }
}

// MARK: - VariantSelectorView
struct VariantSelectorView: View {
    let product: ProductTest
    @State private var selectedColor = ""
    
    var body: some View {
        VStack {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        let uniqueColors = Set(product.variants?.compactMap { variant in
                            variant.attributes.first(where: { $0.isDistinctive ?? false })?.value
                        } ?? []).sorted()
                        
                        ForEach(Array(uniqueColors), id: \.self) { variant in
                            Button {
                                selectedColor = variant
                            } label: {
                                Text(variant)
                                    .opacity(selectedColor == variant ? 1 : 0.2)
                                    .foregroundStyle(.black)
                                    .font(.custom("AbarHighNoEn-SemiBold", size: 16, relativeTo: .body))
                            }
                        }
                    }
                    .padding(.trailing, 14)
                    .frame(width: UIScreen.main.bounds.width, alignment: .trailing)
                }
            }
            
            HStack {
                let allSizes = Set(product.variants?.compactMap { variant in
                    variant.attributes.first(where: { $0.isDistinctive == false })?.value
                } ?? []).sorted()
                
                let availableSizes = product.variants?.compactMap { variant in
                    let color = variant.attributes.first(where: { $0.isDistinctive == true })?.value
                    let size = variant.attributes.first(where: { $0.isDistinctive == false })?.value
                    
                    if color == selectedColor {
                        return size
                    }
                    return nil
                }.sorted() ?? []
                
                let availableStock = product.variants?.compactMap { variant in
                    let color = variant.attributes.first(where: { $0.isDistinctive == true })?.value
                    let size = variant.attributes.first(where: { $0.isDistinctive == false })?.value
                    let stockAvailable = variant.stock_quantity > 0
                    
                    if color == selectedColor && !stockAvailable {
                        return size
                    } else {
                        return nil
                    }
                } ?? []
                
                ForEach(allSizes, id: \.self) { size in
                    let isAvailable = availableSizes.contains(size)
                    let isAvailableStock = availableStock.contains(size)
                    
                    Text(size)
                        .overlay {
                            isAvailableStock ?
                            Rectangle()
                                .frame(width: 20, height: 1)
                                .rotationEffect(.degrees(45)) : nil
                        }
                        .opacity(isAvailable ? 1 : 0.2)
                        .font(.custom("Neue Metana", size: 16, relativeTo: .body).bold())
                        .opacity(!isAvailableStock ? 1 : 0.2)
                }
                
                Spacer()
            }
            .padding(.leading, 12)
            .onAppear {
                if let defaultVariant = product.variants?.first(where: { $0.is_default }) {
                    let distinctiveAttribute = defaultVariant.attributes.first(where: { $0.isDistinctive ?? false })?.value
                    selectedColor = distinctiveAttribute ?? ""
                }
            }
        }
    }
}

// MARK: - Supporting Views and Extensions

struct DropDownMenu: View {
    @State var show = false
    @State var show2 = false

    let title = "درباره محصول"
    let text : String
    let width: CGFloat
    let height: CGFloat
    let font: Font
    let fontCaption: Font

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .stroke(lineWidth: 0.25)
                    .frame(width:width,height: height)
                    
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(show ? 90 : 180))
                    Spacer()

                    Text(title)
                        .font(font)
                }
                .padding(.horizontal)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    show.toggle()
                }
            }

            VStack {
                if show {
                    Text(text)
                        .multilineTextAlignment(.trailing)
                        .font(fontCaption)
                        .padding()
                }
            }  .animation(.easeInOut(duration: 0.3), value: show)
        }
    }
}

func splitProductName(_ name: String) -> String {
    let words = name.split(separator: " ")
    
    if words.count <= 3 {
        return name
    }
    
    for i in stride(from: words.count - 1, through: 2, by: -1) {
        let firstLineWords = words.prefix(i).joined(separator: " ")
        let remainingWords = words.dropFirst(i).joined(separator: " ")
        
        if firstLineWords.count <= 20 {
            return "\(firstLineWords)\n\(remainingWords)"
        }
    }
    
    return name
}

struct RightToLeftModifier1: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.layoutDirection, .rightToLeft)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    PlacesView1(product: ProductTest.sampleProduct, lastNavigation: .menu)
        .environmentObject(ProductViewModel())
        .environmentObject(CategoryViewModel())
        .environmentObject(NavigationStackManager())
}

// MARK: - ProductViewModel Extensions
extension ProductViewModel {
    
    func addToWishlist(_ product: ProductTest) async throws -> WishlistResponse {
        guard !isLoading else { throw HandlingError.alreadyLoading }
        
        let urlString = "http://127.0.0.1:8000/shop/api/v1/wishlist/"
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let body = ["product_id": product.id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(response)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HandlingError.invalidResponse
            }
            
            if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                let wishlistResponse = try JSONDecoder().decode(WishlistResponse.self, from: data)
                print("successfully added to wishlist: \(wishlistResponse)")
                print("\(wishlistResponse.success)")
                return wishlistResponse
            } else {
                throw HandlingError.httpError(httpResponse.statusCode)
            }
        } catch {
            throw HandlingError.networkError(error)
        }
    }
    
    func removeFromWishlist(_ product: ProductTest) async throws -> Bool {
        guard !isLoading else { throw HandlingError.alreadyLoading }
        
        let urlString = "http://127.0.0.1:8000/shop/api/v1/wishlist/product/\(product.id)/"
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        print(UserDefaults.standard.string(forKey: "token"))
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(response)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                throw HandlingError.invalidResponse
            }
            
            if httpResponse.statusCode == 204 {
                print("item is deleted")
                return true
            } else {
                throw HandlingError.httpError(httpResponse.statusCode)
            }
        } catch {
            throw HandlingError.networkError(error)
        }
    }
    
    func checkWishlistItem(_ product: ProductTest) async throws -> Bool {
        let urlString = "http://127.0.0.1:8000/shop/api/v1/wishlist/status/?product_ids=\(product.id)"
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                throw HandlingError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let wishlistCheckResponse = try JSONDecoder().decode(wishlistCheckId.self, from: data)
                
                let isInWishlist = wishlistCheckResponse.wishlist_status["\(product.id)"] ?? false
                print("Product \(product.id) is \(isInWishlist ? "in" : "not in") wishlist")
                
                return wishlistCheckResponse.wishlist_status["\(product.id)"] ?? false
            } else {
                print("HTTP Error: \(httpResponse.statusCode)")
                throw HandlingError.httpError(httpResponse.statusCode)
            }
        } catch {
            print("Network error: \(error)")
            throw HandlingError.networkError(error)
        }
    }
}
