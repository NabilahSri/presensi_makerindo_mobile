---
name: makerindo-security-hygiene
description: >-
  Gunakan saat menangani autentikasi token lokal, base URL server, izin kamera/GPS, Android/iOS
  signing keystore, dependensi pub/gradle, atau pemindaian secret di track mobile.
---

# Makerindo Security Hygiene Skill (Mobile)

## 1. Rujukan Wajib
1. `SECURITY.md`
2. `.gitleaks.toml`
3. `.github/workflows/security.yml`

## 2. Aturan Keamanan Mobile
- Token sesi (`chrono_auth_token`) wajib dibersihkan saat logout dan tidak boleh di-log ke console.
- File `.env*`, `.jks`, `.keystore`, `android/key.properties`, `google-services.json`, dan `GoogleService-Info.plist` dilarang masuk commit.
- Hanya `^test/` yang boleh masuk allowlist `.gitleaks.toml`.
- Hindari menonaktifkan verifikasi sertifikat TLS di kode `http` produksi.

## 3. Verifikasi
- `flutter pub get --enforce-lockfile`
- `gitleaks protect --staged --redact --config .gitleaks.toml`
