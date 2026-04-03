# G4N Hackathon Integration Strategy
**Last Updated**: 2026-04-02  
**Timeline**: 6 weeks development + 3 weeks polish + 3 weeks final  
**Deadline**: ~2 months total

---

## Executive Summary

**Goal**: Merge 3 existing projects (Gamini, cococpod, MyGemma3N) into a single Flutter app that wins the Gemma 4 Hackathon.

**Winning Angle**: 
> "Offline AI for African cocoa farmers — instant disease detection with intelligent farming assistant powered by Gemma 4"

**Judge Appeal** (from hackathon info.md):
- Real-world problem (African farmers need offline solutions)
- Smart architecture (task router + model cascade)
- Offline-first capability (Global Resilience theme)
- Gemma 4 as differentiator (not just any LLM)
- Functional demo + compelling video story

---

## Current Projects Analysis

### 1. **Gamini** (Flutter) ✅ BEST BASE
**What**: Cocoa Ahaban — cocoa pod disease classifier  
**Status**: Production-ready  
**Key Features**:
- EfficientNetB3 TFLite model (92.13% accuracy)
- Detects: anthracnose, CSSVD, healthy pods
- Camera + gallery image input
- Treatment recommendations
- Scan history (Hive storage)
- Local inference (100% offline)

**Tech Stack**:
- Flutter 3.x + Dart
- tflite_flutter for inference
- provider for state management
- hive for local storage
- image_picker + image packages

**Keep As-Is**: CV pipeline, UI structure, storage layer

---

### 2. **cococpod** (Flutter) ⚠️ SKELETAL
**What**: Cocoa pod detection app  
**Status**: Incomplete/template project  
**Key Feature**: YOLO pod detection skeleton (not integrated)

**Decision**: Merge cococpod's YOLO detection into Gamini's pipeline, deprecate standalone app

---

### 3. **MyGemma3N** (Kotlin/Android + Flutter support) 🧠 KNOWLEDGE SOURCE
**What**: Comprehensive offline AI tutor with Gemma 3n models  
**Status**: Mature, feature-rich  
**Key Features**:
- AI Tutor with adaptive curriculum (K-12)
- Voice CBT Coach
- Quiz Generator
- Document Summarizer
- Image Classification
- Voice Commands ("Hi Hi" wake word)
- **Crisis Handbook** (emergency protocols)
- Prompt engineering best practices

**Tech Stack**:
- Kotlin + Jetpack Compose (primary)
- MediaPipe + TensorFlow Lite
- Google AI Edge (LiteRT)
- Gemma 3n models

**Extract From**: 
- Disease treatment knowledge base
- Prompt engineering patterns
- Emergency protocol frameworks
- Offline fallback architecture

---

## Hackathon Requirements (Judging Criteria)

### Submission Requirements
1. **Kaggle Writeup** (≤1500 words) — Explain architecture & Gemma 4 usage
2. **Public Video** (≤3 min) — Tell compelling story with demo
3. **Public Code Repository** (GitHub) — Well-documented, full source
4. **Live Demo** (APK or web) — Judges can test directly
5. **Media Gallery** — Screenshots + cover image

### Judge Priorities
| Criterion | What They Want | Your Edge |
|-----------|---|---|
| **Problem** | Real-world, affects many people | African farmers + offline needs |
| **Wow Factor** | Compelling story + surprising outcome | Instant disease detection in low-connectivity areas |
| **Architecture** | Smart design, not just "big model" | Task router + intelligent fallbacks |
| **Gemma 4 Usage** | Clear, specific integration | Q&A for farmer education (not detection) |
| **Offline Capability** | Works without internet | Core disease detection fully offline |
| **Technical Depth** | Explain challenges & tradeoffs | Domain adaptation + edge-device constraints |
| **Demo Quality** | Works reliably, professional presentation | Smooth UX, handles edge cases |

### Winning Themes (from hackathon)
- ✅ **Global Resilience**: Edge-based, offline disaster response
- ✅ **Digital Equity & Inclusivity**: Works in low-connectivity areas
- ✅ **Health & Sciences**: Agricultural disease detection
- ✅ **Future of Education**: Farmer knowledge + intelligent guidance

---

## Merged App Architecture

### High-Level Flow
```
User Input
    ↓
Task Router (Classifier)
    ├─→ IMAGE (camera/gallery)
    │    ↓
    │   CV Pipeline (YOLO + EfficientNetB3)
    │    ↓
    │   Disease Classification (OFFLINE)
    │
    ├─→ QUESTION (text input)
    │    ↓
    │   Knowledge Base (keyword search)
    │    ├─→ ONLINE: Gemma 4 API (farmer education)
    │    └─→ OFFLINE: Cached responses
    │
    └─→ EMERGENCY (keywords detected)
         ↓
        Emergency Protocol (OFFLINE rules)
```

### Component Details

#### 1. **Task Router** (NEW)
- **Purpose**: Classify input type (image | question | emergency)
- **Implementation**: Rule-based classifier
  - Keywords: "what", "why", "how" → question
  - Keywords: "help", "injury", "bleeding" → emergency
  - File input → image
- **Confidence**: Needed for demo narrative ("see app route inputs intelligently")

#### 2. **CV Pipeline** (From Gamini)
- **Models**:
  - YOLO v8n (pod detection, ~6MB)
  - EfficientNetB3 (disease classification, ~22MB)
- **Input**: Camera frame or gallery image (300×300)
- **Output**: Disease class + confidence score
- **Status**: Fully offline, production-ready
- **Keep**: Existing implementation, just export to service layer

#### 3. **Knowledge Base** (From MyGemma3N)
- **Content**: 
  - Disease descriptions (anthracnose, CSSVD, healthy, others)
  - Treatment recommendations (fungicides, removal protocols)
  - Emergency procedures (when to call COCOBOD, quarantine steps)
  - Farming best practices (seasonal care, pest prevention)
- **Format**: JSON cached locally
- **Access**: Keyword search + optional embeddings (later optimization)
- **Offline**: 100% available without internet

#### 4. **Gemma 4 Q&A** (NEW - from MyGemma3N patterns)
- **Endpoint**: Gemma 4 API (cloud, not offline)
- **Role**: Farmer education, treatment explanations, emergency guidance
  - NOT for disease detection (CV handles that better)
  - YES for: "Why does my cocoa get anthracnose?" "What's the best treatment?"
- **Prompt Engineering**: Domain-adapted for cocoa farming
- **Fallback**: If offline, show cached knowledge base response
- **UI**: Chat-style Q&A interface

#### 5. **Storage** (From Gamini)
- **Hive**: Local scan history + Q&A conversation cache
- **Structure**:
  ```
  scans/
    - image_path, timestamp, disease, confidence
  conversations/
    - timestamp, question, answer_source (cached|gemma4), answer_text
  knowledge_cache/
    - timestamp, disease_data_version
  ```

---

## Folder Structure (Merged App)

```
lib/
├── main.dart
├── app.dart                          # MaterialApp setup
├── models/
│   ├── scan_record.dart              # From Gamini
│   ├── conversation.dart             # NEW - Q&A history
│   └── task_type.dart                # NEW - Router enum
├── services/
│   ├── cv_service.dart               # From Gamini (YOLO + EfficientNet)
│   ├── knowledge_service.dart        # From MyGemma3N data
│   ├── gemma4_service.dart           # NEW - Cloud API integration
│   ├── task_router_service.dart      # NEW - Input classifier
│   └── storage_service.dart          # From Gamini (Hive)
├── providers/
│   ├── scan_provider.dart            # From Gamini
│   ├── history_provider.dart         # From Gamini
│   └── qa_provider.dart              # NEW - Q&A state
├── screens/
│   ├── home_screen.dart              # From Gamini (refactored)
│   │   └── Add: Q&A input option
│   ├── disease_results_screen.dart   # From Gamini
│   ├── qa_screen.dart                # NEW - Chat interface
│   ├── history_screen.dart           # From Gamini (expanded)
│   │   └── Include: Scan + Q&A history
│   └── emergency_screen.dart         # NEW - Emergency protocols
├── widgets/
│   ├── confidence_bar.dart           # From Gamini
│   ├── diagnosis_card.dart           # From Gamini
│   ├── scan_card.dart                # From Gamini
│   ├── qa_message_bubble.dart        # NEW
│   └── emergency_alert.dart          # NEW
├── utils/
│   ├── constants.dart                # From Gamini
│   ├── image_utils.dart              # From Gamini
│   ├── treatment_data.dart           # From Gamini
│   ├── knowledge_base.dart           # NEW - From MyGemma3N data
│   ├── prompt_templates.dart         # NEW - From MyGemma3N patterns
│   └── emergency_keywords.dart       # NEW
└── assets/
    ├── models/
    │   ├── cocoa_b3_v2_92.13_float16.tflite
    │   ├── cocoa_b3_v2_labels.json
    │   └── yolo_pod_detection.tflite  # From cococpod
    ├── data/
    │   ├── diseases.json              # Knowledge base
    │   ├── treatments.json            # Treatment recommendations
    │   └── emergency_protocols.json   # Emergency procedures
    └── images/
        └── reference_images/          # From Gamini
```

---

## 13-Week Development Timeline

### **Weeks 1-2: Merge & Setup** ⚙️
**Goal**: Single Flutter app with unified codebase

**Tasks**:
1. Clone Gamini as base project → rename to `g4n_cocoa_ai`
2. Remove cococpod from codebase (keep reference in docs)
3. Create new folder structure above
4. Extract YOLO model from cococpod, integrate into cv_service
5. Test existing Gamini CV pipeline works in new structure
6. Set up GitHub repo (public)

**Deliverable**: 
- Single Flutter app
- All CV pipeline tests passing
- Compiles and runs on test device

---

### **Weeks 3-4: Task Router** 🧭
**Goal**: Intelligent input classification

**Build**:
- `task_router_service.dart`: Classify input (image | question | emergency)
- Emergency keyword detector (help, injury, bleeding, urgent, etc.)
- Question detector (what, why, how, tell, explain, etc.)
- Image handler (camera capture, gallery pick)
- UI: Home screen with 3 clear entry points

**Code Pattern**:
```dart
// services/task_router_service.dart
class TaskRouterService {
  TaskType classifyInput(String text) {
    if (_isEmergency(text)) return TaskType.emergency;
    if (_isQuestion(text)) return TaskType.question;
    return TaskType.unknown;
  }
  
  bool _isEmergency(String text) {
    final emergencyKeywords = ['help', 'injury', 'bleeding', 'urgent'];
    return emergencyKeywords.any(text.toLowerCase().contains);
  }
}

enum TaskType { image, question, emergency, unknown }
```

**Deliverable**:
- App correctly routes 95%+ of test inputs
- Emergency detection works reliably
- Clean UI with camera + text input options

---

### **Weeks 5-6: Gemma 4 Integration** 🤖
**Goal**: Add intelligent farming Q&A

**Build**:
- `gemma4_service.dart`: Cloud API client
- Prompt engineering for cocoa farming context
- Offline fallback to knowledge base
- Q&A chat UI with history

**Prompt Template**:
```
You are an expert agricultural advisor for cocoa farmers in Ghana.
Your role is to:
1. Explain cocoa diseases (causes, symptoms, spread)
2. Recommend treatments based on disease and severity
3. Provide emergency guidance (when to call COCOBOD, quarantine)
4. Share best practices (seasonal care, pest prevention)

Keep answers:
- Brief (2-3 sentences for quick reference)
- Actionable (specific treatment steps)
- Grounded in local context (mention COCOBOD, local practices)
- Safe (always recommend professional confirmation for diagnosis)
```

**Code Pattern**:
```dart
// services/gemma4_service.dart
class Gemma4Service {
  Future<String> askFarmer(String question) async {
    try {
      final response = await _client.post(
        Uri.parse('https://api.gemini.google.com/v1beta/models/gemma-4:generateContent'),
        headers: {'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': _buildPrompt(question)}]}],
        }),
      );
      return _extractText(response);
    } catch (e) {
      // Fallback to knowledge base
      return _knowledgeService.searchResponse(question);
    }
  }
  
  String _buildPrompt(String question) {
    return '''$_systemPrompt
    
User Question: $question

Remember: Keep your answer brief and actionable for a farmer with limited internet.''';
  }
}
```

**Deliverable**:
- Gemma 4 API integration working
- Q&A works online (with real responses)
- Offline fallback returns cached responses
- Chat history saved with Hive

---

### **Weeks 7-8: Knowledge Base & Offline** 📚
**Goal**: App works fully offline for core features

**Build**:
- `knowledge_service.dart`: Local disease database
- Cached treatment recommendations
- Emergency protocols (rules-based)
- Graceful fallback logic

**Knowledge Base Structure** (assets/data/diseases.json):
```json
{
  "diseases": [
    {
      "id": "anthracnose",
      "name": "Anthracnose (Black Pod)",
      "description": "Fungal disease affecting cocoa pods...",
      "symptoms": ["black patches", "pod rot", "premature drop"],
      "severity": "moderate",
      "treatments": [
        {
          "method": "Copper fungicide",
          "steps": ["Apply 3x weekly", "Focus on pod clusters"],
          "cost": "moderate",
          "effectiveness": 0.75
        }
      ],
      "prevention": ["Prune infected branches", "Improve air flow"]
    }
  ]
}
```

**Code Pattern**:
```dart
// services/knowledge_service.dart
class KnowledgeService {
  late List<Disease> _diseases;
  
  Future<void> init() async {
    final json = await rootBundle.loadString('assets/data/diseases.json');
    final data = jsonDecode(json);
    _diseases = (data['diseases'] as List)
        .map((d) => Disease.fromJson(d))
        .toList();
  }
  
  Disease? findDisease(String name) {
    return _diseases.firstWhereOrNull(
      (d) => d.name.toLowerCase().contains(name.toLowerCase())
    );
  }
  
  String searchResponse(String question) {
    // Keyword matching + cached answer lookup
    final disease = _findDiseaseFromQuestion(question);
    if (disease != null) return disease.treatments.first.description;
    return "I'm not sure. Please ask specifically about a disease or treatment.";
  }
}
```

**Deliverable**:
- Disease knowledge base loaded + searchable
- Offline: Can detect disease + show treatment (no internet needed)
- Q&A with internet: Gemma 4 response
- Q&A without internet: Knowledge base response
- Emergency protocols work offline

---

### **Weeks 9-10: UX & Robustness** 🎨
**Goal**: App feels polished & handles edge cases

**Build**:
- Error handling for model loading failures
- Low-confidence warnings (show scores < 70%)
- Image preprocessing improvements
- Retry logic for Gemma 4 API
- Loading indicators + progress feedback
- Permission handling (camera, storage)
- Device compatibility testing

**Checklist**:
- ✅ App handles missing camera gracefully
- ✅ Shows confidence scores for all predictions
- ✅ Warns user if confidence < 70%
- ✅ Retry Gemma 4 API on timeout
- ✅ Offline indicator in UI
- ✅ Image quality warnings (blurry, too small)
- ✅ Handles app backgrounding + resuming
- ✅ Works on Android 6+ (API 24+)

**Deliverable**:
- Zero crashes during QA testing
- Smooth user experience
- Professional error messages

---

### **Weeks 11-12: Optimization & Testing** ⚡
**Goal**: App runs well on mid-range devices

**Build**:
- Model quantization verification (already TFLite)
- Memory profiling (watch for model leak)
- Battery usage profiling
- Network timeout tuning (Gemma 4 API)
- App size check (should be <100MB)

**Deliverable**:
- Runs smoothly on mid-range Android (Samsung A50 equivalent)
- Inference <500ms per image
- Cold start <2s

---

### **Week 13: Documentation & Release** 📦
**Goal**: Submission-ready package

**Build**:
- Generate APK for judges
- GitHub README with setup instructions
- Architecture documentation
- API key setup guide (Gemma 4)
- Bug report template

**Deliverable**:
- Public GitHub repo (all code visible)
- APK for testing
- Clear README with build steps

---

### **Weeks 14-15: Polish & Demo Video** 🎬
**Goal**: Submission materials ready

**Video Production** (3 min):
1. **Hook (0-15s)**: Farmer in Ghana, spotty internet, crop failing
2. **Problem (15-45s)**: Can't diagnose disease, no reliable AI access
3. **Solution Demo (45-150s)**:
   - Open app
   - Take photo of diseased pod
   - App instantly detects disease (offline) ← WOW moment
   - Asks "What do I do?" 
   - App shows treatment (Q&A with Gemma 4 online, or knowledge base offline)
   - Shows treatment steps + when to call COCOBOD
4. **Impact (150-180s)**: This works offline, no data needed, helps millions of farmers

**Kaggle Writeup** (≤1500 words structure):
- **Title**: "Offline AI for African Agriculture: Real-Time Cocoa Disease Detection with Gemma 4"
- **Problem** (200 words): Ghanaian cocoa farmers lack access to instant, offline disease diagnosis
- **Solution Architecture** (400 words): Task router → CV pipeline → Gemma 4 Q&A with graceful fallback
- **Gemma 4 Integration** (300 words): Why Gemma 4 for education (not detection), prompt engineering, offline fallback
- **Why Offline** (200 words): 70% of Ghana lacks reliable internet; detection must work offline
- **Technical Challenges** (200 words): Model quantization, edge-device constraints, API fallback
- **Impact & Future** (200 words): Potential to help millions of African farmers

**Deliverable**:
- YouTube video (public, unlisted or listed)
- Kaggle writeup (drafted)
- GitHub repo cleaned up
- APK ready for judges

---

### **Weeks 16+ (If Feedback Loop)**
- Address judges' comments
- Iterate on video/writeup
- Final submission

---

## File Reuse Matrix

| File/Component | Source | Action | Notes |
|---|---|---|---|
| `main.dart` | Gamini | **Keep** | No changes needed |
| `app.dart` | Gamini | **Adapt** | Add Q&A provider + route |
| `pubspec.yaml` | Gamini | **Update** | Add http, gemini SDK if needed |
| CV pipeline | Gamini | **Extract** | Move to `cv_service.dart` |
| EfficientNetB3 model | Gamini | **Keep** | Use as-is (92.13% accurate) |
| YOLO model | cococpod | **Integrate** | Add pod detection |
| Storage layer | Gamini | **Extend** | Add Q&A + conversation storage |
| UI components | Gamini | **Reuse** | confidence_bar, diagnosis_card, scan_card |
| Disease data | MyGemma3N | **Extract** | Convert to JSON knowledge base |
| Prompt patterns | MyGemma3N | **Adapt** | Use for Gemma 4 prompts |
| Emergency protocols | MyGemma3N | **Extract** | Use for emergency routing |
| Voice commands | MyGemma3N | **Skip** | Out of scope for 1.5mo deadline |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Gemma 4 API changes | Low | Medium | Implement knowledge base fallback (DONE: weeks 7-8) |
| Model loading failures | Medium | High | Test on multiple devices, add error UI |
| Low internet reliability | High | Medium | All core features (disease detection) work offline |
| Time overrun | Medium | High | Ship MVP (CV only) if Gemma 4 integration late, add later |
| Video submission late | Low | High | Record video by week 14, leave 2 weeks for iteration |
| API key exposure | Low | Critical | Use environment variables, .gitignore API keys |
| Model inference slow | Low | Medium | Pre-optimize with TFLite quantization (already done) |

---

## Success Criteria (Definition of Done)

By submission deadline:
- ✅ Single Flutter app merging all 3 projects
- ✅ Disease detection works fully offline (≥90% accuracy)
- ✅ Gemma 4 Q&A works with graceful offline fallback
- ✅ Task router correctly routes inputs
- ✅ App runs on mid-range Android devices
- ✅ Zero crashes during 1-hour QA session
- ✅ Public GitHub repo with clean code + README
- ✅ 3-min YouTube video showing real-world use case
- ✅ Kaggle writeup explaining architecture + Gemma 4 role
- ✅ Working APK for judges to test
- ✅ Compelling problem statement + story

---

## Questions for Confirmation

Before starting implementation, confirm:

1. **Use Gamini as base** — Yes?
2. **Remove cococpod completely** (keep reference only) — Yes?
3. **Gemma 4 via cloud API** (not offline) — Acceptable?
4. **Target device**: Mid-range Android (Samsung A50 level) — Yes?
5. **Scope priority**: CV detection first, Gemma 4 Q&A second — Correct?
6. **Video story**: Farmer → offline detection → instant diagnosis — Matches your vision?

---

## Next Immediate Steps

1. **Confirm decisions above**
2. **Prepare Gemma 4 API access** (get API key from Google)
3. **Extract YOLO model** from cococpod
4. **Start Week 1 tasks**: Set up merged repo structure

---

## Appendix: Judge Scoring Rubric (Inferred)

**Technical Implementation** (40%)
- Architecture clarity (10%)
- Offline capability (10%)
- Gemma 4 integration quality (10%)
- Code quality + documentation (10%)

**Problem & Impact** (30%)
- Real-world relevance (10%)
- Scale of impact (10%)
- Compelling narrative (10%)

**Demo & Presentation** (20%)
- Video quality + storytelling (10%)
- App demo functionality (10%)

**Bonus** (10%)
- Innovation in model adaptation (5%)
- Community/ecosystem impact (5%)

---

**Status**: Ready for implementation approval  
**Prepared by**: Claude Code  
**Version**: 1.0
