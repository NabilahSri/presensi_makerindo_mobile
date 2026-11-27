## Ringkasan Perubahan
<!-- Satu perubahan logis per PR. Jelaskan masalah/fitur, alasan perubahan, dan referensi issue (mis. Closes #12). -->
- **Masalah / Fitur:**
- **Solusi Teknis:**

## Jenis Perubahan
- [ ] `feat`: Fitur baru mobile
- [ ] `fix`: Perbaikan bug
- [ ] `docs`: Pembaruan dokumentasi
- [ ] `refactor`: Refaktor kode Dart/Flutter
- [ ] `test`: Penambahan atau perbaikan pengujian widget/unit
- [ ] `chore` / `ci`: Konfigurasi, dependensi, atau CI/CD

## Target Branch
<!-- PENTING: Fitur dan bugfix mobile WAJIB menargetkan branch 'staging-mobile'. -->
- [ ] Menargetkan `staging-mobile` (fitur / bugfix / chore / docs)
- [ ] Promosi `staging-mobile` → `mobile` (QC selesai & siap rilis mobile)

## Checklist Verifikasi & Keamanan
- [ ] Judul PR mengikuti format Conventional Commits (mis. `feat(mobile): tambah validasi foto check-out`).
- [ ] Sudah menjalankan `.\scripts\pre-pr-check.ps1` (`flutter pub get`, `flutter analyze`, `flutter test`) dan lulus.
- [ ] Tidak ada file `.env`, keystore (`.jks`/`.keystore`), `key.properties`, API key, atau kredensial di diff.
- [ ] Bebas dari atribut AI (`Co-Authored-By: ...` atau `Generated with ...`).
- [ ] Kompatibel dengan endpoint API di branch `main` (`apps/server/routes/api.php` & `docs/API_CONTRACT.md`).

## Bukti Verifikasi / Screenshot
<!-- Lampirkan output test atau screenshot emulator/perangkat jika relevan. -->
