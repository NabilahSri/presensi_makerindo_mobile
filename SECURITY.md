# Kebijakan Keamanan

## Versi yang Didukung

Perbaikan keamanan diterapkan pada branch aktif berikut di repositori `NabilahSri/presensi_makerindo_mobile`:

| Track | Branch Aktif |
|---|---|
| Web Portal & REST API (`apps/server`) | `main`, `staging-main` |
| Mobile Client (`mobile`) | `mobile`, `staging-mobile` |

## Melaporkan Kerentanan

**Jangan membuka issue publik untuk kerentanan keamanan.** Gunakan salah satu jalur privat berikut:

1. GitHub → tab **Security** → **Report a vulnerability** (Private Vulnerability Reporting): `https://github.com/NabilahSri/presensi_makerindo_mobile/security/advisories/new`.
2. Email kontak keamanan proyek: `TODO: <security-contact-email>`

Sertakan: deskripsi masalah, langkah reproduksi, dampak (misal bypass autentikasi, eskalasi role, kebocoran data/foto presensi), serta commit/branch terkait.

Target respons: konfirmasi awal ≤ 3 hari kerja, penilaian awal ≤ 7 hari.

## Area Kritis (Server & API)

- **Autentikasi & Otorisasi Web:** Validasi login via `AuthService`, pemisahan akses portal web (`super_admin`, `ceo`) vs klien mobile (`karyawan`, `intern`) melalui `RoleMiddleware`, dan pembatasan aksi approval cuti (`can_approve_leaves` atau `super_admin`).
- **Bearer Token Mobile (`auth.api`):** Token disimpan sebagai hash SHA-256 pada tabel `personal_access_tokens` dan divalidasi dengan `hash_equals` di `ApiTokenAuthMiddleware`. Token kedaluwarsa wajib ditolak (HTTP 401).
- **Validasi Presensi & Upload:** Koordinat GPS divalidasi batas numeriknya, aturan WFA/Tugas Luar diverifikasi terhadap `LeaveRequest` berstatus `APPROVED`, serta file foto profil/bukti izin divalidasi tipe dan ukurannya.
- **Ekspor & Laporan:** Sanitasi formula injection pada ekspor `.xlsx` (`ReportController::sanitizeSpreadsheetCell`) dan pembatasan akses unduhan sanksi.
- **Secret & Konfigurasi:** File `apps/server/.env`, `APP_KEY`, kredensial database, dan kunci privat tidak pernah di-commit ke Git.

## Jika Secret Terlanjur Ter-commit

1. **Rotasi** secret tersebut segera (menghapus dari commit terbaru tidak cukup karena histori Git tetap menyimpannya).
2. Beri tahu pemilik repositori (`@NabilahSri`).
3. Pembersihan histori Git dilakukan hanya atas keputusan pemilik repositori.

## Kontrol Otomatis

Workflow [`security.yml`](.github/workflows/security.yml) menjalankan pemindaian `gitleaks` (riwayat penuh), `composer audit`, `npm audit` pada `apps/server/`, serta Dependency Review & CodeQL (saat repositori berstatus publik atau GitHub Advanced Security aktif). Dependabot memantau Composer, npm (`apps/server/`), dan GitHub Actions setiap minggu.
