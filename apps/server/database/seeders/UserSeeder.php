<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roleSuperAdmin = Role::where('name', 'super_admin')->first();
        $roleCEO = Role::where('name', 'ceo')->first();
        $roleKaryawan = Role::where('name', 'karyawan')->first();
        $roleIntern = Role::where('name', 'intern')->first();

        // Password Default Sama Semua untuk Testing: "password"
        $defaultPassword = Hash::make('password');

        // 1. Akun Super Admin
        $admin = User::create([
            'name' => 'Super Admin Dev',
            'email' => 'admin@test.com',
            'password' => $defaultPassword,
            'employment_type' => 'KARTAP',
            'can_approve_leaves' => true,
        ]);
        if ($roleSuperAdmin) {
            $admin->roles()->attach([$roleSuperAdmin->id]);
        }

        // 2. Akun CEO
        $ceo = User::create([
            'name' => 'Bapak CEO',
            'email' => 'ceo@test.com',
            'password' => $defaultPassword,
            'employment_type' => 'KARTAP',
            'can_approve_leaves' => false,
        ]);
        if ($roleCEO) {
            $ceo->roles()->attach([$roleCEO->id]);
        }

        // 3. Akun Karyawan Senior (Diberi Hak Approval Perizinan)
        $manager = User::create([
            'name' => 'Budi Supervisor',
            'email' => 'manager@test.com',
            'password' => $defaultPassword,
            'employment_type' => 'KARTAP',
            'can_approve_leaves' => true,
        ]);
        if ($roleKaryawan) {
            $manager->roles()->attach([$roleKaryawan->id]);
        }

        // 4. Akun Karyawan Regular (PKWT)
        $karyawan = User::create([
            'name' => 'Andi Staff',
            'email' => 'karyawan@test.com',
            'password' => $defaultPassword,
            'employment_type' => 'PKWT',
            'can_approve_leaves' => false,
        ]);
        if ($roleKaryawan) {
            $karyawan->roles()->attach([$roleKaryawan->id]);
        }

        // 5. Akun Anak Magang / Intern
        $intern = User::create([
            'name' => 'Rian Intern',
            'email' => 'intern@test.com',
            'password' => $defaultPassword,
            'employment_type' => 'INTERN',
            'can_approve_leaves' => false,
        ]);
        if ($roleIntern) {
            $intern->roles()->attach([$roleIntern->id]);
        }

        // 6. Karyawan Tambahan untuk Tampilan Realistis Presensi Makerindo
        $engineer = User::create([
            'name' => 'Dewi Anastasia',
            'email' => 'dewi@makerindo.id',
            'password' => $defaultPassword,
            'employment_type' => 'PKWT',
            'can_approve_leaves' => false,
        ]);
        if ($roleKaryawan) {
            $engineer->roles()->attach([$roleKaryawan->id]);
        }

        $designer = User::create([
            'name' => 'Fajar Nugraha',
            'email' => 'fajar@makerindo.id',
            'password' => $defaultPassword,
            'employment_type' => 'PKWT',
            'can_approve_leaves' => false,
        ]);
        if ($roleKaryawan) {
            $designer->roles()->attach([$roleKaryawan->id]);
        }

        $hrTalent = User::create([
            'name' => 'Maya Kartika',
            'email' => 'maya@makerindo.id',
            'password' => $defaultPassword,
            'employment_type' => 'KARTAP',
            'can_approve_leaves' => true,
        ]);
        if ($roleKaryawan) {
            $hrTalent->roles()->attach([$roleKaryawan->id]);
        }

        $internMobile = User::create([
            'name' => 'Dimas Setiawan',
            'email' => 'dimas@makerindo.id',
            'password' => $defaultPassword,
            'employment_type' => 'INTERN',
            'can_approve_leaves' => false,
        ]);
        if ($roleIntern) {
            $internMobile->roles()->attach([$roleIntern->id]);
        }
    }
}
