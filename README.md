# Fitness Gem 💎 - Gemini 3 Hackathon Edition

**Your Hyper-Personalized, Multi-Modal AI Fitness Companion.**

Fitness Gem leverages the groundbreaking capabilities of **Google Gemini 3** to transform home fitness. By combining a **1M+ token context window**, **Context Caching**, and **Native Multi-Modal Video Understanding**, we offer a coaching experience that remembers your entire journey, sees your form in real-time, and keeps you safe.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Gemini 3](https://img.shields.io/badge/Gemini_3-8E75B2?style=flat&logo=google&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)

---

## 🚀 Gemini 3 Powered Innovations

### 🧠 1M+ Context & "Life Log"
Fitness Gem doesn't just remember your last workout; it remembers **everything**.
- **Holistic Analysis**: We utilize Gemini 3's massive context window to ingest a continuous stream of "Life Logs" (diet photos, workout logs, mood notes, sleep data).
- **Long-Term Pattern Recognition**: The AI detects subtle trends over months—correlating poor sleep with reduced squat depth, or identifying that a specific meal plan boosts your endurance.

### ⚡ Smart Context Caching
To deliver instant, personalized coaching without the latency or cost of re-processing massive history:
- **Cached User Persona**: Your injuries, goals, equipment list, and rapid-access health history are cached.
- **Efficient Conversations**: The chat interface feels instant and deeply contextual, recalling details from weeks ago as if they were mentioned seconds ago.

### 🤖 Hybrid Intelligence (Real-Time + Deep Analysis)
We combine the speed of **Edge AI** with the reasoning of **Cloud Gemini 3**:
- **Real-Time Edge AI (Exercise-Specific)**: Specialized on-device models (ML Kit) are fine-tuned for specific exercises (e.g., Squats, Pushups) to count reps with <10ms latency and ensure immediate form safety.
- **Deep Cloud Analysis**: Gemini 3 handles complex, non-deterministic tasks like **Fall Verification** and long-term fatigue analysis, ensuring high-stakes decisions are backed by SOTA reasoning.

### 👁️ Native Multi-Modal Video Coaching
Gone are the days of simple 2D pose heuristics.
- **Deep Form Analysis**: Gemini views your workout video to provide professional-grade feedback (e.g., "Your knees are caving in slightly at the bottom of the squat").
- **Real-Time Feedback Loop**: Analysis runs after every set to adjust the next set's difficulty or provide immediate corrective cues.

---

## 🛡️ Guardian Safety System

Safety is paramount for home exercise.
- **Gemini Fall Verification**: While local sensors detect sudden drops, **Gemini 3** analyzes the video context to distinguish between a "rest" and a "fall," reducing false positives.
- **Emergency Protocols**: If a fall is confirmed and the user is unresponsive, the **Guardian System** automatically notifies pre-set emergency contacts with location context.

---

## ✨ Key Features

- **🗣️ Natural Language Onboarding**: A conversational interview to understand your "Why", not just your stats.
- **📅 Dynamic Curriculum**: Workouts are generated on the fly. Had a stressful day? The AI suggests a restorative flow. Feeling energetic? It ramps up the intensity.
- **📹 Privacy-First Vision**: Processing happens securely, with strict user controls over video data.
- **📊 Progress Dashboard**: Visual insights derived from complex unstructured data, turned into clear graphs and actionable advice.

---

## 📦 Tech Stack

| Component | Technology | Role |
|-----------|------------|------|
| **Frontend** | Flutter (Dart) | Cross-platform mobile application |
| **Brain** | **Google Gemini 3** | Reasoning, Vision, Long-context Analysis |
| **Localization** | Context Caching | Low-latency personalized state management |
| **Edge AI** | Google ML Kit | Real-time low-latency pose detection & fall monitoring |
| **Backend** | Firebase | Auth, Firestore, Cloud Functions |

---

## 🛠️ Getting Started

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/yourusername/fitness-gem.git
    cd fitness-gem
    ```

2.  **Setup Environment**
    Create a `.env` file in the root directory:
    ```env
    GEMINI_API_KEY=your_gemini_api_key
    ```

3.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

4.  **Run the App**
    ```bash
    flutter run
    ```

---

*Built for the Google Gemini 3 Hackathon. Pushing the boundaries of personalized AI health.*
