# VKU OCR Expense Tracker & Receipt Parser (Flutter & Dart)

A modern, offline, on-device AI-powered personal expense tracker built with **Flutter 3.x**, **Google ML Kit Text Recognition**, **Clean Architecture with BLoC**, **Local Database**, and **zero-dependency CustomPainter animations**.

---

## 🌟 Key Features

1. **Hardware Camera & Framing Overlay (Module 1)**:
   - Custom camera screen with flash toggle, tap-to-focus, and framing crop guide overlay.
   - Gallery picker option and quick simulation mode for effortless testing on emulators and desktops.

2. **Core OCR & Heuristic Regex Engine (Module 2)**:
   - **On-Device Text Extraction**: Integrated with `google_mlkit_text_recognition` for sub-100ms offline recognition without cloud latency or API cost.
   - **Vietnamese Currency Parser**: Handles `150.000 đ`, `150,000 VND`, `150.000,00` and anchor detection (`Tổng cộng`, `Thanh toán`, `Total`).
   - **Date Parser**: Extracts `DD/MM/YYYY`, `DD-MM-YYYY`, and ISO formats.
   - **Merchant & Smart Category Classification**: Auto-extracts store names and maps keywords into categories (`Food`, `Study`, `Travel`, `Gear`, `Entertainment`).

3. **Clean Architecture & Local Storage (Module 3)**:
   - Domain layer (`TransactionEntity`, `TransactionRepository`), Data layer (`TransactionModel`, `LocalTransactionRepository`), and Presentation layer (`ExpenseBloc`, `ExpenseState`).
   - SQLite persistence with graceful in-memory fallback for desktop testing.
   - Automatic thumbnail generation (`image` package) cached in application directories.

4. **Zero-Dependency Animated Visualizations with CustomPainter (Module 4)**:
   - **`AnimatedDonutChart`**: Fully custom canvas-rendered Donut chart with 0° to 360° sweeping curve animation, hollow center total display, and category legend.
   - **`AnimatedBarChart`**: Weekly expenditure bar chart with vertical growth spring animation, background gridlines, X-axis labels, and value tags.
   - **100% CustomPainter** - No external charting libraries (`fl_chart`, etc.).

---

## 🏗️ Project Architecture

```
lib/
├── core/
│   ├── services/
│   │   ├── ocr_service.dart               # Google ML Kit integration
│   │   └── image_processing_service.dart  # Thumbnail downsampling & caching
│   └── utils/
│       └── receipt_parser_engine.dart     # Heuristic Regex & Categorization
├── data/
│   ├── models/
│   │   └── transaction_model.dart         # DB mapping model
│   └── repositories/
│       └── local_transaction_repository.dart # SQLite database repository
├── domain/
│   ├── entities/
│   │   └── transaction_entity.dart        # Domain entity & category enum
│   └── repositories/
│       └── transaction_repository.dart    # Abstract repository interface
├── presentation/
│   ├── bloc/
│   │   ├── expense_bloc.dart              # State management
│   │   ├── expense_event.dart
│   │   └── expense_state.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart          # Overview dashboard & charts
│   │   ├── camera_scanner_screen.dart     # Custom camera viewfinder
│   │   └── review_receipt_screen.dart     # Verification & manual edit screen
│   └── widgets/
│       ├── animated_donut_chart.dart      # CustomPainter Donut Chart
│       └── animated_bar_chart.dart        # CustomPainter Bar Chart
└── main.dart                              # DI & Application entry point
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.x`
- Android Studio / VS Code with Dart & Flutter extensions

### Setup & Run

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone <REPO_URL>
   cd vku_ocr_expense
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the automated tests:
   ```bash
   flutter test
   ```

4. Build or launch on a connected device/emulator:
   ```bash
   flutter run
   ```

5. Build Release APK:
   ```bash
   flutter build apk --release
   ```
   The APK output will be located at `build/app/outputs/flutter-apk/app-release.apk`.
