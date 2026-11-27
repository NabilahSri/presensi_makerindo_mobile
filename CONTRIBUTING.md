# Panduan Kontribusi — Presensi Makerindo (Server & Web)

Terima kasih sudah ikut mengembangkan **Presensi Makerindo**. Panduan ini berlaku untuk seluruh kontributor pada branch track server (`main` & `staging-main`).

---

## 1. Strategi Branch & Alur Promosi (2-Tier per Track)

Repository `NabilahSri/presensi_makerindo_mobile` memisahkan kode **Server/Web** (`main`) dan **Mobile Flutter** (`mobile`), masing-masing dilengkapi branch staging sebelum branch utama:

```text
[feat|fix|chore|docs|refactor|test/*] ──PR──► [staging-main] (QC & Review)
                                                    │
                                              Promotion PR (scripts/promote)
                                                    ▼
                                                  [main] (Produksi Stabil)
```

| Branch | Fungsi Utama | Sumber Perubahan | Persetujuan |
|---|---|---|---|
| **`staging-main`** | Integrasi fitur, pengujian QC Web Portal & API sebelum rilis. | PR dari branch kerja (`feat/*`, `feature/*`, `fix/*`, `chore/*`, `docs/*`, `refactor/*`, `test/*`) | Fullstack Maintainer (`@muhamadhabilputrawan`) & Owner (`@NabilahSri`) |
| **`main`** | Kode stabil Web Portal & Backend REST API (`apps/server`). | Promotion PR dari `staging-main` (atau `hotfix/*` darurat) | Repository Owner (`@NabilahSri`) & `@muhamadhabilputrawan` |

> **ATURAN WAJIB**: Dilarang melakukan direct push ke `staging-main` maupun `main`, dan dilarang menggabungkan branch `mobile` / `staging-mobile` ke track server.

---

## 2. Aturan Wajib untuk Asisten AI (Pre-Flight Analysis)

Sebelum asisten coding AI menulis atau mengubah kode:
- Wajib membaca [`AGENTS.md`](AGENTS.md), [`.agents/README.md`](.agents/README.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), dan [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md).
- Dilarang mengarang nama kolom database atau endpoint tanpa memverifikasi migrasi di `apps/server/database/migrations/` dan rute di `apps/server/routes/`.

---

## 3. Setup Lokal (Sekali Saja)

Dari root folder kerja branch `main` (`D:\presensi_makerindo\main`):

```powershell
# 1. Aktifkan git hooks (.githooks) & cek tooling
.\scripts\setup-dev.ps1

# 2. Inisialisasi dependencies, .env, SQLite, migrasi, & build Vite
.\scripts\setup.ps1

# 3. Jalankan server lokal (Laravel + Queue + Pail + Vite)
npm run dev:server
```

*(Pengguna Git Bash/Linux/macOS dapat menjalankan `./scripts/setup-dev.sh`.)*

---

## 4. Alur Kerja Harian Developer

```text
sync staging-main -> branch kerja -> commit kecil -> pre-pr-check -> push branch -> PR ke staging-main
```

| Langkah | PowerShell (Windows) | Bash (Git Bash / Linux / macOS) |
|---|---|---|
| 1. Buat branch kerja dari `origin/staging-main` | `.\scripts\dev-sync.ps1 feat/<topik>` | `./scripts/dev-sync.sh feat/<topik>` |
| 2. Kerjakan & commit kecil terisolasi | `git add <file...>` lalu `git commit -m "feat(scope): pesan"` | `git add <file...>` lalu `git commit -m "feat(scope): pesan"` |
| 3. Sinkron ulang dengan `origin/staging-main` | `.\scripts\dev-sync.ps1` | `./scripts/dev-sync.sh` |
| 4. Jalankan quality gate lokal sebelum PR | `.\scripts\pre-pr-check.ps1` | `./scripts/pre-pr-check.sh` |
| 5. Push branch ke remote | `git push -u origin feat/<topik>` | `git push -u origin feat/<topik>` |
| 6. Buka PR ke `staging-main` | `gh pr create --base staging-main --fill` | `gh pr create --base staging-main --fill` |
| 7. Promosi ke `main` setelah QC lulus | `.\scripts\promote.ps1` | `./scripts/promote.sh` |

### Standar Penamaan & Commit
- **Nama branch kerja**: `feat|feature|fix|chore|docs|refactor|test|hotfix/<topik-huruf-kecil>`
- **Format commit**: Conventional Commits `feat|fix|refactor|style|test|docs|chore|ci|perf|build(scope): pesan` (maksimal 100 karakter di baris pertama)
- **Aturan commit**: Satu perubahan logis per commit, stage file secara eksplisit (`git add <file>`), **tanpa atribusi AI** (`Co-Authored-By`, `Generated with/by`).

---

## 5. Penegakan Kualitas & Keamanan (Hooks & CI/CD)

1. **Git Hooks Lokal** (`.githooks/`):
   - [`pre-push`](.githooks/pre-push): Memblokir penghapusan branch `main` dan `staging-main`, memblokir direct push ke `main` dan `staging-main`, serta memblokir force-push destruktif pada branch mana pun.
   - [`commit-msg`](.githooks/commit-msg): Memvalidasi format Conventional Commits (maks 100 karakter) dan memblokir atribusi AI.
   - [`pre-commit`](.githooks/pre-commit): Memblokir file terlarang (`.env`, kunci privat `.pem`/`.key`/`.p12`/`.pfx`, file `.sql`/`.sqlite`), menjalankan `gitleaks` (bila terpasang), memeriksa gaya kode PHP (`php vendor/bin/pint --test` pada file `.php` ter-stage di `apps/server/`), dan menjalankan `npm run build` saat aset frontend berubah.
2. **CI Pipeline** ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):
   - `lint`: `composer validate --no-check-publish` dan Laravel Pint `--test` pada `apps/server`.
   - `test-build`: Vite production build (`npm run build`), migrasi + seeder SQLite, dan `php artisan test`.
   - Check gabungan **`CI Gate`**.
3. **PR Policy** ([`.github/workflows/pr-policy.yml`](.github/workflows/pr-policy.yml)):
   - Memvalidasi judul Conventional Commits, alur branch (`kerja -> staging-main -> main`), melarang cross-merge dari `mobile`/`staging-mobile`, memblokir atribusi AI, dan memblokir file terlarang.
4. **Security Workflow** ([`.github/workflows/security.yml`](.github/workflows/security.yml)):
   - Pemindaian secret riwayat penuh (`gitleaks`), `composer audit --locked`, `npm audit --omit=dev`, serta Dependency Review & CodeQL (bila repo publik atau GHAS aktif).
