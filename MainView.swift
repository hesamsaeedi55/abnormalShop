import SwiftUI

struct MainView: View {
    
    // MARK: - State Objects
    @StateObject var productVM = ProductViewModel()
    @StateObject var categoryVM = CategoryViewModel()
    @StateObject var attributeVM = AttributeViewModel()
    @StateObject var sortVM = SortViewModel()
    @StateObject var specialOfferVM = specialOfferViewModel()
    @StateObject var navigationStackManager = NavigationStackManager()
    @StateObject var shoppingBasketVM = shoppingBasketViewModel()
    @StateObject var addressVM = AddressViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    
    // MARK: - UI Status
    @State var isMainTabBarPresentedMain: Bool = true
    
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    
    // Cached root views
    @State private var menuRootCached: AnyView? = nil
    @State private var reviewRootCached: AnyView? = nil
    @State private var bookRootCached: AnyView? = nil
    @State private var profileRootCached: AnyView? = nil
    @State private var loginView: AnyView? = AnyView(LoginBrowserView())
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Only render the current tab's view - lazy loading
                if let tabView = navigationStackManager.getViewForTab(navigationStackManager.currentTab) {
                    tabView
                        .environmentObject(navigationStackManager)
                        .environmentObject(shoppingBasketVM)
                        .environmentObject(productVM)
                        .environmentObject(categoryVM)
                        .environmentObject(attributeVM)
                        .environmentObject(sortVM)
                        .environmentObject(specialOfferVM)
                        .environmentObject(authVM)
                        .environmentObject(addressVM)
                        .id(navigationStackManager.currentTab) // Force view refresh on tab change
                } else {
                    loadingView
                }
            }
        }
        .environmentObject(navigationStackManager)
        .environmentObject(shoppingBasketVM)
        .environmentObject(productVM)
        .environmentObject(categoryVM)
        .environmentObject(attributeVM)
        .environmentObject(sortVM)
        .environmentObject(specialOfferVM)
        .environmentObject(authVM)
        .environmentObject(addressVM)
        .onChange(of: navigationStackManager.currentTab) { newTab in
            // ✅ Lazy load views only when tab is accessed for the first time
            loadViewIfNeeded(for: newTab)
        }
        .onAppear {
            // ✅ Load only the initial tab view
            loadViewIfNeeded(for: navigationStackManager.currentTab)
        }
        .safeAreaInset(edge: .bottom) { tabBar }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Lazy Loading Helper
    private func loadViewIfNeeded(for tab: NavigationStackManager.TabPage) {
        switch tab {
        case .menu:
            if menuRootCached == nil {
                menuRootCached = AnyView(SearchView())
                navigationStackManager.setDefaultView(menuRootCached!, for: .menu)
            }
        case .review:
            if reviewRootCached == nil {
                let catView = CategoryView(isMainTabBarVisible: $isMainTabBarPresentedMain)
                    .environmentObject(categoryVM)
                    .environmentObject(productVM)
                    .environmentObject(attributeVM)
                    .environmentObject(sortVM)
                    .environmentObject(specialOfferVM)
                    .environmentObject(navigationStackManager)
                    .environmentObject(shoppingBasketVM)
                    .environmentObject(addressVM)
                
                reviewRootCached = AnyView(catView)
                navigationStackManager.setDefaultView(reviewRootCached!, for: .review)
            }
        case .book:
            if bookRootCached == nil {
                bookRootCached = AnyView(
                    GlassView()
                        .environmentObject(shoppingBasketVM)
                        .environmentObject(productVM)
                        .environmentObject(categoryVM)
                        .environmentObject(attributeVM)
                        .environmentObject(sortVM)
                        .environmentObject(specialOfferVM)
                        .environmentObject(addressVM)
                )
                navigationStackManager.setDefaultView(bookRootCached!, for: .book)
            }
        case .profile:
            if profileRootCached == nil {
                let profileViewStruct = profileView()
                    .environmentObject(authVM)
                    .environmentObject(addressVM)
                profileRootCached = AnyView(profileViewStruct)
                navigationStackManager.setDefaultView(profileRootCached!, for: .profile)
            }
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color(hex: "#F7F5F2").ignoresSafeArea()
            VStack {
                ProgressView().scaleEffect(1.2).foregroundColor(.gray)
                Text("در حال بارگذاری...")
                    .font(.custom("DoranNoEn-Light", size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Tab Bar
    @ViewBuilder
    private var tabBar: some View {
        HStack(spacing: width / 7) {
            TabBarIcon2(navigationManager: navigationStackManager, icon: "map.fill", assignedPage: .menu, width: width/14, height: height/10)
                .padding(.leading, 20)
            
            TabBarIcon2(navigationManager: navigationStackManager, icon: "house.fill", assignedPage: .review, width: width/14, height: height/10)
            
            TabBarIcon2(navigationManager: navigationStackManager, icon: "book.fill", assignedPage: .book, width: width/14, height: height/10)
            
            TabBarIcon2(navigationManager: navigationStackManager, icon: "globe", assignedPage: .profile, width: width/14, height: height/10)
                .padding(.trailing, 20)
        }
        .padding(.bottom, height/30)
        .frame(width: width, height: height/12)
        .background(Rectangle().fill(.ultraThinMaterial))
        .opacity(navigationStackManager.isMainTabBarHidden ? 0 : 1)
        .offset(y: isMainTabBarPresentedMain ? 0 : 100)
        .animation(.easeInOut(duration: 0.3), value: isMainTabBarPresentedMain)
    }
}

// MARK: - Tab Bar Icon
struct TabBarIcon2: View {
    @ObservedObject var navigationManager: NavigationStackManager
    let icon: String
    let assignedPage: NavigationStackManager.TabPage
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Button {
            navigationManager.navigateTo(assignedPage)
        } label: {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
                .foregroundColor(navigationManager.currentTab == assignedPage ? .blue : .gray)
        }
    }
}
