//
//  AuthViewModel.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 6/5/25.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

// MARK: - ViewModel
@MainActor
class AuthViewModel: ObservableObject {
    
    let id = UUID().uuidString.prefix(8) // Unique identifier for this instance
    
    @Published var isInitialLoading = true // Track initial authentication check
    @Published var isAuthenticated = false {
        didSet {
            print("🔐 [\(id)] isAuthenticated changed from \(oldValue) to \(isAuthenticated)")
        }
    }
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "http://127.0.0.1:8000"  // Using localhost
    
    init() {
        print("🔧 [\(id)] AuthViewModel init() called")
        Task {
            await verifyAuthentication()
        }
    }
    
    private func verifyAuthentication() async {
        print("🔍 verifyAuthentication() called")
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("🔍 No access token found, setting isAuthenticated to false")
            isAuthenticated = false
            return
        }
        print("🔍 Found access token: \(accessToken.prefix(20))...")
        
        // First check if token is expired
        if isTokenExpired() {
            // Try to refresh the token
            do {
                try await refreshTokenAsync()
                // If refresh succeeds, verify the user still exists
                await verifyUserExists()
            } catch {
                // If refresh fails, sign out
                signOut()
            }
        } else {
            // If token is not expired, verify the user still exists
            await verifyUserExists()
        }
    }
    
    private func verifyUserExists() async {
        print("🔍 verifyUserExists() called")
        guard let url = URL(string: "\(baseURL)/user/") else {
            print("🔍 Invalid URL, calling signOut()")
            signOut()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔍 Invalid response, calling signOut()")
                signOut()
                return
            }
            
            print("🔍 User verification response status: \(httpResponse.statusCode)")
            
            // If we get a 401 or 404, the user no longer exists or is not authorized
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
                print("🔍 User not authorized (401/404), calling signOut()")
                signOut()
            } else if httpResponse.statusCode == 200 {
                print("🔍 User verification successful, setting isAuthenticated to true")
                isAuthenticated = true
            } else {
                print("🔍 Unexpected status code \(httpResponse.statusCode), calling signOut()")
                signOut()
            }
        } catch {
            print("🔍 Network error in verifyUserExists: \(error), calling signOut()")
            signOut()
        }
    }
    
    // MARK: - Sign in Google
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
                throw AuthError.missingClientID
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                throw AuthError.noRootViewController
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingIDToken
            }
            
            // Send ID token to backend
            try await verifyWithBackend(idToken: idToken)
            
            print("✅ Google Sign-In successful")
            isAuthenticated = true
            print("✅ isAuthenticated set to: \(isAuthenticated)")
                  
        } catch {
            let errorMsg = error.localizedDescription
            self.error = errorMsg
            self.errorMessage = errorMsg
            print("❌ Google Sign-In error: \(error)")
        }
    }
    
    private func verifyWithBackend(idToken: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/google") else {
            print("❌ Invalid URL: \(baseURL)/auth/google")
            throw AuthError.invalidURL
        }
        
        let body = ["id_token": idToken]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            print("📤 Sending request to: \(url)")
            print("📤 Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw AuthError.invalidResponse
            }
            
            print("📥 Received response with status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Server error with status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error details: \(errorString)")
                }
                throw AuthError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
            print("✅ Successfully decoded tokens")
            UserDefaults.standard.set(tokens.access, forKey: "accessToken")
            UserDefaults.standard.set(tokens.refresh, forKey: "refreshToken")
        } catch let decodingError as DecodingError {
            print("❌ Decoding error: \(decodingError)")
            throw AuthError.invalidResponse
        } catch {
            print("❌ Network error: \(error)")
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        print("🚪 [\(id)] signOut() called")
        
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.synchronize()
        
        // Sign out from Google as well
        GIDSignIn.sharedInstance.signOut()
        
        // Update authentication state
        print("🚪 [\(id)] Setting isAuthenticated to false")
        isAuthenticated = false
        isInitialLoading = false
        
        print("🚪 [\(id)] isAuthenticated is now: \(isAuthenticated)")
        
        // Force UI update
        DispatchQueue.main.async {
            print("🚪 [\(id)] Sending objectWillChange")
            self.objectWillChange.send()
        }
    }
 
    // MARK: - Manual Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        print("🔄 Debug - Starting login process")
        
        guard let url = URL(string: "\(baseURL)/token/") else {
            errorMessage = "Invalid URL"
            print("❌ Invalid URL")
            return
        }
        
        let credentials = LoginCredentials(email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(credentials)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                print("❌ Invalid response")
                return
            }
            
            print("📥 Debug - Login response status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Debug - Login response data: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    print("✅ Login response decoded: \(loginResponse)")
                    
                    UserDefaults.standard.set(loginResponse.access, forKey: "accessToken")
                    UserDefaults.standard.set(loginResponse.refresh, forKey: "refreshToken")
                    
                    isAuthenticated = true
                    print("✅ Debug - Login successful, isAuthenticated = \(isAuthenticated)")
                    
                } catch {
                    print("❌ Debug - Decoding error:", error)
                    errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            } else {
                // Handle different error status codes
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Debug - Error response:", errorString)
                    errorMessage = "Login failed: \(errorString)"
                } else {
                    errorMessage = "Login failed with status code: \(httpResponse.statusCode)"
                }
            }
        } catch {
            print("❌ Debug - Network error:", error)
            errorMessage = "Network error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Refresh Token
    func refreshTokenAsync() async throws {
        print("🔄 Debug - Starting token refresh")
        
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            print("❌ Debug - No refresh token found")
            throw AuthError.invalidToken
        }
        
        print("📤 Debug - Found refresh token: \(refreshToken.prefix(20))...")
        
        guard let url = URL(string: "\(baseURL)/token/refresh/") else {
            print("❌ Debug - Invalid refresh URL")
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 Debug - Sending refresh token request")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Debug - Invalid response type")
            throw AuthError.invalidResponse
        }
        
        print("📥 Debug - Refresh token response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Debug - Refresh token response data: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Debug - Failed to refresh token with status: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Debug - Error details: \(errorString)")
            }
            throw AuthError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
        UserDefaults.standard.set(tokens.access, forKey: "accessToken")
        UserDefaults.standard.set(tokens.refresh, forKey: "refreshToken")
        print("✅ Debug - Token refresh successful")
    }
    
    func getValidToken() async throws -> String {
        if isTokenExpired() {
            do {
                try await refreshTokenAsync()
            } catch {
                print("❌ Debug - Token refresh failed: \(error)")
                // Clear invalid tokens
                UserDefaults.standard.removeObject(forKey: "accessToken")
                UserDefaults.standard.removeObject(forKey: "refreshToken")
                throw AuthError.invalidToken
            }
        }
        
        guard let token = UserDefaults.standard.string(forKey: "accessToken"), !token.isEmpty else {
            print("❌ Debug - No valid access token found")
            throw AuthError.invalidToken
        }
        
        return token
    }
    
    // MARK: - Checking if a Token is expired
    func isTokenExpired() -> Bool {
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            return true
        }
        
        let parts = accessToken.components(separatedBy: ".")
        guard parts.count == 3,
              let payloadData = Data(base64Encoded: parts[1].padding(toLength: ((parts[1].count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            return true
        }
        
        return Date().timeIntervalSince1970 >= exp
    }
    
    // MARK: - Models
    struct TokenResponse: Codable {
        let access: String
        let refresh: String
    }
    
    struct LoginResponse: Codable {
        let access: String
        let refresh: String
    }

    struct LoginCredentials: Codable {
        let email: String
        let password: String
    }
    
    struct LoginCredCheck: Codable {
        let email: String
    }
    
    enum AuthError: LocalizedError {
        case missingClientID
        case noRootViewController
        case missingIDToken
        case invalidURL
        case invalidResponse
        case serverError(statusCode: Int)
        case noRefreshToken
        case invalidToken
        
        var errorDescription: String? {
            switch self {
            case .missingClientID:
                return "Google Client ID is missing"
            case .noRootViewController:
                return "Could not find root view controller"
            case .missingIDToken:
                return "Failed to get ID token from Google"
            case .invalidURL:
                return "Invalid backend URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let statusCode):
                return "Server error: \(statusCode)"
            case .noRefreshToken:
                return "No refresh token found"
            case .invalidToken:
                return "Invalid or expired token"
            }
        }
    }
}
