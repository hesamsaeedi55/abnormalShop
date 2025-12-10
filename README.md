# Google Sign-In SwiftUI Implementation

This project demonstrates a complete implementation of Google Sign-In in a SwiftUI app, integrated with a backend authentication flow.

## Setup Instructions

1. Install Dependencies
   ```bash
   # Using Swift Package Manager
   # Add the following packages to your project:
   - https://github.com/google/GoogleSignIn-iOS.git
   ```

2. Configure Google Sign-In
   - Go to the [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select an existing one
   - Enable the Google Sign-In API
   - Create OAuth 2.0 credentials
   - Add your iOS app's bundle identifier
   - Download the `GoogleService-Info.plist` file

3. Update Configuration
   - Replace `YOUR_GOOGLE_CLIENT_ID` in `Info.plist` with your actual Google Client ID
   - Update the `backendURL` in `AuthViewModel.swift` if your backend is hosted elsewhere

4. Backend Requirements
   The backend should implement the following endpoint:
   ```
   POST /auth/google/
   Content-Type: application/json
   
   {
     "id_token": "<Google ID token>"
   }
   ```
   
   Expected response:
   ```json
   {
     "access": "<access_token>",
     "refresh": "<refresh_token>"
   }
   ```

## Features

- Modern SwiftUI implementation (iOS 15+)
- Google Sign-In integration
- Secure token storage
- Error handling
- Loading states
- Clean architecture with MVVM pattern
- Async/await concurrency
- Backend integration

## Security Notes

- Tokens are stored in UserDefaults for simplicity
- For production, consider using Keychain for more secure storage
- Implement token refresh mechanism
- Add proper error handling for network issues
- Implement proper session management

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- GoogleSignIn-iOS package 