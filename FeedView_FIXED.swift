//
//  FeedView.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 8/2/25.
//

import SwiftUI

struct FeedView: View {
    
    @EnvironmentObject var viewModel: ProductViewModel
    @EnvironmentObject var cat: CategoryViewModel
    @EnvironmentObject var attVM: AttributeViewModel
    @EnvironmentObject var sortVM: SortViewModel
    @EnvironmentObject var specialOfferVM: specialOfferViewModel
    @EnvironmentObject var navigationManager: NavigationStackManager
    @EnvironmentObject var basketVM: shoppingBasketViewModel
    
    @State var isInAllProductsTab: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State var searchForSearchToggle = false
    @State var productFinal : ProductTest?
    @Namespace var animation
    @State private var isShowingPopup: Bool = false
    @State var show = false
    @State var searchText = ""
    @State private var categoryVisibility: [String: Bool] = [:]
    @Binding var isMainTabBarPresented: Bool
    @State var personIsPresented: Bool = false
    @State var isSearchActive = false
    @State var isFinalViewActive = false
    @State private var isShowing = false
    @State private var hasLoaded = false // Track if initial load has happened
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) var dismiss
    
    let height = UIScreen.main.bounds.height
    
    var body: some View {
        // ✅ DEBUG: Print when view body is called
        let _ = print("🔄 [FeedView] Body rendering - Products count: \(sortVM.sortedProducts.count)")
        
        if #available(iOS 17.0, *) {
            ZStack {
                // ✅ Add background color to ensure view is visible
                Color(hex: "#F7F5F2")
                    .ignoresSafeArea()
                
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        
                        navBar()
                        
                        HStack(spacing: 0) {
                            ScrollTabView()
                        }
                       
                        Text("it's enabled")
                            .opacity(attVM.isEnabled ? 1 : 0)
                        
                        // FIX: Show error message if loading fails
                        if let error = errorMessage ?? sortVM.lastError {
                            VStack(spacing: 16) {
                                Text("خطا در بارگذاری")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                Button("تلاش مجدد") {
                                    Task {
                                        errorMessage = nil
                                        sortVM.lastError = nil
                                        await loadProducts()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        
                        ScrollView {
                            if specialOfferVM.isActive {
                                lazyGridSpecialOffers(geo: geo)
                            } else {
                                lazyGrid(geo: geo)
                            }
                        }
                        .refreshable {
                            // Refresh logic
                            await refreshProducts()
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
                
                // Filter View Overlay
                if searchForSearchToggle {
                    FilterView(isPresented: $searchForSearchToggle)
                        .environmentObject(attVM)
                        .environmentObject(viewModel)
                        .environmentObject(sortVM)
                        .environmentObject(navigationManager)
                        .ignoresSafeArea(edges: .all)
                        .zIndex(10)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: searchForSearchToggle)
                        .onAppear {
                            isMainTabBarPresented = false
                        }
                        .onDisappear {
                            isMainTabBarPresented = true
                        }
                }
                
                ZStack {
                    VStack {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(isShowing ? 0.001 : 0)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isShowing = false
                            }
                        
                        Spacer()
                        popup(isShowing, height: height)
                    }
                }.opacity(isShowing ? 1 : 0)
            }
            .navigationBarHidden(true)
            .clipped()
            .ignoresSafeArea()
            // FIX: Only load if products aren't already loaded
            .task {
                // ✅ Check if products are already loaded (from CategoryView)
                if !hasLoaded {
                    // Only load if we don't have products yet
                    if sortVM.sortedProducts.isEmpty {
                        await loadProducts()
                    } else {
                        print("✅ [FeedView] Products already loaded: \(sortVM.sortedProducts.count) items")
                    }
                    hasLoaded = true
                }
            }
            .onAppear {
                print("🔄 [FeedView] onAppear called - Products: \(sortVM.sortedProducts.count)")
                // FIX: Also try loading on appear as backup (for real device timing issues)
                if !hasLoaded {
                    if sortVM.sortedProducts.isEmpty {
                        Task {
                            await loadProducts()
                            hasLoaded = true
                        }
                    } else {
                        print("✅ [FeedView] Products already available on appear: \(sortVM.sortedProducts.count) items")
                        hasLoaded = true
                    }
                }
            }
            .onChange(of: navigationManager.currentTab) { newTab in
                // Handle tab changes if needed
                if newTab != .review {
                    // You can add logic here if needed
                }
            }
        } else {
            // ✅ FALLBACK for iOS < 17.0
            ZStack {
                // ✅ Add background color to ensure view is visible
                Color(hex: "#F7F5F2")
                    .ignoresSafeArea()
                
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        navBar()
                        
                        HStack(spacing: 0) {
                            ScrollTabView()
                        }
                       
                        Text("it's enabled")
                            .opacity(attVM.isEnabled ? 1 : 0)
                        
                        ScrollView {
                            if specialOfferVM.isActive {
                                lazyGridSpecialOffers(geo: geo)
                            } else {
                                lazyGrid(geo: geo)
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
            .navigationBarHidden(true)
            .clipped()
            .ignoresSafeArea()
            .onAppear {
                if !hasLoaded {
                    if sortVM.sortedProducts.isEmpty {
                        Task {
                            await loadProducts()
                            hasLoaded = true
                        }
                    } else {
                        print("✅ [FeedView] Products already available on appear: \(sortVM.sortedProducts.count) items")
                        hasLoaded = true
                    }
                }
            }
        }
    }
    
    // FIX: Extract loading logic to separate function with error handling
    private func loadProducts() async {
        // Reset error
        await MainActor.run {
            errorMessage = nil
            sortVM.lastError = nil
        }
        
        // FIX: Add logging for debugging on real device
        print("🔄 [FeedView] Starting to load products")
        print("🔄 [FeedView] Category ID: \(sortVM.categoryId)")
        print("🔄 [FeedView] Current Page: \(sortVM.currentPage)")
        print("🔄 [FeedView] Filters: \([:])")
        print("🔄 [FeedView] Is Loading: \(sortVM.isLoading)")
        
        // FIX: Call sortProduct - it now handles all errors internally
        await sortVM.sortProduct(categoryID: sortVM.categoryId, filters: [:])
        
        // FIX: Check for errors after loading
        await MainActor.run {
            if let error = sortVM.lastError {
                errorMessage = error
                print("❌ [FeedView] Error from SortViewModel: \(error)")
            } else if sortVM.sortedProducts.isEmpty && !sortVM.isLoading {
                // Only show "no products" if we're not still loading
                print("⚠️ [FeedView] No products loaded")
                errorMessage = "هیچ محصولی یافت نشد"
            } else {
                print("✅ [FeedView] Products loaded successfully. Count: \(sortVM.sortedProducts.count)")
            }
        }
    }
    
    private func refreshProducts() async {
        sortVM.currentPage = 1
        sortVM.sortedProducts = []
        await loadProducts()
    }
    
    //MARK: - SORT VIEW FUNCTIONS
    
    @ViewBuilder
    private func navBar() -> some View {
        
        let width = UIScreen.main.bounds.width
         
        VStack {
            Spacer()
            
            HStack(alignment:.bottom) {
                
                Button(action: {
                    
                    sortVM.currentPage = 1
                    sortVM.sortedProducts = []
                    cat.selectedCatID = nil
                    
                    // Use navigationManager to go back
                    navigationManager.popView(from: .review)
                    
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .frame(width: width/16, height: width/16)
                        .foregroundStyle(.black)
                }
                .padding(.bottom,10)
                .padding(.leading,width/18)
                
                Spacer()
                
                Button {
                } label: {
                    Text("\(cat.selectedCatNAME ?? "")")
                        .font(.custom("AbarHighNoEn-SemiBold", size: 18, relativeTo: .body))
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Button {
                    navigationManager.isMainTabBarHidden = true
                    searchForSearchToggle = true
                } label: {
                    Image("filter")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                
                .padding(.bottom,10)
                .padding(.trailing,width/18)
            }
            .padding(.bottom,2)
        }
        .frame(height: height/9 )
        .background(CustomBlurView(effect: .systemThinMaterial))
        Spacer()
    }
    
    @ViewBuilder
    func popup(_ isShowing: Bool,height:CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text("مرتب سازی بر اساس:")
                .frame(maxWidth:.infinity)
                .font(.custom("DoranNoEn-Bold",size:16))
                .foregroundStyle(.black)
                .padding(.bottom,10)
            
            DropUpButtonStyle(switchButton: .newest)
            DropUpButtonStyle(switchButton: .oldest)
            DropUpButtonStyle(switchButton: .priceIncreasing)
            DropUpButtonStyle(switchButton: .priceDecreasing)
            
            Spacer()
        }
        .padding(.bottom,height/20)
        .background(CustomBlurView(effect: .systemUltraThinMaterial))
        .offset(y: isShowing ? 0 : 200)
        .frame(height:height/5)
        .animation(.easeInOut(duration: 0.6), value: isShowing)
    }
    
    @ViewBuilder
    func DropUpButtonStyle(switchButton:sortButton) -> some View {
        var buttonText: String {
            switch switchButton {
            case .newest:
                return "جدیدترین"
            case .oldest:
                return "قدیمی ترین"
            case .priceIncreasing:
                return "ارزان ترین‌ها"
            case .priceDescending:
                return "گران ترین‌ها"
            }
        }
      
        Button {
            switch switchButton {
            case .newest:
                sortVM.sortPublishModel = sortVM.SortModeSelection(.TimeNewest)
                handleSorting()
            case .oldest:
                sortVM.sortPublishModel = sortVM.SortModeSelection(.TimeOldest)
                handleSorting()
            case .priceIncreasing:
                sortVM.sortPublishModel = sortVM.SortModeSelection(.priceAscending)
                handleSorting()
            case .priceDescending:
                sortVM.sortPublishModel = sortVM.SortModeSelection(.priceDescending)
                handleSorting()
            }
        } label: {
            Text(buttonText)
                .frame(maxWidth:.infinity)
                .font(.custom("DoranNoEn-Bold",size:16))
                .foregroundStyle(.black)
                .padding(.bottom,10)
        }
    }
    
    enum sortButton {
        case priceIncreasing
        case priceDescending
        case newest
        case oldest
    }
    
    private func handleSorting() {
        sortVM.currentPage = 1
        if sortVM.activeFilters == [:] {
            handleNoFilterload()
        } else {
            handleFilterload()
        }
        isShowing = false
    }
    
    private func handleNoFilterload() {
        sortVM.currentPage = 1
        if specialOfferVM.isActive {
            sortVM.specialOffersProducts = []
            Task {
                await sortVM.loadSpecialOffersProducts(offerId: specialOfferVM.offerId!, selectedCategory: specialOfferVM.selectedCategory!, man: cat.isMenTapped!, filters: [:])
            }
        } else {
            Task {
                await sortVM.sortProduct(categoryID: sortVM.categoryId, filters: [:])
            }
        }
        isShowing = false
    }
    
    private func handleFilterload() {
        sortVM.currentPage = 1
        
        if specialOfferVM.isActive {
            Task {
                await sortVM.loadSpecialOffersProducts(offerId: specialOfferVM.offerId!, selectedCategory: sortVM.categoryId, man: cat.isMenTapped!, filters: sortVM.activeFilters)
            }
        } else {
            Task {
                await sortVM.sortProduct(categoryID: sortVM.categoryId, filters: sortVM.activeFilters)
            }
        }
        isShowing = false
    }
    
    // MARK: - SCROLL TAB
    @ViewBuilder
    func ScrollTabView() -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TabButton(onVisibilityChange: { key, isVisible in
                        categoryVisibility[key] = isVisible
                    })
                    .environmentObject(attVM)
                }.padding(.leading)
            }
            .onAppear {
                if let attID = attVM.selectedValue{
                    proxy.scrollTo(attID, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - LAZYVGRID
    @ViewBuilder
    private func lazyGrid(geo: GeometryProxy) -> some View {
        LazyVGrid(columns: [
            GridItem(spacing: 3),
            GridItem(spacing: 0),
        ], spacing: 40) {
            
            ForEach(sortVM.sortedProducts) { product in
                Button {
                    Task {
                        await viewModel.loadFinalProduct(product.id)
                        
                        productFinal = viewModel.product
                        
                        // Navigate to product view using NavigationStackManager
                        let productView = PlacesView1(product: productFinal!, lastNavigation: .review)
                            .environmentObject(attVM)
                            .environmentObject(viewModel)
                            .environmentObject(navigationManager)
                            .environmentObject(basketVM)
                        
                        navigationManager.pushView(productView, to: .review)
                    }
                } label: {
                    ProductCard(
                        product: product,
                        width: geo.size.width / 2,
                        height: geo.size.height / 2.4,
                        imageHeight: geo.size.width / 1.4
                    )
                    .onAppear {
                        if let index = sortVM.sortedProducts.firstIndex(where: { $0.id == product.id }),
                           index >= sortVM.sortedProducts.count - 3 {
                            print("NAME:  \(index - 3)")
                            Task {
                                await sortVM.sortProduct(categoryID: sortVM.categoryId, filters: viewModel.activeFilters)
                            }
                        }
                    }
                }
            }
           
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func lazyGridSpecialOffers(geo: GeometryProxy) -> some View {
        LazyVGrid(columns: [
            GridItem(spacing: 16),
            GridItem(spacing: 16),
        ], spacing: 60) {
            
            ForEach(sortVM.specialOffersProducts, id: \.id) { product in
                Button {
                    Task {
                        await viewModel.loadFinalProduct(product.id)
                        
                        productFinal = viewModel.product
                        print(productFinal)
                        // Navigate to product view using NavigationStackManager
                        let productView = PlacesView1(product: productFinal!, lastNavigation: .review)
                            .environmentObject(attVM)
                            .environmentObject(viewModel)
                            .environmentObject(navigationManager)
                        
                        navigationManager.pushView(productView, to: .review)
                    }
                } label: {
                    ProductCard(
                        product: product.product,
                        width: geo.size.width / 2.4,
                        height: geo.size.height / 3,
                        imageHeight: geo.size.width / 2
                    )
                    .onAppear {
                        if let index = specialOfferVM.specialOffersProducts.firstIndex(where: { $0.id == product.id}),
                           index >= specialOfferVM.specialOffersProducts.count - 3 {
                            Task {
                                await sortVM.loadSpecialOffersProducts(offerId: specialOfferVM.offerId!, selectedCategory: specialOfferVM.selectedCategory!, man: cat.isMenTapped!, filters: [:])
                            }
                        }
                    }
                }
            }
           
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - NAVIGATION BAR
    @ViewBuilder
    private func navBar(geo: GeometryProxy) -> some View {
        HStack {
            Button {
                attVM.selectedKeyAsValue = nil
                attVM.categoryID = 0
                
                
                Task {
                    
                    sortVM.sortCaseSelection = .TimeNewest
                    sortVM.activeFilters = [:]
                    sortVM.sortPublishModel = sortVM.SortModeSelection(.TimeNewest)
                    sortVM.currentPage = 1
                    sortVM.sortedProducts = []
                    
                }
                
                
                cat.Parent = true
                specialOfferVM.isActive = false
                // Use NavigationStackManager to go back
                navigationManager.popView(from: .review)
                
            } label: {
                ZStack {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .frame(width: 30,height: 30)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            
            Image("bag")
                .resizable()
                .frame(width: 34,height: 34)
                .padding(.leading,5)
                .padding(.bottom,3)
            
            Spacer()
            
            Button {
                isShowing.toggle()
            } label: {
                Image("sort")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            
            Button {
                searchForSearchToggle = true
            } label: {
                Image("filter")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .frame(height: geo.size.height / 24)
        .padding(.top, geo.size.height / 12)
        .padding(.horizontal)
        .padding(.bottom, 5)
        Divider()
            .background(Color.gray)
    }
}

// MARK: -TAB BUTTON
struct TabButton: View {
    @EnvironmentObject var category: CategoryViewModel
    @EnvironmentObject var productsViewModel: ProductViewModel
    @EnvironmentObject var attVM: AttributeViewModel
    @EnvironmentObject var sortVM: SortViewModel
    
    @State private var selected: String?
    @Namespace private var animation
    
    let onVisibilityChange: (String, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 26) {
            ForEach(attVM.selectedKeyAsValue?.values ?? [], id: \.self) { att in
                Button {
                    if selected == att {
                        attVM.selectedValue = att
                    } else {
                        selected = att
                        
                        if selected == "همه" {
                            sortVM.isInAllProductsTab = true
                        } else {
                            sortVM.isInAllProductsTab = false
                        }
                        
                        attVM.selectedValue = selected!
                        
                        let filter : [String:[String]] = [ attVM.selectedKeyAsValue!.attribute_key:[att]]
                        sortVM.selectedKeyValue = filter
                        sortVM.isSelectingAttributeCategory = false
                        sortVM.currentPage = 1
                        
                        Task {
                            await sortVM.sortProduct(categoryID: productsViewModel.categoryId!, filters: sortVM.selectedKeyValue)
                        }
                    }
                } label: {
                    Text(att)
                        .font(selected == att ? .custom("DoranNoEn-ExtraBold",size:12) : .custom("DoranNoEn-medium",size:12))
                        .foregroundColor(selected == att ? .black : .black.opacity(0.4))
                        .padding(.vertical, 10)
                        .lineLimit(1)
                }
                .id(att)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                // checkVisibility(for: att, geometry: geometry)
                            }
                            .onChange(of: geometry.frame(in: .global)) { _ in
                                // checkVisibility(for: att, geometry: geometry)
                            }
                    }
                )
                .onAppear {
                    selected = attVM.selectedValue
                }
                .onChange(of: attVM.selectedValue) { newValue in
                    selected = newValue
                }
            }
        }
    }
}

#Preview {
    FeedView(isMainTabBarPresented: .constant(true))
        .environmentObject(ProductViewModel())
        .environmentObject(CategoryViewModel())
        .environmentObject(SortViewModel())
        .environmentObject(AttributeViewModel())
        .environmentObject(specialOfferViewModel())
        .environmentObject(NavigationStackManager())
}
