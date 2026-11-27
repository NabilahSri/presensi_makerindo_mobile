# Matriks Role & Hak Akses (RBAC) — Presensi Makerindo

Dokumen ini mendefinisikan pembagian peran dan penegakan akses berdasarkan `RoleSeeder.php`, `User.php`, `AuthService.php`, `RoleMiddleware.php`, `ApiTokenAuthMiddleware.php`, `LeaveApprovalController.php`, `routes/web.php`, dan `routes/api.php`.

## 1. Definisi 4 Peran Utama + Atribut Approver

| Role (`roles.name`) | `is_attendance_required` | Akses Web Portal | Akses Mobile App | Keterangan |
|---|---|---|---|---|
| `super_admin` | `false` | Ya (`canAccessWebPortal()`) | Ditolak (HTTP 403 di API login/token) | Administrator penuh Web Portal, user, setting, presensi, laporan, sanksi, & approval |
| `ceo` | `false` | Ya (`canAccessWebPortal()`) | Ditolak (HTTP 403 di API login/token) | Eksekutif (dashboard eksekutif, lihat laporan & unduh PDF sanksi) |
| `karyawan` | `true` | Ditolak saat login web *(kecuali rute `/approvals` bila login; `AuthService` memblokir login web)* | Ya (`canAccessMobileApp()`) | Karyawan regular (`KARTAP` / `PKWT`). Jika `can_approve_leaves = true`, dapat menyetujui izin |
| `intern` | `true` | Ditolak saat login web | Ya (`canAccessMobileApp()`) | Peserta Magang / PKL |

## 2. Matriks Akses Rute Web (`apps/server/routes/web.php`)

| Modul / Prefix Rute | Middleware / Guard | `super_admin` | `ceo` | `karyawan` (`can_approve_leaves=true`) | `karyawan` / `intern` |
|---|---|:---:|:---:|:---:|:---:|
| `/login` | `guest` | Ya | Ya | Ditolak di `AuthService` | Ditolak di `AuthService` |
| `/profile` (`GET`, `PUT`) | `auth` | Ya | Ya | *(Tidak bisa login web)* | *(Tidak bisa login web)* |
| `/admin/*` (`/admin/dashboard`, `/admin/users`, `/admin/settings`, `/admin/attendances`) | `auth`, `role:super_admin` | Penuh | 403 | 403 | 403 |
| `/executive/dashboard` | `auth`, `role:ceo` | 403 | Penuh | 403 | 403 |
| `/approvals/*` | `auth` + `LeaveApprovalController::authorizeApprover()` | Penuh | 403 (kecuali `can_approve_leaves=true`) | Penuh (jika `auth` terpenuhi; self-approval ditolak 403) | 403 |
| `/sanctions` & `/sanctions/{id}/pdf` | `auth`, `role:super_admin,ceo` | Baca & PDF | Baca & PDF | 403 | 403 |
| `/sanctions` mutasi & `/sanctions/rules/*` | `auth`, `role:super_admin` | Penuh | 403 | 403 | 403 |
| `/reports/*` (GET & export `.xlsx`) | `auth`, `role:super_admin,ceo` | Baca & Export | Baca & Export | 403 | 403 |
| `/reports/daily-tasks` mutasi & `/attendances/location-check-in` | `auth`, `role:super_admin` | Penuh | 403 | 403 | 403 |

## 3. Matriks Akses REST API Mobile (`routes/api.php` & `routes/web.php`)

| Endpoint | Guard | `super_admin` / `ceo` | `karyawan` / `intern` |
|---|---|:---:|:---:|
| `GET /api/branding`, `POST /api/login` | Publik (login cek `canAccessMobileApp()`) | Login ditolak (403) | Diizinkan (`karyawan`, `intern`) |
| `/api/logout`, `/api/profile/*`, `/api/attendance/*`, `/api/reports/*`, `/api/sanctions/*` | `auth.api` | Ditolak di `ApiTokenAuthMiddleware` (403) | Data milik user sendiri |
| `POST /api/attendances/location-check-in` | `auth.api` | Ditolak di `ApiTokenAuthMiddleware` (403) | Data milik user sendiri |
| `/api/leaves`, `POST/PUT/DELETE /api/leaves/*` | `auth.api` | Ditolak (403) | Pengajuan izin milik user sendiri |
| `GET /api/leaves/approvals`, `POST /api/leaves/{id}/action` | `auth.api` + cek `can_approve_leaves` | Ditolak (403) | Hanya `karyawan` dengan `can_approve_leaves = true` (bukan milik sendiri) |
