# Mandatory AI Pre-Flight Documentation Analysis Rule (Mobile)

Berlaku untuk seluruh AI coding agent sebelum menulis, mengubah, atau merancang fitur pada track mobile (`mobile` / `staging-mobile`).

## 1. Dokumen Wajib Dibaca Sebelum Bertindak

1. **Manual Operasional:** `AGENTS.md` dan `.agents/README.md`
2. **Panduan Mobile:** `docs/MOBILE_GUIDE.md`
3. **Konfigurasi Paket & Lint:** `pubspec.yaml` dan `analysis_options.yaml`
4. **Klien API & State Auth:** `lib/services/api_service.dart` dan `lib/services/auth_controller.dart`
5. **Standar Kontribusi & Keamanan:** `CONTRIBUTING.md` dan `SECURITY.md`

## 2. Larangan Halusinasi

- DILARANG mengubah struktur JSON di `lib/models/models.dart` atau path endpoint di `lib/services/api_service.dart` tanpa memastikan kesesuaian dengan backend di branch `main` (`docs/API_CONTRACT.md`).
- DILARANG mencampur kode Laravel/PHP ke branch `mobile` atau `staging-mobile`.
- DILARANG melakukan hardcode token API, kredensial pengguna, atau base URL produksi rahasia di kode Dart.
- DILARANG push langsung ke `mobile` atau `staging-mobile`.

## 3. Verifikasi Sebelum Perubahan

Jalankan `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, dan `flutter test` setelah perubahan terakhir dan laporkan hasil aktualnya.
