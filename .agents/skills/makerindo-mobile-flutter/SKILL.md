---
name: makerindo-mobile-flutter
description: >-
  Gunakan saat mengembangkan atau memodifikasi kode Flutter di lib/ dan test/ (UI screens,
  models, ApiService, AuthController, tema ChronoTheme, dan widget/unit tests).
---

# Makerindo Mobile Flutter Skill

## 1. Peta Kode Utama
- Entry & lifecycle: `lib/main.dart` (`ChronoMobileApp`)
- Konfigurasi versi: `lib/config/app_version.dart` (`AppVersion`)
- Service & state auth: `lib/services/api_service.dart` (`ApiService`), `lib/services/auth_controller.dart` (`AuthController`)
- Model payload JSON: `lib/models/models.dart`
- Tema & komponen: `lib/theme/chrono_theme.dart`, `lib/widgets/{chrono_logo,chrono_widgets}.dart`
- Screens: `lib/screens/{splash,login,main_shell,home_dashboard,mobile_checkin,attendance_history,daily_report,leaves,profile}_screen.dart`
- Tests: `test/chrono_mobile_test.dart`

## 2. Aturan Kualitas & Integrasi
- Pertahankan header anti-cache (`Cache-Control`, `Pragma: no-cache`) di `ApiService`.
- Pastikan kondisi logged-out tidak pernah memanggil endpoint akun privat saat startup atau `AppLifecycleState.resumed`.
- Setiap perubahan pada parsing JSON atau endpoint harus selaras dengan `docs/API_CONTRACT.md` di track `main`.
- Tambahkan atau perbarui test di `test/` untuk setiap bugfix atau fitur baru.

## 3. Verifikasi
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
