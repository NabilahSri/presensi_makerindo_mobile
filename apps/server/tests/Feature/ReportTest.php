<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\DailyReport;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use PhpOffice\PhpSpreadsheet\IOFactory;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use DatabaseTransactions;

    public function test_super_admin_can_access_attendance_report(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($admin)->get(route('reports.attendances'));

        $response->assertOk();
        $response->assertSee('Laporan Rekapitulasi Presensi');
        $response->assertSee('Menu Laporan');
        $response->assertSee('Pengajuan');
        $response->assertSee('Tugas Harian');
    }

    public function test_super_admin_can_access_leave_report(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($admin)->get(route('reports.leaves'));

        $response->assertOk();
        $response->assertSee('Laporan Rekapitulasi Pengajuan');
        $response->assertSee('Komposisi Pengajuan');
    }

    public function test_ceo_role_can_access_reports(): void
    {
        $ceo = User::where('email', 'ceo@test.com')->first();

        $response = $this->actingAs($ceo)->get(route('reports.attendances'));
        $response->assertOk();

        $response = $this->actingAs($ceo)->get(route('reports.leaves'));
        $response->assertOk();

        $response = $this->actingAs($ceo)->get(route('reports.daily-tasks'));
        $response->assertOk();
    }

    public function test_regular_karyawan_cannot_access_reports(): void
    {
        $karyawan = User::where('email', 'karyawan@test.com')->first();

        $response = $this->actingAs($karyawan)->get(route('reports.attendances'));
        $response->assertForbidden();

        $response = $this->actingAs($karyawan)->get(route('reports.leaves'));
        $response->assertForbidden();

        $response = $this->actingAs($karyawan)->get(route('reports.daily-tasks'));
        $response->assertForbidden();
    }

    public function test_super_admin_can_export_attendances(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($admin)->get(route('reports.attendances.export'));

        $response->assertOk();
        $this->assertStringContainsString('spreadsheetml.sheet', $response->headers->get('Content-Type'));
        $this->assertStringContainsString('.xlsx', $response->headers->get('Content-Disposition'));
    }

    public function test_super_admin_can_export_leaves(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($admin)->get(route('reports.leaves.export'));

        $response->assertOk();
        $this->assertStringContainsString('spreadsheetml.sheet', $response->headers->get('Content-Type'));
        $this->assertStringContainsString('.xlsx', $response->headers->get('Content-Disposition'));
    }

    public function test_super_admin_can_access_daily_tasks_monitoring(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($admin)->get(route('reports.daily-tasks'));

        $response->assertOk();
        $response->assertSee('Pemantauan Laporan Tugas Harian');
        $response->assertSee('Rencana Pagi Masuk');
        $response->assertSee('Ekspor ke Excel');
    }

    public function test_super_admin_can_export_daily_tasks(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($admin)->get(route('reports.daily-tasks.export'));

        $response->assertOk();
        $this->assertStringContainsString('spreadsheetml.sheet', $response->headers->get('Content-Type'));
        $this->assertStringContainsString('.xlsx', $response->headers->get('Content-Disposition'));
    }

    public function test_can_store_and_update_daily_task_report(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $user = User::where('email', 'karyawan@test.com')->first();
        $testDate = '2026-10-25';

        // 1. Simpan laporan pagi
        $storeResponse = $this->actingAs($admin)->post(route('reports.daily-tasks.store'), [
            'user_id' => $user->id,
            'date' => $testDate,
            'morning_planned_tasks' => "1. Task testing pagi A\n2. Task testing pagi B",
        ]);

        $storeResponse->assertRedirect();

        $report = DailyReport::where('user_id', $user->id)->whereDate('date', $testDate)->first();
        $this->assertNotNull($report);
        $this->assertEquals('MORNING_ONLY', $report->status);
        $this->assertStringContainsString('Task testing pagi A', $report->morning_planned_tasks);

        // 2. Update evaluasi sore
        $updateResponse = $this->actingAs($admin)->put(route('reports.daily-tasks.update', $report), [
            'evening_completed_tasks' => '1. Task testing pagi A (Selesai)',
            'evening_pending_tasks' => '2. Task testing pagi B (Pending)',
            'evening_additional_tasks' => '1. Task dadakan C',
        ]);

        $updateResponse->assertRedirect();

        $report->refresh();
        $this->assertEquals('COMPLETED', $report->status);
        $this->assertStringContainsString('Task testing pagi A (Selesai)', $report->evening_completed_tasks);
        $this->assertStringContainsString('Task dadakan C', $report->evening_additional_tasks);
    }

    public function test_can_update_daily_task_using_checklist_format(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $user = User::where('email', 'karyawan@test.com')->first();
        $testDate = '2026-10-26';

        // 1. Simpan laporan pagi
        $this->actingAs($admin)->post(route('reports.daily-tasks.store'), [
            'user_id' => $user->id,
            'date' => $testDate,
            'morning_planned_tasks' => "Fitur presensi GPS dan selfie\nTesting kamera mobile\nDeploy staging server",
        ]);

        $report = DailyReport::where('user_id', $user->id)->whereDate('date', $testDate)->first();
        $this->assertNotNull($report);
        $this->assertEquals('MORNING_ONLY', $report->status);

        // 2. Update via Checklist: Task 0 & 2 dicentang (selesai), Task 1 TIDAK dicentang (pending)
        $updateResponse = $this->actingAs($admin)->put(route('reports.daily-tasks.update', $report), [
            'all_morning_tasks' => [
                'Fitur presensi GPS dan selfie',
                'Testing kamera mobile',
                'Deploy staging server',
            ],
            'completed_task_indices' => ['0', '2'], // Task 1 unchecked
            'evening_additional_tasks' => 'Perbaikan akurasi koordinat GPS',
            'additional_tasks_checklist' => [
                'Perbaikan akurasi koordinat GPS',
            ],
            'completed_additional_indices' => ['0'],
        ]);

        $updateResponse->assertRedirect();

        $report->refresh();
        $this->assertEquals('COMPLETED', $report->status);

        // Task 0 & 2 harus masuk di completed
        $this->assertStringContainsString('Fitur presensi GPS dan selfie', $report->evening_completed_tasks);
        $this->assertStringContainsString('Deploy staging server', $report->evening_completed_tasks);
        $this->assertStringContainsString('[Tambahan] Perbaikan akurasi koordinat GPS', $report->evening_completed_tasks);

        // Task 1 yang tidak dicentang otomatis masuk di pending
        $this->assertStringNotContainsString('Testing kamera mobile', $report->evening_completed_tasks);
        $this->assertStringContainsString('Testing kamera mobile', $report->evening_pending_tasks);

        // Task tambahan tetap tersimpan di kolomnya
        $this->assertStringContainsString('Perbaikan akurasi koordinat GPS', $report->evening_additional_tasks);
    }

    public function test_can_store_daily_task_with_immediate_evening_checklist(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $user = User::where('email', 'karyawan@test.com')->first();
        $testDate = '2026-10-27';

        // Simpan langsung dengan checklist sore aktif
        $storeResponse = $this->actingAs($admin)->post(route('reports.daily-tasks.store'), [
            'user_id' => $user->id,
            'date' => $testDate,
            'morning_planned_tasks' => "Task A\nTask B",
            'with_evening_checklist' => '1',
            'all_morning_tasks' => ['Task A', 'Task B'],
            'completed_task_indices' => ['0'], // Task A checked, Task B unchecked
            'evening_additional_tasks' => 'Task Tambahan C',
            'additional_tasks_checklist' => ['Task Tambahan C'],
            'completed_additional_indices' => ['0'],
        ]);

        $storeResponse->assertRedirect();

        $report = DailyReport::where('user_id', $user->id)->whereDate('date', $testDate)->first();
        $this->assertNotNull($report);
        $this->assertEquals('COMPLETED', $report->status);
        $this->assertStringContainsString('Task A', $report->evening_completed_tasks);
        $this->assertStringContainsString('Task B', $report->evening_pending_tasks);
        $this->assertStringContainsString('[Tambahan] Task Tambahan C', $report->evening_completed_tasks);
        $this->assertStringContainsString('Task Tambahan C', $report->evening_additional_tasks);
    }

    public function test_export_attendances_calculates_late_minutes_and_neutralizes_excel_formulas(): void
    {
        $admin = User::where('email', 'admin@test.com')->first();
        $employee = User::where('email', 'karyawan@test.com')->first();
        $originalName = $employee->name;
        $employee->update(['name' => '=CMD("calc")']);

        Attendance::updateOrCreate(
            ['user_id' => $employee->id, 'date' => '2026-10-28'],
            [
                'time_in' => '08:45:00',
                'time_out' => '17:00:00',
                'status' => 'HADIR_ON_SITE',
                'method' => 'FACIAL_LOCATION',
                'is_late' => true,
                'overtime_hours' => 0,
            ]
        );

        $response = $this->actingAs($admin)->get(route('reports.attendances.export', [
            'start_date' => '2026-10-28',
            'end_date' => '2026-10-28',
            'user_id' => $employee->id,
        ]));

        $response->assertOk();
        $binary = $response->streamedContent();
        $tmpFile = tempnam(sys_get_temp_dir(), 'xlsx_qc_').'.xlsx';
        file_put_contents($tmpFile, $binary);

        $spreadsheet = IOFactory::load($tmpFile);
        $sheet = $spreadsheet->getActiveSheet();
        $this->assertEquals("'=CMD(\"calc\")", (string) $sheet->getCell('B2')->getValue());
        $this->assertGreaterThan(0, (int) $sheet->getCell('K2')->getValue());

        @unlink($tmpFile);
        $employee->update(['name' => $originalName]);
    }
}
