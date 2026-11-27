# Presensi Makerindo — Web Portal & Backend REST API

[![Laravel 13](https://img.shields.io/badge/Laravel-13.x-FF2D20?style=flat&logo=laravel&logoColor=white)](https://laravel.com)
[![PHP 8.5+](https://img.shields.io/badge/PHP-8.5%2B-777BB4?style=flat&logo=php&logoColor=white)](https://php.net)
[![Tailwind CSS v4](https://img.shields.io/badge/Tailwind_CSS-v4.x-38B2AC?style=flat&logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![CI](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/ci.yml)
[![Security](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/security.yml/badge.svg)](https://github.com/NabilahSri/presensi_makerindo_mobile/actions/workflows/security.yml)

Repository terpadu untuk sistem **Presensi Makerindo** yang memisahkan **Web Portal & Backend REST API (Laravel 13)** di branch `main` dan **Aplikasi Mobile (Flutter)** di branch `mobile` dalam satu repository GitHub (`NabilahSri/presensi_makerindo_mobile`).

---

## Struktur Repository & Strategi Branch

Repository ini menggunakan **2-Track Workspace dengan Branch Staging Sebelum Branch Utama**:

| Folder Lokal | Branch Utama | Branch Staging (Target PR) | Isi & Stack |
|---|---|---|---|
| `D:\presensi_makerindo\main` | `main` | `staging-main` | **Laravel 13** (`apps/server`) — Web Portal (Blade + Tailwind v4 + Vite 8) & Mobile REST API (`/api/...`) |
| `D:\presensi_makerindo\mobile` | `mobile` | `staging-mobile` | **Flutter** (Dart SDK `^3.12.0`) — Aplikasi Mobile Presensi GPS & Foto (`lib/`, `android/`, `ios/`) |

```text
[feat|fix|chore|docs/*] ──PR──► [staging-main]   ──Promotion PR──► [main]   (Server & Web)
[feat|fix|chore|docs/*] ──PR──► [staging-mobile] ──Promotion PR──► [mobile] (Flutter Client)
```

### Struktur Folder Branch `main`

```text
.
├── .agents/                     # Rules, indeks skill, dan skill AI (konsisten di .agents/)
├── .githooks/                   # commit-msg, pre-commit, pre-push
├── .github/
│   ├── ISSUE_TEMPLATE/          # Template bug report & feature request
│   ├── workflows/               # ci.yml, pr-policy.yml, security.yml, release.yml
│   ├── CODEOWNERS               # Peninjau wajib untuk path sensitif
│   ├── dependabot.yml           # Pembaruan Composer, npm (apps/server), GitHub Actions
│   └── pull_request_template.md # Template standar Pull Request
├── apps/
│   └── server/                  # Aplikasi Laravel 13 (Web Portal + REST API)
│       ├── app/                 # Controllers, Models, Services, Middleware, Requests
│       ├── database/            # Migrations, Seeders, Factories
│       ├── resources/           # Blade Views, CSS (Tailwind v4), JS (Vite)
│       ├── routes/              # web.php (Web Portal) & api.php (Mobile REST API)
│       └── tests/               # Unit & Feature Tests (PHPUnit)
├── docs/
│   ├── runbooks/                # GITHUB_REPOSITORY_SETUP.md
│   ├── API_CONTRACT.md          # Kontrak endpoint Mobile REST API
│   ├── ARCHITECTURE.md          # Arsitektur workspace & alur Git
│   └── README.md                # Indeks dokumentasi
├── scripts/                     # setup.ps1, dev.ps1, setup-dev.*, dev-sync.*, pre-pr-check.*, promote.*
├── .gitleaks.toml               # Konfigurasi pemindaian secret lokal & CI
├── AGENTS.md                    # Pedoman kerja developer & AI agent
├── CHANGELOG.md                 # Catatan rilis (Keep a Changelog)
├── CODE_OF_CONDUCT.md           # Kode etik kolaborasi
├── CONTRIBUTING.md              # Alur kontribusi, git hooks, & PR policy
├── LICENSE                      # Lisensi proyek
├── package.json                 # NPM Workspace Root scripts
├── README.md
└── SECURITY.md                  # Kebijakan pelaporan kerentanan & keamanan
```

---

## Dokumentasi Proyek

| Dokumen | Fokus & Isi |
|---|---|
| [docs/README.md](docs/README.md) | Indeks seluruh dokumentasi teknis |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arsitektur sistem, strategi 2-track + staging branch, dan komunikasi API |
| [docs/API_CONTRACT.md](docs/API_CONTRACT.md) | Daftar lengkap endpoint REST API mobile & autentikasi Bearer Token |
| [docs/runbooks/GITHUB_REPOSITORY_SETUP.md](docs/runbooks/GITHUB_REPOSITORY_SETUP.md) | Panduan setup branch staging, branch protection, secret scanning, dan rilis |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Panduan branching, git hooks lokal, dan quality gate sebelum PR |
| [SECURITY.md](SECURITY.md) | Kebijakan keamanan dan pelaporan kerentanan privat |
| [AGENTS.md](AGENTS.md) | Manual operasional dan daftar aturan AI agent (`.agents/`) |

---

## Prasyarat Lingkungan

- **PHP** `^8.5` (sesuai `apps/server/composer.json`) & **Composer**
- **Node.js** `v20+` (CI memakai Node `22`) & **NPM** `v10+`
- **Database**: SQLite (default `apps/server/.env.example`) atau MySQL/MariaDB/PostgreSQL

---

## Panduan Setup & Menjalankan Lokal

### 1. Clone 2 Folder Kerja (Jika Setup di Mesin Baru)

```bash
mkdir presensi_makerindo && cd presensi_makerindo
git clone -b staging-main https://github.com/NabilahSri/presensi_makerindo_mobile.git main
git clone -b staging-mobile https://github.com/NabilahSri/presensi_makerindo_mobile.git mobile
```

### 2. Aktivasi Hooks & Setup `apps/server`

Dari root folder `main`:

```powershell
# 1. Aktifkan git hooks & periksa tooling (sekali saja):
.\scripts\setup-dev.ps1

# 2. Inisialisasi dependencies, .env, SQLite, migrasi, & build Vite:
.\scripts\setup.ps1
```

*(Pengguna Git Bash/Linux/macOS dapat memakai `./scripts/setup-dev.sh`.)*

Atau setup server secara manual:

```bash
cd apps/server
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
npm install
npm run build
```

### 3. Menjalankan Server Development

Dari root folder `main`:

```bash
# Menjalankan Laravel server, queue, pail logs, dan Vite secara bersamaan
npm run dev:server

# Atau hanya Vite frontend dev server / PHP serve terpisah:
npm run serve
npm run dev
```

### 4. Testing, Linting & Quality Gate Lokal

```bash
# Jalankan test PHPUnit
npm test

# Cek formatting Laravel Pint
npm run lint

# Perbaiki formatting Laravel Pint
npm run lint:fix

# Build produksi frontend Vite
npm run build
```

Sebelum membuka Pull Request ke `staging-main`, jalankan quality gate lengkap:

```powershell
.\scripts\pre-pr-check.ps1
```

---

## CI/CD & Keamanan

| Workflow | Pemicu | Isi |
|---|---|---|
| [`ci.yml`](.github/workflows/ci.yml) | Push & PR (`main`, `staging-main`) | `composer validate`, Laravel Pint, Vite build, PHPUnit (SQLite), dan check gabungan **`CI Gate`** |
| [`pr-policy.yml`](.github/workflows/pr-policy.yml) | PR & Push (`main`, `staging-main`) | Judul Conventional Commits, alur `staging-main -> main`, larang cross-merge `mobile`, blokir atribusi AI & file terlarang |
| [`security.yml`](.github/workflows/security.yml) | Push, PR, mingguan | Secret scan `gitleaks`, `composer audit`, `npm audit`, Dependency Review & CodeQL (bila repo publik/GHAS) |
| [`release.yml`](.github/workflows/release.yml) | Push tag `server-v*` / `v*` | Membuat GitHub Release otomatis dengan catatan rilis |

---

## Berkontribusi & Lisensi

- Baca [CONTRIBUTING.md](CONTRIBUTING.md) untuk alur kerja harian (`setup-dev` → `dev-sync` → commit → `pre-pr-check` → PR ke `staging-main`).
- Kode etik kontributor mengikuti [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- Lisensi proyek tercantum pada [LICENSE](LICENSE).
