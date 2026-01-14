# Fitness Gem 💎

AI-powered home fitness coaching app with real-time pose analysis and personalized workout recommendations.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=flat&logo=google&logoColor=white)
![ML Kit](https://img.shields.io/badge/ML_Kit-4285F4?style=flat&logo=google&logoColor=white)

## Features

- 🎯 **AI Workout Curriculum** - Personalized 10-15 minute workouts based on your profile
- 📹 **Real-time Pose Analysis** - ML Kit pose detection with skeleton overlay
- 🗣️ **Voice Feedback** - TTS corrections during exercise ("Knees out!", "Chest up!")
- 📊 **Progress Tracking** - Session scores and improvement trends
- 🤖 **AI Chat** - Modify workouts through natural conversation
- ⚠️ **Fall Detection** - Safety monitoring with optional guardian alerts

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter (Dart) |
| AI Analysis | Google Gemini 3 Flash Preview |
| Pose Detection | ML Kit Pose Detection |
| TTS | Flutter TTS |
| Charts | fl_chart |
| Backend | Firebase (Auth, Storage) |

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Xcode (for iOS) or Android Studio
- Gemini API Key ([Get one here](https://aistudio.google.com/apikey))
- Firebase Project (optional, for cloud features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fitness-gem.git
   cd fitness-gem/fitness_gem
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your API keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase (Optional)**
   
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Download configuration files:
     - iOS: `GoogleService-Info.plist` → `ios/Runner/`
     - Android: `google-services.json` → `android/app/`
   - Run FlutterFire configure:
     ```bash
     flutterfire configure
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

### iOS-Specific Setup

Add these to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for pose detection</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for voice commands</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition for voice control</string>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── workout_task.dart
│   ├── workout_curriculum.dart
│   ├── exercise_config.dart
│   ├── session_analysis.dart
│   └── user_profile.dart
├── services/                 # Business logic
│   ├── gemini_service.dart   # AI integration
│   ├── tts_service.dart      # Voice feedback
│   ├── firebase_service.dart
│   └── video_recorder.dart
├── views/                    # UI screens
│   ├── home_view.dart
│   ├── camera_view.dart
│   ├── onboarding_view.dart
│   └── results_view.dart
├── utils/                    # Utilities
│   ├── form_rule_checker.dart  # Realtime form feedback
│   ├── rep_counter.dart
│   └── pose_painter.dart
└── widgets/                  # Reusable widgets
```

## Configuration Files

| File | Purpose | Included in Git |
|------|---------|-----------------|
| `.env.example` | Template for environment variables | ✅ |
| `.env` | Your actual API keys | ❌ |
| `GoogleService-Info.plist` | iOS Firebase config | ❌ |
| `google-services.json` | Android Firebase config | ❌ |
| `lib/firebase_options.dart` | Flutter Firebase config | ❌ |

## API Documentation

See [Gemini.md](./Gemini.md) for detailed Gemini API integration guide including:
- System instructions
- Request/Response JSON schemas
- Testing prompts

## Screenshots

*Coming soon*

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google Gemini AI for intelligent workout analysis
- ML Kit for real-time pose detection
- Flutter team for the amazing framework
