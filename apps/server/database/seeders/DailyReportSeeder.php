<?php

namespace Database\Seeders;

use App\Models\DailyReport;
use App\Models\User;
use Illuminate\Database\Seeder;

class DailyReportSeeder extends Seeder
{
    public function run(): void
    {
        // Catatan: Hanya menyemai contoh Daily Report pada hari-hari SEBELUM hari ini
        // agar hari ini selalu bersih menunggu karyawan melakukan Presensi Masuk terlebih dahulu.
        $yesterday = now()->subDay()->toDateString();
        $twoDaysAgo = now()->subDays(2)->toDateString();

        $users = User::pluck('id', 'email');

        // 1. Andi Staff (Kemarin & 2 hari lalu: Lengkap Pagi + Sore)
        if (isset($users['karyawan@test.com'])) {
            DailyReport::updateOrCreate(
                ['user_id' => $users['karyawan@test.com'], 'date' => $yesterday],
                [
                    'morning_submitted_at' => '08:02:00',
                    'morning_planned_tasks' => "1. Mengembangkan fitur validasi geofence GPS pada endpoint mobile\n2. Melakukan unit testing unggah foto selfie presensi\n3. Daily standup koordinasi sprint tim",
                    'evening_submitted_at' => '16:45:00',
                    'evening_completed_tasks' => "1. Mengembangkan fitur validasi geofence GPS pada endpoint mobile (Selesai 100%)\n3. Daily standup koordinasi sprint tim (Selesai)",
                    'evening_pending_tasks' => "2. Melakukan unit testing unggah foto selfie presensi (Tersisa 3 test case, dilanjutkan besok)",
                    'evening_additional_tasks' => "1. Optimasi kompresi gambar selfie pada aplikasi mobile",
                    'status' => 'COMPLETED',
                ]
            );

            DailyReport::updateOrCreate(
                ['user_id' => $users['karyawan@test.com'], 'date' => $twoDaysAgo],
                [
                    'morning_submitted_at' => '08:05:00',
                    'morning_planned_tasks' => "1. Setup migrasi tabel daily reports\n2. Penyempurnaan alur pengajuan cuti dan tugas luar",
                    'evening_submitted_at' => '17:00:00',
                    'evening_completed_tasks' => "1. Setup migrasi tabel daily reports (Selesai)\n2. Penyempurnaan alur pengajuan cuti dan tugas luar (Selesai)",
                    'evening_pending_tasks' => null,
                    'evening_additional_tasks' => "1. Koordinasi teknis skema relasi user dan presensi",
                    'status' => 'COMPLETED',
                ]
            );
        }

        // 2. Dewi Anastasia (Kemarin: Lengkap Pagi + Sore)
        if (isset($users['dewi@makerindo.id'])) {
            DailyReport::updateOrCreate(
                ['user_id' => $users['dewi@makerindo.id'], 'date' => $yesterday],
                [
                    'morning_submitted_at' => '08:12:00',
                    'morning_planned_tasks' => "1. Pengujian akurasi koordinat GPS di area kantor Bandung\n2. Dokumentasi alur presensi masuk dan pulang via aplikasi mobile\n3. Verifikasi data profil karyawan baru",
                    'evening_submitted_at' => '16:55:00',
                    'evening_completed_tasks' => "1. Pengujian akurasi koordinat GPS di area kantor Bandung (Normal)\n2. Dokumentasi alur presensi masuk dan pulang via aplikasi mobile (Selesai)",
                    'evening_pending_tasks' => "3. Verifikasi data profil karyawan baru (Menunggu konfirmasi email staf)",
                    'evening_additional_tasks' => "1. Kalibrasi radius geofence kantor menjadi 100 meter",
                    'status' => 'COMPLETED',
                ]
            );
        }

        // 3. Dimas Setiawan (Kemarin: Lengkap Pagi + Sore)
        if (isset($users['dimas@makerindo.id'])) {
            DailyReport::updateOrCreate(
                ['user_id' => $users['dimas@makerindo.id'], 'date' => $yesterday],
                [
                    'morning_submitted_at' => '08:15:00',
                    'morning_planned_tasks' => "1. Pengujian akses kamera depan pada perangkat Android & iOS\n2. Uji coba respons API presensi GPS dan unggah bukti foto",
                    'evening_submitted_at' => '17:05:00',
                    'evening_completed_tasks' => "1. Pengujian akses kamera depan pada perangkat Android & iOS (Selesai)\n2. Uji coba respons API presensi GPS dan unggah bukti foto (Rata-rata 180ms, stabil)",
                    'evening_pending_tasks' => null,
                    'evening_additional_tasks' => "1. Dokumentasi panduan instalasi APK internal untuk tim",
                    'status' => 'COMPLETED',
                ]
            );
        }

        // 4. Budi Supervisor (Kemarin: Lengkap Pagi + Sore)
        if (isset($users['manager@test.com'])) {
            DailyReport::updateOrCreate(
                ['user_id' => $users['manager@test.com'], 'date' => $yesterday],
                [
                    'morning_submitted_at' => '08:01:00',
                    'morning_planned_tasks' => "1. Review dan verifikasi permohonan cuti tahunan & WFA divisi\n2. Evaluasi rekapitulasi keterlambatan presensi mingguan\n3. Meeting 1-on-1 dengan personil magang",
                    'evening_submitted_at' => '16:50:00',
                    'evening_completed_tasks' => "1. Review dan verifikasi permohonan cuti tahunan & WFA divisi (Semua permohonan selesai diproses)\n3. Meeting 1-on-1 dengan personil magang (Selesai)",
                    'evening_pending_tasks' => "2. Evaluasi keterlambatan mingguan (Menunggu rekapitulasi audit HRD)",
                    'evening_additional_tasks' => "1. Sosialisasi SOP presensi GPS & Foto kepada divisi operasional",
                    'status' => 'COMPLETED',
                ]
            );
        }

        // 5. Fajar Nugraha (Kemarin: Baru Pagi / MORNING_ONLY)
        if (isset($users['fajar@makerindo.id'])) {
            DailyReport::updateOrCreate(
                ['user_id' => $users['fajar@makerindo.id'], 'date' => $yesterday],
                [
                    'morning_submitted_at' => '08:25:00',
                    'morning_planned_tasks' => "1. Optimasi query rekapitulasi presensi & export laporan excel\n2. Review code pull request modul persetujuan cuti\n3. Benchmarking response time server lokal",
                    'evening_submitted_at' => null,
                    'evening_completed_tasks' => null,
                    'evening_pending_tasks' => null,
                    'evening_additional_tasks' => null,
                    'status' => 'MORNING_ONLY',
                ]
            );
        }

        // 6. Rian Intern (Kemarin: Lengkap Pagi + Sore)
        if (isset($users['intern@test.com'])) {
            DailyReport::updateOrCreate(
                ['user_id' => $users['intern@test.com'], 'date' => $yesterday],
                [
                    'morning_submitted_at' => '08:05:00',
                    'morning_planned_tasks' => "1. Mempelajari dokumentasi framework Laravel 12 & Tailwind CSS\n2. Merapikan form-form agar full-width sesuai standar Presensi Makerindo\n3. Membantu QA testing alur pengajuan WFA",
                    'evening_submitted_at' => '16:40:00',
                    'evening_completed_tasks' => "1. Mempelajari dokumentasi framework Laravel 12 & Tailwind CSS (Selesai)\n2. Merapikan form-form agar full-width sesuai standar Presensi Makerindo (Selesai)\n3. Membantu QA testing alur pengajuan WFA (Selesai)",
                    'evening_pending_tasks' => null,
                    'evening_additional_tasks' => null,
                    'status' => 'COMPLETED',
                ]
            );
        }
    }
}
