# Presensi Makerindo — Monorepo Workspace

Repository terpadu (**Monorepo**) untuk sistem **Presensi Makerindo** yang menyatukan **Web Portal & Backend REST API (Laravel 13)** serta **Aplikasi Mobile (Flutter)** dalam satu repository GitHub (`NabilahSri/presensi_makerindo_mobile`).

---

## Struktur Repository & Branching

Repository ini menggunakan strategi **2-Branch Workspace** di lokal maupun GitHub:

| Folder Lokal | Branch GitHub | Isi & Stack | Keterangan |
|---|---|---|---|
| `D:\presensi_makerindo\main` | `main` | **Laravel 13** (`apps/server`) | Web Portal (Blade + Tailwind v4 + Vite) & Mobile REST API (`/api/...`) |
| `D:\presensi_makerindo\mobile` | `mobile` | **Flutter** (Dart SDK `^3.12.0`) | Aplikasi Mobile Presensi GPS & Foto (`lib/`, `android/`, `ios/`) |

### Struktur Folder Branch `main`

```text
.
├── .github/
│   ├── workflows/
│   │   └── ci.yml               # Validasi Composer, Laravel Pint, PHPUnit, & Vite build
│   └── pull_request_template.md # Template standar Pull Request
├── apps/
│   └── server/                  # Aplikasi Laravel 13 (Web Portal + REST API)
│       ├── app/                 # Controllers, Models, Services, Middleware
│       ├── database/            # Migrations, Seeders, Factories
│       ├── resources/           # Blade Views, CSS (Tailwind v4), JS (Vite)
│       ├── routes/              # web.php (Web Portal) & api.php (Mobile REST API)
│       └── tests/               # Unit & Feature Tests
├── docs/
│   ├── ARCHITECTURE.md          # Arsitektur monorepo & alur kerja Git
│   └── API_CONTRACT.md          # Daftar endpoint Mobile REST API
├── scripts/
│   ├── setup.ps1                # Inisialisasi awal server lokal (Windows PowerShell)
│   └── dev.ps1                  # Menjalankan server Laravel + Vite dev
├── AGENTS.md                    # Pedoman kerja developer & AI agent
├── package.json                 # NPM Workspace Root scripts
└── README.md
```

---

## Prasyarat Lingkungan

- **PHP** `^8.5` (sesuai `apps/server/composer.json`) & **Composer**
- **Node.js** `v20+` & **NPM** `v10+`
- **Database**: SQLite (default `.env.example`) atau MySQL/MariaDB

---

## Panduan Setup & Menjalankan Lokal

### 1. Clone 2 Folder Kerja (Jika Setup di Mesin Baru)

```bash
mkdir presensi_makerindo && cd presensi_makerindo
git clone -b main https://github.com/NabilahSri/presensi_makerindo_mobile.git main
git clone -b mobile https://github.com/NabilahSri/presensi_makerindo_mobile.git mobile
```

### 2. Setup `apps/server` (Web + Backend API)

Dari root folder `main`:

```powershell
# Otomatis via PowerShell helper:
.\scripts\setup.ps1
```

Atau manual:

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

### 4. Testing & Code Style

```bash
# Jalankan test PHPUnit
npm test

# Cek formatting Laravel Pint
npm run lint
```
