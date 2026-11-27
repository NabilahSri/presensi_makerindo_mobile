## Ringkasan Perubahan
<!-- Satu perubahan logis per PR. Jelaskan masalah/fitur, alasan perubahan, dan referensi issue (mis. Closes #12). -->
- **Masalah / Fitur:**
- **Solusi Teknis:**

## Jenis Perubahan
- [ ] `feat`: Fitur baru
- [ ] `fix`: Perbaikan bug
- [ ] `docs`: Pembaruan dokumentasi
- [ ] `refactor`: Refaktor kode tanpa mengubah perilaku
- [ ] `test`: Penambahan atau perbaikan pengujian
- [ ] `chore` / `ci`: Konfigurasi, dependensi, atau CI/CD

## Target Branch
<!-- PENTING: Fitur dan bugfix normal WAJIB menargetkan branch 'staging-main'. -->
- [ ] Menargetkan `staging-main` (fitur / bugfix / chore / docs)
- [ ] Promosi `staging-main` → `main` (QC selesai & siap rilis produksi)

## Area Terdampak
- [ ] `apps/server` — Web Portal (`routes/web.php`, `resources/views`)
- [ ] `apps/server` — Backend / Mobile REST API (`routes/api.php`, `app/Services`)
- [ ] `docs` / `scripts` / `.github` / `.githooks` / `.agents`

## Checklist Verifikasi & Keamanan
- [ ] Judul PR mengikuti format Conventional Commits (mis. `feat(api): validasi batas izin WFA`).
- [ ] Sudah menjalankan `.\scripts\pre-pr-check.ps1` (atau `npm run lint`, `npm run build`, `npm test`) dan lulus.
- [ ] Tidak ada file `.env`, kunci privat, dump SQL/SQLite, atau kredensial di diff.
- [ ] Bebas dari atribut AI (`Co-Authored-By: ...` atau `Generated with ...`).
- [ ] Perubahan endpoint API sudah disinkronkan dengan `docs/API_CONTRACT.md` dan branch `mobile` (`staging-mobile`).

## Bukti Verifikasi / Screenshot
<!-- Lampirkan ringkasan hasil test atau screenshot jika menyentuh UI Web Portal. -->
