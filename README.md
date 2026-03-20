# Voom

A random video chat app similar to Azar, built with Flutter, Agora SDK, Firebase, and DeepAR filters.

## Features

- 1-on-1 random video chat
- Real-time video streaming with Agora SDK
- TikTok-style face filters with DeepAR SDK
- Simple matchmaking queue system
- Minimal user profile (anonymous ID)
- Performance optimized for 24-30 FPS video streaming
- Adaptive quality based on network conditions
- Hardware-accelerated filter processing
- **Monetization System:**
  - Coin-based economy
  - In-app purchases for coin packages
  - Premium features (gender/region filters, reconnect, priority matching, premium filters, no ads)
- **Safety & Moderation:**
  - Report user functionality during chat
  - Block user system to prevent future matches
  - Auto-skip when camera is off (privacy protection)
  - Basic AI moderation placeholder
  - Anti-spam skip rate limiting (max 5 skips per minute)

## Tech Stack

- Frontend: Flutter
- Backend: Firebase (Firestore)
- Video: Agora SDK
- Filters: DeepAR SDK
- Performance: Custom monitoring and adaptive quality
- **Monetization: In-app purchases (iOS Store Kit, Google Play Billing)**

## Setup Instructions

### Prerequisites

- Flutter SDK (3.41.4 or later)
- Android Studio or VS Code with Flutter extension
- Android device or emulator for testing

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd voom
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project at https://console.firebase.google.com/
   - Enable Firestore and Authentication in the Firebase Console.

   **Android:**
   - In the Firebase Console go to **Project Settings → Your apps → Android app**.
   - Register the app with package name `com.example.voom` (or your bundle ID).
   - Download `google-services.json` and place it in `android/app/`.

   **iOS:**
   - In the Firebase Console go to **Project Settings → Your apps → iOS+ app**.
   - Register the app with bundle ID `com.example.voom` (must match `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`).
   - Click **Download GoogleService-Info.plist**.
   - Replace the placeholder file at `ios/Runner/GoogleService-Info.plist` with the downloaded file.
   - Open Xcode (`open ios/Runner.xcworkspace`), select the **Runner** target, go to **Build Phases → Copy Bundle Resources**, and confirm `GoogleService-Info.plist` is listed (it was added automatically; if not, drag it in).

4. Set up Agora:
   - Create an Agora account at https://console.agora.io/
   - Get your App ID and add it to `lib/services/agora_service.dart` (replace the placeholder)

5. Set up DeepAR:
   - Get DeepAR license at https://developer.deepar.ai/
   - Add API key to `lib/services/filter_service.dart` (replace the placeholder)

### Running the App

1. Connect an Android device or start an emulator.

2. Run the app:
   ```bash
   flutter run
   ```

### Building APK

```bash
flutter build apk
```

The APK will be generated in `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

- `lib/main.dart`: Main app entry point with screens
- `lib/constants.dart`: App-wide color constants
- `lib/screens/`: UI screens (home, matching, video chat, buy coins)
- `lib/services/`: Business logic services (Agora, DeepAR, matching, monetization, safety)
- `lib/widgets/`: Reusable UI components (buttons, video view, coin balance)
- `lib/models/`: Data models (monetization models, safety models)
- `lib/utils/`: Utility classes (performance monitor)
- `android/`: Android-specific configuration
- `ios/`: iOS-specific configuration
- `pubspec.yaml`: Dependencies and assets

## Performance Optimizations

The app is optimized for smooth 24-30 FPS video streaming and filter processing:

- **Adaptive Video Quality**: Agora SDK automatically adjusts bitrate and resolution based on network conditions
- **Hardware-Accelerated Filters**: DeepAR filters run in background isolates to prevent UI blocking
- **Efficient Rendering**: Video views use RepaintBoundary and optimized widget trees
- **Performance Monitoring**: Real-time FPS tracking with automatic quality adjustments
- **Memory Management**: Proper lifecycle management and resource cleanup

## Current Status

- ✅ Modular code structure implemented
- ✅ Agora SDK integration with performance optimizations
- ✅ DeepAR filter processing with isolate-based background processing
- ✅ Performance monitoring and adaptive quality adjustments
- ✅ Debug APK build completed
- ✅ **Complete monetization system implemented:**
  - Coin balance management
  - In-app purchase integration
  - Premium feature unlocking
  - UI updates for coin display and purchases
- ✅ **Complete safety & moderation system implemented:**
  - Report and block functionality
  - Auto-skip for camera-off scenarios
  - Anti-spam skip rate limiting
  - Basic AI moderation placeholder
  - Configurable safety settings
- 🔄 Firebase matching backend (placeholder implemented)
- 🔄 Real API keys needed for full functionality

## Next Steps for Full MVP

- Add real Agora App ID and DeepAR license keys
- Implement Firebase Firestore matchmaking
- **Set up in-app purchase products in App Store Connect and Google Play Console**
- **Configure product IDs in the code**
- Add safety features (report/block)
- Test on physical devices for FPS validation
- Optimize for different network conditions

## Monetization System

### Coins System
- Users start with 50 free coins
- Coins are deducted for premium features:
  - Gender Filter: 10 coins
  - Region Filter: 15 coins
  - Reconnect: 20 coins
  - Premium Filters: 50 coins (one-time unlock)
  - Priority Matching: 30 coins
  - No Ads: 100 coins (one-time unlock)

### In-App Purchases
- Small Pack: 100 coins for $0.99
- Medium Pack: 500 coins for $4.99
- Large Pack: 1200 coins for $9.99 (best value)

### Premium Features
- **Gender Filter**: Filter matches by gender preference
- **Region Filter**: Filter matches by geographic region
- **Reconnect**: Find a new match during video chat
- **Premium Filters**: Access to exclusive filter effects
- **Priority Matching**: Get matched faster
- **No Ads**: Remove all advertisements

### Implementation
- Cross-platform in-app purchases using `in_app_purchase` package
- Secure payment processing through App Store and Google Play
- Local storage for coin balance and unlocked features
- Real-time UI updates for coin balance and premium status

## Safety & Moderation

### User Safety Features
- **Report System**: Users can report inappropriate behavior during video chats with detailed reason selection
- **Block System**: Blocked users are prevented from future matches and stored locally
- **Auto-Skip Protection**: Calls automatically end if the remote user's camera is off (configurable)
- **Rate Limiting**: Maximum 5 skips per minute to prevent spam and encourage meaningful interactions

### Moderation System
- **AI Moderation Placeholder**: Basic content analysis for inappropriate language and behavior
- **Risk Assessment**: Content flagged as low/medium/high risk with automated actions
- **Report Review**: All reports stored for manual review (backend integration needed)

### Safety Settings
- **Auto-skip camera off**: Automatically end calls when remote camera is disabled
- **Moderation enabled**: Toggle AI content moderation
- **Skip rate limit**: Configurable maximum skips per minute
- **Camera required**: Require camera for matching (privacy protection)

### Implementation Details
- Local storage for reports, blocks, and safety settings
- Real-time safety monitoring during video calls
- Configurable safety parameters
- Privacy-focused design prioritizing user safety
