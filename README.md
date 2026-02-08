# Fitness Gem 💎 - Google Gemini API Hackathon Edition

AI-powered home fitness coaching app that combines real-time device-side pose analysis with **Google Gemini's multi-modal intelligence** for professional-grade feedback.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=flat&logo=google&logoColor=white)
![ML Kit](https://img.shields.io/badge/ML_Kit-4285F4?style=flat&logo=google&logoColor=white)
![FFmpeg](https://img.shields.io/badge/FFmpeg-0078D7?style=flat&logo=ffmpeg&logoColor=white)

## ✨ Hackathon Highlights

### 🧠 Multi-Modal AI Intelligence
- **Twin-Stream Analysis**: We use **Gemini 3 Flash** to analyze two parallel video streams:
  1. **RGB Stream**: Captures raw human movement.
  2. **Skeleton (ControlNet) Stream**: A high-contrast, black-background video with color-coded bones (Red: Right, Blue: Left, Yellow: Torso) to eliminate environment noise and maximize Gemini's biomechanical accuracy.
- **Biomechanical Context**: We inject serialized joint coordinate data and user profile history into the prompt, enabling Gemini to detect subtle form issues like "hip shift" or "knee valgus."

### 🏋️ Dynamic Curriculum Engine
- **AI Onboarding**: A deep-interview system that talks to users during onboarding to understand their injury history and fitness goals beyond simple checkboxes.
- **Smart Planning**: Generates hyper-personalized workout plans using a library of 20+ exercise variations (Diamond Push-ups, Side Planks, etc.) based on available high-quality media assets.

### ⚡ Technical Innovation
- **Cloud-Native, Local-First**: ML Kit handles 30fps pose detection locally, while Gemini provides professional coaching feedback after each set.
- **FFmpeg Hardware Acceleration**: Optimized client-side video processing to generate skeleton overlays without lagging the main UI thread.

## 🚀 Features

- 🎯 **AI Deep Interview** - Natural language onboarding for precise physical assessment.
- 📹 **ControlNet Video Generation** - Real-time generation of noise-free skeleton videos for AI vision.
- 🗣️ **Multilingual AI Coach** - Real-time TTS feedback in English/Korean with personalized encouragement.
- 📊 **Stability Scoring** - Gemini-driven stability and safety scores (1-100) per set.
- ⚠️ **AI Fall Verification** - Vision-based safety monitoring that distinguishes between "lying down to rest" and a "sudden fall."

## 📦 Tech Stack

| Component | Technology | Role |
|-----------|------------|------|
| **Mobile Core** | Flutter (Dart) | Multi-platform UI & Logic |
| **Vision AI** | Google Gemini 3 Flash | High-level movement analysis & Coaching |
| **Pose Logic** | Google ML Kit | Low-latency 2D/3D joint tracking |
| **Video Engine** | FFmpeg (Mobile) | High-contrast skeleton video encoding |
| **Backend** | Firebase (Cloud Functions, Firestore) | Dynamic exercise library & User data |
| **Speech** | Flutter TTS / STT | Voice interaction for "hands-free" workouts |

## 🛠️ Installation & Setup

1. **Clone & Install**
   ```bash
   git clone https://github.com/yourusername/fitness-gem.git
   cd fitness-gem/fitness_gem
   flutter pub get
   ```

2. **Configure API Keys**
   - Create a `.env` file in the root:
     ```bash
     GEMINI_API_KEY=your_key_here
     ```
   - (For reviewers) If you are testing on a simulator/emulator, ensure you have internet access.

3. **Backend Setup (Optional)**
   ```bash
   cd functions
   npm install
   # Deploy to Firebase or use provided seed script:
   npx ts-node src/scripts/seed_exercises.ts
   ```

## 📐 Project Structure

- `lib/services/video_recorder.dart`: **The Core Innovation.** Handles color-coded skeleton drawing and FFmpeg encoding.
- `assets/prompts/`: Contains the System Instructions for the Analyst (Vision) and Consultant (Coaching).
- `lib/utils/rep_counter.dart`: State-machine based repetition counting logic.
- `functions/src/scripts/seed_exercises.ts`: Dynamic exercise library configuration and multi-view sample metadata.

### 📂 Multi-View Training Library
- **Varied Sample Data**: The system supports multiple camera angles and variations for each exercise (e.g., `squat_01`, `squat_02`), enabling the AI to learn from diverse perspectives and provide robust form analysis.
- **Seeding for Scale**: Automated seeding scripts populate Firestore with a rich hierarchy of exercise metadata, directly mapped to high-quality multi-view sample videos.

---
**Google Gemini API Developer Competition 2024 Entry.**  
*Empowering health through accessible, intelligent movement analysis.*

## 📦 Submission & Media Assets

For the hackathon submission, all model files, images, and sample videos must be organized and uploaded to your **Firebase Storage** bucket.

### 📁 Firebase Storage Structure
Ensure your bucket follows this exact hierarchy:
- `/videos/` - Raw MP4 guide videos (e.g., `squat_01.mp4`)
- `/thumbnails/` - Preview JPG images (e.g., `squat_01.jpg`)
- `/images/` - "Ready Pose" sample images (e.g., `squat_01_ready.jpg`)
- `/bundles/` - Zipped asset bundles for each exercise (e.g., `squat_01.zip`)

### 🤐 How to Package Bundles
1. **iOS Models**: Zip your `.mlpackage` folder into a file named **`pose_model.mlpackage.zip`**.
2. **Exercise Bundle**: Create a single ZIP file for the exercise (e.g., `squat_01.zip`) containing:
   - `pose_model.mlpackage.zip` (for iOS)
   - `pose_model.onnx` (for Android)
   - The video, thumbnail, and ready pose image.
3. **Upload**: Upload the final exercise ZIP to the `/bundles/` folder in Firebase Storage.

> [!TIP]
> Refer to [asset_packaging_guide.md](file:///Volumes/Luuse/Developments/fitness-gem/fitness_gem/asset_packaging_guide.md) for a detailed checklist and automation tips.
