# API Contract — Mobile REST API (`apps/server/routes/api.php` & `routes/web.php`)

Base URL lokal default: `http://127.0.0.1:8000/api` (atau `http://10.0.2.2:8000/api` pada Android Emulator).

## 1. Endpoint Publik

| Method | Endpoint | Controller | Keterangan |
|---|---|---|---|
| `GET` | `/api/branding` | `MobileApiController@branding` | Branding aplikasi (`app_name`, `app_slogan`, logo, versi) untuk layar mobile |
| `POST` | `/api/login` | `MobileApiController@login` | Login user (`karyawan` / `intern`) & menghasilkan Bearer token |

## 2. Endpoint Terproteksi (`middleware: auth.api`)

### Autentikasi & Profil
| Method | Endpoint | Sumber Route | Keterangan |
|---|---|---|---|
| `POST` | `/api/logout` | `routes/api.php` | Logout & cabut token aktif |
| `GET` | `/api/profile` | `routes/api.php` | Ambil data profil user & `ui_flags` |
| `POST` | `/api/profile/photo` | `routes/api.php` | Unggah / perbarui foto profil |
| `DELETE` | `/api/profile/photo` | `routes/api.php` | Hapus foto profil |
| `PUT` | `/api/profile/password` | `routes/api.php` | Ubah password akun |

### Presensi GPS & Foto
| Method | Endpoint | Sumber Route | Keterangan |
|---|---|---|---|
| `GET` | `/api/attendance/today` | `routes/api.php` | Status presensi hari ini & geofence kantor |
| `POST` | `/api/attendance/wfh` | `routes/api.php` | Check-in WFH (`attendanceWfaCheckIn`) |
| `POST` | `/api/attendance/wfa` | `routes/api.php` | Check-in WFA (`attendanceWfaCheckIn`) |
| `POST` | `/api/attendance/checkout` | `routes/api.php` | Check-out presensi |
| `GET` | `/api/attendance/history` | `routes/api.php` | Riwayat presensi user per bulan/tahun |
| `POST` | `/api/attendances/location-check-in` | `routes/web.php` | Check-in/out lokasi berbasis `presence_type` (`ON_SITE`, `WFA`, `TUGAS_LUAR`, `AUTO`) |

### Daily Report (Tugas Pagi & Sore)
| Method | Endpoint | Sumber Route | Keterangan |
|---|---|---|---|
| `GET` | `/api/reports/today` | `routes/api.php` | Status laporan harian hari ini |
| `POST` | `/api/reports/morning` | `routes/api.php` | Kirim rencana tugas pagi |
| `POST` | `/api/reports/evening` | `routes/api.php` | Kirim evaluasi & realisasi tugas sore |
| `GET` | `/api/reports/history` | `routes/api.php` | Riwayat laporan harian |

### Perizinan & Dynamic Approval
| Method | Endpoint | Sumber Route | Keterangan |
|---|---|---|---|
| `GET` | `/api/leaves` | `routes/api.php` | Daftar pengajuan izin user |
| `POST` | `/api/leaves` | `routes/api.php` | Ajukan izin baru (`SAKIT`, `IZIN`, `WFA`, `CUTI`, `TUGAS_LUAR`) |
| `GET` | `/api/leaves/approvals` | `routes/api.php` | Daftar pengajuan izin yang perlu disetujui |
| `POST` / `PUT` | `/api/leaves/{leaveRequest}/update` & `/api/leaves/{leaveRequest}` | `routes/api.php` | Perbarui pengajuan izin |
| `DELETE` | `/api/leaves/{leaveRequest}` | `routes/api.php` | Hapus pengajuan izin |
| `POST` | `/api/leaves/{leaveRequest}/action` | `routes/api.php` | Approve / reject pengajuan izin |

### Sanksi & Kedisiplinan
| Method | Endpoint | Sumber Route | Keterangan |
|---|---|---|---|
| `GET` | `/api/sanctions` | `routes/api.php` | Daftar sanksi pegawai |
| `GET` | `/api/sanctions/{employeeSanction}` | `routes/api.php` | Detail sanksi |
| `GET` | `/api/sanctions/{employeeSanction}/download` | `routes/api.php` | Unduh PDF surat sanksi |
