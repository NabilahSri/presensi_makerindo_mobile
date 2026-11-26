# API Contract — Mobile REST API (`apps/server/routes/api.php`)

Base URL lokal default: `http://127.0.0.1:8000/api` (atau `http://10.0.2.2:8000/api` pada Android Emulator).

## 1. Endpoint Publik

| Method | Endpoint | Controller | Keterangan |
|---|---|---|---|
| `GET` | `/api/branding` | `MobileApiController@branding` | Branding aplikasi untuk layar mobile |
| `POST` | `/api/login` | `MobileApiController@login` | Login user & menghasilkan Bearer token |

## 2. Endpoint Terproteksi (`middleware: auth.api`)

### Autentikasi & Profil
| Method | Endpoint | Keterangan |
|---|---|---|
| `POST` | `/api/logout` | Logout & cabut token |
| `GET` | `/api/profile` | Ambil data profil user |
| `POST` | `/api/profile/photo` | Unggah / perbarui foto profil |
| `DELETE` | `/api/profile/photo` | Hapus foto profil |
| `PUT` | `/api/profile/password` | Ubah password akun |

### Presensi GPS & Foto
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/api/attendance/today` | Status presensi hari ini |
| `POST` | `/api/attendance/wfh` | Check-in WFH |
| `POST` | `/api/attendance/wfa` | Check-in WFA |
| `POST` | `/api/attendance/checkout` | Check-out presensi |
| `GET` | `/api/attendance/history` | Riwayat presensi user |

### Daily Report (Tugas Pagi & Sore)
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/api/reports/today` | Laporan harian hari ini |
| `POST` | `/api/reports/morning` | Kirim laporan pagi |
| `POST` | `/api/reports/evening` | Kirim laporan sore |
| `GET` | `/api/reports/history` | Riwayat laporan harian |

### Perizinan & Dynamic Approval
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/api/leaves` | Daftar pengajuan izin user |
| `POST` | `/api/leaves` | Ajukan izin baru |
| `GET` | `/api/leaves/approvals` | Daftar izin yang perlu disetujui |
| `POST` / `PUT` | `/api/leaves/{leaveRequest}` | Perbarui pengajuan izin |
| `DELETE` | `/api/leaves/{leaveRequest}` | Hapus pengajuan izin |
| `POST` | `/api/leaves/{leaveRequest}/action` | Approve / reject pengajuan izin |

### Sanksi & Kedisiplinan
| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/api/sanctions` | Daftar sanksi pegawai |
| `GET` | `/api/sanctions/{employeeSanction}` | Detail sanksi |
| `GET` | `/api/sanctions/{employeeSanction}/download` | Unduh dokumen sanksi |
