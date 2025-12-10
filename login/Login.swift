struct LoginBrowserView: View {
    @State private var tracker = false
    @State private var floatingEffect: CGFloat = 100
    @State private var email: String = ""
    @State private var password: String = ""
    @EnvironmentObject var loginViewModel: AuthViewModel 

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // Background Image with Animation
                    HStack {
                        Image("swim")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width)
                            .scaleEffect(1.2)
                            .brightness(-0.13)
                            .offset(x: floatingEffect)
                            .ignoresSafeArea()
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                                    floatingEffect = -geo.size.width * 0.45
                                }
                            }
                    }
                    
                    VStack {
                        VStack(spacing:geo.size.height/62) {
                            // Username and Email Fields
                            MyToggleNormal2(text: $email, selectedTab1: false, placeholder: "ایمیل", textAlign: .trailing)
                                .padding(.top,geo.size.height/12)
                            
                            MyToggleNormal2(text: $password, selectedTab1: false, placeholder: "پسورد", textAlign: .trailing)
                            
                            // Login Button
                            Button {
                                Task {
                                    await loginViewModel.login(email: email, password: password)
                                }
                            } label: {
                                GlassMorphicCard2(
                                    width: geo.size.width / 3.8,
                                    height: geo.size.height / 24,
                                    text: "ورود"
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button {
                            Task {
                                await loginViewModel.signInWithGoogle()
                            }
                        } label: {
                            Text("Sign in With Google")
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        // Signup Section
                        HStack {
                            NavigationLink(destination: SignupPage()) {
                                GlassMorphicCard2(
                                    width: geo.size.width / 4.8,
                                    height: geo.size.height / 24,
                                    text: "ثبت نام"
                                )
                            }
                            
                            Text("حساب کاربری ندارید؟")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .allowsTightening(true)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        NavigationLink(destination: eynak()) {
                            Text("ورود بدون حساب کاربری")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .lineLimit(1)
                                .underline()
                                .minimumScaleFactor(0.8)
                                .allowsTightening(true)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .fullScreenCover(isPresented: $tracker) {
                    joinPage(name: "", email: "", password: "")
                }
            }
            .onChange(of: loginViewModel.isAuthenticated) { newValue in
                print("Authentication state changed to: \(newValue)")
            }
        }
    }
} 