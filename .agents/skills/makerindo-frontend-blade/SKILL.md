---
name: makerindo-frontend-blade
description: >-
  Gunakan saat memodifikasi Blade views, komponen partials/layouts, Tailwind CSS v4, atau aset Vite 8
  pada apps/server/resources/.
---

# Makerindo Frontend & Blade Skill

## 1. Struktur Aset & Views (`apps/server/resources/`)
- Layout utama: `resources/views/layouts/{app,header,sidebar,footer}.blade.php`
- Partial reusable: `resources/views/partials/` (`custom-dialogs`, `pagination`, `photo-zoom-modal`, `user-avatar`)
- Halaman domain: `admin/`, `approvals/`, `auth/`, `executive/`, `profile/`, `reports/`, `sanctions/`
- CSS & JS: `resources/css/app.css` (Tailwind CSS v4 `@import 'tailwindcss';` dan token `@theme --color-chrono-*` / `--color-hrms-*`), `resources/js/app.js`, dikonfigurasi via `apps/server/vite.config.js`.

## 2. Aturan Kualitas UI & Keamanan
- Selalu escape output user dengan `{{ ... }}`; hindari `{!! ... !!}` pada input pengguna.
- Pastikan tidak mengimpor library JS baru tanpa mendaftarkannya di `apps/server/package.json`.
- Verifikasi kompilasi aset produksi setiap kali mengubah CSS/JS/Blade: `npm run build` (dari root `main`).
