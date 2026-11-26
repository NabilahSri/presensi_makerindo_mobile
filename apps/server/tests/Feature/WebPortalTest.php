<?php

namespace Tests\Feature;

use App\Models\LeaveRequest;
use App\Models\Role;
use App\Models\Setting;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class WebPortalTest extends TestCase
{
    use DatabaseTransactions;

    public function test_super_admin_can_login_and_access_admin_portal(): void
    {
        $response = $this->post('/login', [
            'email' => 'admin@test.com',
            'password' => 'password',
        ]);

        $response->assertRedirect(route('admin.dashboard'));

        $user = User::where('email', 'admin@test.com')->first();
        $this->actingAs($user)->get(route('admin.dashboard'))->assertOk();
        $this->actingAs($user)->get(route('admin.users.index'))->assertOk();
        $this->actingAs($user)->get(route('admin.attendances.index'))->assertOk();
        $this->actingAs($user)->get(route('admin.settings.index'))->assertOk();
        $this->actingAs($user)->get(route('sanctions.index'))->assertOk();
    }

    public function test_ceo_can_login_and_access_executive_dashboard(): void
    {
        $response = $this->post('/login', [
            'email' => 'ceo@test.com',
            'password' => 'password',
        ]);

        $response->assertRedirect(route('executive.dashboard'));

        $user = User::where('email', 'ceo@test.com')->first();
        $this->assertFalse($user->isAttendanceRequired());

        $dashboardResponse = $this->actingAs($user)->get(route('executive.dashboard'));
        $dashboardResponse->assertOk();
        $dashboardResponse->assertSee('Mode Pengawasan Eksekutif', false);
        $dashboardResponse->assertSee('Tren Kehadiran &amp; Kedisiplinan 6 Bulan Terakhir', false);
        $dashboardResponse->assertSee('Kedisiplinan Tepat Waktu', false);
        $dashboardResponse->assertSee('Rasio Penyelesaian Tugas', false);
        $dashboardResponse->assertViewHas('recentAttendances', function ($recent) {
            $today = now()->toDateString();

            return $recent->getCollection()->every(
                fn ($att) => Carbon::parse($att->date)->toDateString() === $today
            );
        });

        // CEO dapat mengakses seluruh laporan komprehensif dan bebas kewajiban laporan tugas harian
        $dailyTaskResponse = $this->actingAs($user)->get(route('reports.daily-tasks'));
        $dailyTaskResponse->assertOk();
        $dailyTaskResponse->assertViewHas('users', function ($users) {
            return ! $users->pluck('email')->contains('ceo@test.com');
        });
    }

    public function test_karyawan_and_intern_are_denied_web_access_even_with_approval_flag(): void
    {
        foreach (['karyawan@test.com', 'intern@test.com', 'manager@test.com'] as $email) {
            $response = $this->post('/login', [
                'email' => $email,
                'password' => 'password',
            ]);

            $response->assertSessionHasErrors('email');
            $this->assertGuest();
        }
    }

    public function test_web_role_with_approval_permission_can_access_approvals(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $this->actingAs($admin)->get(route('approval.index'))->assertOk();
    }

    public function test_approver_can_approve_leave_and_auto_generate_attendances(): void
    {
        $approver = User::where('email', 'manager@test.com')->first();
        $employee = User::where('email', 'karyawan@test.com')->first();

        $leave = LeaveRequest::create([
            'user_id' => $employee->id,
            'type' => 'SAKIT',
            'start_date' => '2026-10-20',
            'end_date' => '2026-10-21',
            'reason' => 'Demam tinggi',
            'status' => 'PENDING',
        ]);

        $this->actingAs($approver)
            ->patch(route('approval.approve', $leave))
            ->assertRedirect();

        $this->assertDatabaseHas('leave_requests', [
            'id' => $leave->id,
            'status' => 'APPROVED',
            'approved_by' => $approver->id,
        ]);

        $this->assertDatabaseHas('attendances', [
            'user_id' => $employee->id,
            'date' => '2026-10-20',
            'status' => 'SAKIT',
        ]);

        $this->assertDatabaseHas('attendances', [
            'user_id' => $employee->id,
            'date' => '2026-10-21',
            'status' => 'SAKIT',
        ]);
    }

    public function test_admin_can_create_and_update_user_with_roles(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $role = Role::first();

        // 1. Create employee
        $createResponse = $this->actingAs($admin)->post(route('admin.users.store'), [
            'name' => 'Budi Santoso',
            'email' => 'budi.santoso@example.com',
            'password' => 'secret123',
            'employment_type' => 'KARTAP',
            'can_approve_leaves' => 1,
            'roles' => [$role->id],
        ]);

        $createResponse->assertRedirect(route('admin.users.index'));
        $createdUser = User::where('email', 'budi.santoso@example.com')->first();
        $this->assertNotNull($createdUser);
        $this->assertTrue($createdUser->roles->contains('id', $role->id));
        $this->assertTrue((bool) $createdUser->can_approve_leaves);

        // 2. Update employee
        $updateResponse = $this->actingAs($admin)->put(route('admin.users.update', $createdUser), [
            'name' => 'Budi Santoso Updated',
            'email' => 'budi.santoso@example.com',
            'employment_type' => 'PKWT',
            'can_approve_leaves' => 0,
            'roles' => [$role->id],
        ]);

        $updateResponse->assertRedirect(route('admin.users.index'));
        $createdUser->refresh();
        $this->assertEquals('Budi Santoso Updated', $createdUser->name);
        $this->assertEquals('PKWT', $createdUser->employment_type);
        $this->assertFalse((bool) $createdUser->can_approve_leaves);
        $this->assertTrue($createdUser->roles->contains('id', $role->id));
    }

    public function test_admin_can_dynamically_update_app_name_slogan_and_logo_in_settings(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $this->actingAs($admin)->put(route('admin.settings.update'), [
            'app_name' => 'Presensi Nusantara',
            'app_slogan' => 'Solusi Presensi GPS & Foto Modern',
            'late_tolerance_minutes' => 15,
            'overtime_tolerance_minutes' => 30,
            'office_name' => 'Kantor Pusat Nusantara',
            'office_address' => 'Jl. Jend. Sudirman Kav. 52',
            'office_latitude' => -6.2088,
            'office_longitude' => 106.8456,
            'office_radius_meters' => 100,
        ])->assertRedirect();

        $this->assertDatabaseHas('settings', ['key' => 'app_name', 'value' => 'Presensi Nusantara']);
        $this->assertDatabaseHas('settings', ['key' => 'app_slogan', 'value' => 'Solusi Presensi GPS & Foto Modern']);

        // Pastikan nama aplikasi dan slogan baru otomatis tampil di sidebar dasbor & halaman pengaturan
        $dashboard = $this->actingAs($admin)->get(route('admin.dashboard'));
        $dashboard->assertOk();
        $dashboard->assertSee('Presensi Nusantara', false);
        $dashboard->assertSee('Solusi Presensi GPS &amp; Foto Modern', false);
    }

    public function test_web_user_can_upload_and_remove_profile_photo(): void
    {
        Storage::fake('public');

        $admin = User::where('email', 'admin@test.com')->first();

        // 1. Unggah foto profil via halaman /profile
        $uploadRes = $this->actingAs($admin)->put(route('profile.update'), [
            'name' => $admin->name,
            'email' => $admin->email,
            'profile_photo' => UploadedFile::fake()->image('admin-avatar.jpg', 250, 250),
        ]);

        $uploadRes->assertRedirect();
        $admin->refresh();
        $this->assertNotNull($admin->profile_photo_path);
        Storage::disk('public')->assertExists($admin->profile_photo_path);

        // Pastikan foto tampil di halaman profil, header, dan daftar karyawan
        $page = $this->actingAs($admin)->get(route('profile.edit'));
        $page->assertOk();
        $page->assertSee($admin->profile_photo_url, false);

        $usersPage = $this->actingAs($admin)->get(route('admin.users.index'));
        $usersPage->assertOk();
        $usersPage->assertSee($admin->profile_photo_url, false);

        // 2. Ubah foto karyawan lewat Kelola Karyawan (/admin/users/{id})
        $employee = User::where('email', 'karyawan@test.com')->first();
        $empRoleIds = $employee->roles()->pluck('roles.id')->toArray();
        $empUploadRes = $this->actingAs($admin)->put(route('admin.users.update', $employee), [
            'name' => $employee->name,
            'email' => $employee->email,
            'employment_type' => $employee->employment_type,
            'roles' => $empRoleIds,
            'profile_photo' => UploadedFile::fake()->image('emp-avatar.png', 250, 250),
        ]);
        $empUploadRes->assertRedirect(route('admin.users.index'));
        $employee->refresh();
        $this->assertNotNull($employee->profile_photo_path);
        Storage::disk('public')->assertExists($employee->profile_photo_path);

        // 3. Hapus foto profil via checkbox remove_profile_photo
        $oldPath = $admin->profile_photo_path;
        $removeRes = $this->actingAs($admin)->put(route('profile.update'), [
            'name' => $admin->name,
            'email' => $admin->email,
            'remove_profile_photo' => '1',
        ]);

        $removeRes->assertRedirect();
        $admin->refresh();
        $this->assertNull($admin->profile_photo_path);
        Storage::disk('public')->assertMissing($oldPath);
    }

    public function test_web_approval_and_daily_task_authorization_guards(): void
    {
        $ceo = User::where('email', 'ceo@test.com')->first();
        $ceo->update(['can_approve_leaves' => false]);
        $admin = User::where('email', 'admin@test.com')->first();
        $employee = User::where('email', 'karyawan@test.com')->first();

        $leave = LeaveRequest::create([
            'user_id' => $employee->id,
            'type' => 'IZIN',
            'start_date' => '2026-12-20',
            'end_date' => '2026-12-20',
            'reason' => 'Uji otorisasi approval web',
            'status' => 'PENDING',
        ]);

        // 1. CEO tanpa can_approve_leaves ditolak (403) pada /approvals & aksi approve/reject
        $this->actingAs($ceo)->get(route('approval.index'))->assertForbidden();
        $this->actingAs($ceo)->patch(route('approval.approve', $leave))->assertForbidden();
        $this->actingAs($ceo)->patch(route('approval.reject', $leave), ['rejection_reason' => 'Coba tolak'])->assertForbidden();

        // 2. CEO ditolak (403) melakukan write pada /reports/daily-tasks
        $this->actingAs($ceo)->post(route('reports.daily-tasks.store'), [
            'user_id' => $employee->id,
            'date' => '2026-12-20',
            'morning_planned_tasks' => 'Coba isi CEO',
        ])->assertForbidden();

        // 3. Approver tidak dapat menyetujui pengajuan miliknya sendiri (403)
        $selfLeave = LeaveRequest::create([
            'user_id' => $admin->id,
            'type' => 'IZIN',
            'start_date' => '2026-12-21',
            'end_date' => '2026-12-21',
            'reason' => 'Izin milik admin sendiri',
            'status' => 'PENDING',
        ]);
        $this->actingAs($admin)->patch(route('approval.approve', $selfLeave))->assertForbidden();

        // 4. Pengajuan yang sudah APPROVED tidak dapat ditimpa menjadi REJECTED
        $this->actingAs($admin)->patch(route('approval.approve', $leave))->assertRedirect();
        $this->actingAs($admin)->patch(route('approval.reject', $leave), ['rejection_reason' => 'Timpa status'])->assertRedirect();
        $this->assertEquals('APPROVED', $leave->fresh()->status);

        // 5. SettingController menolak SVG berbahaya yang mengandung <script>
        $maliciousSvg = UploadedFile::fake()->createWithContent(
            'xss.svg',
            '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script><circle cx="10" cy="10" r="5"/></svg>'
        );
        $svgRes = $this->actingAs($admin)->put(route('admin.settings.update'), [
            'late_tolerance_minutes' => 15,
            'overtime_tolerance_minutes' => 30,
            'app_logo' => $maliciousSvg,
        ]);
        $svgRes->assertRedirect();
        $savedPath = Setting::getValue('app_logo_path', '');
        $this->assertNotEmpty($savedPath);
        $fullLogoPath = public_path($savedPath);
        $this->assertFileExists($fullLogoPath);
        $this->assertStringNotContainsString('<script', strtolower((string) file_get_contents($fullLogoPath)));
        @unlink($fullLogoPath);

        // 6. SanctionRule store menormalkan kode ke uppercase sebelum cek unik & mewajibkan threshold pada AUTO_LATE
        $this->actingAs($admin)->post(route('sanctions.rules.store'), [
            'code' => 'auto-late-dup',
            'name' => 'Test Case Sensitive Rule',
            'category' => 'DISIPLIN_WAKTU',
            'trigger_type' => 'AUTO_LATE',
            'threshold_count' => 4,
            'default_level' => 'TEGURAN_LISAN',
        ])->assertRedirect();

        $this->actingAs($admin)->post(route('sanctions.rules.store'), [
            'code' => 'AUTO-LATE-DUP',
            'name' => 'Duplikat Kapital',
            'category' => 'DISIPLIN_WAKTU',
            'trigger_type' => 'AUTO_LATE',
            'threshold_count' => 4,
            'default_level' => 'TEGURAN_LISAN',
        ])->assertSessionHasErrors('code');
    }
}
