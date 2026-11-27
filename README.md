# Presensi Makerindo — Mobile Client (Flutter)

[![Flutter 3.44](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart 3.12+](https://img.shields.io/badge/Dart-3.12%2B-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![CI Mobile](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/ci-mobile.yml/badge.svg?branch=mobile)](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/ci-mobile.yml)
[![Security Mobile](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/security.yml/badge.svg?branch=mobile)](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/security.yml)

Aplikasi mobile **Presensi Makerindo** (Presensi GPS & Foto, Daily Report, Perizinan, dan Sanksi) pada branch `mobile` dari repository terpadu `NabilahSri/presensi_makerindo_mobile`.

> **Catatan Workspace & Staging:**
> - Branch kerja harian Flutter diarahkan melalui PR ke **`staging-mobile`**, lalu dipromosikan ke **`mobile`**.
> - Kode Web Portal & Backend REST API (Laravel 13) berada pada branch **`main`** (staging: **`staging-main`**) di `D:\presensi_makerindo\main`.

---

## Struktur Folder

```text
.
├── .agents/                     # Rules, indeks skill, dan skill AI (konsisten di .agents/)
├── .githooks/                   # commit-msg, pre-commit, pre-push
├── .github/
│   ├── ISSUE_TEMPLATE/          # Template bug report & feature request mobile
│   ├── workflows/               # ci-mobile.yml, pr-policy.yml, security.yml, release.yml
│   ├── CODEOWNERS               # Peninjau wajib untuk path sensitif
│   ├── dependabot.yml           # Pembaruan pub, gradle (/android), GitHub Actions
│   └── pull_request_template.md
├── android/                     # Konfigurasi native Android
├── docs/
│   ├── MOBILE_GUIDE.md          # Panduan setup, testing, & build mobile
│   └── README.md                # Indeks dokumentasi mobile
├── ios/                         # Konfigurasi native iOS
├── lib/
│   ├── config/                  # Versi aplikasi (app_version.dart)
│   ├── models/                  # Model data JSON API
│   ├── screens/                 # Halaman UI (Login, Dashboard, Check-in, Report, Izin, Profil)
│   ├── services/                # ApiService & AuthController
│   ├── theme/                   # Tema aplikasi
│   ├── widgets/                 # Komponen UI reusable
│   └── main.dart
├── scripts/                     # setup-dev.*, dev-sync.*, pre-pr-check.*, promote.*
├── test/                        # Widget & unit tests
├── AGENTS.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── pubspec.yaml
├── README.md
└── SECURITY.md
```

---

## Prasyarat & Setup Lokal

- **Flutter SDK** (Dart SDK `^3.12.0` sesuai `pubspec.yaml`; teruji pada Flutter `3.44.1`)
- **Android Studio / Xcode** sesuai target device

```powershell
# 1. Aktifkan git hooks & periksa tooling (sekali saja):
.\scripts\setup-dev.ps1
```

```bash
# 2. Pasang dependensi, format check, analisis statis, & jalankan test:
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run
```

Sebelum membuka Pull Request ke `staging-mobile`, jalankan:

```powershell
.\scripts\pre-pr-check.ps1
```

---

## Koneksi Backend API

Pengaturan default di `lib/services/api_service.dart`:
- **Android Emulator:** `http://10.0.2.2:8000/api`
- **Desktop / iOS Simulator:** `http://127.0.0.1:8000/api`
- Dapat diubah runtime dari aplikasi melalui pengaturan Base URL (tersimpan di `SharedPreferences` dengan key `chrono_api_base_url`).

---

## CI/CD & Keamanan

| Workflow | Pemicu | Isi |
|---|---|---|
| [`ci-mobile.yml`](.github/workflows/ci-mobile.yml) | Push & PR (`mobile`, `staging-mobile`) | `flutter pub get`, `dart format` (advisory), `flutter analyze`, `flutter test`, dan check gabungan **`CI Gate`** |
| [`pr-policy.yml`](.github/workflows/pr-policy.yml) | PR & Push (`mobile`, `staging-mobile`) | Judul Conventional Commits, alur `staging-mobile -> mobile`, larang cross-merge `main`, blokir atribusi AI & file sensitif |
| [`security.yml`](.github/workflows/security.yml) | Push, PR, mingguan | Secret scan `gitleaks`, validasi dependensi pub, Dependency Review (bila repo publik/GHAS) |
| [`release.yml`](.github/workflows/release.yml) | Push tag `mobile-v*` | Membuat GitHub Release otomatis untuk rilis mobile |

Kebijakan kerentanan dan penanganan keystore ada di [SECURITY.md](SECURITY.md), alur kontribusi di [CONTRIBUTING.md](CONTRIBUTING.md), dan lisensi di [LICENSE](LICENSE).

---

## Tim & Maintainer

- **Repository Owner:** `@NabilahSri`
- **Fullstack Developer & Maintainer:** Muhamad Habil Putrawan (`@muhamadhabilputrawan` — `muhamadhabilputrawan@gmail.com`)
