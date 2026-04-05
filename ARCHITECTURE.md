# CocoaGuard — Architecture

## System Overview

CocoaGuard is an offline-first Flutter app that routes user input to the right AI pipeline:
- **Photos** → on-device TFLite CV models (leaf classifier or YOLO + pod classifier)
- **Text questions** → Gemma 4 cloud API → cached answers → local knowledge base (in order)
- **Emergency keywords** → instant offline emergency protocols

```
┌─────────────────────────────────────────────────────┐
│                    User Input                        │
└────────────┬──────────────┬───────────────┬─────────┘
             │              │               │
           Photo         Question        Emergency
             │              │               │
             ▼              ▼               ▼
    ┌────────────┐  ┌───────────────┐  ┌──────────────┐
    │ Scan Mode  │  │  Gemma 4 API  │  │  Emergency   │
    │ Selector   │  │  (online)     │  │  Protocols   │
    └──────┬─────┘  └───────┬───────┘  │  (offline)   │
           │         fallback│          └──────────────┘
      ┌────┴────┐           ▼
      │         │   ┌───────────────┐
    Leaf       Pod  │ Response Cache│
      │         │   │  (Hive)       │
      ▼         ▼   └───────┬───────┘
 ┌────────┐ ┌──────┐   fallback│
 │EfficNet│ │YOLO  │          ▼
 │Leaf    │ │Detect│  ┌───────────────┐
 │3 class │ └──┬───┘  │ Knowledge Base│
 └────────┘    │      │  (offline)    │
               ▼      └───────────────┘
          ┌──────────┐
          │EfficNet  │
          │Pod       │
          │5 class   │
          └──────────┘
```

---

## Component Map

```
lib/
├── main.dart                    # App entry: storage init, service wiring
├── app.dart                     # Provider tree, MaterialApp, shell navigation
│
├── screens/
│   ├── unified_screen.dart      # Home: camera preview + bottom input bar
│   ├── results_screen.dart      # Leaf scan results + treatment + Q&A button
│   ├── pod_results_screen.dart  # Pod scan results + bounding boxes
│   ├── qa_screen.dart           # Gemma 4 chat with offline fallback
│   ├── history_screen.dart      # Saved scan history
│   ├── library_screen.dart      # Offline disease browser
│   ├── emergency_screen.dart    # Offline emergency protocols
│   └── settings_screen.dart     # API key, clear history, about
│
├── providers/
│   ├── scan_provider.dart       # Leaf scan state + lazy model load
│   ├── pod_scan_provider.dart   # Pod scan state + image compression
│   ├── qa_provider.dart         # Q&A state: Gemma4 → cache → knowledge
│   └── history_provider.dart    # Scan history CRUD
│
├── services/
│   ├── leaf_classifier_service.dart   # EfficientNetB3 leaf inference
│   ├── pod_classifier_service.dart    # EfficientNetB3 pod inference + YOLO orchestration
│   ├── yolo_detector.dart             # YOLOv8 pod detection
│   ├── yolo_preprocessor.dart         # Letterbox resize to 640×640
│   ├── yolo_postprocessor.dart        # NMS + bounding box decoding
│   ├── score_blender.dart             # Blend YOLO confidence + classifier scores
│   ├── gemma4_service.dart            # HTTP client for Gemma 4 API
│   ├── knowledge_service.dart         # Keyword search over local JSON
│   └── storage_service.dart           # Hive init + box accessors
│
├── models/
│   ├── scan_record.dart         # Hive model for scan history
│   ├── bounding_box.dart        # YOLO detection result
│   ├── detected_pod.dart        # Pod with crop + diagnosis
│   └── diagnosis_result.dart    # Classification output + differential
│
└── utils/
    ├── image_utils.dart         # Preprocess: constrain size, center-crop, tensor
    ├── image_quality_checker.dart  # Blur + brightness checks
    ├── image_cropper.dart       # Crop detected pod regions
    ├── constants.dart           # Model paths, thresholds, colors
    └── treatment_data.dart      # Dart-side treatment lookup tables
```

---

## CV Pipeline

### Leaf Classification (single-stage)

```
Camera/Gallery image
        │
        ▼
constrainSize() — cap at 1280px longest side
        │
        ▼
centerCropToSquare() → copyResize(300×300)
        │
        ▼
imageToFloat32Tensor() — pixel values 0–255, shape [1,300,300,3]
        │
        ▼
EfficientNetB3 TFLite (leaf_classifier.tflite)
        │
        ▼
3 class scores → argmax → diagnosis
        │
        ├─ CSSVD score ≥ 30%? → override to "potentially infected"
        └─ confidence < 55%?  → show low-confidence warning
```

**Why EfficientNetB3 float16?**  22 MB vs ~85 MB for full float32. 92.13% accuracy on the Gamini dataset. Runs in ~200–400 ms on mid-range Android.

### Pod Detection + Classification (two-stage)

```
Camera/Gallery image
        │
        ▼
constrainSize() — cap at 1280px
        │
        ▼
YoloPreprocessor: letterbox resize to 640×640, normalize [0,1]
        │
        ▼
YOLOv8 TFLite (yolo_pod_detect.tflite) — detects pod bounding boxes
        │
        ▼
YoloPostprocessor: NMS, threshold=0.05, decode to original coords
        │
        ▼ (per detected pod, max 10)
ImageCropper: extract pod region with 5% padding
        │
        ▼
EfficientNetB3 pod classifier (pod_classifier.tflite)
        │
        ▼
ScoreBlender: weighted average of YOLO class scores + classifier scores
        │
        ▼
5 class scores → top-1 diagnosis + optional differential diagnosis
```

**Why YOLO first?**  Farmers photograph entire trees with multiple pods. Without localization, a single-stage classifier would average disease signals from the whole image. YOLO gives us per-pod diagnosis.

**Why threshold 0.05?** The default 0.20 missed many pods in natural farm lighting. The score blender downstream compensates by weighting the EfficientNet classifier more heavily than the low-confidence YOLO detections.

**Why cap at 10 pods?**  Prevents OOM crashes on dense pod images. Pods are ranked by YOLO confidence so the most clearly visible ones are retained.

---

## Gemma 4 Integration + Translation Bridge

```
User question (any language)
      │
      ▼
QaProvider.ask()
      │
      ├─ [If Twi & online] TranslationService.translate(Twi → English)
      │   - Uses Gemini 2.5 Flash API (same key as Gemma 4)
      │   - Timeout: 5s, 1 retry on failure
      │   - If translation fails → send original Twi text as fallback
      │
      ├─ Build prompt (PromptTemplates):
      │   - System: "You are an expert agricultural advisor for Ghanaian cocoa farmers..."
      │   - Context: last scan result if available (disease, confidence, scan type)
      │   - User question (translated to English if needed)
      │
      ├─ [Online] Gemma4Service.generate()
      │   - POST generativelanguage.googleapis.com/v1beta/models/gemma-3-4b-it:generateContent
      │   - Timeout: 10s
      │   - Retry: 1× on timeout/network/5xx (2s delay)
      │   - No retry on 401/403/429
      │   → Cache response in Hive (key = language + normalized question)
      │
      ├─ [If Twi & response] TranslationService.translate(English → Twi)
      │   - Translate Gemma 4 response back to Twi
      │   - If translation fails → use English response as fallback
      │
      ├─ [Offline / error] Check Hive response cache
      │   → Return cached answer (already in correct language) tagged "Cached answer"
      │
      └─ [No cache] KnowledgeService.search()
          - Keyword match against diseases_knowledge_<lang>.json
          - Scores: disease id/name match (+5), token overlap (+1), FAQ match (+2)
          - Multilingual intent detection (treatment/prevention/cause/symptom in any language)
          → Return best match (in user's language) tagged "Offline answer"
```

**Translation Bridge (Twi only)**:
- Gemma 4 doesn't natively understand Twi, so questions are translated to English before sending
- Responses are translated back to Twi before displaying to the user
- Cache keys are language-tagged (`tw:what_is_anthracnose`) to prevent serving stale English answers when switching back to Twi
- If translation fails at any step, falls back gracefully (sends original or returns English)

**Multilingual Scan Results**:
- Disease display names, severity labels, treatment recommendations all available in 4 languages
- UI text on results screens (buttons, warnings, section headers) reads from language-aware labels in `KnowledgeService._allLabels`
- Treatment lookup uses `getLeafTreatment()` / `getPodTreatment()` helpers that return translations

**Why Gemma 4 for Q&A only (not disease detection)?**  Gemma 4 is a language model — it cannot process images natively. The TFLite models are purpose-trained for cocoa disease visual classification. Using Gemma 4 for detection would require image captioning + text inference, adding latency and reducing accuracy. The clean split: TFLite sees the image, Gemma 4 answers text questions about the result.

**Why cache responses in Hive?**  Farmers in rural Ghana frequently ask the same questions. After the first online answer, the app serves it instantly offline. The cache key includes the language code to prevent serving stale answers in the wrong language when users switch.

---

## Offline Fallback Strategy

```
Feature                  Online      Offline (fresh)    Offline (returning user)
─────────────────────────────────────────────────────────────────────────────────
Leaf/pod scanning        ✅ full      ✅ full             ✅ full
Image quality check      ✅ full      ✅ full             ✅ full
Scan history             ✅ full      ✅ full             ✅ full
Emergency protocols      ✅ instant   ✅ instant          ✅ instant
Disease library          ✅ full      ✅ full             ✅ full
Q&A                      Gemma 4     knowledge base      cached + knowledge base
Treatment recommendations ✅ full     ✅ full             ✅ full
```

No feature is gated on connectivity. The connectivity indicator in the home screen is informational only — it tells the user whether Gemma 4 Q&A will use live AI or cached/offline answers.

---

## State Management

Provider is used throughout. Each domain has one `ChangeNotifier`:

| Provider | Scope | Key state |
|----------|-------|-----------|
| `ScanProvider` | Leaf scan lifecycle | `isLoading`, `currentResult`, `error` |
| `PodScanProvider` | Pod scan lifecycle | `isLoading`, `currentResult`, `currentImageBytes` |
| `QaProvider` | Q&A conversation | `messages`, `isLoading`, `scanContext` |
| `HistoryProvider` | Scan history list | `records`, `isLoading` |

The `PodClassifierService` also extends `ChangeNotifier` to expose model loading state to the UI (shows "Loading models..." on first pod scan).

---

## Data Storage (Hive)

| Box | Key type | Value type | Contents |
|-----|----------|------------|----------|
| `scan_records` | String (UUID) | `ScanRecord` | Saved leaf + pod scan history |
| `chat_messages` | int (index) | `ChatMessage` | Conversation history |
| `response_cache` | String (normalized question) | String | Cached Gemma 4 responses |

Hive was chosen over SQLite because the data model is document-like (no joins needed), and Hive requires no native code — simpler CI/CD, works on all Flutter platforms.

---

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| ML framework | TensorFlow Lite | Both source models (Gamini, cococpod) use TFLite. No conversion overhead. |
| Model format | float16 | Halves model size (22 MB vs ~44 MB) with negligible accuracy loss at inference |
| State management | Provider | Simple, well-understood, zero boilerplate for this app size |
| Cloud AI | Gemma 4 API | Hackathon requirement; also best available model for agricultural domain Q&A |
| Local storage | Hive | Pure Dart, no native dependencies, fast key-value access |
| Image size cap | 1280px | Camera photos can be 4000+ px. YOLO only needs 640px input; capping at 1280 saves 4–9× decode time with zero accuracy loss |
| Pod cap | 10 | Prevents OOM on dense images; sorted by confidence to keep best detections |
| CSSVD threshold | 30% | CSSVD is the most economically damaging cocoa disease. A false negative is worse than a false positive — early warning is preferable |
