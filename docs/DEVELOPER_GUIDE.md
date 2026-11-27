# Panduan Developer — Presensi Makerindo (Server & Web)

## 1. Prasyarat Lingkungan

- **PHP** `^8.5` (ekstensi SQLite aktif; `pdo_sqlite`, `sqlite3`, `mbstring`, `xml`, `ctype`, `iconv`, `intl`)
- **Composer** 2.x
- **Node.js** `v20+` (disarankan `v22`) & **NPM** `v10+`
- **Git** & **GitHub CLI (`gh`)** (opsional `gitleaks` untuk pemindaian secret sebelum commit)

## 2. Setup Awal

Dari root workspace `main`:

```powershell
# 1. Aktifkan git hooks & periksa tooling (sekali saja)
.\scripts\setup-dev.ps1

# 2. Setup server (composer install, .env, key:generate, sqlite migrate, npm install & build)
.\scripts\setup.ps1
```

## 3. Menjalankan Aplikasi Lokal

```bash
# Menjalankan php artisan serve, queue:listen, pail, & vite dev bersamaan
npm run dev:server

# Atau jalankan terpisah:
npm run serve
npm run dev
```

## 4. Perintah Kualitas & Pengujian

Seluruh skrip root di `package.json` menargetkan `apps/server`:

```bash
# Cek gaya kode PSR-12 (Laravel Pint)
npm run lint

# Perbaiki gaya kode otomatis
npm run lint:fix

# Build aset produksi Vite + Tailwind CSS v4
npm run build

# Jalankan seluruh test suite PHPUnit
npm test
```

Untuk verifikasi penuh sebelum membuka Pull Request ke `staging-main`:

```powershell
.\scripts\pre-pr-check.ps1
```

## 5. Alur Branching Singkat

1. Sinkronkan branch baru dari `origin/staging-main`: `.\scripts\dev-sync.ps1 feat/<topik>`
2. Commit atomik dengan format Conventional Commits tanpa atribusi AI.
3. Jalankan `.\scripts\pre-pr-check.ps1`, push branch, dan buka PR ke `staging-main`.
4. Setelah QC selesai, buat Promotion PR ke `main` dengan `.\scripts\promote.ps1`.
