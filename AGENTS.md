# AGENTS.md — Pedoman Pengembangan Monorepo Presensi Makerindo

Dokumen ini menjadi acuan bagi developer dan AI coding agent saat bekerja di repository `presensi_makerindo_mobile` (branch `main`).

## 1. Peta Workspace

- **Web Portal & Backend API**: `apps/server/` (Laravel 13, Blade, Tailwind CSS v4, Vite 8).
- **Mobile App**: berada pada branch terpisah `mobile` (di lokal pada folder sejajar `../mobile`).
- **Dokumentasi**: `docs/` (`ARCHITECTURE.md`, `API_CONTRACT.md`).
- **Skrip Otomatisasi**: `scripts/` (`setup.ps1`, `dev.ps1`).

## 2. Aturan Utama

1. **Jangan campurkan kode Flutter ke branch `main`**, dan jangan taruh kode Laravel ke branch `mobile`.
2. Selalu jalankan perintah Artisan, Composer, dan test Laravel dengan target working directory `apps/server` (atau via root script `npm test`, `npm run lint`, `npm run build`).
3. Setiap perubahan endpoint di `apps/server/routes/api.php` atau struktur payload JSON di `MobileApiController` wajib memperbarui `docs/API_CONTRACT.md` dan disinkronkan dengan `lib/services/api_service.dart` di branch `mobile`.
4. Jangan pernah meng-commit file `.env`, kunci privat, atau kredensial ke Git.
5. Gunakan Conventional Commits (`feat(server): ...`, `fix(api): ...`, `docs: ...`).
