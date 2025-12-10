//
//  SearchView.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 7/26/25.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    
    @State var searchText = ""
    @State var isSearchFocused = false
    @State var isActivePresentation: Bool = false
    @State var isAlertActive: Bool = false
    @State var isLoading : Bool = false
    @State var hasSearched: Bool = false
    @State var productFinal : ProductTest?
    
    // MARK: - ENVIRONMENT OBJECTS
    @State var noResult = false
    @EnvironmentObject var productVM: ProductViewModel
    @EnvironmentObject var attVM : AttributeViewModel
    @EnvironmentObject var navigationVM: NavigationStackManager
    @State var  magnifyingTapped = false
    @State var initialViewText = true
    
    var body: some View {
        // FIX: Remove GeometryReader, use VStack with proper constraints
        VStack(spacing: 0) {
            // FIX 1: Pass the SAME ProductViewModel instance
            SearchBarView(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused,
                productVM: productVM,
                isLoading: $isLoading,
                hasSearched: $hasSearched,
                magnifyingTapped: $magnifyingTapped,
                isAlertActivated: $isAlertActive
            )
            .padding(.horizontal)
            .frame(height: 60) // Fixed height instead of geo-based
            
            // FIX 2: Add ScrollView for better display
            ScrollView {
                LazyVStack {
                    ForEach(productVM.searchedProducts, id:\.id) { product in
                        Button {
                            Task {
                                await productVM.loadFinalProduct(product.id)
                                productFinal = product
                                
                                // Navigate to product view using NavigationStackManager
                                let productView = PlacesView2(product: product, lastNavigation: .menu)
                                    .environmentObject(attVM)
                                    .environmentObject(productVM)
                                    .environmentObject(navigationVM)
                                
                                navigationVM.pushView(productView, to: .menu)
                            }
                        } label: {
                            productRow(product)
                        }
                    }
                }
            }
            .opacity(isLoading ? 0 : 1)
            
            Spacer()
        }
        .onChange(of: searchText) { newText in
            if newText == "" {
                Task {
                    await productVM.clearProducts()
                }
            }
            magnifyingTapped = false
        }
        .onChange(of: productVM.error) { newValue in
            isAlertActive = newValue
        }
        .alert("حداقل دو حرف وارد کنید", isPresented: $isAlertActive) {
            Button {
                magnifyingTapped = false
                isAlertActive = false
            } label: {
                Label("باشه", systemImage: "exclamationmark")
            }
        }
        .overlay {
            // FIX: Use overlay instead of ZStack for loading/empty states
            if isLoading {
                startLoadingView()
            } else if productVM.searchedProducts.isEmpty && searchText != "" && searchText.count >= 2 && magnifyingTapped == true && isLoading == false {
                noResultsView()
            } else if initialViewText {
                initialView()
            }
        }
    }
    
    @ViewBuilder
    func productRow(_ product: ProductTest) -> some View {
        HStack {
            let primaryURL = URL(string: product.images.first(where: { $0.isPrimary })?.url ?? "")
            
            KFImage(primaryURL)
                .placeholder {
                    ProgressView()
                }
                .onFailure { error in
                    print("Failed: \(error)")
                }
                .resizable()
                .aspectRatio(4/5, contentMode: .fill)
                .frame(width: 100, height: 120)
                .clipped()
                .cornerRadius(8)
                .padding(8)
            
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Text("\(product.name)")
                        .font(.headline)
                        .lineLimit(2)
                    Button {
                        // Add to cart action
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                Text(product.getFormattedPrice())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Spacer()
        }
        .background(.ultraThinMaterial.opacity(0.8))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .shadow(radius: 8, x: 1, y: 1)
        .onAppear {
            if let index = productVM.searchedProducts.firstIndex(where: { $0.id == product.id }),
               index >= productVM.searchedProducts.count - 3 {
                Task {
                    await productVM.searchProductos(query: searchText)
                }
            }
        }
    }
    
    @ViewBuilder
    func startLoadingView() -> some View {
        ProgressView()
    }
    
    @ViewBuilder
    func initialView() -> some View {
        if !isLoading && productVM.searchedProducts.isEmpty {
            Text("محصول یا برند موردنظرتون رو جستجو کنید")
                .foregroundStyle(.black)
                .font(.custom("DoranNoEn-Bold", size: 20))
                .frame(maxWidth: .infinity)
                .opacity(0.3)
        }
    }
    
    @ViewBuilder
    func noResultsView() -> some View {
        if !isLoading && productVM.searchedProducts.isEmpty {
            Text("هیچ چیزی پیدا نشد")
                .foregroundStyle(.black)
                .font(.custom("DoranNoEn-Bold", size: 20))
                .frame(maxWidth: .infinity)
                .opacity(0.3)
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(ProductViewModel())
        .environmentObject(AttributeViewModel())
        .environmentObject(NavigationStackManager())
}

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearchFocused: Bool
    @FocusState private var textFieldFocused: Bool
    // FIX: Remove unused isAnimated state
    @ObservedObject var productVM: ProductViewModel
    @Binding var isLoading : Bool
    @Binding var hasSearched: Bool
    @Binding var magnifyingTapped : Bool
    @Binding var isAlertActivated : Bool
    
    var body: some View {
        if #available(iOS 16.0, *) {
            HStack(spacing: 15) {
                if !searchText.isEmpty {
                    Button(action: {
                        // FIX: Remove withAnimation wrapper, use explicit animation only where needed
                        hasSearched = false
                        isLoading = false
                        productVM.currentSearchPage = 1
                        searchText = ""
                        productVM.searchedProducts = []
                        textFieldFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSearchFocused ? .black : .gray)
                            .padding(.leading)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Search TextField
                TextField("جستجوی محصولات، برندها و ...", text: $searchText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .accentColor(.black)
                    .multilineTextAlignment(.trailing)
                    .focused($textFieldFocused)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                
                Button {
                    if searchText.count == 0 {
                        isAlertActivated = true
                        return
                    } else if !searchText.isEmpty {
                        magnifyingTapped = true
                        
                        if searchText.count < 2 {
                            isAlertActivated = true
                            return
                        }
                        
                        productVM.currentOperation = .search
                        
                        Task {
                            await MainActor.run {
                                timerEnable()
                            }
                            
                            await productVM.clearProducts()
                            await productVM.searchProductos(query: searchText)
                            productVM.currentSearchText = searchText
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSearchFocused ? .black : .gray)
                        .padding(.trailing)
                }
                .disabled(isLoading)
            }
            .padding(.vertical, 15)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lineWidth: 4)
                    .foregroundStyle(.white)
                    .shadow(radius: 8, x: 1, y: 1)
            )
            .padding(.horizontal, 10)
            .shadow(
                color: isSearchFocused ? Color.black.opacity(0.1) : Color.clear,
                radius: isSearchFocused ? 8 : 0,
                x: 0,
                y: isSearchFocused ? 4 : 0
            )
            // FIX: Single animation modifier at the end, using explicit animation
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSearchFocused)
            .onChange(of: textFieldFocused) { focused in
                // FIX: Use explicit animation only when focus actually changes
                isSearchFocused = focused
            }
            .onAppear {
                // FIX: Remove unused animation code
                if productVM.currentSearchText == nil {
                    searchText = ""
                } else {
                    searchText = productVM.currentSearchText!
                }
            }
        }
    }
    
    func timerEnable() {
        isLoading = true
        if productVM.searchedProducts.first != nil {
            isLoading = false
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
}


