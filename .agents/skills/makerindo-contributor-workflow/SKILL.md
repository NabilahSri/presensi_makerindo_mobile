---
name: makerindo-contributor-workflow
description: >-
  Gunakan saat memulai tugas, memperbarui branch lokal, membuat commit, atau membuka PR pada
  track mobile Presensi Makerindo (branch kerja -> staging-mobile -> mobile).
---

# Makerindo Contributor Workflow (Mobile)

Track mobile menerapkan alur 2-tier:
- `staging-mobile`: target seluruh PR fitur, bugfix, chore, dan docs Flutter untuk QC.
- `mobile`: branch stabil mobile yang dipromosikan dari `staging-mobile`.

## 1. Setup Sekali Saja
1. Jalankan `.\scripts\setup-dev.ps1` (atau `./scripts/setup-dev.sh`) untuk mengaktifkan `.githooks`.
2. Jalankan `flutter pub get`.

## 2. Alur Harian
1. Buat branch baru dari `origin/staging-mobile`: `.\scripts\dev-sync.ps1 feat/mobile-<topik>`.
2. Kerjakan dalam commit atomik format Conventional Commits tanpa atribusi AI.
3. Sinkronkan jika tertinggal: `.\scripts\dev-sync.ps1`.
4. Jalankan gate lokal lengkap: `.\scripts\pre-pr-check.ps1`.
5. Push branch dan buka PR ke `staging-mobile`: `gh pr create --base staging-mobile --fill`.

## 3. Promosi ke `mobile`
Setelah QC di `staging-mobile` selesai dan seluruh check hijau, jalankan `.\scripts\promote.ps1` (atau `./scripts/promote.sh`).
