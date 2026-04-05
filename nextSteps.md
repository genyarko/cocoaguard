# G4N — Implementation Plan (nextSteps.md)
**Created**: 2026-04-02  
**Deadline**: ~June 2, 2026 (2 months from hackathon start)  
**Platform**: Flutter (Dart)  
**Base project**: g4n (currently a blank Flutter scaffold at `C:\Users\genya\Downloads\g4n`)

---
*** Sometimes crashes after detecting too many pods
*** look into options to speed inference up (e.g. enabling GPU/NNAPI delegate, or
quantizing models to int8)? not working after doing this.

## What We Have Right Now

### g4n (this repo)
- Blank Flutter template (`lib/main.dart` is the default counter app)
- `pubspec.yaml` has no dependencies beyond `cupertino_icons`
- This is where we build the merged app

### Source Projects (in `g4n projects data/`)

| Project | Platform | Models | Classes | Status |
|---------|----------|--------|---------|--------|
| **Gamini** (Cocoa Ahaban) | Flutter | EfficientNetB3 (22 MB, float16, 92.13% acc) | 3: anthracnose, cssvd, healthy | Production-ready |
| **cococpod** | Flutter | EfficientNetB3 (pod_scanner.tflite) + YOLOv8 (yolo_pod_detect.tflite) | 5: carmenta, healthy, moniliasis, phytophthora, witches_broom | Functional, has YOLO pipeline |
| **MyGemma3N** (G3N) | Android/Kotlin | Gemma 3n + TFLite embeddings | N/A (text AI) | Mature, extract knowledge patterns only |

### Key Observation
- Gamini detects **3 leaf diseases** (anthracnose, cssvd, healthy)
- cococpod detects **5 pod diseases** (carmenta, healthy, moniliasis, phytophthora, witches_broom)
- These are **complementary** — leaves vs pods. The merged app should do both.
- cococpod also has a **YOLO detector** that locates pods in a photo before classifying them — this is the two-stage pipeline we want.

### Existing Assets to Reuse

**From Gamini** (copy into g4n):
| File | What it does | Copy to |
|------|-------------|---------|
| `lib/services/classifier_service.dart` | TFLite model loading + inference | `lib/services/leaf_classifier_service.dart` |
| `lib/services/storage_service.dart` | Hive CRUD for scan history | `lib/services/storage_service.dart` |
| `lib/models/scan_record.dart` + `.g.dart` | Hive model for scan records | `lib/models/scan_record.dart` |
| `lib/providers/scan_provider.dart` | Scan flow state management | `lib/providers/scan_provider.dart` |
| `lib/providers/history_provider.dart` | History list state | `lib/providers/history_provider.dart` |
| `lib/screens/home_screen.dart` | Camera/gallery + recent scans | `lib/screens/home_screen.dart` (refactor) |
| `lib/screens/results_screen.dart` | Diagnosis card + confidence bars | `lib/screens/results_screen.dart` (refactor) |
| `lib/screens/history_screen.dart` | Scan history list | `lib/screens/history_screen.dart` |
| `lib/screens/info_screen.dart` | Disease guide | `lib/screens/info_screen.dart` |
| `lib/widgets/confidence_bar.dart` | Color-coded progress bar | `lib/widgets/confidence_bar.dart` |
| `lib/widgets/diagnosis_card.dart` | Result display | `lib/widgets/diagnosis_card.dart` |
| `lib/widgets/scan_card.dart` | History thumbnail card | `lib/widgets/scan_card.dart` |
| `lib/utils/constants.dart` | Colors, thresholds | `lib/utils/constants.dart` |
| `lib/utils/image_utils.dart` | Crop, resize, tensor conversion | `lib/utils/image_utils.dart` |
| `lib/utils/treatment_data.dart` | Treatment recs (3 classes) | `lib/utils/treatment_data.dart` (expand) |
| `assets/model/cocoa_b3_v2_92.13_float16.tflite` | Leaf classifier model | `assets/models/leaf_classifier.tflite` |
| `assets/model/cocoa_b3_v2_labels.json` | Leaf labels (3 classes) | `assets/models/leaf_labels.json` |

**From cococpod** (copy into g4n):
| File | What it does | Copy to |
|------|-------------|---------|
| `lib/ml/detection/yolo_detector.dart` | YOLO pod detection | `lib/services/yolo_detector.dart` |
| `lib/ml/detection/yolo_preprocessor.dart` | YOLO input preprocessing | `lib/services/yolo_preprocessor.dart` |
| `lib/ml/detection/yolo_postprocessor.dart` | YOLO output → bounding boxes | `lib/services/yolo_postprocessor.dart` |
| `lib/ml/detection/bounding_box.dart` | Bounding box model | `lib/models/bounding_box.dart` |
| `lib/ml/detection/detected_pod.dart` | Detected pod model | `lib/models/detected_pod.dart` |
| `lib/ml/detection/image_cropper.dart` | Crop detected pods from image | `lib/utils/image_cropper.dart` |
| `lib/ml/detection/score_blender.dart` | Blend YOLO + classifier scores | `lib/services/score_blender.dart` |
| `lib/ml/model_service.dart` | Pod classification service | `lib/services/pod_classifier_service.dart` |
| `lib/ml/preprocessor.dart` | EfficientNet input prep | `lib/services/pod_preprocessor.dart` |
| `lib/ml/postprocessor.dart` | EfficientNet output parsing | `lib/services/pod_postprocessor.dart` |
| `lib/features/detection/bounding_box_painter.dart` | Draw boxes on image | `lib/widgets/bounding_box_painter.dart` |
| `lib/features/treatment/treatment_data.dart` | Treatment recs (5 classes) | merge into `lib/utils/treatment_data.dart` |
| `lib/features/scan/scan_screen.dart` | Camera scan UI | reference for building scan UI |
| `lib/features/scan/scan_mode_selector.dart` | Leaf vs pod selector | reference for mode switching |
| `assets/models/pod_scanner.tflite` | Pod classifier model | `assets/models/pod_classifier.tflite` |
| `assets/models/yolo_pod_detect.tflite` | YOLO pod detection model | `assets/models/yolo_pod_detect.tflite` |
| `assets/models/pod_labels.json` | Pod labels (5 classes) | `assets/models/pod_labels.json` |
| `assets/data/treatments.json` | Full treatment JSON (5 diseases) | `assets/data/pod_treatments.json` |

**From MyGemma3N** (extract concepts, not code — it's Kotlin):
| What | Purpose | How to use |
|------|---------|-----------|
| Prompt engineering patterns | Domain-adapted prompts for farming Q&A | Translate to Dart prompt templates |
| Crisis handbook structure | Emergency protocol framework | Build `assets/data/emergency_protocols.json` |
| Offline fallback architecture | How to gracefully degrade when offline | Apply same pattern in Dart services |
| RAG approach | Keyword search over local knowledge | Simplify into `KnowledgeService` |

---

## Hackathon Submission Checklist (from hackathon info.md)

- [ ] **Kaggle Writeup** — max 1500 words, must explain architecture + Gemma 4 usage
- [ ] **Video** — max 3 min, YouTube link, tell the problem + demo the solution
- [ ] **Public Code Repository** — GitHub, well-documented, shows Gemma 4 implementation
- [ ] **Live Demo** — APK or web build judges can test without login
- [ ] **Media Gallery** — cover image + screenshots

---

## Phase Plan

### PHASE 0: Project Setup (Days 1-3)
> Get the blank g4n project ready to receive code from the source projects.

**Tasks**:
- [x] 0.1 — Update `pubspec.yaml` with all required dependencies (from Gamini + cococpod)
- [x] 0.2 — Create the target folder structure under `lib/`
- [x] 0.3 — Copy model files into `assets/models/`
- [x] 0.4 — Copy treatment data into `assets/data/`
- [x] 0.5 — Create `assets/data/leaf_treatments.json` (from Gamini's treatment_data.dart)
- [ ] 0.6 — Run `flutter pub get` — verify project compiles
- [x] 0.7 — Set up `.gitignore` (exclude `.env`, API keys, build artifacts)
- [ ] 0.8 — Initialize public GitHub repo

**Target folder structure after Phase 0**:
```
lib/
  main.dart
  app.dart
  models/
  services/
  providers/
  screens/
  widgets/
  utils/
assets/
  models/
    leaf_classifier.tflite          (from Gamini)
    leaf_labels.json                (from Gamini)
    pod_classifier.tflite           (from cococpod)
    pod_labels.json                 (from cococpod)
    yolo_pod_detect.tflite          (from cococpod)
  data/
    pod_treatments.json             (from cococpod)
    leaf_treatments.json            (new, from Gamini treatment_data.dart)
    diseases_knowledge.json         (new, comprehensive knowledge base)
    emergency_protocols.json        (new)
  images/
```

**Dependencies to add to pubspec.yaml**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # ML inference
  tflite_flutter: ^0.11.0
  # Camera + images
  image_picker: ^1.1.2
  camera: ^0.11.1
  image: ^4.3.0
  # State management
  provider: ^6.1.2
  # Local storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
  # Networking (Gemma 4 API)
  http: ^1.2.0
  # Utilities
  uuid: ^4.5.1
  intl: ^0.19.0
  permission_handler: ^11.3.1
  connectivity_plus: ^6.0.0        # detect online/offline
  fl_chart: ^0.70.2                # optional: analytics charts
```

**Exit criteria**: `flutter run` launches the app on a device with no errors.

---

### PHASE 1: CV Pipeline — Leaf Classification (Days 4-10)
> Port Gamini's leaf disease detection into g4n. This is the fastest win — already production-ready.

**Tasks**:
- [x] 1.1 — Copy `classifier_service.dart` from Gamini → adapt as `leaf_classifier_service.dart`
- [x] 1.2 — Copy `image_utils.dart` from Gamini → `utils/image_utils.dart`
- [x] 1.3 — Copy `scan_record.dart` + `.g.dart` → `models/scan_record.dart`
- [x] 1.4 — Copy `storage_service.dart` → `services/storage_service.dart`
- [x] 1.5 — Copy `scan_provider.dart` + `history_provider.dart` → `providers/`
- [x] 1.6 — Build basic home screen with camera + gallery buttons (reference Gamini's `home_screen.dart`)
- [x] 1.7 — Build results screen showing diagnosis + confidence bars (reference Gamini's `results_screen.dart`)
- [x] 1.8 — Copy widgets: `confidence_bar.dart`, `diagnosis_card.dart`, `scan_card.dart`
- [x] 1.9 — Wire up `app.dart` with providers and navigation
- [ ] 1.10 — Test: take photo of cocoa leaf → get classification with confidence score
- [ ] 1.11 — Test: scan history saves and loads correctly

**Exit criteria**: User can photograph a cocoa leaf, get disease classification (anthracnose / cssvd / healthy) with confidence score, and view scan history. All offline.

---

### PHASE 2: CV Pipeline — Pod Detection + Classification (Days 11-20)
> Port cococpod's two-stage YOLO + EfficientNet pipeline. This is the "wow factor" — detect pods in a photo, then classify each one.

**Tasks**:
- [ ] 2.1 — Copy YOLO detector files from cococpod: `yolo_detector.dart`, `yolo_preprocessor.dart`, `yolo_postprocessor.dart`
- [ ] 2.2 — Copy pod models: `bounding_box.dart`, `detected_pod.dart`
- [ ] 2.3 — Copy `image_cropper.dart`, `score_blender.dart`
- [ ] 2.4 — Copy `model_service.dart` → adapt as `pod_classifier_service.dart`
- [ ] 2.5 — Copy `bounding_box_painter.dart` → `widgets/`
- [ ] 2.6 — Build scan mode selector UI (Leaf scan vs Pod scan)
- [ ] 2.7 — Build pod detection results screen (image with bounding boxes + per-pod classification)
- [ ] 2.8 — Merge treatment data: combine Gamini's 3-class leaf treatments with cococpod's 5-class pod treatments
- [ ] 2.9 — Build treatment recommendation screen (show treatments for detected disease)
- [ ] 2.10 — Update scan history to distinguish leaf scans from pod scans
- [ ] 2.11 — Test: take photo of cocoa pods → YOLO draws bounding boxes → each pod classified
- [ ] 2.12 — Test: both scan modes work end-to-end on a real device

**Exit criteria**: User can choose "Leaf Scan" or "Pod Scan". Leaf scan classifies 3 diseases. Pod scan detects pods with bounding boxes and classifies 5 diseases. Both fully offline.

---

### PHASE 3: Task Router + Home Screen Redesign (Days 21-27)
> Build the intelligent input classifier that routes user input to the right pipeline. This is the architecture judges want to see.

**Tasks**:
- [x] 3.1 — Create `task_type.dart` enum: `image`, `question`, `emergency`, `unknown`
- [x] 3.2 — Create `task_router_service.dart` with rule-based classification:
  - Emergency keywords → `TaskType.emergency`
  - Question patterns (what/why/how/tell/explain) → `TaskType.question`
  - Image input → `TaskType.image`
- [x] 3.3 — Redesign home screen: unified entry point with 3 clear paths
  - Camera button (→ scan mode selector → leaf or pod)
  - Text input field (→ router decides: question or emergency)
  - Quick action cards (Scan Leaf, Scan Pod, Ask Question, Emergency)
- [x] 3.4 — Build emergency screen: instant offline display of emergency protocols
  - Contact COCOBOD
  - Quarantine steps
  - First aid for agricultural chemical exposure
- [x] 3.5 — Create `assets/data/emergency_protocols.json` with structured emergency data
- [x] 3.6 — Wire router into navigation: text input → classify → route to correct screen
- [x] 3.7 — Add connectivity detection (`connectivity_plus`) — show online/offline indicator in app bar
- [x] 3.8 — Test: type "my tree is dying help" → routes to emergency
- [x] 3.9 — Test: type "why do my pods turn black" → routes to Q&A (Phase 4)
- [x] 3.10 — Test: tap camera → routes to scan mode selector

**Exit criteria**: App has a single home screen where the user can scan, ask questions, or get emergency help. Router correctly classifies inputs. Emergency protocols display instantly offline.

---

### PHASE 4: Gemma 4 Cloud Q&A (Days 28-38)
> Integrate Gemma 4 API for intelligent farming Q&A. This is what makes the app "Gemma 4 powered" for the judges.

**Tasks**:
- [x] 4.1 — Create `gemma4_service.dart`: HTTP client for Gemma 4 API
  - Endpoint: Google AI Generative Language API (generativelanguage.googleapis.com)
  - Authentication: API key from environment variable (GEMMA_API_KEY)
  - Request/response parsing with error classification
- [x] 4.2 — Create domain-specific system prompt for cocoa farming:
  - Role: expert agricultural advisor for Ghanaian cocoa farmers
  - Scope: disease explanation, treatment advice, farming best practices, emergency guidance
  - Constraints: brief answers, actionable steps, mention COCOBOD when relevant
- [x] 4.3 — Create `conversation.dart` model (Hive): store Q&A history
  - Fields: id, timestamp, question, answer, source (gemma4 / knowledge_base / cached), scanContext
- [x] 4.4 — Create `qa_provider.dart`: manage Q&A state, conversation history
- [x] 4.5 — Build Q&A chat screen:
  - Message bubbles (user questions + AI answers)
  - Loading indicator while waiting for Gemma 4 response
  - Source tag on each answer ("Powered by Gemma 4" vs "Offline answer")
  - Suggested questions (e.g., "What causes black pod?", "How to prevent CSSVD?")
- [x] 4.6 — Create `qa_message_bubble.dart` widget
- [x] 4.7 — Implement context-aware prompts: if user just scanned a diseased pod, prepend that context to the question
  - e.g., "The user just scanned a cocoa pod and it was classified as phytophthora with 87% confidence. They are now asking: [user question]"
- [x] 4.8 — Create `prompt_templates.dart`: structured prompt builder
- [x] 4.9 — Handle API errors gracefully (timeout, rate limit, auth failure)
- [ ] 4.10 — Test: ask "What causes black pod?" → get Gemma 4 response
- [ ] 4.11 — Test: scan a diseased pod → tap "Ask about this disease" → contextual Q&A
- [ ] 4.12 — Test: API error → show friendly error message

**Exit criteria**: User can ask farming questions and get intelligent answers from Gemma 4 via cloud API. Questions after a scan include disease context. Errors handled gracefully.

---

### PHASE 5: Offline Knowledge Base + Fallback (Days 39-45)
> When there's no internet, the app still answers questions from a local knowledge base. This is the "offline-first" story judges want.

**Tasks**:
- [x] 5.1 — Create `assets/data/diseases_knowledge.json`: comprehensive knowledge base combining:
  - Gamini's 3 leaf disease entries (anthracnose, cssvd, healthy)
  - cococpod's 5 pod disease entries (carmenta, healthy, moniliasis, phytophthora, witches_broom)
  - Additional entries: farming best practices, seasonal care, COCOBOD resources
  - Each entry: description, symptoms, causes, treatments, prevention, severity, FAQ
- [x] 5.2 — Create `knowledge_service.dart`:
  - Load knowledge base from assets on app startup
  - Keyword search: match user question against disease names, symptoms, treatments
  - Return best matching knowledge entry
  - Cache frequently asked question/answer pairs
- [x] 5.3 — Integrate fallback into `qa_provider.dart`:
  - Try Gemma 4 API first
  - If offline / error → try cached Gemma 4 response → fall back to `knowledge_service.dart`
  - Tag answer source in UI ("Powered by Gemma 4" / "Cached answer" / "Offline answer")
- [x] 5.4 — Cache Gemma 4 responses in Hive for future offline access
  - Key: normalized question text (lowercased, stripped punctuation)
  - Value: Gemma 4 response text
  - Serve cached response if same/similar question asked offline
- [x] 5.5 — Build "Offline Library" screen: browsable list of all diseases + treatments (no AI needed)
  - Replaced Info tab with Library tab in bottom nav
  - Disease cards with expandable symptoms, causes, treatments, prevention, FAQ
  - Farming best practices section
  - COCOBOD resources section
- [ ] 5.6 — Test: airplane mode → ask question → get knowledge base response
- [ ] 5.7 — Test: online → ask question → get Gemma 4 response → go offline → ask same question → get cached response
- [ ] 5.8 — Test: browse Offline Library → view disease info

**Exit criteria**: App provides answers to farming questions even without internet. Gemma 4 responses are cached for future offline use. User can browse disease library anytime.

---

### PHASE 6: UX Polish + Edge Cases (Days 46-52)
> Make the app feel production-quality. Zero crashes, smooth transitions, professional look.

**Tasks**:
- [x] 6.1 — App branding: name, icon, splash screen, color scheme
  - Name: "G4N" or "CocoaGuard" or similar
  - Colors: earthy greens + browns (cocoa farming theme)
- [x] 6.2 — Low-confidence warnings: if classification < 55%, show warning + suggest retaking photo
- [x] 6.3 — Image quality checks: warn if image is too dark, blurry, or wrong subject
- [x] 6.4 — Loading states: model loading spinner on first launch, scan progress indicator
- [x] 6.5 — Error handling audit: review every service for unhandled exceptions
- [x] 6.6 — Permission handling: camera, storage — graceful prompts and fallbacks
- [x] 6.7 — Onboarding screen: brief intro (1-3 slides) explaining what the app does
  - Reference cococpod's `onboarding_screen.dart` for inspiration
- [x] 6.8 — Settings screen: API key input, clear history, about page
- [x] 6.9 — Responsive layout: test on different screen sizes
- [x] 6.10 — Accessibility: text contrast, font sizes, screen reader labels
- [x] 6.11 — Test on at least 2 real devices (mid-range + low-end Android)
- [x] 6.12 — Fix all crashes found during testing

**Exit criteria**: App looks professional, handles edge cases gracefully, works on mid-range Android devices. No crashes during 30-min QA session.

---

### PHASE 7: Performance Optimization (Days 53-56)
> Make sure the app is fast and light enough for the target devices.

**Tasks**:
- [x] 7.1 — Measure app cold start time (target: <3s)
- [x] 7.2 — Measure inference time per model:
  - Leaf classifier: target <500ms
  - YOLO pod detection: target <800ms
  - Pod classifier (per pod): target <500ms
- [x] 7.3 — Measure app size: target <80MB (models are ~50MB total)
- [x] 7.4 — Memory profiling: check for model memory leaks, image buffer leaks
- [x] 7.5 — Lazy-load models: only load leaf model when user picks leaf scan, only load YOLO + pod model when user picks pod scan
- [x] 7.6 — Gemma 4 API timeout tuning: 10s timeout with 1 retry, then fallback
- [x] 7.7 — Image compression: resize camera images before sending to models
- [x] 7.8 — Battery impact check: ensure background services are minimal

**Exit criteria**: App starts in <3s, classifies in <1s, APK is <80MB, no memory leaks.

---

### PHASE 8: Documentation + GitHub Repo (Days 57-60)
> Prepare the public code repository that judges will inspect.

**Tasks**:
- [x] 8.1 — Write `README.md`:
  - Project overview + problem statement
  - Architecture diagram (text or image)
  - Setup instructions (flutter pub get, API key setup)
  - How to build APK
  - Screenshots
  - Model details (what each TFLite model does, accuracy, size)
- [x] 8.2 — Write `ARCHITECTURE.md`:
  - System design diagram
  - Task router explanation
  - CV pipeline details
  - Gemma 4 integration details
  - Offline fallback strategy
  - Why each technical choice was made
- [x] 8.3 — Clean up code: remove dead code, TODOs, debug prints
- [x] 8.4 — Add code comments where logic is non-obvious (not everywhere — just tricky parts)
- [x] 8.5 — Verify `.gitignore` excludes: `.env`, API keys, `build/`, `.dart_tool/`
- [x] 8.6 — Push final code to public GitHub repo
- [x] 8.7 — Build release APK: `flutter build apk --release`
- [ ] 8.8 — Test APK on a clean device (not your dev device)

**Exit criteria**: Public GitHub repo is clean, well-documented, and builds successfully. APK runs on a fresh device.

---

### PHASE 9: Video + Kaggle Writeup (Days 61-70)
> Create the submission materials. The video is the most important part according to the hackathon rules.

**Tasks**:

#### Video (3 min, YouTube)
- [ ] 9.1 — Write video script:
  - **Hook (0:00-0:15)**: "2 million cocoa farmers in Ghana. Most have no internet. When disease hits, they lose everything."
  - **Problem (0:15-0:40)**: Show the reality — remote farm, no connectivity, disease spreading. "By the time they get help, it's too late."
  - **Solution intro (0:40-1:00)**: "G4N — an AI-powered farming assistant that works offline." Show app opening.
  - **Demo: Scan (1:00-1:40)**: Live demo — photograph diseased pod → YOLO detects pods → classifies disease → shows treatment. "All of this happened on-device. No internet needed."
  - **Demo: Ask (1:40-2:20)**: Type question → Gemma 4 answers with farming advice. Go offline → ask same question → knowledge base answers. "Intelligent fallback — always has an answer."
  - **Demo: Emergency (2:20-2:35)**: Type emergency → instant protocol. "When it matters most, speed saves harvests."
  - **Architecture (2:35-2:50)**: Quick diagram showing task router → CV / Gemma 4 / Rules. "Smart routing — right model for the right task."
  - **Closing (2:50-3:00)**: "G4N: AI that works where farmers are. Built with Gemma 4."
- [ ] 9.2 — Record screen captures of app demo
- [ ] 9.3 — Record or source B-roll (cocoa farms, farmers, Ghana landscape)
- [ ] 9.4 — Edit video (keep it tight — no dead time)
- [ ] 9.5 — Upload to YouTube (public or unlisted)

#### Kaggle Writeup (max 1500 words)
- [ ] 9.6 — Write writeup:
  - **Title**: "G4N: Offline-First AI for African Cocoa Farmers, Powered by Gemma 4"
  - **Problem** (~200 words): Cocoa farming challenges in Ghana, lack of diagnostic tools, connectivity gaps
  - **Solution Architecture** (~400 words): Task router, dual CV pipeline (leaf + pod), Gemma 4 cloud Q&A, offline knowledge base
  - **Gemma 4 Integration** (~300 words): Why Gemma 4 for farming Q&A (not detection), prompt engineering, context-aware responses after scans, response caching for offline
  - **Offline-First Design** (~200 words): Why offline matters, which components work without internet, graceful degradation
  - **Technical Challenges** (~150 words): Model optimization for mobile, two-stage detection, balancing accuracy vs speed
  - **Impact** (~150 words): Potential reach, scalability to other crops, future plans
- [ ] 9.7 — Create cover image for Media Gallery
- [ ] 9.8 — Take 4-6 app screenshots for Media Gallery
- [ ] 9.9 — Select writeup track (most likely: "Global Resilience" or "Health & Sciences")

**Exit criteria**: Video uploaded to YouTube, writeup drafted on Kaggle, media gallery populated.

---

### PHASE 10: Final Submission (Days 71-75)
> Submit everything and do final checks.

**Tasks**:
- [ ] 10.1 — Review all submission requirements one more time:
  - [ ] Kaggle Writeup saved + submitted
  - [ ] Video attached to Media Gallery
  - [ ] GitHub repo link in "Project Links"
  - [ ] Live demo (APK file) attached
  - [ ] Cover image uploaded
  - [ ] Track selected
- [ ] 10.2 — Have someone else test the APK on their device
- [ ] 10.3 — Watch your own video — does it tell a compelling story?
- [ ] 10.4 — Read your writeup — does it clearly explain Gemma 4 usage?
- [ ] 10.5 — Final GitHub push: make sure repo is public and README is accurate
- [ ] 10.6 — Click "Submit" on Kaggle

**Exit criteria**: Submission is live on Kaggle.

---

## Critical Path (What Blocks What)

```
Phase 0 (setup)
  └─→ Phase 1 (leaf CV) ─────────────────────┐
  └─→ Phase 2 (pod CV, depends on Phase 1)    │
        └─→ Phase 3 (router + home redesign) ──┤
              └─→ Phase 4 (Gemma 4 Q&A)        │
                    └─→ Phase 5 (offline KB) ───┤
                                                ├─→ Phase 6 (UX polish)
                                                │     └─→ Phase 7 (performance)
                                                │           └─→ Phase 8 (docs + repo)
                                                │                 └─→ Phase 9 (video + writeup)
                                                │                       └─→ Phase 10 (submit)
                                                │
                                                └─→ [MINIMUM VIABLE SUBMISSION]
                                                    If time runs out at Phase 3,
                                                    you can still submit with:
                                                    - Dual CV pipeline (leaf + pod)
                                                    - Task router
                                                    - Emergency protocols
                                                    - No Gemma 4 (add later)
```

## Minimum Viable Submission (If Time Gets Tight)

If you can only finish Phases 0-3, you still have:
- Leaf disease detection (3 classes, offline)
- Pod disease detection with YOLO (5 classes, offline)
- Scan mode selector (leaf vs pod)
- Task router (image / question / emergency)
- Emergency protocols (offline)
- Treatment recommendations for 8 diseases
- Scan history

**Missing**: Gemma 4 Q&A, offline knowledge base, video polish

**This can still place** if the demo video tells a strong story about offline agriculture AI. Add a simple note: "Gemma 4 integration is in progress — architecture designed for cloud Q&A with offline fallback."

---

## Daily Time Budget (Suggested)

Assuming ~3 hours/day of focused work:

| Phase | Days | Hours | Cumulative |
|-------|------|-------|------------|
| Phase 0: Setup | 3 | 9h | 9h |
| Phase 1: Leaf CV | 7 | 21h | 30h |
| Phase 2: Pod CV | 10 | 30h | 60h |
| Phase 3: Router | 7 | 21h | 81h |
| Phase 4: Gemma 4 | 11 | 33h | 114h |
| Phase 5: Offline KB | 7 | 21h | 135h |
| Phase 6: UX Polish | 7 | 21h | 156h |
| Phase 7: Performance | 4 | 12h | 168h |
| Phase 8: Docs | 4 | 12h | 180h |
| Phase 9: Video | 10 | 30h | 210h |
| Phase 10: Submit | 5 | 15h | 225h |
| **Total** | **75 days** | **225h** | |

This fits in 75 days (~10.7 weeks, or ~2.5 months) at 3 hours/day. You have ~60 days (2 months), so at ~3.75 hours/day you're on track. Push harder on weekends and you have buffer.

---

## Risk Register

| Risk | Mitigation |
|------|-----------|
| **YOLO model doesn't work in Flutter TFLite** | cococpod already proves it does — copy their exact setup |
| **Gemma 4 API not yet available** | Use Gemini API with Gemma 4 model ID; if unavailable, use Gemini 1.5 Flash as placeholder and swap later |
| **Models too large for low-end devices** | Lazy-load models; only load what's needed for current scan mode |
| **API key exposure in GitHub** | Use `.env` file + `.gitignore`; document setup in README |
| **Video quality isn't good enough** | Start scripting in Phase 6, not Phase 9; iterate early |
| **Time overrun on CV pipeline** | Gamini + cococpod code is already written; this is a port, not greenfield |
| **Flutter TFLite plugin issues** | Both source projects use `tflite_flutter: ^0.11.0` — proven to work |

---

## Open Questions to Resolve Before Phase 1

1. **App name**: G4N? CocoaGuard? CocosAI? (Needed for branding in Phase 6, but pick early)
2. **Gemma 4 API access**: Do you already have an API key? If not, apply via Google AI Studio now — don't wait until Phase 4.
3. **Test device**: Which Android phone will you test on? (Affects performance targets)
4. **Do you want both leaf AND pod scanning?** (I assumed yes — both models exist. But if you want to simplify, pick one.)
5. **Video production**: Do you have video editing tools? (CapCut, DaVinci Resolve, etc.)

---

**Status**: Ready for Phase 0  
**Next action**: Confirm open questions above, then start Phase 0 tasks.
