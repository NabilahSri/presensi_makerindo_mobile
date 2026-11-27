# Mandatory AI Pre-Flight Documentation Analysis Rule

Berlaku untuk seluruh AI coding agent sebelum menulis, mengubah, atau merancang arsitektur kode pada track server (`main` / `staging-main`).

## 1. Dokumen Wajib Dibaca Sebelum Bertindak

1. **Manual Operasional:** `AGENTS.md` dan `.agents/README.md`
2. **Arsitektur & Branching:** `docs/ARCHITECTURE.md`
3. **Kontrak API Mobile:** `docs/API_CONTRACT.md`
4. **Skema Database Aktual:** `docs/DATABASE_SCHEMA.md` serta file aktual di `apps/server/database/migrations/`
5. **Matriks Hak Akses:** `docs/RBAC_MATRIX.md`
6. **Standar Kontribusi & Keamanan:** `CONTRIBUTING.md` dan `SECURITY.md`

## 2. Larangan Halusinasi

- DILARANG menebak nama tabel, kolom, atau enum tanpa memeriksa `apps/server/database/migrations/` dan `docs/DATABASE_SCHEMA.md`.
- DILARANG mengembalikan konsep lama yang telah dihapus pada migrasi `2026_11_25_110000_remove_payroll_finance_and_rfid.php` (payroll, insentif proyek, perangkat RFID).
- DILARANG mencampur kode Flutter ke dalam branch `main` atau `staging-main`.
- DILARANG push langsung ke `main` atau `staging-main`.

## 3. Verifikasi Sebelum Perubahan

Pastikan setiap perubahan pada `routes/api.php` atau `MobileApiController` tercatat di `docs/API_CONTRACT.md` dan perintah verifikasi (`npm run lint`, `npm run build`, `npm test`) dijalankan setelah edit terakhir.
