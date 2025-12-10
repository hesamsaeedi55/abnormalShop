//
//  profileView.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 9/1/25.
//

import SwiftUI

struct profileView: View {
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    @State var isAddressPresented: Bool = false
    @State var isUserInformationActive: Bool = false
    @EnvironmentObject var navigationVM : NavigationStackManager
    @EnvironmentObject var authVM : AuthViewModel
    @EnvironmentObject var addressVM : AddressViewModel
    @Environment(\.dismiss) var dismiss
    @State var isLoginViewActive = false
    @State var isConfirmationLogoutActive = false
    @State var currentIndex = 0
    @State var isFullScreen = false
    @State var cachedImages: [UIImage] = []
    var body: some View {
        NavigationStack {
            VStack {
                navigationBar()
                
                ZStack {
                    Image("f7")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height/2)
                        .clipped()
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white, location: 0.0),
                                    .init(color: .white, location: 0.7),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: height/8)
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .white, location: 0.3),
                                        .init(color: .white, location: 0.7),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                
                // Centered TabView with Parallax Effect
                ScrollView {
                    HStack {
                        Spacer()
                        TabView(selection: $currentIndex) {
                            ForEach(cachedImages.indices, id: \.self) { idx in
                                GeometryReader { geometry in
                                    Image(uiImage: cachedImages[idx])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                isFullScreen = true
                                            }
                                        }
                                        .disabled(isFullScreen)
                                        .id("hero-\(idx)")
                                        .scaleEffect(calculateScale(geometry: geometry))
                                        .offset(y: calculateOffset(geometry: geometry))
                                        .blur(radius: calculateBlur(geometry: geometry))
                                        .background(Color.black)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minX)
                                            }
                                        )
                                        .clipped()
                                }
                                .tag(idx)
                            }
                            .frame(width: width, height: height * 0.4) // Fixed height for consistent scaling
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: height * 0.4)
                        Spacer()
                    }
                    .padding(.top, 50) // Add some top padding for scroll space
                }
                .scrollIndicators(.hidden)
                
                ScrollView {
                    HStack(alignment: .top) {
                        Spacer()
                        
                        VStack(alignment: .trailing,spacing:20) {
                            buttonProfiles(text: "اطلاعات کاربری", action: {
                                
                                let userInformationView = userInformationView().environmentObject(navigationVM)
                                
                                navigationVM.pushView(userInformationView, to: .profile)
                                
                            })
                            
                            buttonProfiles(text: "آدرس های من", action: {
                                
                                let addressView = AddressView()
                                    .environmentObject(navigationVM)
                                    .environmentObject(addressVM)
                                
                                navigationVM.pushView(addressView, to: .profile)
                                
                            })
                            
                            buttonProfiles(text: "تاریخچه خرید‌ها", action: {
                            
                                navigationVM.pushView(ShoppingBasket(), to: .profile)
                                
                            })

                            
                            buttonProfiles(text: "تاریخچه خرید‌ها", action: {isAddressPresented = true})
                            
                            buttonProfiles(text: "چیزایی که دوس دارم", action: {isAddressPresented = true})
                            
                            buttonProfiles(text: "خروج از حساب کاربری", action: {
                                isConfirmationLogoutActive = true
                            })

                        }.padding(.trailing,20)
                    }
                }
                
            }.ignoresSafeArea()
                .confirmationDialog(Text("آیا از حساب کاربری خود خارج می‌شوید؟"), isPresented: $isConfirmationLogoutActive) {
                            Button("خروج", role: .destructive) {
                                print("🔴 Logout confirmed - calling signOut()")
                                print("🔴 Before signOut - isAuthenticated: \(authVM.isAuthenticated)")
                                
                                // Clear all navigation stacks first
                                authVM.signOut()
                                
                                print("🔴 After signOut - isAuthenticated: \(authVM.isAuthenticated)")
                            }
                          
                            Button("کنسل", role: .cancel) {}
                       }
             
        }
        
    }
    
    // MARK: - Parallax Effect Calculations
    
    private func calculateScale(geometry: GeometryProxy) -> CGFloat {
        let scrollOffset = geometry.frame(in: .global).minY
        let maxScale: CGFloat = 1.2 // Maximum scale when scrolled up
        let threshold: CGFloat = 100 // Scroll threshold for maximum effect
        
        // When scrolling up (negative offset), increase scale
        if scrollOffset < 0 {
            let scaleFactor = min(abs(scrollOffset) / threshold, 1.0)
            return 1.0 + (scaleFactor * (maxScale - 1.0))
        }
        
        return 1.0
    }
    
    private func calculateOffset(geometry: GeometryProxy) -> CGFloat {
        let scrollOffset = geometry.frame(in: .global).minY
        
        // Parallax offset effect - move image slower than scroll
        if scrollOffset < 0 {
            return scrollOffset * 0.5 // Move at half the scroll speed
        }
        
        return 0
    }
    
    private func calculateBlur(geometry: GeometryProxy) -> CGFloat {
        let scrollOffset = geometry.frame(in: .global).minY
        
        // Add subtle blur when scrolling up
        if scrollOffset < 0 {
            return min(abs(scrollOffset) / 50, 2.0) // Max blur of 2.0
        }
        
        return 0
    }
    
    @ViewBuilder
    func buttonProfiles(text:String ,action:@escaping ()->Void) -> some View {
                
        Button {
            
            action()
            
        }label:{
            Text(text)
                .font(.custom("DoranNoEn-Bold", size: 20))
                .foregroundColor(.black)
        }
    }
    
    
    @ViewBuilder
    func navigationBar() -> some View {
        
      VStack {
              VStack {
                  Spacer()
                  
                  HStack(alignment:.bottom) {

                  Button(action: {
                     
                      dismiss()
                  }) {
                      Image(systemName: "chevron.left.circle.fill")
                          .resizable()
                          .frame(width: width/16, height: width/16)
                          .foregroundStyle(.black)
                  }
                  .padding(.leading,width/18)
                  .padding(.bottom,10)

                  Spacer()
                  
                  
                      Text("پروفایل کاربری")
                          .font(.custom("DoranNoEn-ExtraBold", size: 20, relativeTo: .body))

                 
                  Spacer()
                      
                      Button(action: {
                        
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

      }
    }
}
