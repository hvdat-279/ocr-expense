# 📱 VKU OCR Expense Tracker & Receipt Parser (Flutter & Dart)

<p align="center">
  <b>A smart, offline personal finance management application powered by on-device AI and custom canvas graphics.</b><br>
  Developed for <i>Mini-Project #3 (Cross-Platform Mobile Development - VKU)</i>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter 3.x" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart 3" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2B%20BLoC-blue" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/AI-ML%20Kit%20%26%20Gemini%20Vision-orange" alt="On-Device AI" />
  <img src="https://img.shields.io/badge/Canvas-100%25%20CustomPainter-success" alt="CustomPainter" />
</p>

---

## 🎯 Project Overview & Problem Scenario

Students and organization treasurers frequently handle physical receipts and bills from supermarkets, cafes, and bookstores. Manually typing expense numbers into spreadsheets is tedious and prone to clerical errors.

**VKU OCR Expense Tracker** automates this workflow directly on mobile devices:
1. **Sub-100ms On-Device AI**: Extracts receipt text offline using Google ML Kit with zero cloud cost.
2. **Dual AI Parsing Engine**: Combines Vietnamese currency Regex Heuristics and Google Gemini 1.5/3.5 Vision AI to eliminate invoice ID confusion and extract exact monetary totals.
3. **Low-Level Native Graphics**: Visualizes financial trends directly on the canvas using Flutter's native `CustomPainter` without any third-party charting libraries (such as `fl_chart`).
4. **Locket-Style Photo Memories**: Browses past expenditures and original receipts organized by calendar date.

---

## 🏗️ Clean Architecture & Project Structure

The project strictly follows **Clean Architecture** with unidirectional data flow driven by **BLoC (Business Logic Component)**:

```
lib/
├── core/
│   ├── services/
│   │   ├── ocr_service.dart               # Google ML Kit On-Device Text Recognition
│   │   ├── gemini_ai_service.dart         # Multimodal Gemini Vision AI parser
│   │   └── image_processing_service.dart  # Automatic image compression & thumbnail cache
│   └── utils/
│       └── receipt_parser_engine.dart     # Heuristic Regex & smart categorization
├── data/
│   ├── models/
│   │   └── transaction_model.dart         # SQLite entity serialization & mapping
│   └── repositories/
│       └── local_transaction_repository.dart # Persistent SQLite storage & query engine
├── domain/
│   ├── entities/
│   │   └── transaction_entity.dart        # Core business entity (Income / Expense)
│   └── repositories/
│       └── transaction_repository.dart    # Repository contract interface
├── presentation/
│   ├── bloc/
│   │   ├── expense_bloc.dart              # State management controller
│   │   ├── expense_event.dart             # UI events (Add, Update, Delete, Clear)
│   │   └── expense_state.dart             # Presentation states
│   ├── screens/
│   │   ├── dashboard_screen.dart          # Main dashboard with balanced Income/Expense cards
│   │   ├── camera_scanner_screen.dart     # Custom viewfinder with framing crop guide
│   │   ├── review_receipt_screen.dart     # Verification, editing & income/expense selector
│   │   └── calendar_history_tab.dart      # Interactive calendar & Locket-style photo viewer
│   └── widgets/
│       ├── animated_donut_chart.dart      # CustomPainter 360° animated Donut chart
│       └── animated_bar_chart.dart        # CustomPainter 7-day spending Bar chart
└── main.dart                              # Dependency injection & App entrypoint
```

---

## 🌟 Core Features & Technical Highlights

### 1. Custom Hardware Camera & Framing Crop Overlay
- Custom viewfinder (not default system camera) with rule-of-thirds grid and cyan accent brackets.
- Toggle torch flash, tap-to-focus with haptic feedback, and fallback gallery image picker.
- Automatic image downsampling (800px width, 75% JPEG quality) stored in application documents directory.

### 2. Dual AI & Heuristic Regex Engine
- **Vietnamese Currency Parser**: Accurately handles formats like `150.000 đ`, `150,000 VND`, and `150000`.
- **False-Positive Prevention**: Strict filtering eliminates order numbers, receipt IDs (`HĐ`, `Số phiếu`, `STT`), customer cash, and tax numbers (`MST`).
- **Smart Categorization**: Automatically detects merchant names and maps keywords into categories: `Food`, `Study`, `Travel`, `Gear`, `Entertainment`, `Lương/Thưởng`, and `Khác`.

### 3. Native Canvas Data Visualizations (`CustomPainter`)
- **`AnimatedDonutChart`**: Horizontally centered donut chart with $0^\circ \rightarrow 360^\circ$ sweep animation (`Curves.easeOutCubic`), white segment dividers, and symmetric percentage chips.
- **`AnimatedBarChart`**: Weekly expenditure bar chart with vertical growth spring animation (`Curves.easeOutBack`), custom gradient fills, and background gridlines.
- **100% Zero Third-Party Libraries**: Built exclusively using Flutter's low-level canvas API.

### 4. Interactive Review & Locket Photo History
- Separate **Tổng Chi (Expense)** and **Tổng Thu (Income)** tracking.
- Top-floating non-disruptive notifications that never shift bottom navigation or action buttons.
- **Locket Album Viewer**: Tap any day on the interactive monthly calendar to view photos captured on that day in rounded Locket-style frames with full-screen immersive zoom.

---

## 🚀 Getting Started & Setup Instructions

### Prerequisites
- Flutter SDK `^3.x`
- Android Studio / VS Code with Dart & Flutter extensions
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hvdat-279/ocr-expense.git
   cd ocr-expense
   ```

2. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run automated unit tests:**
   ```bash
   flutter test
   ```

4. **Launch the application in debug mode:**
   ```bash
   flutter run
   ```

5. **Build standalone release APK (Deliverable 1):**
   ```bash
   flutter build apk --release
   ```
   The standalone output APK is generated at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 📦 Mandatory Submission Deliverables

- **Deliverable 1 (Live Demo / APK)**: [Download `app-release.apk`](https://github.com/hvdat-279/ocr-expense/releases)
- **Deliverable 2 (GitHub Repository)**: [https://github.com/hvdat-279/ocr-expense](https://github.com/hvdat-279/ocr-expense)
- **Deliverable 3 (Technical Report PDF)**: Generated from `SHORT_REPORT.md` conforming to the official rubric.

---

## 📄 License
This project was developed for academic purposes under the Vietnam - Korea University of Information and Communication Technology (VKU).
