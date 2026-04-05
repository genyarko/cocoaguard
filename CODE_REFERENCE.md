# CocoaGuard — Complete Code Reference

**Last Updated**: April 2026  
**Codebase**: 51 Dart files, ~5,500 lines (excluding comments)  
**Platform**: Flutter 3.11+ (iOS 12+, Android 21+)

---

## Quick Navigation

- [Architecture Overview](#architecture-overview)
- [Screens & Navigation](#screens--navigation)
- [State Management (Providers)](#state-management-providers)
- [Services & Business Logic](#services--business-logic)
- [Data Models](#data-models)
- [Utilities & Helpers](#utilities--helpers)
- [Asset Structure](#asset-structure)
- [Key Algorithms](#key-algorithms)
- [Common Tasks](#common-tasks)

---

## Architecture Overview

CocoaGuard is an **offline-first**, **modular Flutter app** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                  Screens (UI)                            │
│  (unified, results, pod_results, qa, history, library)  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Providers (State Management)                │
│  (scan, pod_scan, qa, history)                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│             Services (Business Logic)                    │
│ ┌──────────────────┐  ┌──────────────────┐              │
│ │ CV Pipeline      │  │ Cloud & Offline  │              │
│ ├─ Leaf classifier │  ├─ Gemma4 API      │              │
│ ├─ YOLO detector   │  ├─ Knowledge base  │              │
│ ├─ Pod classifier  │  └─ Storage (Hive)  │              │
│ └─ Quality check   │                      │              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│        Data Models (Scan, Chat, Hive records)           │
└─────────────────────────────────────────────────────────┘
```

---

## Screens & Navigation

### Main Entry Point

**`unified_screen.dart`** — Home screen with:
- Camera preview (top 80%)
- Bottom text input field for Q&A
- Bottom navigation bar (Leaf | Pod | Camera | History | Library)
- Auto-routes to results screens on scan completion
- Shows loading spinner + progress message during inference

### Scan Result Screens

**`results_screen.dart`** (Leaf results)
- Large diagnosis card (name + icon + confidence %)
- Optionally shows "Potentially Infected" warning if CSSVD ≥ 30%
- Low-confidence warning if < 55%
- Image quality issues summary
- Per-class confidence bars
- "Scan Another" + "Save Result" buttons
- "Ask about this disease" button (routes to Q&A with context)
- Treatment recommendations (expandable)

**`pod_results_screen.dart`** (Pod results)
- Annotated image with bounding boxes (one box per detected pod)
- Per-pod diagnosis cards (name, confidence, alternative)
- Pod summary (worst disease, healthiest pod, pod count)
- "Save Result" + "Ask" buttons
- Disease summary + treatment

### Q&A Interface

**`qa_screen.dart`**
- Message bubbles (user question right-aligned, AI answer left-aligned)
- Suggested questions (if empty)
- Typing indicator while waiting for response
- Source badge: "Powered by Gemma 4" | "Cached answer" | "Offline"
- Load previous conversations
- Clear chat button

### Utilities & Settings

**`history_screen.dart`**
- Scrollable list of saved scans
- Thumbnail image + diagnosis + confidence + date + scan type badge
- Swipe-to-delete individual scans
- Tap to replay full results
- Clear all history button

**`library_screen.dart`** (Offline disease guide)
- Expandable disease cards (leaf & pod diseases)
- Per-disease: description, symptoms, causes, treatments, prevention, FAQ
- Farming tips section
- COCOBOD contact info
- No internet required

**`settings_screen.dart`**
- Clear history + chat
- Help & guide
- Privacy policy
- About (version, GitHub link)

---

## State Management (Providers)

All state is managed via `ChangeNotifier` providers (Provider 6.x pattern).

### `ScanProvider` (Leaf Classification)
**Manages**: Leaf scan lifecycle

```dart
// Usage in a widget
final scanProv = context.read<ScanProvider>();
await scanProv.pickFromCamera();  // user picks image
// → runClassification automatically called
// → setState notifyListeners
// → UI reads scanProv.currentResult to display

// Methods
pickFromCamera()                    // open camera
pickFromGallery()                   // open gallery
runClassification(File imageFile)   // run inference (lazy-loads model)
saveCurrentResult()                 // save to Hive + disk
clear()                             // reset state

// State properties
bool isLoading
String? error
File? currentImage
LeafClassificationResult? currentResult
List<String> qualityWarnings
```

### `PodScanProvider` (Pod Detection & Classification)
**Manages**: Pod scan lifecycle + detection results

```dart
// Similar interface to ScanProvider
// + supports imageBytes for efficient reprocessing

// Unique properties
Uint8List? currentImageBytes              // keep for replay
DetectionResult? currentResult            // list of DetectedPod
```

### `QaProvider` (Q&A State)
**Manages**: Conversation history, Gemma 4 caching, offline fallback

```dart
// Usage
final qaProv = context.read<QaProvider>();

// Send a question (with optional scan context)
await qaProv.ask("How do I treat CSSVD?");
// → tries Gemma 4 → caches if successful
// → falls back to knowledge base if offline
// → stores ChatMessage in Hive

// Set context (user just scanned a disease)
qaProv.setScanContext(
  disease: 'CSSVD',
  confidence: 87.5,
  scanType: 'leaf',
);

// State properties
List<ChatMessage> messages
bool isLoading
String? error
ScanContext? scanContext
```

### `HistoryProvider` (Scan History)
**Manages**: All saved scans (Hive persistence)

```dart
// Usage
final histProv = context.read<HistoryProvider>();
await histProv.loadHistory();
histProv.deleteRecord(scanId);
await histProv.clearHistory();

// State
List<ScanRecord> records  // all saved scans
```

### `LanguageProvider` (Multilingual Support)
**Manages**: App language preference, persistence, and knowledge base reloading

```dart
// Usage
final langProv = context.read<LanguageProvider>();
await langProv.setLanguage(AppLanguage.french);
// → reloads knowledge base in French
// → notifies listeners (LibraryScreen rebuilds)
// → persists choice in Hive

// State properties
AppLanguage language           // current language
```

**Persistence:**
- Language preference saved in Hive `app_settings` box under key `'app_language'`
- Restored on app startup in `main.dart`
- Passed to `KnowledgeService.init(language: savedLanguage)` during initialization

---

## Services & Business Logic

### Leaf Classification Pipeline

**`leaf_classifier_service.dart`**

```dart
class LeafClassifierService {
  Future<void> init()                            // lazy load model
  LeafClassificationResult classify(File file)  // run inference
}

// Result includes:
// - diagnosis (String): 'anthracnose' | 'cssvd' | 'healthy'
// - confidence (double): 0.0–1.0
// - scoreMap (Map): all class probabilities
// - isPotentiallyInfected (bool): true if CSSVD ≥ 30%
```

**Processing steps:**
1. `ImageUtils.constrainSize()` — cap at 1280px longest side
2. `ImageUtils.centerCropToSquare()` — largest inscribed square
3. `copyResize()` — to 300×300 pixels
4. `imageToFloat32Tensor()` — to [1, 300, 300, 3] tensor, values 0–255
5. TFLite inference → 3 logits
6. Argmax + CSSVD ≥30% check

### Pod Detection + Classification Pipeline

**`pod_classifier_service.dart`**

```dart
Future<DetectionResult?> detectAndClassify(
  img.Image image,
  {Uint8List? originalBytes}
) // Orchestrates YOLO + EfficientNet
```

**Two-stage process:**

**Stage 1: YOLO Detection**
- Preprocess: letterbox to 640×640, normalize to [0,1]
- Run YOLOv8 TFLite inference
- Post-process: NMS (IoU=0.45, confidence=0.05)
- Output: list of bounding boxes in original coordinates

**Stage 2: Per-Pod Classification**
- For each pod (max 10 to prevent OOM):
  - Crop region with 5% padding
  - Resize crop to 300×300
  - Run EfficientNetB3 inference (5 classes)
  - Blend YOLO class scores (25% weight) + classifier softmax (75% weight)
- Output: diagnosed pod + confidence + alternative diagnosis if ambiguous

**`score_blender.dart`**
```dart
List<double> blend(List<double> classifierProbs, 
                   List<double> yoloScores)
// Weighted geometric mean: 0.75 classifier, 0.25 YOLO
// Special case: if strong disease signal, dampen healthy class
```

### Gemma 4 Cloud API

**`gemma4_service.dart`**

```dart
class Gemma4Service {
  Future<String> generate(String prompt)  // call Gemma 4 API
}
```

**Behavior:**
- Endpoint: `generativelanguage.googleapis.com/v1beta/models/gemma-3-4b-it`
- Timeout: 10 seconds
- Retry: 1× on timeout/network/5xx errors (2s backoff)
- No retry: 401/403 (auth) or 429 (rate limit)
- Throws `Gemma4Exception` on failure (caller handles fallback)

**Response caching:**
- On success: store in Hive `response_cache` box
- Key: normalized question (lowercased, punctuation stripped)
- Reuse cache for identical/similar questions offline

### Offline Knowledge Base & Multilingual Support

**`knowledge_service.dart`**

```dart
enum AppLanguage { english, french, spanish, twi }

class KnowledgeService {
  Future<void> init({AppLanguage language = AppLanguage.english})  // load JSON
  String search(String question)      // keyword-based Q&A
  Future<void> setLanguage(AppLanguage lang)  // switch language
  String sectionTitle(String key)     // translate UI labels
}
```

**Supported Languages:**
- 🇺🇸 **English** — default
- 🇫🇷 **Français** (French)
- 🇪🇸 **Español** (Spanish)
- 🇬🇭 **Twi** (Asante Twi)

**Asset files:**
- `diseases_knowledge.json` — English
- `diseases_knowledge_fr.json` — French
- `diseases_knowledge_es.json` — Spanish
- `diseases_knowledge_tw.json` — Twi

**Search algorithm (language-aware):**
1. Tokenize question (lowercase, no punctuation)
2. For each disease in the current language's JSON:
   - Score disease name/id match (+5)
   - Score token overlap in symptoms/causes/treatments (+1 per match)
   - Score FAQ match (if ≥2 tokens overlap: +2)
3. Return best match (score ≥2) with multilingual formatting
4. Format answer with translated section headers (Symptoms, Causes, Treatment, Prevention)
5. Multilingual keyword matching: detect user intent (treatment/prevention/cause/symptom) in any supported language

**UI Label Translation:**
All static labels (section headers, button text, etc.) are stored in `_allLabels` map keyed by `AppLanguage`. Use `sectionTitle(key)` to fetch translated labels for the Library screen.

### Image Processing

**`image_utils.dart`**

```dart
static img.Image preprocessFile(File file)
// Center-crop → resize 300×300 → return img.Image

static img.Image constrainSize(img.Image image)
// If longest side > 1280px: downscale to 1280px (maintaining aspect)
// Else: return as-is

static Float32List imageToFloat32Tensor(img.Image image)
// Convert 300×300 image → [1, 300, 300, 3] tensor
// Pixel values kept as 0–255 (not normalized)
```

**`image_quality_checker.dart`**

```dart
static Future<ImageQualityResult> check(File file)
// Checks:
// - Brightness (40–235 acceptable, else warns "too dark" or "overexposed")
// - Sharpness (Laplacian variance ≥50, else "blurry")
// - Dimensions (≥224×224, else "too small")
// Runs on 256px downsampled copy for speed
// Returns warnings list
```

### Storage

**`storage_service.dart`**

```dart
class StorageService {
  static Future<void> init()  // init Hive + open boxes
  
  // Scan records
  Future<void> saveRecord(ScanRecord record)
  List<ScanRecord> getAllRecords()
  Future<void> deleteRecord(String id)
  
  // Q&A chat
  Box<ChatMessage> chatBox        // Hive box accessor
  
  // Response cache
  Box<String> responseCacheBox    // Hive box accessor (String→String)
}
```

**Four Hive boxes:**
1. `scan_records` — `ScanRecord` (leaf & pod scans)
2. `chat_messages` — `ChatMessage` (Q&A history)
3. `response_cache` — String→String (question → Gemma4 answer)
4. `app_settings` — String→dynamic (app preferences, e.g., language choice)

---

## Data Models

### `ScanRecord` (Hive, typeId=0)
Serializable record of a saved scan.

```dart
class ScanRecord {
  final String id;                  // UUID
  final String imagePath;           // path to saved image file
  final String diagnosis;           // class name (e.g., 'cssvd')
  final double confidence;          // 0.0–1.0
  final List<double> allScores;     // per-class scores
  final DateTime scannedAt;
  final String scanType;            // 'leaf' or 'pod'
}
```

### `ChatMessage` (Hive, typeId=1)
Serializable Q&A message.

```dart
class ChatMessage {
  final String id;                  // UUID
  final DateTime timestamp;
  final String question;            // user input
  final String answer;              // AI or offline response
  final String source;              // 'gemma4' | 'cached' | 'knowledge_base'
  final ScanContext? scanContext;   // optional: disease context
}
```

### `LeafClassificationResult`
Leaf scan output.

```dart
class LeafClassificationResult {
  final String diagnosis;           // 'anthracnose' | 'cssvd' | 'healthy'
  final double confidence;          // 0.0–1.0
  final List<double> allScores;     // 3 class scores
  final Map<String, double> scoreMap; // class name → score
  final bool isPotentiallyInfected; // true if CSSVD ≥30%
}
```

### `DetectedPod`
One detected pod result.

```dart
class DetectedPod {
  final BoundingBox box;            // [left, top, right, bottom]
  final DiagnosisResult diagnosis;  // class + confidence + alternative
  final Uint8List cropBytes;        // JPEG crop (80% quality)
}
```

### `DiagnosisResult`
Classification output with alternatives.

```dart
class DiagnosisResult {
  final String className;           // e.g., 'phytophthora'
  final String displayName;         // e.g., 'Phytophthora (Black Pod Rot)'
  final double confidence;          // 0.0–1.0
  final bool isUncertain;           // true if < 50% confidence
  final List<double> probabilities; // all class scores
  final DateTime timestamp;
  final AlternativeDiagnosis? alternative; // runner-up if ambiguous
}
```

---

## Utilities & Helpers

### `constants.dart`
**Model paths:**
```dart
static const String leafModelPath = 'assets/models/leaf_classifier.tflite';
static const String yoloModelPath = 'assets/models/yolo_pod_detect.tflite';
static const String podModelPath = 'assets/models/pod_classifier.tflite';
```

**Colors:**
```dart
static Color colorForDiagnosis(String diagnosis)
// Maps disease name → color for UI (diagnosis cards, bars)
```

### `app_colors.dart`
**Brand colors:**
- Chartreuse: `#C6F91F` (primary, success)
- Onyx: `#141115` (dark background)
- Toffee Brown: `#8D6346` (secondary)
- Lemon Lime: `#DDF45B` (warning)

**Disease colors:**
- Healthy: chartreuse
- Anthracnose: orange
- CSSVD: dark red
- Phytophthora: very dark gray
- Carmenta: crimson
- Moniliasis: saddle brown
- Witches' Broom: dark brown

### `treatment_data.dart`
Offline lookup tables for disease treatments.

```dart
final leafTreatments = {
  'cssvd': {
    'name': 'CSSVD',
    'severity': 'severe',
    'recommendations': [
      'Remove infected trees and surrounding contact trees',
      'Replant with CSSVD-tolerant varieties',
      'Contact COCOBOD for quarantine guidelines',
    ],
  },
  // ... more diseases
};

final podTreatments = { ... };
```

### `prompt_templates.dart`
Gemma 4 prompt engineering.

```dart
static const String systemPrompt =
  "You are an expert agricultural advisor for Ghanaian cocoa farmers...";

static String question(String q) => systemPrompt + q;

static String questionAfterScan({
  required String disease,
  required double confidence,
  required String scanType,
  required String userQuestion,
}) => systemPrompt + contextInfo + userQuestion;

static const List<String> suggestedQuestions = [
  "What causes black pod?",
  "How do I prevent CSSVD?",
  // ...
];
```

### `interpreter_options_builder.dart`
TFLite delegate configuration (NNAPI → GPU → CPU).

```dart
static InterpreterOptions build({String label = ''}) {
  // Try NNAPI (Android hardware accelerator)
  // → Fall back to GPU delegate
  // → Fall back to CPU (4 threads)
  // Never throws; always returns a valid InterpreterOptions
}
```

---

## Asset Structure

```
assets/
├── models/
│   ├── leaf_classifier.tflite         (22 MB, EfficientNetB3 float16)
│   ├── pod_classifier.tflite          (22 MB, EfficientNetB3 float16)
│   ├── yolo_pod_detect.tflite         (22 MB, YOLOv8)
│   ├── leaf_labels.json               ({"class_names": ["anthracnose", "cssvd", "healthy"]})
│   └── pod_labels.json                ({"class_names": [...], "display_names": {...}})
├── data/
│   ├── diseases_knowledge.json        (Offline Q&A database — English)
│   ├── diseases_knowledge_fr.json     (French translation)
│   ├── diseases_knowledge_es.json     (Spanish translation)
│   ├── diseases_knowledge_tw.json     (Twi/Asante Twi translation)
│   ├── emergency_protocols.json       (Emergency response guides)
│   ├── leaf_treatments.json           (Treatment lookup)
│   └── pod_treatments.json
└── images/
    ├── pod_icon.png
    └── cocoaguard_logo.png
```

---

## Key Algorithms

### YOLO Letterbox Resize
```
Input: image of any size, target 640×640
Process:
  1. Compute scale: min(640/width, 640/height)
  2. Resize image to (width*scale, height*scale)
  3. Place centered on 640×640 gray canvas
  4. Normalize all pixel values to [0, 1]
Output: [1, 640, 640, 3] tensor + letterbox metadata for inverse transform
```

### Non-Maximum Suppression (NMS)
```
Input: YOLO detections (boxes, confidences)
Process:
  1. Sort by confidence descending
  2. For each box, compute IoU (intersection-over-union) with kept boxes
  3. If IoU > 0.45, discard; else keep
Output: filtered boxes (fewer duplicates)
```

### Confidence Bar Rendering
```
Input: disease class, score (0–1)
Process:
  1. Look up disease color (AppConstants.colorForDiagnosis)
  2. Fill bar width = score * 100%
  3. Overlay percentage text
  4. Color coding: red if dangerous, yellow if warning, green if healthy
```

### CSSVD Confidence Override
```
Input: leaf classifier output (3 scores)
Process:
  1. Find CSSVD score
  2. If CSSVD score ≥ 0.30 AND not top-1 prediction:
     → Use CSSVD as diagnosis (confidence = CSSVD score)
     → Set isPotentiallyInfected = true
     → Show warning in UI
  Rationale: CSSVD is highest economic risk; early warning preferred to false negative
```

### Score Blending (YOLO + Classifier)
```
Input: classifier softmax probabilities, YOLO class scores
Process:
  1. Compute weighted geometric mean:
     blended[i] = (classifier[i] ^ 0.75) * (yolo[i] ^ 0.25)
  2. If classifier disagrees with YOLO on disease:
     → Boost classifier weight to 0.85
  3. Dampen healthy class if any disease has >0.10 confidence
  Rationale: Balance both signals; prefer classifier for disease ID but trust YOLO for false positives
```

---

## Common Tasks

### Adding a New Disease Class
1. Export new TFLite model (trained on new crop disease)
2. Update labels JSON: add class name to `class_names` array
3. Update `constants.dart`: add disease color to map
4. Update `treatment_data.dart`: add severity + recommendations
5. Update `diseases_knowledge.json`: add disease entry with symptoms/causes/FAQ
6. Update help text and library screen (if new disease category)

### Changing Model Paths
1. Edit `lib/utils/constants.dart`
2. Update assets/ directory
3. Update `pubspec.yaml` asset list
4. Run `flutter pub get`

### Adding a New Language
1. **Add to enum**: `AppLanguage` in `knowledge_service.dart`
   ```dart
   enum AppLanguage { english, french, spanish, twi, portuguese }  // example
   ```

2. **Add code mapping**: in `AppLanguageExt` (required for API/storage)
   ```dart
   case AppLanguage.portuguese:
     return 'pt';
   ```

3. **Add display name**: in `AppLanguageExt.displayName` (for UI FilterChips)
   ```dart
   case AppLanguage.portuguese:
     return 'Português';
   ```

4. **Create knowledge base JSON**: `assets/data/diseases_knowledge_<code>.json`
   - Structure: same as English version (diseases, general_farming, cocobod_resources)
   - Translate all disease names, descriptions, symptoms, causes, treatments, prevention, FAQ

5. **Add UI labels**: add language entry to `_allLabels` static map
   - Keys: diseaseGuide, farmingTips, cocobodResources, offlineNote, severity, causes, symptoms, prevention, treatment, faq, cocobodOffers, contactWhen, connectPrompt, noAnswer, diseases, tips, ghanaCocoaBoard, whenToContact, servicesAvailable

6. **Add filename mapping**: update `_getFilename()` switch
   ```dart
   case AppLanguage.portuguese:
     return 'diseases_knowledge_pt.json';
   ```

7. **Add search keywords**: add language keywords to `_formatDiseaseAnswer()` multilingual lists (askTreatment, askPrevention, askCause, askSymptom)

8. **Add COCOBOD keywords** (optional): extend `cocobodKeywords` list if language has unique terms

### Adding Offline Data
1. Create/edit JSON in `assets/data/` (English version)
2. If multilingual: create translations for each `AppLanguage` (FR, ES, Twi)
3. Add entries to `_allLabels` map in `KnowledgeService` if new UI labels needed
4. Update `_getFilename()` if new languages added
5. Update multilingual keyword lists in `_formatDiseaseAnswer()` for new languages
6. Update `KnowledgeService` if new search-able content
3. Load in `TreatmentSection` if new treatment category
4. Update Library screen if new browseable content

### Caching a Gemma 4 Response
- Automatic: every successful API call cached in Hive `response_cache`
- Key: normalized question (lowercase, stripped punctuation)
- Reuse: if same/similar question asked offline, return cached answer with source='cached'

### Handling Model Load Failure
```dart
// In ScanProvider.runClassification():
if (!_classifier.isReady) {
  try {
    await _classifier.init();
  } catch (e) {
    _error = 'Failed to load leaf AI model: $e';
    notifyListeners();
    return;
  }
}
```

### Testing a New Delegate
1. Update `InterpreterOptionsBuilder.build()`
2. Run on device with `flutter run`
3. Watch logs for `[DELEGATE/...]` message indicating which was selected
4. Compare `[PERF]` timing before & after

---

## Common Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| Model load fails | Interpreter instantiated twice concurrently | Use `_isLoading` flag to guard init() |
| OOM on many pods | Encoding all crops as PNG in memory | Switch to JPEG (80% quality) + cap at 10 pods |
| Low inference speed | CPU-only inference | Enable NNAPI/GPU via InterpreterOptionsBuilder |
| Q&A returns stale answer | Cache key doesn't match question | Normalize both when caching and retrieving |
| Blurry/dark photo accepted | Quality checker thresholds too lenient | Lower sharpness threshold or brightness range |
| CSSVD false negatives | Model trained on high-quality images only | Use CSSVD ≥30% override + show warning |

---

## Further Reading

- **Architecture**: See [`ARCHITECTURE.md`](ARCHITECTURE.md) for system design and CV pipeline details
- **Setup**: See [`README.md`](README.md) for build instructions and quick start
- **API Integration**: See `gemma4_service.dart` for timeout/retry config
- **Performance**: See `interpreter_options_builder.dart` for hardware acceleration

---

**Last Updated**: April 2026  
**Maintained by**: George Nyarko  
**Questions?** See Help screen in-app or [GitHub Issues](https://github.com/genyarko/cocoaguard/issues)
