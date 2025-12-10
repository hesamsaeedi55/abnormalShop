//
//  ImageStore.swift
//  Robust Image Caching with Retry Logic
//

import SwiftUI
import Foundation
import Combine

class ImageStore: ObservableObject {
    static let shared = ImageStore()
    
    // MARK: - Configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    private let timeoutInterval: TimeInterval = 30.0
    
    // MARK: - Private Properties
    private var cache: [String: UIImage] = [:]
    private var downloadTasks: [String: Task<Void, Never>] = [:]
    private var retryCounters: [String: Int] = [:]
    private var lastRetryTime: [String: Date] = [:]
    
    private let session: URLSession
    private let cacheQueue = DispatchQueue(label: "com.imagestore.cache", qos: .userInitiated)
    
    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50MB memory cache
            diskCapacity: 200 * 1024 * 1024,   // 200MB disk cache
            diskPath: "image_cache"
        )
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Preloads multiple images with retry logic
    func preload(urls: [URL], keyPrefix: String) async -> [UIImage] {
        return await withTaskGroup(of: UIImage?.self) { group in
            var images: [UIImage?] = Array(repeating: nil, count: urls.count)
            
            for (index, url) in urls.enumerated() {
                let key = "\(keyPrefix)-\(index)"
                group.addTask {
                    await self.loadImage(url: url, key: key)
                }
            }
            
            var index = 0
            for await image in group {
                images[index] = image
                index += 1
            }
            
            return images.compactMap { $0 }
        }
    }
    
    /// Loads a single image with retry logic
    func loadImage(url: URL, key: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = await getCachedImage(for: key) {
            return cachedImage
        }
        
        // Cancel any existing download task for this key
        downloadTasks[key]?.cancel()
        
        // Create new download task with retry logic
        let task = Task {
            await downloadWithRetry(url: url, key: key)
        }
        
        downloadTasks[key] = task
        return await task.value
    }
    
    /// Clears cache for a specific prefix
    func clear(prefix: String) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let keysToRemove = self.cache.keys.filter { $0.hasPrefix(prefix) }
            for key in keysToRemove {
                self.cache.removeValue(forKey: key)
                self.retryCounters.removeValue(forKey: key)
                self.lastRetryTime.removeValue(forKey: key)
                self.downloadTasks[key]?.cancel()
                self.downloadTasks.removeValue(forKey: key)
            }
        }
    }
    
    /// Clears all cache
    func clearAll() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.cache.removeAll()
            self.retryCounters.removeAll()
            self.lastRetryTime.removeAll()
            
            // Cancel all download tasks
            for task in self.downloadTasks.values {
                task.cancel()
            }
            self.downloadTasks.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func getCachedImage(for key: String) async -> UIImage? {
        return await cacheQueue.run { [weak self] in
            return self?.cache[key]
        }
    }
    
    private func setCachedImage(_ image: UIImage, for key: String) async {
        await cacheQueue.run { [weak self] in
            self?.cache[key] = image
        }
    }
    
    private func downloadWithRetry(url: URL, key: String) async -> UIImage? {
        var attempt = 0
        
        while attempt < maxRetryAttempts {
            attempt += 1
            
            do {
                let image = try await downloadImage(from: url)
                
                // Success - cache the image and reset retry counter
                await setCachedImage(image, for: key)
                await cacheQueue.run { [weak self] in
                    self?.retryCounters[key] = 0
                    self?.lastRetryTime[key] = nil
                }
                
                print("✅ Successfully downloaded image: \(url.lastPathComponent) (attempt \(attempt))")
                return image
                
            } catch {
                print("❌ Download failed for \(url.lastPathComponent) (attempt \(attempt)): \(error.localizedDescription)")
                
                // Check if we should retry
                if attempt < maxRetryAttempts {
                    let delay = calculateRetryDelay(for: key, attempt: attempt)
                    print("⏳ Retrying in \(delay) seconds...")
                    
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    print("🚫 Max retry attempts reached for \(url.lastPathComponent)")
                    
                    // Update retry counter for future reference
                    await cacheQueue.run { [weak self] in
                        self?.retryCounters[key] = attempt
                        self?.lastRetryTime[key] = Date()
                    }
                }
            }
        }
        
        return nil
    }
    
    private func downloadImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageDownloadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ImageDownloadError.httpError(httpResponse.statusCode)
        }
        
        guard let image = UIImage(data: data) else {
            throw ImageDownloadError.invalidImageData
        }
        
        return image
    }
    
    private func calculateRetryDelay(for key: String, attempt: Int) -> TimeInterval {
        // Exponential backoff with jitter
        let baseDelay = retryDelay * pow(2.0, Double(attempt - 1))
        let jitter = Double.random(in: 0.1...0.5)
        return baseDelay + jitter
    }
    
    // MARK: - Error Types
    
    enum ImageDownloadError: LocalizedError {
        case invalidResponse
        case httpError(Int)
        case invalidImageData
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .invalidImageData:
                return "Invalid image data received"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Convenience Extensions

extension ImageStore {
    /// Loads a single image from URL string
    func loadImage(from urlString: String, key: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return nil
        }
        return await loadImage(url: url, key: key)
    }
    
    /// Preloads images from URL strings
    func preload(urlStrings: [String], keyPrefix: String) async -> [UIImage] {
        let urls = urlStrings.compactMap { URL(string: $0) }
        return await preload(urls: urls, keyPrefix: keyPrefix)
    }
    
    /// Preloads a single image with key prefix (convenience method)
    func preloadSingleImage(url: URL, keyPrefix: String) async -> UIImage? {
        let key = "\(keyPrefix)-single"
        return await loadImage(url: url, key: key)
    }
}

// MARK: - DispatchQueue Extension

extension DispatchQueue {
    func run<T>(_ block: () throws -> T) async rethrows -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.async {
                do {
                    let result = try block()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
