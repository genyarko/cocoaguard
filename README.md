# CocoaGuard 🫘

**AI-powered cocoa disease detection for farmers, by farmers.**

CocoaGuard is a Flutter mobile app that helps Ghanaian cocoa farmers detect plant diseases in real-time using on-device machine learning. Point your camera at a leaf or pod and get instant diagnoses with treatment recommendations—even without internet.

**Built for the Google Gemma Hackathon** | Powered by Gemma 4 AI

---

## ✨ Features

### Core Scanning
- **Leaf Classification** — Detects Anthracnose, CSSVD, and healthy leaves
- **Pod Detection & Classification** — YOLO-powered detection of individual pods, classifies Phytophthora, Carmenta, Moniliasis, Witches' Broom
- **Real-Time AI** — TensorFlow Lite models run locally on your device
- **Confidence Scoring** — Transparency on diagnosis certainty with actionable warnings

### Offline-First
- ✅ **100% Offline Scanning** — All ML inference runs on-device; no photos sent anywhere
- ✅ **Offline Knowledge Base** — Browse disease info, treatments, and prevention tips anytime
- ✅ **Cached Q&A** — Previous answers available offline; new questions use Gemma 4 when connected
- ✅ **Multilingual** — Available in English, French, Spanish, and Twi

### Smart Features
- **Image Quality Checks** — Warns if photo is blurry, too dark, or overexposed
- **Low-Confidence Alerts** — Recommends retaking photos when results are uncertain (< 55%)
- **Scan History** — Save and revisit past scans with confidence scores
- **Context-Aware Q&A** — Ask about detected diseases; Gemma 4 provides tailored advice
- **Emergency Protocols** — Quick access to COCOBOD contact info for critical diseases like CSSVD

---

## 🚀 Quick Start

### Requirements
- **Flutter** 3.11+ ([Install](https://flutter.dev/docs/get-started/install))
- **Android SDK** 21+ or **iOS 12+**
- **Git**

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/genyarko/cocoaguard.git
   cd cocoaguard
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment (optional for Gemma 4 Q&A)**
   ```bash
   cp .env.example .env
   # Edit .env and add your Gemma 4 API key if available
   ```

4. **Run on a device**
   ```bash
   # List connected devices
   flutter devices
   
   # Run on a specific device
   flutter run -d <device_id>
   ```

5. **Build APK (for distribution)**
   ```bash
   # Universal APK (~140 MB, works on all devices)
   flutter build apk --release

   # Split APKs — smaller per-device (~91 MB for arm64)
   flutter build apk --release --split-per-abi

   # Output: build/app/outputs/flutter-apk/
   ```

   > **Note on size**: The three TFLite models total ~66 MB. The per-architecture APK is ~91 MB for arm64 (most modern Android phones).

---

## 📱 Usage

### Scanning a Leaf
1. Tap **Leaf** in the bottom navigation
2. Choose "Take Photo" (camera) or "Pick from Gallery"
3. Frame the leaf to fill most of the screen
4. Wait for classification
5. Review results, treatments, and confidence score
6. Optionally ask Gemma 4 "What causes this disease?"

### Scanning Pods
1. Tap **Pod** or use the center camera button
2. Frame 1–4 pods clearly
3. App detects each pod and classifies disease per pod
4. Review summary and individual pod details
5. Get treatment advice or ask follow-up questions

### Asking Questions
- Tap **Ask AI** to open the Q&A screen
- Type any farming question (e.g., "How do I treat black pod rot?")
- When **offline**: Answers come from the local knowledge base
- When **online**: Gemma 4 generates personalized answers; responses are cached for offline use

### Browsing Offline
- Tap **Library** to explore diseases, farming tips, and COCOBOD resources
- No internet required

### Changing Language
- Tap **Settings** → **Language**
- Choose from **English**, **Français** (French), **Español** (Spanish), or **Twi** (Asante Twi)
- App saves your preference and restarts with the new language
- All offline content, farming tips, and help text translate instantly

---

## 🏗️ Architecture

### Tech Stack
- **Frontend** — Flutter (Dart)
- **ML Inference** — TensorFlow Lite (on-device)
- **State Management** — Provider
- **Local Storage** — Hive
- **Cloud API** — Gemma 4 (text-only, optional)

### Key Directories
```
lib/
├── screens/              # UI screens (home, scan results, settings, help, privacy)
├── providers/            # State management (ScanProvider, PodScanProvider, QaProvider)
├── services/             # ML services (leaf/pod classifiers, YOLO detection, Gemma4 API)
├── models/               # Data models (ScanRecord, DetectedPod, Diagnosis)
├── utils/                # Helpers (colors, image quality checker, constants)
├── widgets/              # Reusable UI components
└── main.dart             # App entry point

assets/
├── models/               # TF Lite models & labels
├── data/                 # Knowledge base JSON, treatment data
└── images/               # UI icons & logos
```

### ML Models

| Model | File | Size | Classes | Accuracy |
|-------|------|------|---------|----------|
| Leaf Classifier | `leaf_classifier.tflite` | 22 MB | 3 (anthracnose, cssvd, healthy) | 92.13% |
| Pod Detector | `yolo_pod_detect.tflite` | 22 MB | Bounding boxes | — |
| Pod Classifier | `pod_classifier.tflite` | 22 MB | 5 (carmenta, healthy, moniliasis, phytophthora, witches_broom) | — |

**Total model size**: ~66 MB (EfficientNetB3 float16 + YOLOv8)

### Performance (Samsung Galaxy Note 10, mid-range Android)

| Metric | Target | Measured |
|--------|--------|----------|
| Cold start | < 3s | ~1.0s |
| Leaf classify | < 500ms | prints at runtime |
| YOLO detection | < 800ms | prints at runtime |
| Pod classify/pod | < 500ms | prints at runtime |

Performance timings print to debug logs (`[PERF]` prefix) for on-device measurement.

---

## 🔐 Privacy & Security

✅ **No data collection** — Your photos never leave your device
✅ **On-device processing** — All ML inference happens locally
✅ **Minimal cloud usage** — Only text questions to Gemma 4 (photos never sent)
✅ **Full control** — Clear scan & chat history anytime in Settings

See [Privacy Policy](lib/screens/privacy_policy_screen.dart) for full details.

---

## 📚 Documentation

- **Help & Guide** — In-app getting started, scanning tips, confidence levels, FAQs
- **Privacy Policy** — Data handling, permissions, offline mode, deletion rights
- **Architecture** — See [`ARCHITECTURE.md`](ARCHITECTURE.md) for system design and technical decisions

---

## 🌾 Detected Diseases

### Leaf Diseases
| Disease | Severity | Cause |
|---------|----------|-------|
| **Anthracnose** (Black Pod) | Moderate | Fungal (Colletotrichum) |
| **CSSVD** | Severe | Viral (transmitted by mealybugs) |

### Pod Diseases
| Disease | Severity | Cause |
|---------|----------|-------|
| **Phytophthora** (Black Pod Rot) | High | Oomycete (P. palmivora, P. megakarya) |
| **Carmenta** (Pod Borer) | High | Insect moth larvae |
| **Moniliasis** (Frosty Pod) | High | Fungal (M. roreri) — biosecurity risk |
| **Witches' Broom** | High | Fungal (M. perniciosa) — biosecurity risk |

---

## 🛠️ Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Build for iOS
```bash
flutter build ios
# Or: open ios/Runner.xcworkspace in Xcode for advanced signing
```

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open-source. See LICENSE file for details.

---

## 🙏 Acknowledgments

- **Gemma 4 API** — For powering the AI Q&A engine
- **TensorFlow Lite** — For on-device ML inference
- **Flutter & Dart** — For the fantastic cross-platform framework
- **COCOBOD (Ghana Cocoa Board)** — For domain expertise and context
- **Cocoa farming communities** — For inspiration and real-world use cases

---

## 📞 Support

- **Help & Guide** — Tap Help in the app Settings
- **Report Issues** — [GitHub Issues](https://github.com/genyarko/cocoaguard/issues)
- **Privacy Questions** — See in-app Privacy Policy

---

**CocoaGuard — Empowering cocoa farmers with AI.** 🌱
