<?php

use App\Http\Controllers\Admin\AttendanceController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\SettingController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Approval\LeaveApprovalController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Executive\DashboardController as ExecutiveDashboardController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SanctionController;
use App\Models\Attendance;
use App\Models\DailyReport;
use App\Models\LeaveRequest;
use App\Services\AttendanceService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('login');
});

Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [LoginController::class, 'login'])->name('login.store');
});

Route::middleware('auth')->group(function () {
    Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

    // User Self-Service Profile Routes
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');

    // Super Admin Routes
    Route::middleware('role:super_admin')->prefix('admin')->name('admin.')->group(function () {
        Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');
        Route::get('/', fn () => redirect()->route('admin.dashboard'));
        Route::resource('users', UserController::class)->except(['show']);
        Route::get('/settings', [SettingController::class, 'index'])->name('settings.index');
        Route::put('/settings', [SettingController::class, 'update'])->name('settings.update');
        Route::post('/settings/holidays', [SettingController::class, 'storeHoliday'])->name('settings.holidays.store');
        Route::delete('/settings/holidays/{holiday}', [SettingController::class, 'destroyHoliday'])->name('settings.holidays.destroy');

        // Attendance Logs & Manual Override
        Route::get('/attendances', [AttendanceController::class, 'index'])->name('attendances.index');
        Route::post('/attendances/manual-override', [AttendanceController::class, 'manualOverride'])->name('attendances.override');
    });

    // Executive / CEO Routes
    Route::middleware('role:ceo')->prefix('executive')->name('executive.')->group(function () {
        Route::get('/dashboard', [ExecutiveDashboardController::class, 'index'])->name('dashboard');
    });

    // Leave Approvals Route (Super Admin or User with can_approve_leaves)
    Route::prefix('approvals')->name('approval.')->group(function () {
        Route::get('/', [LeaveApprovalController::class, 'index'])->name('index');
        Route::patch('/{leaveRequest}/approve', [LeaveApprovalController::class, 'approve'])->name('approve');
        Route::patch('/{leaveRequest}/reject', [LeaveApprovalController::class, 'reject'])->name('reject');
    });

    // Sanctions & Disciplinary Routes (Super Admin & CEO)
    Route::middleware('role:super_admin,ceo')->group(function () {
        Route::get('/sanctions', [SanctionController::class, 'index'])->name('sanctions.index');
        Route::get('/sanctions/{employeeSanction}/pdf', [SanctionController::class, 'downloadPdf'])->name('sanctions.pdf');
    });

    Route::middleware('role:super_admin')->prefix('sanctions')->name('sanctions.')->group(function () {
        Route::post('/detect', [SanctionController::class, 'detectAutoSanctions'])->name('detect');
        Route::post('/', [SanctionController::class, 'storeSanction'])->name('store');
        Route::put('/{employeeSanction}', [SanctionController::class, 'updateSanction'])->name('update');
        Route::post('/rules', [SanctionController::class, 'storeRule'])->name('rules.store');
        Route::put('/rules/{sanctionRule}', [SanctionController::class, 'updateRule'])->name('rules.update');
        Route::delete('/rules/{sanctionRule}', [SanctionController::class, 'destroyRule'])->name('rules.destroy');
    });

    // Reports & Rekapitulasi Routes (Super Admin & CEO read-only)
    Route::middleware('role:super_admin,ceo')->prefix('reports')->name('reports.')->group(function () {
        Route::get('/', [ReportController::class, 'index'])->name('index');
        Route::get('/attendances', [ReportController::class, 'attendances'])->name('attendances');
        Route::get('/attendances/export', [ReportController::class, 'exportAttendances'])->name('attendances.export');
        Route::get('/leaves', [ReportController::class, 'leaves'])->name('leaves');
        Route::get('/leaves/export', [ReportController::class, 'exportLeaves'])->name('leaves.export');
        Route::get('/daily-tasks', [ReportController::class, 'dailyTasks'])->name('daily-tasks');
        Route::get('/daily-tasks/export', [ReportController::class, 'exportDailyTasks'])->name('daily-tasks.export');
    });

    // Write endpoints khusus Super Admin untuk Daily Tasks & Web Location Check-in
    Route::middleware('role:super_admin')->group(function () {
        Route::post('/reports/daily-tasks', [ReportController::class, 'storeDailyTask'])->name('reports.daily-tasks.store');
        Route::put('/reports/daily-tasks/{dailyReport}', [ReportController::class, 'updateDailyTask'])->name('reports.daily-tasks.update');
        Route::post('/attendances/location-check-in', [AttendanceController::class, 'locationCheckIn'])->name('attendances.location-check-in');
    });
});

// API Endpoint for Location Attendance Check-in (Terproteksi Bearer Token + Kebijakan Mobile)
Route::middleware('auth.api')->post('/api/attendances/location-check-in', function (Request $request, AttendanceService $attendanceService) {
    $validated = $request->validate([
        'latitude' => 'required|numeric|between:-90,90',
        'longitude' => 'required|numeric|between:-180,180',
        'presence_type' => 'required|in:ON_SITE,WFA,TUGAS_LUAR,AUTO',
        'notes' => 'nullable|string|max:255',
    ]);

    $user = $request->user();
    $today = now()->toDateString();

    $existing = Attendance::where('user_id', $user->id)
        ->whereDate('date', $today)
        ->first();

    // Jika sudah check-in dan belum check-out -> proses check-out wajib lulus gate Daily Report sore COMPLETED
    if ($existing && $existing->time_in && $existing->time_out === null) {
        $dailyReport = DailyReport::where('user_id', $user->id)
            ->whereDate('date', $today)
            ->first();

        if (! $dailyReport || $dailyReport->status !== 'COMPLETED') {
            return response()->json([
                'success' => false,
                'message' => 'Anda wajib menyelesaikan evaluasi laporan tugas sore hingga selesai sebelum melakukan presensi pulang.',
                'daily_report_status' => $dailyReport?->status ?? 'NOT_SUBMITTED',
            ], 422);
        }
    }

    // Jika belum check-in dan bukan magang -> wajib patuhi kebijakan izin WFA / TUGAS_LUAR
    if ((! $existing || ! $existing->time_in) && $user->employment_type !== 'INTERN') {
        $requestedType = $validated['presence_type'];

        if ($requestedType === 'WFA') {
            $hasApprovedWfa = LeaveRequest::where('user_id', $user->id)
                ->where('type', 'WFA')
                ->where('status', 'APPROVED')
                ->whereDate('start_date', '<=', $today)
                ->whereDate('end_date', '>=', $today)
                ->exists();

            if (! $hasApprovedWfa) {
                return response()->json([
                    'success' => false,
                    'message' => 'Presensi WFA hanya dapat dilakukan jika pengajuan WFA Anda untuk hari ini sudah disetujui (APPROVED).',
                ], 422);
            }
        } elseif ($requestedType === 'TUGAS_LUAR') {
            $hasApprovedTugasLuar = LeaveRequest::where('user_id', $user->id)
                ->where('type', 'TUGAS_LUAR')
                ->where('status', 'APPROVED')
                ->whereDate('start_date', '<=', $today)
                ->whereDate('end_date', '>=', $today)
                ->exists();

            if (! $hasApprovedTugasLuar) {
                return response()->json([
                    'success' => false,
                    'message' => 'Presensi Tugas Luar hanya dapat dilakukan jika pengajuan Tugas Luar Anda untuk hari ini sudah disetujui (APPROVED).',
                ], 422);
            }
        } elseif ($requestedType === 'AUTO') {
            $hasApprovedWfa = LeaveRequest::where('user_id', $user->id)
                ->where('type', 'WFA')
                ->where('status', 'APPROVED')
                ->whereDate('start_date', '<=', $today)
                ->whereDate('end_date', '>=', $today)
                ->exists();

            if (! $hasApprovedWfa) {
                $validated['presence_type'] = 'ON_SITE';
            }
        }
    }

    $result = $attendanceService->recordLocationAttendance(
        user: $user,
        latitude: (float) $validated['latitude'],
        longitude: (float) $validated['longitude'],
        presenceType: $validated['presence_type'],
        notes: $validated['notes'] ?? null
    );

    return response()->json([
        'success' => true,
        'action' => $result['action'],
        'message' => $result['message'],
        'distance' => $result['distance'],
        'is_within_radius' => $result['is_within_radius'],
        'attendance' => $result['attendance'],
    ]);
})->name('api.attendances.location-check-in');
