# Dokumentasi Teknis — Presensi Makerindo (Server & Web)

Pusat dokumentasi resmi untuk track server (`main` & `staging-main`) pada repository `NabilahSri/presensi_makerindo_mobile`.

## Daftar Dokumen

| Dokumen | Fokus & Isi |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arsitektur workspace 2-track + branch staging, komponen Laravel 13, dan alur koneksi mobile |
| [API_CONTRACT.md](API_CONTRACT.md) | Daftar lengkap endpoint REST API untuk klien Flutter (`routes/api.php` & `routes/web.php`) |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Skema tabel, relasi ERD, dan tipe kolom berdasarkan migrasi aktif |
| [RBAC_MATRIX.md](RBAC_MATRIX.md) | Matriks hak akses 4 peran (`super_admin`, `ceo`, `karyawan`, `intern`) dan aturan approval |
| [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) | Prasyarat, setup lokal Windows/Unix, perintah pengujian, linting, dan build |
| [runbooks/GITHUB_REPOSITORY_SETUP.md](runbooks/GITHUB_REPOSITORY_SETUP.md) | Panduan manual setup branch `staging-main`/`staging-mobile`, Branch Protection, dan fitur keamanan GitHub |
