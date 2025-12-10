//
//  FeedView_DEBUG.swift
//  DEBUG VERSION - Minimal view to test if environment objects are the issue
//

import SwiftUI

struct FeedView_DEBUG: View {
    @EnvironmentObject var viewModel: ProductViewModel
    @EnvironmentObject var cat: CategoryViewModel
    @EnvironmentObject var attVM: AttributeViewModel
    @EnvironmentObject var sortVM: SortViewModel
    @EnvironmentObject var specialOfferVM: specialOfferViewModel
    @EnvironmentObject var navigationManager: NavigationStackManager
    @EnvironmentObject var basketVM: shoppingBasketViewModel
    
    @Binding var isMainTabBarPresented: Bool
    
    var body: some View {
        // MINIMAL TEST VIEW - Just to see if view renders at all
        ZStack {
            Color.red.ignoresSafeArea()
            
            VStack {
                Text("FeedView is rendering!")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                
                Text("If you see this, the view is working")
                    .foregroundColor(.white)
                    .padding()
                
                // Test accessing environment objects one by one
                Group {
                    Text("ProductVM: \(viewModel.products.count) products")
                    Text("CategoryVM: \(cat.categories.count) categories")
                    Text("SortVM: \(sortVM.sortedProducts.count) sorted")
                }
                .foregroundColor(.white)
                .padding()
            }
        }
    }
}

