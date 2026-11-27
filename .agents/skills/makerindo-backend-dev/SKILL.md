---
name: makerindo-backend-dev
description: >-
  Gunakan saat mengembangkan atau memodifikasi backend Laravel 13 pada apps/server/ (Controllers,
  Services, Models, Middleware, Migrations, dan pengujian PHPUnit).
---

# Makerindo Backend Development Skill

## 1. Pre-Flight Wajib
Baca sebelum mengubah kode backend:
1. `docs/DATABASE_SCHEMA.md` & `apps/server/database/migrations/`
2. `docs/RBAC_MATRIX.md` & `apps/server/app/Http/Middleware/` (`RoleMiddleware`, `ApiTokenAuthMiddleware`)
3. `docs/API_CONTRACT.md` & `apps/server/routes/` (`web.php`, `api.php`)

## 2. Konvensi Arsitektur (`apps/server/`)
- **Services:** Taruh logika kalkulasi presensi, jarak Haversine, dan autentikasi web di `app/Services/` (`AttendanceService`, `AuthService`).
- **Auth & RBAC:**
  - Portal web hanya untuk `super_admin` dan `ceo` (`User::canAccessWebPortal()`), serta rute `/approvals` yang memeriksa `can_approve_leaves || super_admin`.
  - Mobile API (`auth.api`) hanya untuk `karyawan` dan `intern` (`User::canAccessMobileApp()`) dengan Bearer Token `PersonalAccessToken` ber-hash SHA-256.
- **Migrasi:** Pertahankan kompatibilitas driver SQLite untuk PHPUnit CI (`2026_11_27_000001_sync_sqlite_enum_constraints.php` sebagai acuan). Jangan hidupkan kembali tabel/kolom payroll atau RFID yang telah dihapus.

## 3. Verifikasi
Dari root `main`:
- `npm run lint` (`./vendor/bin/pint --test` di `apps/server`)
- `npm test` (`php artisan test` di `apps/server`)
