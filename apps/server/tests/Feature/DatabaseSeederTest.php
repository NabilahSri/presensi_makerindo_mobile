<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class DatabaseSeederTest extends TestCase
{
    use DatabaseTransactions;

    public function test_database_seeder_has_all_modular_data_present(): void
    {
        // Verify Roles
        $this->assertDatabaseHas('roles', ['name' => 'super_admin']);
        $this->assertDatabaseHas('roles', ['name' => 'ceo']);
        $this->assertDatabaseHas('roles', ['name' => 'karyawan']);
        $this->assertDatabaseHas('roles', ['name' => 'intern']);
        $this->assertDatabaseMissing('roles', ['name' => 'finance']);

        // Verify Settings
        $this->assertDatabaseHas('settings', ['key' => 'late_tolerance_minutes', 'value' => '15']);
        $this->assertDatabaseHas('settings', ['key' => 'overtime_tolerance_minutes', 'value' => '30']);
        $this->assertDatabaseHas('settings', ['key' => 'office_radius_meters']);

        // Verify Users & Role associations
        $admin = User::where('email', 'admin@test.com')->first();
        $this->assertNotNull($admin);
        $this->assertTrue($admin->hasRole('super_admin'));
        $this->assertTrue((bool) $admin->can_approve_leaves);

        $karyawan = User::where('email', 'karyawan@test.com')->first();
        $this->assertNotNull($karyawan);
        $this->assertTrue($karyawan->hasRole('karyawan'));

        $intern = User::where('email', 'intern@test.com')->first();
        $this->assertNotNull($intern);
        $this->assertTrue($intern->hasRole('intern'));
    }
}
