//
//  ssssssApp.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 3/16/23.
//

import SwiftUI
@available(iOS 16.0, *)
@main
struct YourApp: App {
    
    @StateObject var authVM = AuthViewModel()
    @StateObject var productVM = ProductViewModel()
    @StateObject var categoryVM = CategoryViewModel()
    @StateObject var attributeVM = AttributeViewModel()
    @StateObject var sortVM = SortViewModel()
    @StateObject var specialOfferVM = specialOfferViewModel()
    @StateObject var navigationStackManager = NavigationStackManager()
    
    @State private var showLoadingScreen: Bool = true
    @State private var isAnimating: Bool = false
    @State private var authenticationChecked: Bool = false
    @State var shouldShowMainView: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
            if authVM.isAuthenticated {
                
                MainView() // Use MainView instead of TabNavigationView
                    .environmentObject(authVM)
                    .environmentObject(productVM)
                    .environmentObject(categoryVM)
                    .environmentObject(attributeVM)
                    .environmentObject(sortVM)
                    .environmentObject(specialOfferVM)
                    .environmentObject(navigationStackManager)
                    .transition(.opacity)
                    .id("authenticated")
                    .onAppear {
                        print("🔵 MainView appeared - isAuthenticated: \(authVM.isAuthenticated)")
                    }
                
            } else {
                LoginBrowserView()
                    .environmentObject(authVM)
                    .transition(.opacity)
                    .id("unauthenticated")
                    .onAppear {
                        print("🔴 LoginBrowserView appeared - isAuthenticated: \(authVM.isAuthenticated)")
                    }
            }
            }
            .onChange(of: authVM.isAuthenticated) { newValue in
                print("🔄 Authentication state changed to: \(newValue)")
            }
            .onAppear {
                print("🚀 App started - isAuthenticated: \(authVM.isAuthenticated)")
                print("🚀 Showing: \(authVM.isAuthenticated ? "MainView" : "LoginBrowserView")")
            }
        }
    }
}
