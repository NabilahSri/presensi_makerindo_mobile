# Panduan Rules & Skills AI — Presensi Makerindo (Mobile)

Seluruh aturan dan skill AI untuk track mobile (`mobile` & `staging-mobile`) disimpan di folder `.agents/` agar root repositori tetap ringkas (hanya `AGENTS.md` di root).

## 1. Aturan Wajib (`.agents/rules/`)

| Berkas | Fungsi |
|---|---|
| [`rules/ai-preflight-analysis.md`](rules/ai-preflight-analysis.md) | Kewajiban membaca dokumen `.md`, `pubspec.yaml`, dan `api_service.dart` sebelum menulis kode |
| [`rules/collaboration.md`](rules/collaboration.md) | Aturan branching `staging-mobile -> mobile`, commit atomik, keamanan keystore, & tanpa atribusi AI |

## 2. Daftar Skills (`.agents/skills/`)

| Nama Skill | Sasaran & Lingkup Tugas | Dokumen Acuan Utama |
|---|---|---|
| **`makerindo-contributor-workflow`** | Branch kerja dari `staging-mobile`, commit, pre-PR check, PR ke `staging-mobile`, promosi ke `mobile` | `CONTRIBUTING.md`, `docs/MOBILE_GUIDE.md` |
| **`makerindo-mobile-flutter`** | Screens (`lib/screens/`), Models (`lib/models/`), `ApiService`, `AuthController`, & widget/unit tests | `docs/MOBILE_GUIDE.md`, `pubspec.yaml`, `analysis_options.yaml` |
| **`makerindo-security-hygiene`** | Proteksi token `SharedPreferences`, izin GPS/kamera, keystore Android/iOS, `gitleaks` | `SECURITY.md`, `.gitleaks.toml` |
| **`makerindo-pr-review`** | Review keamanan PR, validasi kompatibilitas API backend, & promosi `staging-mobile -> mobile` | `CONTRIBUTING.md`, `.github/workflows/pr-policy.yml` |
