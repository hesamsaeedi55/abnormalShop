//
//  NavigationStackManager.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/9/25.
//

import SwiftUI

// MARK: - Navigation Stack Manager
class NavigationStackManager: ObservableObject {
    
    @Published var currentTab: TabPage = .review
    @Published var navigationStacks: [TabPage: [AnyView]] = [:]
    @Published private var defaultViews: [TabPage: AnyView] = [:]
    @Published var isMainTabBarHidden: Bool = false
    
    enum TabPage: CaseIterable, Hashable {
        case menu, review, book, profile
    }

    init() {
        for tab in TabPage.allCases {
            navigationStacks[tab] = []
        }
    }

    // MARK: - Navigation Methods
    func navigateTo(_ tab: TabPage) {
        currentTab = tab
    }

    func pushView<Content: View>(_ view: Content, to tab: TabPage? = nil) {
        let currentTargetTab = tab ?? currentTab
        // FIX: Ensure @Published fires by reassigning the dictionary
        var stacks = navigationStacks
        if stacks[currentTargetTab] == nil {
            stacks[currentTargetTab] = []
        }
        stacks[currentTargetTab]?.append(AnyView(view))
        navigationStacks = stacks // This triggers @Published
    }
    

    func popView(from tab: TabPage? = nil) {
        let targetTab = tab ?? currentTab
        // FIX: Ensure @Published fires by reassigning the dictionary
        var stacks = navigationStacks
        _ = stacks[targetTab]?.popLast()
        navigationStacks = stacks // This triggers @Published
    }

    func popToRoot(from tab: TabPage? = nil) {
        let targetTab = tab ?? currentTab
        // FIX: Ensure @Published fires by reassigning the dictionary
        var stacks = navigationStacks
        stacks[targetTab] = []
        navigationStacks = stacks // This triggers @Published
    }

    func getCurrentView(for tab: TabPage) -> AnyView? {
        navigationStacks[tab]?.last
    }

    // MARK: - Default View Management
    func setDefaultView<Content: View>(_ view: Content, for tab: TabPage) {
        if defaultViews[tab] == nil { // ✅ only set once
            defaultViews[tab] = AnyView(view)
        }
    }

    func getDefaultView(for tab: TabPage) -> AnyView? {
        defaultViews[tab]
    }

    // last tab or default tab
    func getViewForTab(_ tab: TabPage) -> AnyView? {
        getCurrentView(for: tab) ?? getDefaultView(for: tab)
    }
}

// MARK: - Tab State Models
struct TabState {
    var currentView: String
    var viewData: [String: Any]
    var navigationPath: [String]

    init(currentView: String = "", viewData: [String: Any] = [:], navigationPath: [String] = []) {
        self.currentView = currentView
        self.viewData = viewData
        self.navigationPath = navigationPath
    }
}

// MARK: - View Identifiers
enum ViewIdentifier: String, CaseIterable {
    case mainView = "MainView"
    case categoryView = "CategoryView"
    case feedView = "FeedView"
    case productView = "ProductView"
    case profileView = "ProfileView"
    case searchView = "SearchView"
    case glassView = "GlassView"
}

// MARK: - Tab Navigation View (DISABLED - Using MainView instead)
/*
struct TabNavigationView: View {
    @StateObject private var navigationManager = NavigationStackManager()
    @StateObject private var productVM = ProductViewModel()
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var attributeVM = AttributeViewModel()
    @StateObject private var sortVM = SortViewModel()
    @StateObject private var specialOfferVM = specialOfferViewModel()

    @State private var isMainTabBarPresented: Bool = true
    @State private var isGlassViewLoaded: Bool = false

    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width

    var body: some View {
        NavigationStack {
            ZStack { currentTabView }
        }
        .environmentObject(navigationManager)
        .environmentObject(productVM)
        .environmentObject(categoryVM)
        .environmentObject(attributeVM)
        .environmentObject(sortVM)
        .environmentObject(specialOfferVM)
        
        .onAppear {
            // ✅ Cache root views once
            navigationManager.setDefaultView(SearchView(), for: .menu)
            
            navigationManager.setDefaultView(
                CategoryView(isMainTabBarVisible: $isMainTabBarPresented),
                for: .review
            )
            navigationManager.setDefaultView(profileView(), for: .profile)

            // Lazy load book tab
            if !isGlassViewLoaded {
                navigationManager.setDefaultView(loadingView, for: .book)
            }
        }
        .safeAreaInset(edge: .bottom) { tabBar }
        .edgesIgnoringSafeArea(.bottom)
    }

    // MARK: - Current Tab View
    @ViewBuilder
    private var currentTabView: some View {
        ZStack {
            ForEach(NavigationStackManager.TabPage.allCases, id: \.self) { tab in
                navigationManager.getViewForTab(tab)
                    .opacity(navigationManager.currentTab == tab ? 1 : 0)
                    .zIndex(navigationManager.currentTab == tab ? 1 : 0)
            }
        }
    }

    // MARK: - Book Loading
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color(hex: "#F7F5F2").ignoresSafeArea()
            VStack {
                ProgressView().scaleEffect(1.2)
                Text("در حال بارگذاری...")
                    .font(.custom("DoranNoEn-Light", size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isGlassViewLoaded = true
                navigationManager.setDefaultView(GlassView(), for: .book) // ✅ replaces once
            }
        }
    }

    // MARK: - Tab Bar
    @ViewBuilder
    private var tabBar: some View {
        HStack {
            TabBarIcon2(
                navigationManager: navigationManager,
                icon: "map.fill",
                assignedPage: .menu,
                width: width/14,
                height: height/10
            )
            .padding(.leading, 20)

            TabBarIcon2(
                navigationManager: navigationManager,
                icon: "house.fill",
                assignedPage: .review,
                width: width/14,
                height: height/10
            )

            TabBarIcon2(
                navigationManager: navigationManager,
                icon: "book.fill",
                assignedPage: .book,
                width: width/14,
                height: height/10
            )

            TabBarIcon2(
                navigationManager: navigationManager,
                icon: "globe",
                assignedPage: .profile,
                width: width/14,
                height: height/10
            )
            .padding(.trailing, 20)
        }
        .frame(width: width, height: height/12)
        .background(Rectangle().fill(.ultraThinMaterial))
        .opacity(isMainTabBarPresented ? 1.0 : 0.0)
        .offset(y: isMainTabBarPresented ? 0 : 100)
        .animation(.easeInOut(duration: 0.3), value: isMainTabBarPresented)
    }
}
*/
