---
name: makerindo-security-hygiene
description: >-
  Gunakan saat menangani file .env, Bearer token, upload foto/lampiran, audit dependensi, atau
  konfigurasi workflow keamanan pada track server.
---

# Makerindo Security Hygiene Skill

## 1. Rujukan Wajib
1. `SECURITY.md`
2. `.gitleaks.toml`
3. `.github/workflows/security.yml`

## 2. Aturan Secret & Upload
- Secret hanya disimpan di `apps/server/.env` (git-ignored) atau GitHub Secrets. `apps/server/.env.example` hanya berisi placeholder non-sensitif.
- Validasi token mobile di `ApiTokenAuthMiddleware` wajib menggunakan hash SHA-256 (`PersonalAccessToken::findToken` dengan `hash_equals`) dan menolak token kedaluwarsa.
- Sanitasi nilai sel string pada ekspor `.xlsx` (`ReportController::sanitizeSpreadsheetCell`) untuk mencegah formula injection.
- Hanya `^apps/server/tests/` yang boleh masuk allowlist `.gitleaks.toml`.

## 3. Verifikasi
- `composer --working-dir=apps/server audit --locked --no-interaction`
- `npm --prefix apps/server audit --omit=dev --audit-level=high`
- `gitleaks protect --staged --redact --config .gitleaks.toml`
