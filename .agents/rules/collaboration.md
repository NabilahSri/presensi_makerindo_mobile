# Aturan Kolaborasi — Presensi Makerindo (Mobile)

Aturan ini berlaku bagi setiap kontributor dan agen AI pada branch track mobile (`mobile` & `staging-mobile`):

1. **Alur Branch Staging:** Dilarang commit atau push langsung ke `mobile` maupun `staging-mobile`. Buat branch kerja (`feat|feature|fix|chore|docs|refactor|test|hotfix/<topik>`) dari `origin/staging-mobile` menggunakan `scripts/dev-sync.ps1` / `scripts/dev-sync.sh`, lalu ajukan PR ke `staging-mobile`.
2. **Promosi ke Rilis Mobile:** Branch `mobile` hanya menerima perubahan melalui Promotion PR dari `staging-mobile` (`scripts/promote.ps1` / `scripts/promote.sh`) atau `hotfix/*` darurat.
3. **Pre-Flight Dokumentasi Wajib:** Baca `AGENTS.md`, `docs/MOBILE_GUIDE.md`, dan `.agents/` sebelum menulis kode.
4. **Satu Perubahan Logis per Commit:** Gunakan Conventional Commits (maks 100 karakter di baris pertama) dan stage file secara eksplisit (`git add <file...>`), bukan `git add .` tanpa pemeriksaan.
5. **Tanpa Atribusi AI:** Dilarang menyertakan `Co-Authored-By` atau `Generated with/by` di pesan commit maupun deskripsi PR.
6. **Tanpa Penghapusan Tanpa Konfirmasi:** Jangan menghapus file, direktori, atau branch secara destruktif tanpa persetujuan eksplisit.
7. **Secret & Keystore Hygiene:** Jangan pernah commit `.env*`, `.jks`, `.keystore`, `key.properties`, `google-services.json`, atau `GoogleService-Info.plist`.
8. **Quality Gate Sebelum PR:** Jalankan `.\scripts\pre-pr-check.ps1` (atau `./scripts/pre-pr-check.sh`) sebelum membuka PR dan lengkapi checklist PR template.
