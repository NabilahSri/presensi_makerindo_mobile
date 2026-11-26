# Presensi Makerindo — Mobile Client (Flutter)

Aplikasi mobile **Presensi Makerindo** (Presensi GPS & Foto, Daily Report, Perizinan, dan Sanksi) pada branch `mobile` dari repository terpadu `NabilahSri/presensi_makerindo_mobile`.

> **Catatan Monorepo:** Kode Web Portal & Backend REST API (Laravel 13) berada pada branch **`main`** (`D:\presensi_makerindo\main`).

---

## Struktur Folder

```text
.
├── .github/
│   ├── workflows/
│   │   └── ci-mobile.yml        # Flutter analyze & unit test CI
│   └── pull_request_template.md
├── android/                     # Konfigurasi native Android
├── ios/                         # Konfigurasi native iOS
├── lib/
│   ├── config/                  # Versi aplikasi (app_version.dart)
│   ├── models/                  # Model data JSON API
│   ├── screens/                 # Halaman UI (Login, Dashboard, Check-in, Report, Izin, Profil)
│   ├── services/                # ApiService & AuthController
│   ├── theme/                   # Tema aplikasi
│   ├── widgets/                 # Komponen UI reusable
│   └── main.dart
├── test/                        # Widget & unit tests
├── AGENTS.md
├── pubspec.yaml
└── README.md
```

---

## Prasyarat & Setup Lokal

- **Flutter SDK** (Dart SDK `^3.12.0` sesuai `pubspec.yaml`)
- **Android Studio / Xcode** sesuai target device

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Koneksi Backend API

Pengaturan default di `lib/services/api_service.dart`:
- **Android Emulator:** `http://10.0.2.2:8000/api`
- **Desktop / iOS Simulator:** `http://127.0.0.1:8000/api`
- Dapat diubah runtime dari aplikasi melalui pengaturan Base URL (tersimpan di `SharedPreferences` dengan key `chrono_api_base_url`).
