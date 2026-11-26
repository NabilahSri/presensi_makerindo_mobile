# Arsitektur Monorepo — Presensi Makerindo

## 1. Ringkasan Desain

Project **Presensi Makerindo** menggabungkan Web Portal, Backend REST API, dan Aplikasi Mobile dalam satu repository GitHub (`NabilahSri/presensi_makerindo_mobile`) dengan pemisahan branch yang tegas:

- **Branch `main`** (`D:\presensi_makerindo\main`):
  - Berisi workspace monorepo dengan `apps/server` (Laravel 13 monolith yang melayani Web Dashboard berbasis Blade + Tailwind v4 dan REST API untuk klien mobile).
- **Branch `mobile`** (`D:\presensi_makerindo\mobile`):
  - Berisi project Flutter (`presensi_makerindo`) tepat di root branch agar kompatibel langsung dengan Flutter CLI, Android Studio, dan Xcode.

## 2. Alur Kerja Git (Branching Workflow)

```text
[feat/... / fix/...] ──PR──> [main]    (Web Portal & Backend REST API)
[feat/... / fix/...] ──PR──> [mobile]  (Flutter Mobile App)
```

- Gunakan branch fitur (`feat/<nama-fitur>` atau `fix/<nama-bug>`) dari `main` untuk perubahan Web/Backend.
- Gunakan branch fitur (`feat/mobile-<nama-fitur>` atau `fix/mobile-<nama-bug>`) dari `mobile` untuk perubahan Flutter.
- Jangan merge `mobile` ke `main` atau sebaliknya agar workspace masing-masing tetap bersih.

## 3. Komunikasi Mobile <-> Backend

Aplikasi mobile (`lib/services/api_service.dart` di branch `mobile`) terhubung ke Laravel REST API (`apps/server/routes/api.php` di branch `main`):

- **Android Emulator default**: `http://10.0.2.2:8000/api`
- **Desktop / iOS Simulator default**: `http://127.0.0.1:8000/api`
- **Autentikasi**: Bearer Token (`auth.api` middleware).
