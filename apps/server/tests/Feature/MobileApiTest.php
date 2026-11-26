<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\DailyReport;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MobileApiTest extends TestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();

        // Pastikan fixture manager@test.com selalu memiliki hak persetujuan di dalam transaksi test
        User::where('email', 'manager@test.com')->update(['can_approve_leaves' => true]);
    }

    public function test_mobile_login_profile_password_and_logout_flow(): void
    {
        // 1. Login sebagai Karyawan PKWT
        $loginResponse = $this->postJson('/api/login', [
            'email' => 'karyawan@test.com',
            'password' => 'password',
            'device_name' => 'Flutter-Android',
        ]);

        $loginResponse->assertOk()
            ->assertJsonStructure([
                'success',
                'access_token',
                'token_type',
                'user' => [
                    'id',
                    'name',
                    'email',
                    'employment_type',
                    'can_approve_leaves',
                    'roles',
                    'ui_flags',
                ],
            ]);

        $token = $loginResponse->json('access_token');
        $this->assertNotEmpty($token);
        $this->assertEquals('PKWT', $loginResponse->json('user.employment_type'));
        $this->assertEquals('GPS_PHOTO', $loginResponse->json('user.ui_flags.primary_attendance_mode'));

        // 2. Get Profile dengan Bearer Token
        $profileResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/profile');

        $profileResponse->assertOk()
            ->assertJsonPath('data.email', 'karyawan@test.com');

        // 3. Update Password
        $pwdResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/profile/password', [
                'current_password' => 'password',
                'password' => 'newsecret123',
                'password_confirmation' => 'newsecret123',
            ]);

        $pwdResponse->assertOk()
            ->assertJsonPath('success', true);

        // 4. Logout menghapus token
        $logoutResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/logout');

        $logoutResponse->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_mobile_attendance_daily_report_and_checkout_gate_flow(): void
    {
        Storage::fake('public');

        $intern = User::where('employment_type', 'INTERN')->first();
        $today = now()->toDateString();

        Attendance::where('user_id', $intern->id)->whereDate('date', $today)->delete();
        DailyReport::where('user_id', $intern->id)->whereDate('date', $today)->delete();

        $token = $intern->createToken('flutter-test')->plainTextToken;

        // 1. Cek status absensi hari ini sebelum check-in
        $todayRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/attendance/today');

        $todayRes->assertOk()
            ->assertJsonPath('has_checked_in', false)
            ->assertJsonPath('can_checkout', false);

        // 2. Check-in WFH/WFA dengan unggah foto wajah + GPS
        $checkInRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'face_image' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $checkInRes->assertStatus(201)
            ->assertJsonPath('success', true);

        // 3. Kirim rencana tugas pagi (Daily Report Morning)
        $morningRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports/morning', [
                'morning_planned_tasks' => "1. Integrasi halaman Home Flutter\n2. Uji endpoint presensi WFA",
            ]);

        $morningRes->assertStatus(201)
            ->assertJsonPath('data.status', 'MORNING_ONLY');

        // 4. Coba Checkout SEBELUM evaluasi sore selesai -> Harus ditolak (422)
        $earlyCheckoutRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/attendance/checkout');

        $earlyCheckoutRes->assertStatus(422)
            ->assertJsonPath('daily_report_status', 'MORNING_ONLY');

        // 5. Ambil rencana tugas pagi dari /api/reports/today
        $reportTodayRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports/today');

        $reportTodayRes->assertOk()
            ->assertJsonPath('has_submitted_morning', true)
            ->assertJsonPath('is_completed', false);

        // 6. Kirim evaluasi tugas sore (Daily Report Evening -> COMPLETED)
        $eveningRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports/evening', [
                'evening_completed_tasks' => '1. Integrasi halaman Home Flutter (Selesai)',
                'evening_pending_tasks' => '2. Uji endpoint presensi WFA (Dilanjutkan besok)',
                'evening_additional_tasks' => 'Perbaikan tata letak kartu profil',
            ]);

        $eveningRes->assertOk()
            ->assertJsonPath('data.status', 'COMPLETED')
            ->assertJsonPath('can_checkout', true);

        // 7. Checkout setelah DailyReport COMPLETED -> Berhasil (200 OK) dengan lokasi & foto selfie
        $checkoutRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/attendance/checkout', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'face_image' => UploadedFile::fake()->image('selfie_out.jpg'),
            ]);

        $checkoutRes->assertOk()
            ->assertJsonPath('success', true);

        $this->assertNotNull($checkoutRes->json('attendance.time_out'));
        $this->assertNotEmpty($checkoutRes->json('attendance.checkout_face_image_url'));

        // 8. Cek riwayat presensi & laporan tugas (pastikan format tanggal Y-m-d tanpa pergeseran UTC)
        $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/attendance/history')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.date', $today);

        $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports/history')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.date', $today);
    }

    public function test_mobile_leave_submission_and_dynamic_approval_flow(): void
    {
        $employee = User::where('email', 'karyawan@test.com')->first();
        $approver = User::where('email', 'manager@test.com')->first();

        $empToken = $employee->createToken('emp-mobile')->plainTextToken;
        $mgrToken = $approver->createToken('mgr-mobile')->plainTextToken;

        // 1. Karyawan biasa tidak berhak mengakses /api/leaves/approvals (403)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/leaves/approvals')
            ->assertStatus(403);

        // 2. Karyawan mengajukan WFH/WFA minimal H-1 lewat aplikasi mobile
        $tomorrow = now()->addDay()->toDateString();
        $dayAfter = now()->addDays(2)->toDateString();
        $submitLeaveRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'WFH',
                'start_date' => $tomorrow,
                'end_date' => $dayAfter,
                'reason' => 'Koordinasi proyek dari rumah',
            ]);

        $submitLeaveRes->assertStatus(201)
            ->assertJsonPath('data.type', 'WFA')
            ->assertJsonPath('data.status', 'PENDING');

        $leaveId = $submitLeaveRes->json('data.id');

        // 3. Approver melihat daftar pengajuan PENDING dan menyetujuinya via HP
        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->getJson('/api/leaves/approvals')
            ->assertOk()
            ->assertJsonPath('success', true);

        $approveRes = $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson("/api/leaves/{$leaveId}/action", [
                'status' => 'APPROVED',
            ]);

        $approveRes->assertOk()
            ->assertJsonPath('data.status', 'APPROVED');

        // Pastikan tabel attendances terisi otomatis untuk tanggal tersebut
        $this->assertDatabaseHas('attendances', [
            'user_id' => $employee->id,
            'date' => $tomorrow,
            'status' => 'WFA',
        ]);
    }

    public function test_hybrid_sanction_rules_auto_late_detection_and_mobile_api(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $employee = User::where('email', 'karyawan@test.com')->first();

        // 1. Admin menambah aturan pelanggaran administratif baru
        $this->actingAs($admin)->post(route('sanctions.rules.store'), [
            'code' => 'LATE-TEST-3X',
            'name' => 'Terlambat Masuk > 3 Kali Sebulan (Uji)',
            'category' => 'DISIPLIN_WAKTU',
            'trigger_type' => 'AUTO_LATE',
            'threshold_count' => 3,
            'default_level' => 'SP1',
            'description' => 'Aturan uji keterlambatan > 3 kali',
            'is_active' => 1,
        ])->assertRedirect();

        // 2. Buat 4 catatan terlambat untuk karyawan pada bulan Desember 2026 (> 3 kali)
        for ($d = 1; $d <= 4; $d++) {
            Attendance::create([
                'user_id' => $employee->id,
                'date' => sprintf('2026-12-%02d', $d),
                'time_in' => '08:40:00',
                'time_out' => '17:05:00',
                'status' => 'HADIR_ON_SITE',
                'method' => 'FACIAL_LOCATION',
                'is_late' => true,
                'overtime_hours' => 0,
            ]);
        }

        // 3. Jalankan deteksi otomatis sanksi untuk periode 12/2026
        $this->actingAs($admin)->post(route('sanctions.detect'), [
            'month' => 12,
            'year' => 2026,
        ])->assertRedirect();

        $this->assertDatabaseHas('employee_sanctions', [
            'user_id' => $employee->id,
            'month' => 12,
            'year' => 2026,
            'source' => 'AUTO_DETECTED',
            'status' => 'ACTIVE',
        ]);

        // 4. Pastikan halaman web /sanctions dapat dirender dengan normal (200 OK)
        $this->actingAs($admin)->get(route('sanctions.index', ['month' => 12, 'year' => 2026]))
            ->assertOk()
            ->assertSee('Manajemen Sanksi & Aturan Kedisiplinan');

        // 5. Karyawan mengecek sanksi miliknya lewat Mobile API (/api/sanctions)
        $empToken = $employee->createToken('emp-sanction-test')->plainTextToken;

        $sanctionsRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/sanctions');

        $sanctionsRes->assertOk()
            ->assertJsonPath('success', true);
        $this->assertGreaterThanOrEqual(1, $sanctionsRes->json('summary.active_sanctions'));

        // 6. Uji unduh PDF Surat Peringatan (SP) di Web & Mobile API
        $sanctionRecord = \App\Models\EmployeeSanction::where('user_id', $employee->id)->first();
        $this->actingAs($admin)->get(route('sanctions.pdf', $sanctionRecord->id))
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->get("/api/sanctions/{$sanctionRecord->id}/download")
            ->assertOk();
    }

    public function test_holidays_calendar_and_attendance_override(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $employee = User::where('email', 'karyawan@test.com')->first();

        // 1. Uji Kalender Hari Libur Nasional & Perhitungan Hari Kerja Efektif
        $this->actingAs($admin)->post(route('admin.settings.holidays.store'), [
            'date' => '2026-11-18',
            'name' => 'Hari Libur Uji Sistem',
            'type' => 'NASIONAL',
        ])->assertRedirect();

        $effectiveDays = \App\Models\Holiday::calculateEffectiveWorkingDays(11, 2026);
        $this->assertEquals(20, $effectiveDays); // Nov 2026 has 21 weekdays minus 1 holiday on Wed Nov 18 = 20

        // 2. Uji Koreksi / Input Presensi Manual oleh Super Admin
        $this->actingAs($admin)->post(route('admin.attendances.override'), [
            'user_id' => $employee->id,
            'date' => '2026-11-10',
            'status' => 'HADIR_ON_SITE',
            'time_in' => '07:55',
            'time_out' => '18:00',
            'is_late' => 0,
            'overtime_hours' => 1,
        ])->assertRedirect();

        $this->assertDatabaseHas('attendances', [
            'user_id' => $employee->id,
            'date' => '2026-11-10',
            'overtime_hours' => 1,
        ]);
    }

    public function test_mobile_api_edge_cases_and_security_guards(): void
    {
        Storage::fake('public');

        $employee = User::where('email', 'karyawan@test.com')->first();
        $approver = User::where('email', 'manager@test.com')->first();
        $today = now()->toDateString();

        Attendance::where('user_id', $employee->id)->whereDate('date', $today)->delete();
        DailyReport::where('user_id', $employee->id)->whereDate('date', $today)->delete();

        $empToken = $employee->createToken('emp-edge')->plainTextToken;
        $mgrToken = $approver->createToken('mgr-edge')->plainTextToken;

        // 1. Morning & Evening report ditolak (422) jika belum check-in hari ini
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/reports/morning', [
                'morning_planned_tasks' => 'Tugas sebelum absen',
            ])
            ->assertStatus(422);

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/reports/evening', [
                'evening_completed_tasks' => 'Evaluasi sebelum absen',
            ])
            ->assertStatus(422);

        // Jika ada data report yatim hari ini tanpa presensi masuk, API tetap mengunci status report
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('has_checked_in', false)
            ->assertJsonPath('daily_report.has_morning_report', false)
            ->assertJsonPath('daily_report.has_evening_report', false);

        // 2. Check-in WFH tanpa face_image ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('face_image');

        // 3. Izin WFH (diajukan H-1) disetujui untuk hari ini (membuat row attendance tanpa time_in),
        //    lalu karyawan melakukan Mobile Check-In -> WAJIB mencatat time_in (bukan time_out)
        $this->travel(-1)->days();
        $leaveRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->post('/api/leaves', [
                'type' => 'WFH',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'WFH hari ini',
                'attachment' => UploadedFile::fake()->image('bukti.jpg'),
            ], ['Accept' => 'application/json']);
        $this->travelBack();

        $leaveRes->assertStatus(201);
        $this->assertNotEmpty($leaveRes->json('data.attachment_url'));
        $leaveId = $leaveRes->json('data.id');

        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson("/api/leaves/{$leaveId}/action", ['status' => 'APPROVED'])
            ->assertOk();

        // Double action pada pengajuan yang sudah APPROVED ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson("/api/leaves/{$leaveId}/action", [
                'status' => 'REJECTED',
                'rejection_reason' => 'Coba ubah ulang',
            ])
            ->assertStatus(422);

        // Riwayat approval berdasarkan filter status=APPROVED dapat diakses
        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->getJson('/api/leaves/approvals?status=APPROVED')
            ->assertOk()
            ->assertJsonPath('filter_status', 'APPROVED');

        // Self-approval ditolak (403)
        $tomorrow = now()->addDay()->toDateString();
        $mgrLeaveRes = $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson('/api/leaves', [
                'type' => 'IZIN',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'Urusan pribadi',
            ]);
        $mgrLeaveRes->assertStatus(201);
        $mgrLeaveId = $mgrLeaveRes->json('data.id');

        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson("/api/leaves/{$mgrLeaveId}/action", ['status' => 'APPROVED'])
            ->assertStatus(403);

        // Mobile Check-In pada hari WFA yang sudah disetujui -> harus isi time_in dan time_out tetap null
        $wfhCheckIn = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'face_image' => UploadedFile::fake()->image('selfie_wfh.jpg'),
            ]);

        $wfhCheckIn->assertStatus(201);
        $this->assertNotNull($wfhCheckIn->json('attendance.time_in'));
        $this->assertNull($wfhCheckIn->json('attendance.time_out'));
        $this->assertNotEmpty($wfhCheckIn->json('attendance.face_image_url'));

        // 4. Daily Report tidak bisa ditimpa ulang lewat /reports/morning setelah COMPLETED
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/reports/morning', ['morning_planned_tasks' => 'Task 1'])
            ->assertStatus(201);

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/reports/evening', ['evening_completed_tasks' => 'Task 1 selesai'])
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/reports/morning', ['morning_planned_tasks' => 'Coba timpa'])
            ->assertStatus(422);
    }

    public function test_only_regular_employee_and_intern_can_login_to_mobile_api(): void
    {
        // Role mobile yang diizinkan: karyawan (termasuk approver) dan intern
        foreach (['karyawan@test.com', 'manager@test.com', 'intern@test.com'] as $allowedEmail) {
            $this->postJson('/api/login', [
                'email' => $allowedEmail,
                'password' => 'password',
            ])->assertOk()->assertJsonPath('success', true);
        }

        // Role khusus web tanpa role karyawan/intern ditolak masuk ke API Mobile (403)
        foreach (['admin@test.com', 'ceo@test.com'] as $webOnlyEmail) {
            $this->postJson('/api/login', [
                'email' => $webOnlyEmail,
                'password' => 'password',
            ])->assertStatus(403)->assertJsonPath('success', false);

            // Token lama milik role web juga wajib ditolak middleware auth.api (403)
            $webUser = User::where('email', $webOnlyEmail)->first();
            $token = $webUser->createToken('legacy-token')->plainTextToken;

            $this->withHeader('Authorization', 'Bearer ' . $token)
                ->getJson('/api/profile')
                ->assertStatus(403);
        }
    }

    public function test_employee_wfa_checkin_requires_approved_wfa_leave_while_intern_can_checkin(): void
    {
        Storage::fake('public');

        $employee = User::where('email', 'karyawan@test.com')->first();
        $approver = User::where('email', 'manager@test.com')->first();
        $intern = User::where('employment_type', 'INTERN')->first();
        $today = now()->toDateString();

        Attendance::whereIn('user_id', [$employee->id, $intern->id])->whereDate('date', $today)->delete();
        \App\Models\LeaveRequest::whereIn('user_id', [$employee->id, $intern->id])->delete();

        $empToken = $employee->createToken('emp-wfa-gate')->plainTextToken;
        $mgrToken = $approver->createToken('mgr-wfa-gate')->plainTextToken;
        $internToken = $intern->createToken('intern-wfa-gate')->plainTextToken;

        // 1. Karyawan belum mengajukan WFA -> can_mobile_checkin = false & POST /attendance/wfh ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('has_approved_wfa_today', false)
            ->assertJsonPath('can_mobile_checkin', false);

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.9175,
                'longitude' => 107.6191,
                'face_image' => UploadedFile::fake()->image('selfie1.jpg'),
            ])
            ->assertStatus(422);

        // 2. Karyawan mengajukan WFH (H-1) namun masih PENDING -> tetap ditolak (422)
        $this->travel(-1)->days();
        $leaveRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'WFH',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'WFH hari ini',
            ])->assertStatus(201);
        $this->travelBack();

        $leaveId = $leaveRes->json('data.id');

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('wfa_request_today_status', 'PENDING')
            ->assertJsonPath('can_mobile_checkin', false);

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.9175,
                'longitude' => 107.6191,
                'face_image' => UploadedFile::fake()->image('selfie2.jpg'),
            ])
            ->assertStatus(422)
            ->assertJsonPath('wfa_request_today_status', 'PENDING');

        // 3. Setelah di-ACC (APPROVED) -> can_mobile_checkin = true & check-in WFH berhasil (201)
        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson("/api/leaves/{$leaveId}/action", ['status' => 'APPROVED'])
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('has_approved_wfa_today', true)
            ->assertJsonPath('wfa_request_today_status', 'APPROVED')
            ->assertJsonPath('can_mobile_checkin', true);

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.9175,
                'longitude' => 107.6191,
                'face_image' => UploadedFile::fake()->image('selfie3.jpg'),
            ])
            ->assertStatus(201)
            ->assertJsonPath('attendance.status', 'WFA');

        // 4. Magang (INTERN) tetap dapat check-in harian lewat mobile tanpa pengajuan WFA (tercatat HADIR_ON_SITE)
        $this->withHeader('Authorization', 'Bearer ' . $internToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('can_mobile_checkin', true);

        $this->withHeader('Authorization', 'Bearer ' . $internToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.9175,
                'longitude' => 107.6191,
                'face_image' => UploadedFile::fake()->image('selfie_intern.jpg'),
            ])
            ->assertStatus(201)
            ->assertJsonPath('attendance.status', 'HADIR_ON_SITE');
    }

    public function test_employee_onsite_checkin_enforces_strict_office_geofence(): void
    {
        Storage::fake('public');

        \App\Models\Setting::updateOrCreate(['key' => 'office_latitude'], ['value' => '-6.20880000']);
        \App\Models\Setting::updateOrCreate(['key' => 'office_longitude'], ['value' => '106.84560000']);
        \App\Models\Setting::updateOrCreate(['key' => 'office_radius_meters'], ['value' => '100']);

        $employee = User::where('email', 'karyawan@test.com')->first();
        $today = now()->toDateString();

        Attendance::where('user_id', $employee->id)->whereDate('date', $today)->delete();
        \App\Models\LeaveRequest::where('user_id', $employee->id)->delete();

        $empToken = $employee->createToken('emp-onsite-gps')->plainTextToken;

        // 1. /attendance/today melaporkan can_onsite_checkin = true & can_mobile_checkin = false
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('can_mobile_checkin', false)
            ->assertJsonPath('can_onsite_checkin', true);

        // 2. Mode ON_SITE (GPS & Foto Kantor) di LUAR radius kantor -> WAJIB ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'presence_type' => 'ON_SITE',
                'face_image' => UploadedFile::fake()->image('selfie_outside.jpg'),
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('location');

        // 3. Mode ON_SITE (GPS & Foto Kantor) di DALAM radius kantor -> BERHASIL (201) dengan status HADIR_ON_SITE
        $res = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.20885000,
                'longitude' => 106.84565000,
                'presence_type' => 'ON_SITE',
                'face_image' => UploadedFile::fake()->image('selfie_office.jpg'),
            ]);

        $res->assertStatus(201)
            ->assertJsonPath('is_within_radius', true)
            ->assertJsonPath('attendance.status', 'HADIR_ON_SITE')
            ->assertJsonPath('attendance.method', 'FACIAL_LOCATION');
        $this->assertNotEmpty($res->json('attendance.face_image_url'));
    }

    public function test_checkout_enforces_photo_gps_and_onsite_geofence_while_wfa_is_radius_free(): void
    {
        Storage::fake('public');

        \App\Models\Setting::updateOrCreate(['key' => 'office_latitude'], ['value' => '-6.20880000']);
        \App\Models\Setting::updateOrCreate(['key' => 'office_longitude'], ['value' => '106.84560000']);
        \App\Models\Setting::updateOrCreate(['key' => 'office_radius_meters'], ['value' => '100']);

        $employee = User::where('email', 'karyawan@test.com')->first();
        $approver = User::where('email', 'manager@test.com')->first();
        $today = now()->toDateString();

        Attendance::whereIn('user_id', [$employee->id, $approver->id])->whereDate('date', $today)->delete();
        DailyReport::whereIn('user_id', [$employee->id, $approver->id])->whereDate('date', $today)->delete();

        $empToken = $employee->createToken('emp-checkout-onsite')->plainTextToken;
        $mgrToken = $approver->createToken('mgr-checkout-wfa')->plainTextToken;

        // A. Karyawan On-Site (hadir di kantor) + Daily Report COMPLETED
        Attendance::create([
            'user_id' => $employee->id,
            'date' => $today,
            'time_in' => '08:00:00',
            'status' => 'HADIR_ON_SITE',
            'method' => 'FACIAL_LOCATION',
            'is_late' => false,
            'overtime_hours' => 0,
        ]);
        DailyReport::create([
            'user_id' => $employee->id,
            'date' => $today,
            'morning_planned_tasks' => '1. Kerja kantor',
            'evening_completed_tasks' => '1. Kerja kantor',
            'status' => 'COMPLETED',
        ]);

        // /attendance/today mengembalikan checkout_mode = ONSITE_GEOFENCE
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('can_checkout', true)
            ->assertJsonPath('checkout_mode', 'ONSITE_GEOFENCE');

        // Checkout tanpa foto/GPS ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/checkout')
            ->assertStatus(422)
            ->assertJsonValidationErrors(['latitude', 'longitude', 'face_image']);

        // Checkout On-Site di LUAR radius kantor ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/checkout', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'face_image' => UploadedFile::fake()->image('out_outside.jpg'),
            ])
            ->assertStatus(422)
            ->assertJsonPath('is_within_radius', false);

        // Checkout On-Site di DALAM radius kantor + foto selfie -> BERHASIL (200)
        $onsiteOut = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/checkout', [
                'latitude' => -6.20885000,
                'longitude' => 106.84565000,
                'face_image' => UploadedFile::fake()->image('out_office.jpg'),
            ]);

        $onsiteOut->assertOk()
            ->assertJsonPath('is_within_radius', true);
        $this->assertNotNull($onsiteOut->json('attendance.time_out'));
        $this->assertNotEmpty($onsiteOut->json('attendance.checkout_face_image_url'));

        // B. Karyawan WFA + Daily Report COMPLETED -> bebas radius tapi tetap wajib foto & GPS
        Attendance::create([
            'user_id' => $approver->id,
            'date' => $today,
            'time_in' => '08:00:00',
            'status' => 'WFA',
            'method' => 'FACIAL_LOCATION',
            'is_late' => false,
            'overtime_hours' => 0,
        ]);
        DailyReport::create([
            'user_id' => $approver->id,
            'date' => $today,
            'morning_planned_tasks' => '1. Kerja WFA',
            'evening_completed_tasks' => '1. Kerja WFA',
            'status' => 'COMPLETED',
        ]);

        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('checkout_mode', 'MOBILE_FREE');

        $wfaOut = $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson('/api/attendance/checkout', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'face_image' => UploadedFile::fake()->image('out_wfa.jpg'),
            ]);

        $wfaOut->assertOk();
        $this->assertNotNull($wfaOut->json('attendance.time_out'));
        $this->assertNotEmpty($wfaOut->json('attendance.checkout_face_image_url'));
    }

    public function test_dynamic_work_start_and_end_time_settings_drive_late_and_overtime_calculation(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $employee = User::where('email', 'karyawan@test.com')->first();
        $empToken = $employee->createToken('emp-schedule')->plainTextToken;

        // 1. Admin mengatur jam masuk 09:00, jam pulang 18:00, toleransi terlambat 15m, ambang lembur 30m
        $this->actingAs($admin)->put(route('admin.settings.update'), [
            'work_start_time' => '09:00',
            'work_end_time' => '18:00',
            'late_tolerance_minutes' => 15,
            'overtime_tolerance_minutes' => 30,
        ])->assertRedirect();

        // 2. Endpoint /api/attendance/today mengembalikan jadwal kerja dinamis
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('work_schedule.work_start_time', '09:00')
            ->assertJsonPath('work_schedule.work_end_time', '18:00')
            ->assertJsonPath('work_schedule.late_tolerance_minutes', 15)
            ->assertJsonPath('work_schedule.overtime_tolerance_minutes', 30);

        // 3. Verifikasi kalkulasi terlambat & lembur mengikuti jam dinamis (09:00 - 18:00)
        $service = app(\App\Services\AttendanceService::class);
        $this->assertFalse($service->isLateAt(\Carbon\Carbon::parse('2026-11-24 09:10:00')));
        $this->assertTrue($service->isLateAt(\Carbon\Carbon::parse('2026-11-24 09:16:00')));
        $this->assertEquals(0, $service->calculateOvertimeHours(\Carbon\Carbon::parse('2026-11-24 18:20:00')));
        $this->assertEquals(1, $service->calculateOvertimeHours(\Carbon\Carbon::parse('2026-11-24 19:05:00')));
        $this->assertEquals(2, $service->calculateOvertimeHours(\Carbon\Carbon::parse('2026-11-24 20:15:00')));
    }

    public function test_public_branding_endpoint_reflects_web_settings_changes(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $this->actingAs($admin)->put(route('admin.settings.update'), [
            'app_name' => 'Presensi Nusantara',
            'app_slogan' => 'Presensi GPS & Foto Modern',
            'late_tolerance_minutes' => 15,
            'overtime_tolerance_minutes' => 30,
        ])->assertRedirect();

        $this->getJson('/api/branding')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.app_name', 'Presensi Nusantara')
            ->assertJsonPath('data.app_slogan', 'Presensi GPS & Foto Modern');
    }

    public function test_cuti_tugas_luar_lead_time_rules_and_sakit_auto_approval(): void
    {
        Storage::fake('public');

        $employee = User::where('email', 'karyawan@test.com')->first();
        $approver = User::where('email', 'manager@test.com')->first();
        $today = now()->toDateString();
        $tomorrow = now()->addDay()->toDateString();
        $plus6Days = now()->addDays(6)->toDateString();
        $plus7Days = now()->addDays(7)->toDateString();

        Attendance::whereIn('user_id', [$employee->id, $approver->id])->whereDate('date', $today)->delete();
        DailyReport::whereIn('user_id', [$employee->id, $approver->id])->whereDate('date', $today)->delete();
        \App\Models\LeaveRequest::whereIn('user_id', [$employee->id, $approver->id])->delete();

        $empToken = $employee->createToken('emp-leave-rules')->plainTextToken;
        $mgrToken = $approver->createToken('mgr-leave-rules')->plainTextToken;

        // 1. CUTI wajib minimal H-7 (seminggu sebelumnya)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'CUTI',
                'start_date' => $plus6Days,
                'end_date' => $plus6Days,
                'reason' => 'Cuti terlalu mendadak',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('start_date');

        $cutiRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'CUTI',
                'start_date' => $plus7Days,
                'end_date' => $plus7Days,
                'reason' => 'Cuti tahunan terencana',
            ]);
        $cutiRes->assertStatus(201)
            ->assertJsonPath('data.type', 'CUTI')
            ->assertJsonPath('data.status', 'PENDING');

        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson('/api/leaves/' . $cutiRes->json('data.id') . '/action', ['status' => 'APPROVED'])
            ->assertOk();

        $this->assertDatabaseHas('attendances', [
            'user_id' => $employee->id,
            'date' => $plus7Days,
            'status' => 'CUTI',
        ]);

        // 2. IZIN wajib minimal H-1 (1 hari sebelumnya)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'IZIN',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'Izin hari ini harus ditolak',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('start_date');

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'IZIN',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'Izin besok',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.status', 'PENDING');

        // 3. WFH wajib minimal H-1 (1 hari sebelumnya)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'WFH',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'WFH hari ini harus ditolak',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('start_date');

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'WFH',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'WFH besok',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.type', 'WFA')
            ->assertJsonPath('data.status', 'PENDING');

        // 4. SAKIT langsung APPROVED otomatis tanpa perlu ACC atasan + langsung mengisi presensi
        $sakitRes = $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson('/api/leaves', [
                'type' => 'SAKIT',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'Demam tinggi',
            ]);
        $sakitRes->assertStatus(201)
            ->assertJsonPath('auto_approved', true)
            ->assertJsonPath('data.type', 'SAKIT')
            ->assertJsonPath('data.status', 'APPROVED');

        $this->assertDatabaseHas('attendances', [
            'user_id' => $approver->id,
            'date' => $today,
            'status' => 'SAKIT',
        ]);

        // Status /attendance/today langsung mendeteksi is_on_leave_today = true beserta detail izin/cuti/sakit
        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('is_on_leave_today', true)
            ->assertJsonPath('today_leave_status', 'SAKIT')
            ->assertJsonPath('today_leave_detail.type', 'SAKIT')
            ->assertJsonPath('today_leave_detail.reason', 'Demam tinggi')
            ->assertJsonPath('can_mobile_checkin', false)
            ->assertJsonPath('can_onsite_checkin', false);

        // 5. TUGAS_LUAR dapat diajukan hari ini, di-ACC, lalu membuka presensi Mobile (bebas radius + selfie)
        $tlRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'TUGAS_LUAR',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'Kunjungan klien luar kota',
            ]);
        $tlRes->assertStatus(201)
            ->assertJsonPath('data.type', 'TUGAS_LUAR')
            ->assertJsonPath('data.status', 'PENDING');

        $this->withHeader('Authorization', 'Bearer ' . $mgrToken)
            ->postJson('/api/leaves/' . $tlRes->json('data.id') . '/action', ['status' => 'APPROVED'])
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->getJson('/api/attendance/today')
            ->assertOk()
            ->assertJsonPath('has_approved_tugas_luar_today', true)
            ->assertJsonPath('can_mobile_checkin', true);

        $tlCheckIn = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/attendance/wfh', [
                'latitude' => -6.91750000,
                'longitude' => 107.61910000,
                'presence_type' => 'TUGAS_LUAR',
                'face_image' => UploadedFile::fake()->image('selfie_tugas_luar.jpg'),
            ]);
        $tlCheckIn->assertStatus(201)
            ->assertJsonPath('attendance.status', 'TUGAS_LUAR');

        // 6. Setelah sudah melakukan presensi masuk hari ini, pengajuan SAKIT untuk hari ini WAJIB ditolak (422)
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'SAKIT',
                'start_date' => $today,
                'end_date' => $today,
                'reason' => 'Coba ajuin sakit setelah sudah presensi',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('start_date');
    }

    public function test_employee_can_edit_and_cancel_pending_leave_but_not_approved_or_others(): void
    {
        $employee = User::where('email', 'karyawan@test.com')->first();
        $other = User::where('email', 'manager@test.com')->first();
        $tomorrow = now()->addDay()->toDateString();
        $dayAfter = now()->addDays(2)->toDateString();

        $empToken = $employee->createToken('emp-edit-leave')->plainTextToken;
        $otherToken = $other->createToken('other-edit-leave')->plainTextToken;

        // 1. Buat pengajuan IZIN berstatus PENDING
        $createRes = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'IZIN',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'Keperluan keluarga awal',
            ]);
        $createRes->assertStatus(201);
        $leaveId = $createRes->json('data.id');

        // 2. Pegawai lain tidak boleh mengedit atau membatalkan (403)
        $this->withHeader('Authorization', 'Bearer ' . $otherToken)
            ->postJson("/api/leaves/{$leaveId}/update", [
                'type' => 'WFA',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'Coba edit milik orang lain',
            ])
            ->assertStatus(403);

        $this->withHeader('Authorization', 'Bearer ' . $otherToken)
            ->deleteJson("/api/leaves/{$leaveId}")
            ->assertStatus(403);

        // 3. Pemilik dapat mengedit pengajuan PENDING
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson("/api/leaves/{$leaveId}/update", [
                'type' => 'WFA',
                'start_date' => $tomorrow,
                'end_date' => $dayAfter,
                'reason' => 'Diubah menjadi WFA koordinasi proyek',
            ])
            ->assertOk()
            ->assertJsonPath('data.type', 'WFA')
            ->assertJsonPath('data.reason', 'Diubah menjadi WFA koordinasi proyek');

        // 4. Pemilik dapat membatalkan pengajuan PENDING
        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->deleteJson("/api/leaves/{$leaveId}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('leave_requests', ['id' => $leaveId]);

        // 5. Pengajuan yang sudah APPROVED tidak dapat diedit atau dibatalkan (422)
        $approvedCreate = $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson('/api/leaves', [
                'type' => 'IZIN',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'Izin akan disetujui',
            ])->assertStatus(201);
        $approvedId = $approvedCreate->json('data.id');

        $this->withHeader('Authorization', 'Bearer ' . $otherToken)
            ->postJson("/api/leaves/{$approvedId}/action", ['status' => 'APPROVED'])
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->postJson("/api/leaves/{$approvedId}/update", [
                'type' => 'WFA',
                'start_date' => $tomorrow,
                'end_date' => $tomorrow,
                'reason' => 'Coba edit setelah ACC',
            ])
            ->assertStatus(422);

        $this->withHeader('Authorization', 'Bearer ' . $empToken)
            ->deleteJson("/api/leaves/{$approvedId}")
            ->assertStatus(422);
    }

    public function test_mobile_user_can_upload_and_delete_profile_photo(): void
    {
        Storage::fake('public');

        $employee = User::where('email', 'karyawan@test.com')->first();
        $token = $employee->createToken('profile-photo-test')->plainTextToken;

        // 1. Upload foto profil pertama
        $uploadRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->post('/api/profile/photo', [
                'photo' => UploadedFile::fake()->image('avatar-1.jpg', 300, 300),
            ], ['Accept' => 'application/json']);

        $uploadRes->assertOk()
            ->assertJsonPath('success', true);

        $firstPath = $uploadRes->json('data.profile_photo_path');
        $this->assertNotEmpty($firstPath);
        $this->assertStringContainsString('/storage/' . $firstPath, (string) $uploadRes->json('data.profile_photo_url'));
        Storage::disk('public')->assertExists($firstPath);

        // 2. Ganti foto profil baru -> foto lama otomatis terhapus
        $replaceRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->post('/api/profile/photo', [
                'photo' => UploadedFile::fake()->image('avatar-2.png', 300, 300),
            ], ['Accept' => 'application/json']);

        $replaceRes->assertOk();
        $secondPath = $replaceRes->json('data.profile_photo_path');
        $this->assertNotEquals($firstPath, $secondPath);
        Storage::disk('public')->assertMissing($firstPath);
        Storage::disk('public')->assertExists($secondPath);

        // 3. GET /api/profile mengembalikan profile_photo_url terbaru
        $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/profile')
            ->assertOk()
            ->assertJsonPath('data.profile_photo_path', $secondPath);

        // 4. Hapus foto profil
        $deleteRes = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson('/api/profile/photo');

        $deleteRes->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.profile_photo_path', null)
            ->assertJsonPath('data.profile_photo_url', null);

        Storage::disk('public')->assertMissing($secondPath);
    }
}
