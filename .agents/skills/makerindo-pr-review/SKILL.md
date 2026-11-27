---
name: makerindo-pr-review
description: >-
  Gunakan saat meninjau atau mempromosikan Pull Request pada track server (staging-main atau main).
---

# Makerindo PR Review Skill (Server)

## 1. Konteks Branch Target
- **`staging-main`:** PR fitur, bugfix, docs, atau chore dari branch kerja (`feat/*`, `fix/*`, dll.).
- **`main`:** Promotion PR dari `staging-main` (atau `hotfix/*` darurat) setelah QC selesai.
- Tolak setiap PR yang mencoba menggabungkan branch `mobile` / `staging-mobile` ke track server.

## 2. Checklist Review
1. **Keamanan & Secret:** Tidak ada `.env`, kunci privat, dump SQL/SQLite, atau token nyata di diff.
2. **AuthZ & RBAC:** Rute baru memiliki middleware `auth`, `role:...`, atau `auth.api` sesuai `docs/RBAC_MATRIX.md`, dan self-approval izin tetap ditolak.
3. **Sinkronisasi API Mobile:** Jika `routes/api.php`, `MobileApiController`, atau `POST /api/attendances/location-check-in` berubah, `docs/API_CONTRACT.md` harus ikut diperbarui.
4. **Migrasi & Tests:** Migrasi kompatibel dengan SQLite pengujian dan diiringi Feature/Unit test di `apps/server/tests/`.
5. **CI & Kebersihan:** Judul PR Conventional Commits, tanpa atribusi AI, dan check `CI Gate`, `PR Policy`, serta `Security` lulus.
