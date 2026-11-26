<?php

namespace Database\Seeders;

use App\Models\SanctionRule;
use Illuminate\Database\Seeder;

class SanctionSeeder extends Seeder
{
    public function run(): void
    {
        $rules = [
            [
                'code' => 'LATE-3X',
                'name' => 'Terlambat Masuk > 3 Kali Sebulan',
                'category' => 'DISIPLIN_WAKTU',
                'trigger_type' => 'AUTO_LATE',
                'threshold_count' => 3,
                'default_level' => 'TEGURAN_LISAN',
                'description' => 'Diterbitkan otomatis apabila karyawan tercatat terlambat masuk melebihi 3 kali dalam satu bulan berjalan.',
                'is_active' => true,
            ],
            [
                'code' => 'LATE-5X',
                'name' => 'Terlambat Masuk > 5 Kali Sebulan',
                'category' => 'DISIPLIN_WAKTU',
                'trigger_type' => 'AUTO_LATE',
                'threshold_count' => 5,
                'default_level' => 'SP1',
                'description' => 'Surat Peringatan 1 (SP1) otomatis apabila keterlambatan bulanan melebihi 5 kali.',
                'is_active' => true,
            ],
            [
                'code' => 'ALPHA-2X',
                'name' => 'Alpa Tanpa Keterangan > 1 Hari Sebulan',
                'category' => 'KEHADIRAN',
                'trigger_type' => 'AUTO_ALPHA',
                'threshold_count' => 1,
                'default_level' => 'SP1',
                'description' => 'Peringatan kedisiplinan atas ketidakhadiran tanpa pemberitahuan (Alpa) lebih dari 1 hari kerja.',
                'is_active' => true,
            ],
            [
                'code' => 'TASK-01',
                'name' => 'Kelalaian Pengisian Laporan Tugas Harian (Daily Report)',
                'category' => 'KINERJA_TUGAS',
                'trigger_type' => 'MANUAL',
                'threshold_count' => null,
                'default_level' => 'TEGURAN_LISAN',
                'description' => 'Teguran administratif karena berulang kali tidak melengkapi rencana tugas pagi atau evaluasi tugas sore.',
                'is_active' => true,
            ],
            [
                'code' => 'SOP-01',
                'name' => 'Pelanggaran SOP & Etika Kerja Perusahaan',
                'category' => 'ETIKA_SOP',
                'trigger_type' => 'MANUAL',
                'threshold_count' => null,
                'default_level' => 'SP1',
                'description' => 'Pelanggaran terhadap prosedur operasional standar, tata tertib kantor, atau etika kerja.',
                'is_active' => true,
            ],
            [
                'code' => 'GPS-01',
                'name' => 'Manipulasi Lokasi GPS / Foto Presensi',
                'category' => 'ETIKA_SOP',
                'trigger_type' => 'MANUAL',
                'threshold_count' => null,
                'default_level' => 'SP2',
                'description' => 'Pelanggaran berat integritas presensi berupa penggunaan lokasi palsu (Fake GPS) atau manipulasi foto kehadiran.',
                'is_active' => true,
            ],
        ];

        foreach ($rules as $rule) {
            SanctionRule::updateOrCreate(['code' => $rule['code']], $rule);
        }
    }
}
