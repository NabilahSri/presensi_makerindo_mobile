# Setup Repositori GitHub (Pemilik)

Panduan satu kali untuk pemilik repositori `NabilahSri/presensi_makerindo_mobile` dalam mengaktifkan branch staging (`staging-main` & `staging-mobile`), Branch Protection, dan fitur keamanan GitHub.

---

## 1. Membuat Branch Staging (`staging-main` & `staging-mobile`)

Repository menggunakan model **2-Track dengan branch staging tepat sebelum masing-masing branch utama**:

- `staging-main` dibuat dari `main` (untuk QC Web Portal & Backend REST API)
- `staging-mobile` dibuat dari `mobile` (untuk QC Flutter Mobile App)

Jalankan perintah berikut **hanya setelah proses QC file selesai**:

```bash
# 1. Di folder kerja D:\presensi_makerindo\main
git fetch origin --prune
git checkout -b staging-main origin/main
git push -u origin staging-main

# 2. Di folder kerja D:\presensi_makerindo\mobile
git fetch origin --prune
git checkout -b staging-mobile origin/mobile
git push -u origin staging-mobile
```

---

## 2. Undang Kolaborator & Perbarui CODEOWNERS

1. Buka **Settings → Collaborators → Add people**.
2. Berikan role **Write** (bukan Admin) kepada anggota tim, dan pastikan akun memakai 2FA.
3. Tambahkan username GitHub kolaborator pada `.github/CODEOWNERS` di masing-masing track (`main` dan `mobile`).

---

## 3. Branch Protection / Rulesets (`main`, `staging-main`, `mobile`, `staging-mobile`)

> [!IMPORTANT]
> **Branch protection / rulesets untuk repo private di GitHub Free plan tidak aktif via UI/API** (membutuhkan GitHub Pro/Team atau repo berstatus **public**).
> Selama belum aktif, perlindungan lokal berjalan melalui `.githooks/pre-push` dan workflow `.github/workflows/pr-policy.yml` (bersifat deteksi di CI, bukan pencegahan sisi server).

Setelah plan mendukung, buat aturan **Branch protection rule** (atau Ruleset) untuk ke-4 branch inti: **`main`**, **`staging-main`**, **`mobile`**, dan **`staging-mobile`**:

- **Require a pull request before merging**
  - **Required approvals:** minimal `1`
  - **Dismiss stale pull request approvals when new commits are pushed:** aktif
  - **Require review from Code Owners:** aktif
- **Require status checks to pass before merging**
  - **Require branches to be up to date before merging:** aktif
  - **Status checks yang diwajibkan:** **`CI Gate`** *(nama job dibuat seragam di `ci.yml` track server dan `ci-mobile.yml` track mobile)*
  - *(Opsional tambahan)*: `Secret scan (gitleaks)`
- **Require conversation resolution before merging:** aktif
- **Block force pushes** (nonaktifkan allow force pushes) & **Block deletions** (nonaktifkan allow deletions)
- **Larang push langsung:** jangan centang bypass untuk kontributor biasa.

---

## 4. Fitur Keamanan (Settings → Code security)

Aktifkan seluruh fitur berikut:
- **Dependency graph**
- **Dependabot alerts** & **Dependabot security updates**
- **Secret scanning** & **Push protection**
- **Private vulnerability reporting** (terhubung ke `.github/ISSUE_TEMPLATE/config.yml` dan `SECURITY.md`)
- **Code scanning (CodeQL)** *(gratis untuk repo publik; untuk repo privat memerlukan GitHub Advanced Security)*

---

## 5. Pengaturan Pull Request & Actions (Settings → General & Actions)

- **Settings → General → Pull Requests:**
  - Izinkan **Squash merging** (disarankan untuk PR fitur ke `staging-main` / `staging-mobile`) dan **Merge commits** (untuk Promotion PR `staging-main -> main` / `staging-mobile -> mobile` bila ingin riwayat promosi jelas).
  - Aktifkan **Automatically delete head branches** *(catatan: branch inti `main`, `staging-main`, `mobile`, `staging-mobile` tetap aman dari penghapusan bila dilindungi Branch Protection)*.
- **Settings → Actions → General:**
  - **Workflow permissions:** pilih **Read repository contents and packages permissions** (prinsip least-privilege; hanya `release.yml` yang meminta `contents: write`).
  - Nonaktifkan **Allow GitHub Actions to create and approve pull requests**.

---

## 6. Konvensi Tag Release (1 Repo, 2 Track)

Karena `main` dan `mobile` berada di satu repositori GitHub yang sama, gunakan prefix tag yang terpisah agar workflow rilis tidak saling tertukar:
- **Rilis Server/Web (dari branch `main`):** `git tag server-v1.0.0 && git push origin server-v1.0.0` *(atau `v*` bila dipakai untuk rilis terpadu; ditangani oleh `.github/workflows/release.yml` di branch `main`)*.
- **Rilis Mobile (dari branch `mobile`):** `git tag mobile-v1.0.0 && git push origin mobile-v1.0.0` *(ditangani oleh `.github/workflows/release.yml` di branch `mobile`)*.
