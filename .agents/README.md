# Panduan Rules & Skills AI — Presensi Makerindo (Server)

Seluruh aturan dan skill AI untuk track server (`main` & `staging-main`) disimpan di folder `.agents/` agar root repositori tetap ringkas (hanya `AGENTS.md` di root).

## 1. Aturan Wajib (`.agents/rules/`)

| Berkas | Fungsi |
|---|---|
| [`rules/ai-preflight-analysis.md`](rules/ai-preflight-analysis.md) | Kewajiban membaca dokumen `.md` dan migrasi sebelum menulis kode |
| [`rules/collaboration.md`](rules/collaboration.md) | Aturan branching `staging-main -> main`, commit atomik, keamanan, & tanpa atribusi AI |

## 2. Daftar Skills (`.agents/skills/`)

| Nama Skill | Sasaran & Lingkup Tugas | Dokumen Acuan Utama |
|---|---|---|
| **`makerindo-contributor-workflow`** | Branch kerja dari `staging-main`, commit, pre-PR check, PR ke `staging-main`, promosi ke `main` | `CONTRIBUTING.md`, `docs/DEVELOPER_GUIDE.md` |
| **`makerindo-backend-dev`** | Controller, Services, Models, Migrasi SQLite/SQL, Middleware RBAC/API, PHPUnit tests | `docs/ARCHITECTURE.md`, `docs/DATABASE_SCHEMA.md`, `docs/RBAC_MATRIX.md`, `docs/API_CONTRACT.md` |
| **`makerindo-frontend-blade`** | Blade views (`apps/server/resources/views/`), Tailwind CSS v4 (`@theme`), Vite 8 | `apps/server/resources/css/app.css`, `apps/server/vite.config.js` |
| **`makerindo-security-hygiene`** | Penanganan `.env`, Bearer token `PersonalAccessToken`, sanitasi export, `composer/npm audit`, `gitleaks` | `SECURITY.md`, `.gitleaks.toml` |
| **`makerindo-pr-review`** | Review keamanan PR, validasi kontrak API, migrasi, & promosi `staging-main -> main` | `docs/RBAC_MATRIX.md`, `docs/API_CONTRACT.md`, `.github/workflows/pr-policy.yml` |
