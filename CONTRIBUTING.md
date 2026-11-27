# Panduan Kontribusi — Presensi Makerindo (Mobile Flutter)

Terima kasih sudah ikut mengembangkan klien mobile **Presensi Makerindo**. Panduan ini berlaku untuk seluruh kontributor pada branch track mobile (`mobile` & `staging-mobile`).

---

## 1. Strategi Branch & Alur Promosi (2-Tier per Track)

Repository `NabilahSri/presensi_makerindo_mobile` memisahkan kode **Mobile Flutter** (`mobile`) dari **Server/Web Laravel** (`main`), masing-masing memiliki branch staging sebelum branch utama:

```text
[feat|fix|chore|docs|refactor|test/*] ──PR──► [staging-mobile] (QC & Review Mobile)
                                                    │
                                              Promotion PR (scripts/promote)
                                                    ▼
                                                 [mobile] (Rilis Stabil Mobile)
```

| Branch | Fungsi Utama | Sumber Perubahan | Persetujuan |
|---|---|---|---|
| **`staging-mobile`** | Integrasi fitur, pengujian QC Android/iOS sebelum rilis mobile. | PR dari branch kerja (`feat/*`, `feature/*`, `fix/*`, `chore/*`, `docs/*`, `refactor/*`, `test/*`) | Maintainer (`@NabilahSri`) |
| **`mobile`** | Kode stabil aplikasi Flutter (`lib/`, `android/`, `ios/`, `test/`). | Promotion PR dari `staging-mobile` (atau `hotfix/*` darurat) | Repository Owner (`@NabilahSri`) |

> **ATURAN WAJIB**: Dilarang melakukan direct push ke `staging-mobile` maupun `mobile`, dan dilarang menggabungkan branch `main` / `staging-main` ke track mobile.

---

## 2. Aturan Wajib untuk Asisten AI (Pre-Flight Analysis)

Sebelum asisten coding AI menulis atau mengubah kode Dart/Flutter:
- Wajib membaca [`AGENTS.md`](AGENTS.md), [`.agents/README.md`](.agents/README.md), dan [`docs/MOBILE_GUIDE.md`](docs/MOBILE_GUIDE.md).
- Pastikan perubahan payload model di `lib/models/models.dart` dan panggilan API di `lib/services/api_service.dart` tetap selaras dengan kontrak REST API di branch `main` (`docs/API_CONTRACT.md`).

---

## 3. Setup Lokal (Sekali Saja)

Dari root folder kerja branch `mobile` (`D:\presensi_makerindo\mobile`):

```powershell
# 1. Aktifkan git hooks (.githooks) & cek tooling Flutter
.\scripts\setup-dev.ps1

# 2. Pasang dependensi & verifikasi awal
flutter pub get
flutter analyze
flutter test
```

*(Pengguna Git Bash/Linux/macOS dapat menjalankan `./scripts/setup-dev.sh`.)*

---

## 4. Alur Kerja Harian Developer

| Langkah | PowerShell (Windows) | Bash (Git Bash / Linux / macOS) |
|---|---|---|
| 1. Buat branch kerja dari `origin/staging-mobile` | `.\scripts\dev-sync.ps1 feat/mobile-<topik>` | `./scripts/dev-sync.sh feat/mobile-<topik>` |
| 2. Kerjakan & commit kecil terisolasi | `git add <file...>` lalu `git commit -m "feat(mobile): pesan"` | `git add <file...>` lalu `git commit -m "feat(mobile): pesan"` |
| 3. Sinkron ulang dengan `origin/staging-mobile` | `.\scripts\dev-sync.ps1` | `./scripts/dev-sync.sh` |
| 4. Jalankan quality gate lokal sebelum PR | `.\scripts\pre-pr-check.ps1` | `./scripts/pre-pr-check.sh` |
| 5. Push branch ke remote | `git push -u origin feat/mobile-<topik>` | `git push -u origin feat/mobile-<topik>` |
| 6. Buka PR ke `staging-mobile` | `gh pr create --base staging-mobile --fill` | `gh pr create --base staging-mobile --fill` |
| 7. Promosi ke `mobile` setelah QC lulus | `.\scripts\promote.ps1` | `./scripts/promote.sh` |

### Standar Penamaan & Commit
- **Nama branch kerja**: `feat|feature|fix|chore|docs|refactor|test|hotfix/<topik-huruf-kecil>`
- **Format commit**: Conventional Commits `feat|fix|refactor|style|test|docs|chore|ci|perf|build(scope): pesan` (maksimal 100 karakter di baris pertama)
- **Aturan commit**: Satu perubahan logis per commit, stage file secara eksplisit (`git add <file>`), **tanpa atribusi AI** (`Co-Authored-By`, `Generated with/by`).

---

## 5. Penegakan Kualitas & Keamanan (Hooks & CI/CD)

1. **Git Hooks Lokal** (`.githooks/`):
   - [`pre-push`](.githooks/pre-push): Memblokir penghapusan branch `mobile` dan `staging-mobile`, memblokir direct push ke `mobile` dan `staging-mobile`, serta memblokir force-push destruktif pada branch mana pun.
   - [`commit-msg`](.githooks/commit-msg): Memvalidasi format Conventional Commits (maks 100 karakter) dan memblokir atribusi AI.
   - [`pre-commit`](.githooks/pre-commit): Memblokir file terlarang (`.env`, `.jks`, `.keystore`, `key.properties`, kunci privat, `google-services.json`, `GoogleService-Info.plist`), menjalankan `gitleaks` (bila terpasang), serta memeriksa `dart format` dan `flutter analyze` pada file `.dart` ter-stage.
2. **CI Pipeline** ([`.github/workflows/ci-mobile.yml`](.github/workflows/ci-mobile.yml)):
   - Menjalankan `flutter pub get`, `dart format --output=none --set-exit-if-changed .` (advisory), `flutter analyze`, `flutter test`, dan check gabungan **`CI Gate`**.
3. **PR Policy** ([`.github/workflows/pr-policy.yml`](.github/workflows/pr-policy.yml)):
   - Memvalidasi judul Conventional Commits, alur branch (`kerja -> staging-mobile -> mobile`), melarang cross-merge dari `main`/`staging-main`, memblokir atribusi AI, dan memblokir file sensitif/keystore.
4. **Security Workflow** ([`.github/workflows/security.yml`](.github/workflows/security.yml)):
   - Pemindaian secret riwayat penuh (`gitleaks`), validasi lockfile `flutter pub get --enforce-lockfile`, serta Dependency Review (bila repo publik atau GHAS aktif).
