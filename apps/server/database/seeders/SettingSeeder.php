<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Setting::firstOrCreate(['key' => 'app_name'], ['value' => 'Presensi Makerindo']);
        Setting::firstOrCreate(['key' => 'app_slogan'], ['value' => 'Sistem Presensi GPS & Foto Makerindo']);
        Setting::firstOrCreate(['key' => 'app_logo_path'], ['value' => '']);
        Setting::firstOrCreate(['key' => 'work_start_time'], ['value' => '08:00']);
        Setting::firstOrCreate(['key' => 'work_end_time'], ['value' => '17:00']);
        Setting::firstOrCreate(['key' => 'late_tolerance_minutes'], ['value' => '15']);
        Setting::firstOrCreate(['key' => 'overtime_tolerance_minutes'], ['value' => '30']);
        Setting::firstOrCreate(['key' => 'office_name'], ['value' => 'Kantor PT Makerindo Prima Solusi']);
        Setting::firstOrCreate(['key' => 'office_address'], ['value' => 'Kantor PT Makerindo Prima Solusi, Bandung']);
        Setting::firstOrCreate(['key' => 'office_latitude'], ['value' => '-6.20880000']);
        Setting::firstOrCreate(['key' => 'office_longitude'], ['value' => '106.84560000']);
        Setting::firstOrCreate(['key' => 'office_radius_meters'], ['value' => '100']);
    }
}
