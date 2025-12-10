//
//  CategoryView.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 8/1/25.
//

import SwiftUI

struct CategoryView: View {
    
    @EnvironmentObject var catVM : CategoryViewModel
    @EnvironmentObject var productVM: ProductViewModel
    @EnvironmentObject var attVM: AttributeViewModel
    @EnvironmentObject var sortVM: SortViewModel
    @EnvironmentObject var specialOfferVM: specialOfferViewModel
    @EnvironmentObject var navigationManager: NavigationStackManager
    @EnvironmentObject var shoppingBasketVM: shoppingBasketViewModel
    @EnvironmentObject var basketVM: shoppingBasketViewModel
    @EnvironmentObject var addressVM: AddressViewModel
    
    @State private var selectedCategory: SubCategory?
    @Binding var isMainTabBarVisible: Bool
    
    @State var isSelected: Bool = false
    @State private var hasPreloadedSubcategories: Bool = false // Track preloading status
  
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    var body: some View {
        VStack {
            VStack {
              
                navBar()
                    .onAppear {
                        Task {
                            do {
                                try await addressVM.loadAddress()
                            } catch {
                                
                            }
                        }
                    }
                GeometryReader { geo in
                    VStack(spacing:20) {
                        // Gender Selection Tabs
                        genderSelectionView(geo: geo)
                        
                        // Category List
                        categoryListView()
                        specialOffersView()
                    }
                }
            }
        }
        .ignoresSafeArea()
        .task {
            Task {
                await catVM.loadCategories()
            }
        }
        .onAppear {
            Task {
                await specialOfferVM.loadSpecialOffers()
            }
        }
        .onChange(of: catVM.parentCategories) { _ in
            // ✅ Preload subcategories for all parent categories when they're loaded
            if !hasPreloadedSubcategories && !catVM.parentCategories.isEmpty {
                Task {
                    await preloadAllSubcategories()
                    hasPreloadedSubcategories = true
                }
            }
        }
        .onChange(of: catVM.isMenTapped) { _ in
            // ✅ Reset and preload again when gender changes
            hasPreloadedSubcategories = false
            if !catVM.parentCategories.isEmpty {
                Task {
                    await preloadAllSubcategories()
                    hasPreloadedSubcategories = true
                }
            }
        }
    }
    
    // MARK: - Preload Helper
    private func preloadAllSubcategories() async {
        // ✅ Load subcategories for all parent categories in parallel
        await withTaskGroup(of: Void.self) { group in
            for category in catVM.parentCategories {
                group.addTask {
                    await catVM.loadSubCategories(category.id)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func navBar() -> some View {
        VStack {
            Spacer()
            
            HStack(alignment:.bottom) {
                
                Button(action: {
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
                
                Text("دسته بندی")
                    .font(.custom("DoranNoEn-ExtraBold", size: 20, relativeTo: .body))
                
                Spacer()
                
                Button(action: {
                    navigationManager.pushView(ShoppingBasket().environmentObject(navigationManager).environmentObject(addressVM), to: .review)
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image("bag")
                            .resizable()
                            .frame(width: width/12, height: width/12)
                            .blendMode(.multiply)
                            .foregroundStyle(.black)
                            .overlay {
                                Text("\(shoppingBasketVM.basket.total_items)")
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(maxWidth: width / 30, maxHeight: height / 30)
                                    .minimumScaleFactor(0.5)
                                    .padding(4)
                                    .background(.black)
                                    .clipShape(Circle())
                                    .foregroundStyle(.white)
                                    .offset(x: width/20,y: -height/70)
                            }
                    }
                }
                .padding(.trailing,width/18)
                .padding(.bottom,10)
            }
            .padding(.bottom,2)
        }
        .frame(height: height/9 )
        .background(CustomBlurView(effect: .systemThinMaterial))
        
        Spacer()
            .zIndex(1)
    }
    
    @ViewBuilder
    private func genderSelectionView(geo: GeometryProxy) -> some View {
        HStack {
            Spacer()
            HStack(spacing: 0) {
                // Women's Tab
                VStack(alignment: .trailing, spacing: 5) {
                    Button {
                        catVM.isMenTapped = false
                    } label: {
                        HStack {
                            Spacer()
                            Text("زنونه")
                                .font(.custom("DoranNoEn-ExtraBold", size: 16, relativeTo: .body))
                                .padding(.trailing, 8)
                                .foregroundStyle(!catVM.isMenTapped! ? .white : .black)
                                .onAppear {
                                    Task {
                                        await shoppingBasketVM.loadShoppingBasket()
                                    }
                                }
                            Spacer()
                        }
                    }
                    .overlay {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1))
                    }
                }
                .background(catVM.isMenTapped! ? .clear : .black)
               
                // Men's Tab
                HStack {
                    VStack(alignment: .trailing, spacing: 5) {
                        Button {
                            catVM.isMenTapped! = true
                            catVM.isMenTapped = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("مردونه")
                                    .font(.custom("DoranNoEn-ExtraBold", size: 16, relativeTo: .body))
                                    .padding(.trailing, 8)
                                    .foregroundStyle(catVM.isMenTapped! ? .white : .black)
                                Spacer()
                            }
                        }
                    }
                }
                .overlay {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                }
                .onChange(of: catVM.isMenTapped!) { newGender in
                    Task {
                        catVM.isMenTapped = newGender
                        await catVM.loadCategories()
                    }
                }
                .background(catVM.isMenTapped! ? .black : .clear)
            }
            .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.04)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func specialOffersView() -> some View {
        HStack {
            Spacer()
            
            VStack(alignment: .trailing,spacing: 0) {
                ForEach(specialOfferVM.specialOffers,id:\.id) { offer in
                    if offer.products.count > 1 {
                        Button {
                            Task {
                                specialOfferVM.currentPage = 1
                                specialOfferVM.offerId = offer.id
                                specialOfferVM.selectedCategory = -1
                                
                                await specialOfferVM.loadSpecialOffersCategories(offerId: offer.id, man: catVM.isMenTapped!)
                                await sortVM.loadSpecialOffersProducts(offerId: offer.id, selectedCategory: specialOfferVM.selectedCategory!, man: catVM.isMenTapped!, filters: [:])
                                sortVM.categoryId = specialOfferVM.specialOffersCategoryModel.first?.id ?? 0
                                attVM.selectedValue = specialOfferVM.specialOffersCategoryModel.first?.name ?? ""
                                
                                specialOfferVM.isActive = true
                                
                                // Navigate to FeedView using NavigationStackManager
                                let feedView = FeedView(isMainTabBarPresented: $isMainTabBarVisible)
                                    .environmentObject(catVM)
                                    .environmentObject(productVM)
                                    .environmentObject(attVM)
                                    .environmentObject(sortVM)
                                    .environmentObject(specialOfferVM)
                                    .environmentObject(navigationManager)
                                    .environmentObject(basketVM)
                                
                                navigationManager.pushView(feedView, to: .review)
                            }
                        } label: {
                            Text(offer.title)
                                .font(.custom("DoranNoEn-Bold", size: 24))
                                .foregroundStyle(.black)
                                .shimmer()
                                .padding(.vertical,10)
                                .padding(.trailing)
                                .padding(.trailing)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func categoryListView() -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(catVM.parentCategories, id: \.id) { cat in
                    Shimmer2(show: $isSelected, subcat: cat)
                        .padding(.vertical, 20)
                        .padding(.trailing)
                }
            }
        }
        .environmentObject(catVM)
        .environmentObject(attVM)
        .environmentObject(productVM)
    }
      
    // MARK: - Helper Methods
    
    private func shouldShowCategory(_ category: categoriesModel) -> Bool {
        if catVM.isMenTapped! {
            return category.gender == "مردانه" || category.gender == nil
        } else {
            return category.gender == "زنانه"
        }
    }
    
    private func removeSex(word: String) -> String {
        return word
            .replacingOccurrences(of: "مردانه", with: "")
            .replacingOccurrences(of: "زنانه", with: "")
    }
}

// MARK: - Updated Shimmer2 Component
struct Shimmer2: View {
    
    @Binding var show: Bool
    @State var isSelected: Bool = false
    @EnvironmentObject var cateogryviewmodel : CategoryViewModel
    @EnvironmentObject var CVM : CategoryViewModel
    @EnvironmentObject var AVM : AttributeViewModel
    @EnvironmentObject var sortVM : SortViewModel
    @EnvironmentObject var PVM : ProductViewModel
    @EnvironmentObject var navigationManager: NavigationStackManager
    
    @State var subcat: SubCategory
    
    @State private var animationPhase: Int = 0
    private let animationDuration: Double = 0.08
    private let totalPhases = 7
    
    // ✅ Get subcategories for this specific parent category
    private var subCategoriesForParent: [SubCategory] {
        CVM.getSubCategories(for: subcat.id)
    }
    
    var body: some View {
        VStack(spacing:0) {
            HStack {
                Spacer()
                
                Button {
                    if show == true {
                        if cateogryviewmodel.selectedCatID == subcat.id {
                            show = false
                            cateogryviewmodel.selectedCatID = nil
                        } else {
                            cateogryviewmodel.selectedCatID = subcat.id
                            cateogryviewmodel.Parent = true
                            handleButtonTap()
                        }
                    } else {
                        show = true
                        cateogryviewmodel.selectedCatID = subcat.id
                        handleButtonTap()
                    }
                } label: {
                    HStack(spacing:4) {
                        Text("|")
                            .rotationEffect(.degrees(show && subcat.id == cateogryviewmodel.selectedCatID ? -90 : 0))
                            .foregroundStyle(.black)
                            .frame(width: 16, height:16)
                        
                        VStack(spacing:0){
                            Text(subcat.label)
                                .font(.custom("DoranNoEn-Bold", size: 24))
                                .foregroundColor(foregroundColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .bold()
                .padding(.horizontal)
            }
            
            if show && cateogryviewmodel.selectedCatID == subcat.id {
                ScrollView(.horizontal,showsIndicators: false) {
                    HStack {
                        if CVM.selectedCatID == subcat.id {
                            // ✅ Use the preloaded subcategories for this parent
                            ForEach(subCategoriesForParent, id:\.id) { cat in
                                Button {
                                    Task {
                                        await CVM.loadCategories()
                                        
                                        AVM.categoryID = cat.id
                                        sortVM.categoryId = cat.id
                                        
                                        await AVM.loadValueCategories()
                                        
                                        CVM.selectedCatID = cat.id
                                        PVM.categoryId = cat.id
                                        
                                        AVM.selectedValue = AVM.selectedKeyAsValue?.values.first
                                        
                                        CVM.selectedCatNAME = cat.label
                                        
                                        // ✅ IMPORTANT: Load products BEFORE navigating
                                        // Reset pagination for fresh load
                                        sortVM.currentPage = 1
                                        sortVM.sortedProducts = []
                                        
                                        // Load products and wait for completion
                                        await sortVM.sortProduct(categoryID: cat.id, filters: [:])
                                        
                                        // ✅ Wait until loading is complete
                                        // This ensures products are ready when FeedView appears on real device
                                        while sortVM.isLoading {
                                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                        }
                                        
                                        // ✅ Navigate to FeedView using NavigationStackManager
                                        // Products are now loaded and ready
                                        await MainActor.run {
                                            let feedView = FeedView(isMainTabBarPresented: .constant(true))
                                                .environmentObject(cateogryviewmodel)
                                                .environmentObject(PVM)
                                                .environmentObject(AVM)
                                                .environmentObject(sortVM)
                                                .environmentObject(specialOfferViewModel())
                                                .environmentObject(navigationManager)
                                            
                                            print("✅ Navigating to FeedView with \(sortVM.sortedProducts.count) products")
                                            navigationManager.pushView(feedView, to: .review)
                                        }
                                    }
                                } label: {
                                    VStack {
                                        Spacer()
                                        Text(cat.label)
                                            .font(.custom("DoranNoEn-Medium", size: 18))
                                            .padding(.horizontal, 10)
                                            .foregroundStyle(CVM.selectedCatID == cat.id ? .red : Color.gray)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .frame(height:show && cateogryviewmodel.selectedCatID == subcat.id ? 40 : 0)
                }
            }
            
            Divider()
                .opacity(show && cateogryviewmodel.selectedCatID == subcat.id ? 1 : 0)
        }
        .frame(maxWidth:.infinity,maxHeight: show && cateogryviewmodel.selectedCatID == subcat.id ? 40 : 0)
    }
    
    private var foregroundColor: Color {
        if animationPhase > 0 && animationPhase <= totalPhases {
            return animationPhase % 2 == 1 ? .black : .white
        }
        return isSelected ? .black : .black
    }
    
    func handleButtonTap() {
        isSelected.toggle()
        startAnimationSequence()
    }
    
    private func startAnimationSequence() {
        animationPhase = 0
        
        for phase in 1...totalPhases {
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration * Double(phase)) {
                animationPhase = phase
                
                if phase == totalPhases {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        animationPhase = 0
                    }
                }
            }
        }
    }
}

// MARK: - CategoryViewModel Extension (UPDATED)
extension CategoryViewModel {
    
    // ✅ IMPORTANT: You need to update your CategoryViewModel to use a dictionary instead of a single array
    // Change: @Published var subCategories: [SubCategory] = []
    // To: @Published var subCategoriesByParent: [Int: [SubCategory]] = [:]
    
    func loadSubCategories(_ parentId: Int) async {
        var urlString: String
        
        if isMenTapped! {
             urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/flattened-by-gender/?gender_name=men"
        } else {
             urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/flattened-by-gender/?gender_name=women"
        }
        
        var request = URLRequest(url : URL(string:urlString)!)
        request.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        do {
            let (data,_) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(subCategoryModel.self, from: data)
            
            await MainActor.run {
                // ✅ Store subcategories by parent ID instead of overwriting
                // OLD: subCategories = decoded.categories
                // NEW: subCategoriesByParent[parentId] = decoded.categories
                // You need to add this property to CategoryViewModel:
                // @Published var subCategoriesByParent: [Int: [SubCategory]] = [:]
                subCategoriesByParent[parentId] = decoded.categories
                print("✅ Loaded \(decoded.categories.count) subcategories for parent \(parentId)")
            }
        } catch {
            print("❌ Error loading subcategories for parent \(parentId): \(error)")
        }
    }
    
    // ✅ Helper method to get subcategories for a specific parent
    func getSubCategories(for parentId: Int) -> [SubCategory] {
        // OLD: return subCategories
        // NEW: return subCategoriesByParent[parentId] ?? []
        return subCategoriesByParent[parentId] ?? []
    }
}

