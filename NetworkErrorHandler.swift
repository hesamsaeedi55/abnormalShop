// Network Error Handler - Reusable error handling for network operations
// Add this to your AddressViewModel class or create as a separate extension

import Foundation
import Network

// MARK: - Network Error Types
enum NetworkError: Error {
    case noInternet
    case timeout
    case authenticationRequired
    case serverUnreachable
    case invalidResponse
    case serverError(Int)
    case unknown(String)
    
    // Convert to user-friendly Persian message
    var localizedMessage: String {
        switch self {
        case .noInternet:
            return "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"
        case .timeout:
            return "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"
        case .authenticationRequired:
            return "ابتدا وارد حساب کاربری خود شوید"
        case .serverUnreachable:
            return "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"
        case .invalidResponse:
            return "پاسخ نامعتبر از سرور دریافت شد"
        case .serverError(let code):
            return "سرور خطا برگرداند (کد: \(code))"
        case .unknown(let message):
            return "خطای شبکه: \(message)"
        }
    }
    
    // Convert to NSError for throwing
    func toNSError(domain: String = "NetworkError") -> NSError {
        let code: Int
        switch self {
        case .noInternet:
            code = -1009
        case .timeout:
            code = -1001
        case .authenticationRequired:
            code = 401
        case .serverUnreachable:
            code = -1004
        case .invalidResponse:
            code = 3
        case .serverError(let serverCode):
            code = serverCode
        case .unknown:
            code = -1
        }
        
        return NSError(
            domain: domain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: localizedMessage]
        )
    }
}

// MARK: - Network Error Handler
extension NetworkError {
    /// Convert URLError to NetworkError enum
    static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet:
            return .noInternet
        case .timedOut:
            // For non-critical operations, timeout usually means connectivity issues
            return .noInternet
        case .cannotConnectToHost, .cannotFindHost:
            return .serverUnreachable
        case .userAuthenticationRequired:
            return .authenticationRequired
        default:
            return .unknown(urlError.localizedDescription)
        }
    }
    
    /// Handle HTTP response status codes
    static func from(httpStatusCode: Int) -> NetworkError? {
        switch httpStatusCode {
        case 200...299:
            return nil // Success
        case 401, 403:
            return .authenticationRequired
        case 404:
            return .serverError(404)
        case 500...599:
            return .serverError(httpStatusCode)
        default:
            return .serverError(httpStatusCode)
        }
    }
}

// MARK: - Usage Helper Functions

/// Handle network errors and convert to NSError for throwing (for async throws functions)
func handleNetworkError(_ error: Error, domain: String = "AddressError") throws {
    if let urlError = error as? URLError {
        let networkError = NetworkError.from(urlError)
        throw networkError.toNSError(domain: domain)
    } else if let nsError = error as? NSError {
        // Handle other NSErrors
        throw nsError
    } else {
        // Handle unknown errors
        let networkError = NetworkError.unknown(error.localizedDescription)
        throw networkError.toNSError(domain: domain)
    }
}

/// Handle network errors and set error message (for async functions with Published properties)
func handleNetworkErrorForUI(_ error: Error, errorMessage: inout String?, showError: inout Bool) {
    if let urlError = error as? URLError {
        let networkError = NetworkError.from(urlError)
        errorMessage = networkError.localizedMessage
        showError = true
    } else {
        let networkError = NetworkError.unknown(error.localizedDescription)
        errorMessage = networkError.localizedMessage
        showError = true
    }
}

/// Handle HTTP response and convert status codes to errors if needed
func handleHTTPResponse(_ response: HTTPURLResponse?, domain: String = "AddressError") throws {
    guard let httpResponse = response else {
        throw NetworkError.invalidResponse.toNSError(domain: domain)
    }
    
    if let error = NetworkError.from(httpStatusCode: httpResponse.statusCode) {
        throw error.toNSError(domain: domain)
    }
    // Success - no error to throw
}

