# Kebijakan Keamanan (Mobile Client)

## Versi yang Didukung

Perbaikan keamanan diterapkan pada branch aktif berikut di repositori `NabilahSri/presensi_makerindo_mobile`:

| Track | Branch Aktif |
|---|---|
| Mobile Client (`mobile`) | `mobile`, `staging-mobile` |
| Web Portal & REST API (`main`) | `main`, `staging-main` |

## Melaporkan Kerentanan

**Jangan membuka issue publik untuk kerentanan keamanan.** Gunakan salah satu jalur privat berikut:

1. GitHub → tab **Security** → **Report a vulnerability** (Private Vulnerability Reporting): `https://github.com/NabilahSri/presensi_makerindo_mobile/security/advisories/new`.
2. Email kontak keamanan proyek (Fullstack Developer / Maintainer): `muhamadhabilputrawan@gmail.com`

Sertakan: deskripsi masalah, langkah reproduksi, dampak (misal kebocoran token lokal, bypass validasi lokasi/izin, kebocoran kredensial rilis), serta commit/branch terkait.

Target respons: konfirmasi awal ≤ 3 hari kerja, penilaian awal ≤ 7 hari.

## Area Kritis (Flutter Mobile)

- **Token & Penyimpanan Lokal:** Token autentikasi (`chrono_auth_token`) dan URL API (`chrono_api_base_url`) hanya disimpan di `SharedPreferences` saat runtime, dibersihkan saat logout (`AuthController.logout`), dan tidak boleh di-hardcode di kode sumber.
- **Kunci Signing & Konfigurasi Build:** File `.jks`, `.keystore`, `android/key.properties`, `.env*`, `google-services.json`, dan `GoogleService-Info.plist` dilarang masuk ke Git.
- **Privasi Data Lokasi & Foto:** Izin kamera dan GPS hanya digunakan saat aksi presensi/profil berlangsung dan tidak dikirim ke pihak ketiga di luar endpoint resmi `ApiService`.
- **Komunikasi Backend:** Produksi wajib memakai HTTPS; loopback HTTP (`10.0.2.2` / `127.0.0.1`) hanya untuk pengembangan lokal.

## Jika Secret atau Keystore Terlanjur Ter-commit

1. **Rotasi / cabut** token API atau buat keystore rilis baru segera (menghapus di commit baru tidak membersihkan histori Git).
2. Beri tahu pemilik repositori (`@NabilahSri`) dan Fullstack Maintainer (`@muhamadhabilputrawan`).
3. Pembersihan histori Git dilakukan hanya atas keputusan pemilik repositori.

## Kontrol Otomatis

Workflow [`security.yml`](.github/workflows/security.yml) menjalankan `gitleaks` (riwayat penuh), pemeriksaan dependensi Flutter (`flutter pub get` & pemeriksaan status paket), serta Dependency Review (saat repositori berstatus publik atau GitHub Advanced Security aktif). Dependabot memantau `pub`, `gradle` (`/android`), dan `github-actions` setiap minggu.
