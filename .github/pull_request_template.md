## Deskripsi Perubahan
- **Masalah / Fitur:**
- **Solusi Teknis:**

## Jenis Perubahan
- [ ] `feat`: Fitur baru
- [ ] `fix`: Perbaikan bug
- [ ] `docs`: Dokumentasi
- [ ] `refactor`: Refactoring kode
- [ ] `chore`: Konfigurasi / CI / dependencies

## Area Terdampak
- [ ] `apps/server` — Web Portal (`routes/web.php`, `resources/views`)
- [ ] `apps/server` — Backend / Mobile REST API (`routes/api.php`, `app/Services`)
- [ ] `mobile` — Flutter Client (branch `mobile`)
- [ ] `docs` / `scripts` / `.github`

## Checklist Verifikasi
- [ ] `npm test` (PHPUnit) berjalan tanpa error
- [ ] `npm run lint` (Laravel Pint) lolos
- [ ] `npm run build` (Vite) sukses
- [ ] Tidak ada file `.env` atau kredensial yang ikut ter-commit
- [ ] Perubahan API sudah disinkronkan dengan `docs/API_CONTRACT.md`
