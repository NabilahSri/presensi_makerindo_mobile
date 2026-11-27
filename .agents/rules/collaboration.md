# Aturan Kolaborasi — Presensi Makerindo (Server)

Aturan ini berlaku bagi setiap kontributor dan agen AI pada branch track server (`main` & `staging-main`):

1. **Alur Branch Staging:** Dilarang commit atau push langsung ke `main` maupun `staging-main`. Buat branch kerja (`feat|feature|fix|chore|docs|refactor|test|hotfix/<topik>`) dari `origin/staging-main` menggunakan `scripts/dev-sync.ps1` / `scripts/dev-sync.sh`, lalu ajukan PR ke `staging-main`.
2. **Promosi ke Produksi:** Branch `main` hanya menerima perubahan melalui Promotion PR dari `staging-main` (`scripts/promote.ps1` / `scripts/promote.sh`) atau `hotfix/*` darurat.
3. **Pre-Flight Dokumentasi Wajib:** Baca dokumen `docs/` dan `.agents/` sebelum menulis kode.
4. **Satu Perubahan Logis per Commit:** Gunakan Conventional Commits (maks 100 karakter di baris pertama) dan stage file secara eksplisit (`git add <file...>`), bukan `git add .` tanpa pemeriksaan.
5. **Tanpa Atribusi AI:** Dilarang menyertakan `Co-Authored-By` atau `Generated with/by` di pesan commit maupun deskripsi PR.
6. **Tanpa Penghapusan Tanpa Konfirmasi:** Jangan menghapus file, direktori, branch, atau tabel database tanpa persetujuan eksplisit.
7. **Secret Hygiene:** Jangan pernah commit `.env`, kunci privat, dump `.sql`, atau file `.sqlite`.
8. **Quality Gate Sebelum PR:** Jalankan `.\scripts\pre-pr-check.ps1` (atau `./scripts/pre-pr-check.sh`) sebelum membuka PR dan lengkapi seluruh checklist PR template.
