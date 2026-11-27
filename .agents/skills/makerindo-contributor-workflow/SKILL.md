---
name: makerindo-contributor-workflow
description: >-
  Gunakan saat memulai tugas, memperbarui branch lokal, membuat commit, atau membuka PR pada
  track server Presensi Makerindo (branch kerja -> staging-main -> main).
---

# Makerindo Contributor Workflow (Server)

Track server menerapkan alur 2-tier:
- `staging-main`: target seluruh PR fitur, bugfix, chore, dan docs untuk QC Web & API.
- `main`: branch stabil produksi yang dipromosikan dari `staging-main`.

## 1. Setup Sekali Saja
1. Jalankan `.\scripts\setup-dev.ps1` (atau `./scripts/setup-dev.sh`) untuk mengaktifkan `.githooks`.
2. Jalankan `.\scripts\setup.ps1` jika server `apps/server` belum diinisialisasi.

## 2. Alur Harian
1. Buat branch baru dari `origin/staging-main`: `.\scripts\dev-sync.ps1 feat/<topik>`.
2. Kerjakan dalam commit atomik format Conventional Commits tanpa atribusi AI.
3. Sinkronkan jika tertinggal: `.\scripts\dev-sync.ps1`.
4. Jalankan gate lokal lengkap: `.\scripts\pre-pr-check.ps1`.
5. Push branch dan buka PR ke `staging-main`: `gh pr create --base staging-main --fill`.

## 3. Promosi ke `main`
Setelah QC di `staging-main` selesai dan seluruh check hijau, jalankan `.\scripts\promote.ps1` (atau `./scripts/promote.sh`).
