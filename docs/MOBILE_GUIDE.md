# Panduan Pengembang Mobile (Flutter)

## 1. Prasyarat Lingkungan

- **Flutter SDK** `3.x` (teruji pada `3.44.1`) dengan **Dart SDK** `^3.12.0` (sesuai `pubspec.yaml`)
- **Android Studio / Android SDK** (untuk target Android, `namespace`/`applicationId`: `com.makerindo.presensi`)
- **Xcode** (khusus macOS untuk target iOS)
- **Git** & **GitHub CLI (`gh`)** (opsional `gitleaks`)

## 2. Setup Awal & Verifikasi Lokal

```powershell
# 1. Aktifkan git hooks (.githooks) & cek tooling (sekali saja)
.\scripts\setup-dev.ps1
```

```bash
# 2. Pasang dependencies & jalankan seluruh pemeriksaan
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Atau gunakan skrip pre-PR lengkap sebelum membuka Pull Request ke `staging-mobile`:

```powershell
.\scripts\pre-pr-check.ps1
```

## 3. Konfigurasi Koneksi Backend API

`lib/services/api_service.dart` menggunakan default base URL berikut:
- **Android Emulator:** `http://10.0.2.2:8000/api`
- **Desktop / iOS Simulator:** `http://127.0.0.1:8000/api`

Base URL dan token login disimpan di `SharedPreferences` (`chrono_api_base_url` dan `chrono_auth_token`) sehingga pengguna dapat mengganti alamat server di layar login tanpa recompilation.

## 4. Versi Aplikasi & Signing Rilis

- Versi paket diatur di `pubspec.yaml` (`version: 1.0.0+1`) dan konstanta tampilan di `lib/config/app_version.dart` (diperbarui saat rilis menggunakan tag `mobile-v*`).
- Saat membangun rilis Android (`flutter build appbundle` / `flutter build apk --release`), pastikan `android/key.properties` dan file `.jks`/`.keystore` **tidak pernah di-commit** (sudah diabaikan oleh `.gitignore` dan diblokir oleh `.githooks/pre-commit` serta `.github/workflows/pr-policy.yml`).

## 5. Alur Branching Singkat

1. Buat branch kerja dari `origin/staging-mobile`: `.\scripts\dev-sync.ps1 feat/mobile-<topik>`
2. Pastikan perubahan model/API selaras dengan `docs/API_CONTRACT.md` di branch `main`.
3. Jalankan `.\scripts\pre-pr-check.ps1`, push branch, dan buka PR ke `staging-mobile`.
4. Setelah QC selesai, buat Promotion PR ke `mobile` dengan `.\scripts\promote.ps1`.
