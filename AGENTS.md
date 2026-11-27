# AGENTS.md — Pedoman Pengembangan Monorepo Presensi Makerindo

Dokumen ini menjadi acuan bagi developer dan AI coding agent saat bekerja di repository `NabilahSri/presensi_makerindo_mobile` pada track server (`main` & `staging-main`).

---

## 0. Wajib Baca Sebelum Menulis Kode (Pre-Flight `.agents/`)

Sebelum merencanakan, mengubah, atau membuat kode, baca dokumen sumber kebenaran berikut:
1. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Arsitektur 2-track + branch staging & komponen server.
2. [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — Kontrak endpoint REST API mobile (`apps/server/routes/api.php` & `routes/web.php`).
3. [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) — Skema tabel & relasi aktif pada `apps/server/database/migrations/`.
4. [`docs/RBAC_MATRIX.md`](docs/RBAC_MATRIX.md) — Pembagian 4 role (`super_admin`, `ceo`, `karyawan`, `intern`) & guard Web vs API.
5. [`CONTRIBUTING.md`](CONTRIBUTING.md) & [`.agents/README.md`](.agents/README.md) — Aturan workflow, rules (`.agents/rules/`), dan daftar skill (`.agents/skills/`).

---

## 1. Peta Workspace

- **Web Portal & Backend API**: `apps/server/` (Laravel 13, Blade, Tailwind CSS v4, Vite 8).
- **Mobile App**: berada pada branch terpisah `mobile` / `staging-mobile` (di lokal pada folder sejajar `../mobile`).
- **Dokumentasi**: `docs/` (`README.md`, `ARCHITECTURE.md`, `API_CONTRACT.md`, `DATABASE_SCHEMA.md`, `RBAC_MATRIX.md`, `DEVELOPER_GUIDE.md`, `runbooks/GITHUB_REPOSITORY_SETUP.md`).
- **Skrip Otomatisasi**: `scripts/` (`setup.ps1`, `dev.ps1`, `setup-dev.*`, `dev-sync.*`, `pre-pr-check.*`, `promote.*`).
- **Konfigurasi AI**: terpusat di `.agents/` (`README.md`, `rules/`, `skills/`).

---

## 2. Aturan Utama

1. **Jangan campurkan kode Flutter ke branch `main`/`staging-main`**, dan jangan taruh kode Laravel ke branch `mobile`/`staging-mobile`.
2. Selalu jalankan perintah Artisan, Composer, dan test Laravel dengan target working directory `apps/server` (atau via root script `npm test`, `npm run lint`, `npm run build`).
3. Setiap perubahan endpoint di `apps/server/routes/api.php` (atau rute API di `routes/web.php`) maupun struktur payload JSON di `MobileApiController` wajib memperbarui `docs/API_CONTRACT.md` dan disinkronkan dengan `lib/services/api_service.dart` di track `mobile`.
4. Jangan pernah meng-commit `apps/server/.env`, kunci privat (`.pem`, `.key`, `.p12`, `.pfx`), file `.sql`/`.sqlite`, atau kredensial ke Git.
5. Gunakan Conventional Commits (`feat(server): ...`, `fix(api): ...`, `docs: ...`), satu perubahan logis per commit, stage file secara eksplisit (`git add <file...>`), dan **tanpa atribusi AI** (`Co-Authored-By`, `Generated with/by`).
6. Dilarang melakukan direct push atau force-push ke `main` dan `staging-main`. Seluruh perubahan fitur/fix masuk ke `staging-main` melalui PR, lalu dipromosikan ke `main`.
7. Jangan menghapus file, direktori, branch, atau tabel database secara destruktif tanpa konfirmasi eksplisit pemilik repositori.
