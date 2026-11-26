<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\DailyReport;
use App\Models\EmployeeSanction;
use App\Models\LeaveRequest;
use App\Models\SanctionRule;
use App\Models\Setting;
use App\Models\User;
use App\Services\AttendanceService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class MobileApiController extends Controller
{
    public function __construct(protected AttendanceService $attendanceService) {}

    /**
     * Format data user standar untuk konsumsi aplikasi mobile Flutter
     */
    private function formatUserPayload(User $user, ?Request $request = null): array
    {
        $user->loadMissing('roles');

        $photoPath = $user->profile_photo_path;
        $photoUrl = null;
        if (! empty($photoPath)) {
            $photoUrl = $request
                ? rtrim($request->getSchemeAndHttpHost(), '/').'/storage/'.ltrim($photoPath, '/')
                : $user->profile_photo_url;
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'profile_photo_path' => $photoPath,
            'profile_photo_url' => $photoUrl,
            'employment_type' => $user->employment_type,
            'can_approve_leaves' => (bool) $user->can_approve_leaves,
            'is_attendance_required' => $user->isAttendanceRequired(),
            'roles' => $user->roles->pluck('name')->values()->all(),
            'role_details' => $user->roles->map(fn ($r) => [
                'name' => $r->name,
                'display_name' => $r->display_name,
            ])->values()->all(),
            'ui_flags' => [
                'primary_attendance_mode' => 'GPS_PHOTO',
                'show_leave_approval_menu' => (bool) $user->can_approve_leaves || $user->hasRole('super_admin'),
            ],
        ];
    }

    // =========================================================================
    // 0. BRANDING APLIKASI (PUBLIC)
    // =========================================================================

    private function formatBrandPayload(Request $request): array
    {
        Setting::clearBrandCache();
        $brand = Setting::getBrandSettings();
        $logoPath = $brand['logo_path'];

        $version = config('app.version', ['number' => '1.0.0', 'build' => 1]);
        $verNumber = is_array($version) ? ($version['number'] ?? '1.0.0') : (string) $version;
        $verBuild = is_array($version) ? (int) ($version['build'] ?? 1) : 1;

        return [
            'app_name' => $brand['name'],
            'app_slogan' => $brand['slogan'],
            'app_logo_path' => $logoPath,
            'app_logo_url' => $logoPath
                ? rtrim($request->getSchemeAndHttpHost(), '/').'/'.ltrim($logoPath, '/')
                : null,
            'office_name' => $brand['office_name'],
            'app_version' => $verNumber,
            'app_build' => $verBuild,
        ];
    }

    public function branding(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $this->formatBrandPayload($request),
        ]);
    }

    // =========================================================================
    // 1. AUTENTIKASI & PROFIL (AUTH & PROFILE)
    // =========================================================================

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'nullable|string|max:100',
        ]);

        $user = User::with('roles')->where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau kata sandi yang Anda masukkan tidak sesuai.',
            ], 401);
        }

        if (! $user->canAccessMobileApp()) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Aplikasi Presensi Makerindo Mobile hanya untuk Karyawan Regular dan Magang. Silakan masuk melalui Portal Web Presensi Makerindo.',
            ], 403);
        }

        $tokenResult = $user->createToken($validated['device_name'] ?? 'flutter-mobile');
        $brandPayload = $this->formatBrandPayload($request);

        return response()->json([
            'success' => true,
            'message' => 'Berhasil masuk ke aplikasi '.($brandPayload['app_name'] ?? 'Presensi Makerindo').' Mobile.',
            'access_token' => $tokenResult->plainTextToken,
            'token_type' => 'Bearer',
            'user' => $this->formatUserPayload($user, $request),
            'brand' => $brandPayload,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $currentToken = $request->attributes->get('current_access_token');
        if ($currentToken) {
            $currentToken->delete();
        } elseif ($request->user()) {
            $request->user()->tokens()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Sesi Anda telah diakhiri dan token berhasil dihapus.',
        ]);
    }

    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => $this->formatUserPayload($user, $request),
        ]);
    }

    public function updateProfilePhoto(Request $request): JsonResponse
    {
        $request->validate([
            'photo' => 'required|image|max:5120',
        ], [
            'photo.required' => 'Foto profil wajib dipilih.',
            'photo.image' => 'Berkas harus berupa gambar yang valid.',
            'photo.max' => 'Ukuran foto profil maksimal 5 MB.',
        ]);

        $user = $request->user();

        if (! empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
            Storage::disk('public')->delete($user->profile_photo_path);
        }

        $path = $request->file('photo')->store('profile-photos', 'public');
        $user->update(['profile_photo_path' => $path]);
        $user->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Foto profil berhasil diperbarui.',
            'data' => $this->formatUserPayload($user, $request),
        ]);
    }

    public function deleteProfilePhoto(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
            Storage::disk('public')->delete($user->profile_photo_path);
        }

        $user->update(['profile_photo_path' => null]);
        $user->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Foto profil berhasil dihapus.',
            'data' => $this->formatUserPayload($user, $request),
        ]);
    }

    public function updatePassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (! Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Kata sandi saat ini tidak sesuai.',
            ], 422);
        }

        $user->update([
            'password' => Hash::make($validated['password']),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kata sandi akun berhasil diperbarui.',
        ]);
    }

    // =========================================================================
    // 2. PRESENSI & RIWAYAT KEHADIRAN (ATTENDANCES)
    // =========================================================================

    private function findOpenAttendanceTodayOrYesterday(User $user): ?Attendance
    {
        $today = now()->toDateString();
        $attendance = Attendance::where('user_id', $user->id)
            ->whereDate('date', $today)
            ->first();

        if ($attendance) {
            return $attendance;
        }

        $yesterday = now()->subDay()->toDateString();

        return Attendance::where('user_id', $user->id)
            ->whereDate('date', $yesterday)
            ->whereNotNull('time_in')
            ->whereNull('time_out')
            ->first();
    }

    public function attendanceToday(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = now()->toDateString();

        $attendance = $this->findOpenAttendanceTodayOrYesterday($user);
        $attendanceDate = $attendance ? Carbon::parse($attendance->date)->toDateString() : $today;

        $dailyReport = DailyReport::where('user_id', $user->id)
            ->whereDate('date', $attendanceDate)
            ->first();

        $officeSettings = $this->attendanceService->getOfficeSettings();

        $hasCheckedIn = $attendance !== null && ! empty($attendance->time_in);
        $hasCheckedOut = $attendance !== null && ! empty($attendance->time_out);
        $activeDailyReport = $hasCheckedIn ? $dailyReport : null;
        $hasMorningReport = $activeDailyReport !== null && ! empty($activeDailyReport->morning_planned_tasks);
        $hasEveningReport = $activeDailyReport !== null && $activeDailyReport->status === 'COMPLETED';

        $todayWfaLeaves = LeaveRequest::where('user_id', $user->id)
            ->where('type', 'WFA')
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('created_at', 'desc')
            ->get();

        $hasApprovedWfaToday = $todayWfaLeaves->contains('status', 'APPROVED');
        $wfaRequestStatus = $hasApprovedWfaToday
            ? 'APPROVED'
            : ($todayWfaLeaves->first()?->status);

        $todayTugasLuarLeaves = LeaveRequest::where('user_id', $user->id)
            ->where('type', 'TUGAS_LUAR')
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('created_at', 'desc')
            ->get();

        $hasApprovedTugasLuarToday = $todayTugasLuarLeaves->contains('status', 'APPROVED');
        $tugasLuarRequestStatus = $hasApprovedTugasLuarToday
            ? 'APPROVED'
            : ($todayTugasLuarLeaves->first()?->status);

        $nonWorkingStatuses = ['CUTI', 'SAKIT', 'IZIN'];
        $approvedNonWorkingLeaveToday = LeaveRequest::where('user_id', $user->id)
            ->whereIn('type', $nonWorkingStatuses)
            ->where('status', 'APPROVED')
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('created_at', 'desc')
            ->first();

        $isOnLeaveToday = ($attendance !== null && in_array($attendance->status, $nonWorkingStatuses, true))
            || $approvedNonWorkingLeaveToday !== null;
        $todayLeaveStatus = $approvedNonWorkingLeaveToday?->type
            ?? ($isOnLeaveToday ? $attendance?->status : null);

        $isIntern = $user->employment_type === 'INTERN';
        $canMobileCheckIn = ! $hasCheckedIn && ! $isOnLeaveToday && ($isIntern || $hasApprovedWfaToday || $hasApprovedTugasLuarToday);
        $canOnsiteCheckIn = ! $hasCheckedIn && ! $isOnLeaveToday && ! $isIntern && ! $hasApprovedWfaToday && ! $hasApprovedTugasLuarToday;

        $checkoutMode = null;
        if ($hasCheckedIn && ! $hasCheckedOut) {
            $checkoutMode = ($isIntern || in_array($attendance?->status, ['WFA', 'TUGAS_LUAR'], true))
                ? 'MOBILE_FREE'
                : 'ONSITE_GEOFENCE';
        }

        return response()->json([
            'success' => true,
            'date' => $attendanceDate,
            'has_checked_in' => $hasCheckedIn,
            'has_checked_out' => $hasCheckedOut,
            'can_checkout' => $hasCheckedIn && ! $hasCheckedOut && $hasEveningReport,
            'checkout_mode' => $checkoutMode,
            'has_approved_wfa_today' => $hasApprovedWfaToday,
            'wfa_request_today_status' => $wfaRequestStatus,
            'has_approved_tugas_luar_today' => $hasApprovedTugasLuarToday,
            'tugas_luar_request_today_status' => $tugasLuarRequestStatus,
            'is_on_leave_today' => $isOnLeaveToday,
            'today_leave_status' => $todayLeaveStatus,
            'today_leave_detail' => $approvedNonWorkingLeaveToday ? [
                'id' => $approvedNonWorkingLeaveToday->id,
                'type' => $approvedNonWorkingLeaveToday->type,
                'start_date' => substr((string) $approvedNonWorkingLeaveToday->start_date, 0, 10),
                'end_date' => substr((string) $approvedNonWorkingLeaveToday->end_date, 0, 10),
                'reason' => $approvedNonWorkingLeaveToday->reason,
            ] : null,
            'can_mobile_checkin' => $canMobileCheckIn,
            'can_onsite_checkin' => $canOnsiteCheckIn,
            'attendance' => $attendance ? [
                'id' => $attendance->id,
                'date' => $attendanceDate,
                'time_in' => $attendance->time_in,
                'time_out' => $attendance->time_out,
                'status' => $attendance->status,
                'method' => $attendance->method,
                'is_late' => (bool) $attendance->is_late,
                'overtime_hours' => (int) $attendance->overtime_hours,
                'latitude' => $attendance->latitude ? (float) $attendance->latitude : null,
                'longitude' => $attendance->longitude ? (float) $attendance->longitude : null,
                'face_image_path' => $attendance->face_image_path,
                'face_image_url' => $attendance->face_image_url,
                'checkout_latitude' => $attendance->checkout_latitude ? (float) $attendance->checkout_latitude : null,
                'checkout_longitude' => $attendance->checkout_longitude ? (float) $attendance->checkout_longitude : null,
                'checkout_face_image_path' => $attendance->checkout_face_image_path,
                'checkout_face_image_url' => $attendance->checkout_face_image_url,
            ] : null,
            'daily_report' => [
                'has_morning_report' => $hasMorningReport,
                'has_evening_report' => $hasEveningReport,
                'status' => $activeDailyReport?->status,
                'morning_submitted_at' => $activeDailyReport?->morning_submitted_at,
                'evening_submitted_at' => $activeDailyReport?->evening_submitted_at,
            ],
            'office' => $officeSettings,
            'work_schedule' => $this->attendanceService->getWorkScheduleSettings(),
        ]);
    }

    public function attendanceWfaCheckIn(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'presence_type' => 'nullable|in:WFA,WFH,ON_SITE,TUGAS_LUAR,AUTO',
            'face_image' => 'required|file|mimes:jpg,jpeg,png,webp|max:5120',
            'notes' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        $today = now()->toDateString();

        $existing = Attendance::where('user_id', $user->id)
            ->whereDate('date', $today)
            ->first();

        if ($existing && $existing->time_in) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah melakukan presensi masuk hari ini pada pukul '.substr($existing->time_in, 0, 5).' WIB.',
                'attendance' => $existing,
            ], 422);
        }

        if ($existing && in_array($existing->status, ['CUTI', 'SAKIT', 'IZIN'], true)) {
            $label = match ($existing->status) {
                'CUTI' => 'Cuti',
                'SAKIT' => 'Sakit',
                default => 'Izin',
            };

            return response()->json([
                'success' => false,
                'message' => "Anda tercatat sedang {$label} hari ini sehingga tidak perlu melakukan presensi masuk.",
                'attendance' => $existing,
            ], 422);
        }

        $todayWfaLeaves = LeaveRequest::where('user_id', $user->id)
            ->where('type', 'WFA')
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('created_at', 'desc')
            ->get();

        $hasApprovedWfaToday = $todayWfaLeaves->contains('status', 'APPROVED');
        $latestWfaStatus = $todayWfaLeaves->first()?->status;

        $todayTugasLuarLeaves = LeaveRequest::where('user_id', $user->id)
            ->where('type', 'TUGAS_LUAR')
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('created_at', 'desc')
            ->get();

        $hasApprovedTugasLuarToday = $todayTugasLuarLeaves->contains('status', 'APPROVED');
        $latestTugasLuarStatus = $todayTugasLuarLeaves->first()?->status;

        $isIntern = $user->employment_type === 'INTERN';
        $requestedType = strtoupper((string) ($validated['presence_type'] ?? ''));

        // Karyawan (KARTAP/PKWT) tanpa izin WFA/TUGAS_LUAR APPROVED melakukan presensi kantor (ON_SITE)
        // menggunakan GPS & Foto dengan validasi radius kantor ketat di AttendanceService.
        $isOnsiteOfficeCheckIn = ! $isIntern && $requestedType === 'ON_SITE';
        $isTugasLuarRequested = $requestedType === 'TUGAS_LUAR';

        if ($isTugasLuarRequested && ! $hasApprovedTugasLuarToday) {
            $reasonMsg = match ($latestTugasLuarStatus) {
                'PENDING' => 'Presensi Tugas Luar belum dapat dilakukan karena pengajuan Tugas Luar Anda hari ini masih menunggu persetujuan (PENDING).',
                'REJECTED' => 'Presensi Tugas Luar ditolak karena pengajuan Tugas Luar Anda hari ini berstatus REJECTED.',
                default => 'Presensi Tugas Luar hanya dapat dilakukan jika pengajuan Tugas Luar Anda untuk hari ini sudah disetujui (APPROVED).',
            };

            return response()->json([
                'success' => false,
                'tugas_luar_request_today_status' => $latestTugasLuarStatus,
                'message' => $reasonMsg,
            ], 422);
        }

        if (! $isIntern && ! $hasApprovedWfaToday && ! $hasApprovedTugasLuarToday && ! $isOnsiteOfficeCheckIn) {
            $reasonMsg = match ($latestWfaStatus) {
                'PENDING' => 'Presensi WFA/WFH belum dapat dilakukan karena pengajuan WFH Anda hari ini masih menunggu persetujuan (PENDING).',
                'REJECTED' => 'Presensi WFA/WFH ditolak karena pengajuan WFH Anda hari ini berstatus REJECTED. Silakan lakukan presensi Kantor (ON_SITE) dengan GPS & Foto di dalam radius kantor.',
                default => 'Presensi WFA/WFH atau Tugas Luar hanya dapat dilakukan jika pengajuan Anda untuk hari ini sudah disetujui (APPROVED). Jika hadir di kantor, gunakan mode Presensi Kantor (ON_SITE) dengan GPS & Foto di dalam radius kantor.',
            };

            return response()->json([
                'success' => false,
                'wfa_request_today_status' => $latestWfaStatus,
                'message' => $reasonMsg,
            ], 422);
        }

        // Tentukan mode presensi akhir sebelum menyimpan file agar jika radius ditolak (422) tidak menyimpan file yatim.
        if ($isOnsiteOfficeCheckIn) {
            $effectivePresenceType = 'ON_SITE';
        } elseif ($hasApprovedTugasLuarToday && ($isTugasLuarRequested || ! $hasApprovedWfaToday)) {
            $effectivePresenceType = 'TUGAS_LUAR';
        } elseif ($hasApprovedWfaToday) {
            $effectivePresenceType = 'WFA';
        } else {
            // Magang (INTERN) presensi harian via kamera & GPS tanpa batasan radius
            $effectivePresenceType = 'INTERN_MOBILE';
        }

        $result = $this->attendanceService->recordLocationAttendance(
            user: $user,
            latitude: (float) $validated['latitude'],
            longitude: (float) $validated['longitude'],
            presenceType: $effectivePresenceType,
            notes: $validated['notes'] ?? null
        );

        $faceImagePath = null;
        if ($request->hasFile('face_image')) {
            $faceImagePath = $request->file('face_image')->store('faces/'.now()->format('Y-m'), 'public');
        }

        /** @var Attendance $attendance */
        $attendance = $result['attendance'];
        if ($faceImagePath) {
            $attendance->update(['face_image_path' => $faceImagePath]);
            $attendance->refresh();
        }

        return response()->json([
            'success' => true,
            'message' => $result['message'],
            'distance_meters' => $result['distance'],
            'is_within_radius' => $result['is_within_radius'],
            'attendance' => $attendance,
        ], 201);
    }

    public function attendanceCheckout(Request $request): JsonResponse
    {
        $user = $request->user();
        $attendance = $this->findOpenAttendanceTodayOrYesterday($user);

        if (! $attendance || ! $attendance->time_in) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum melakukan presensi masuk hari ini.',
            ], 422);
        }

        if ($attendance->time_out) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah melakukan presensi pulang hari ini pada pukul '.substr($attendance->time_out, 0, 5).' WIB.',
            ], 422);
        }

        $attendanceDate = Carbon::parse($attendance->date)->toDateString();

        // Validasi kunci: DailyReport sore WAJIB sudah berstatus COMPLETED
        $dailyReport = DailyReport::where('user_id', $user->id)
            ->whereDate('date', $attendanceDate)
            ->first();

        if (! $dailyReport || $dailyReport->status !== 'COMPLETED') {
            return response()->json([
                'success' => false,
                'message' => 'Anda wajib menyelesaikan evaluasi laporan tugas sore hingga selesai sebelum melakukan presensi pulang.',
                'daily_report_status' => $dailyReport?->status ?? 'NOT_SUBMITTED',
            ], 422);
        }

        $validated = $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'face_image' => 'required|file|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        $latitude = (float) $validated['latitude'];
        $longitude = (float) $validated['longitude'];
        $office = $this->attendanceService->getOfficeSettings();
        $distance = $this->attendanceService->calculateDistance(
            $latitude,
            $longitude,
            $office['latitude'],
            $office['longitude']
        );
        $isWithinRadius = $distance <= $office['radius'];

        $isIntern = $user->employment_type === 'INTERN';
        $requiresOfficeGeofence = ! $isIntern && $attendance->status === 'HADIR_ON_SITE';

        if ($requiresOfficeGeofence && ! $isWithinRadius) {
            return response()->json([
                'success' => false,
                'message' => "Presensi pulang ditolak: Anda tercatat hadir di kantor, namun posisi Anda berada di luar radius kantor ({$distance} meter dari kantor, batas {$office['radius']} meter). Silakan lakukan presensi pulang dari dalam area kantor dengan GPS dan foto selfie.",
                'errors' => [
                    'location' => [
                        "Posisi Anda berada di luar radius kantor ({$distance} meter dari kantor, batas {$office['radius']} meter).",
                    ],
                ],
                'distance_meters' => $distance,
                'is_within_radius' => false,
            ], 422);
        }

        $checkoutFacePath = $request->file('face_image')->store('faces-checkout/'.now()->format('Y-m'), 'public');

        $now = now();
        $overtimeHours = $this->attendanceService->calculateOvertimeHours($now, $attendanceDate);

        $attendance->update([
            'time_out' => $now->format('H:i:s'),
            'overtime_hours' => $overtimeHours,
            'checkout_face_image_path' => $checkoutFacePath,
            'checkout_latitude' => $latitude,
            'checkout_longitude' => $longitude,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Presensi pulang berhasil dicatat pada pukul {$now->format('H:i')} WIB.".($overtimeHours > 0 ? " Lembur tercatat: {$overtimeHours} jam." : ''),
            'overtime_hours' => $overtimeHours,
            'distance_meters' => $distance,
            'is_within_radius' => $isWithinRadius,
            'attendance' => $attendance->fresh(),
        ]);
    }

    public function attendanceHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        $month = (int) $request->input('month', now()->month);
        $year = (int) $request->input('year', now()->year);

        $records = Attendance::where('user_id', $user->id)
            ->whereMonth('date', $month)
            ->whereYear('date', $year)
            ->orderBy('date', 'desc')
            ->get();

        $summary = [
            'month' => $month,
            'year' => $year,
            'total_records' => $records->count(),
            'hadir_on_site' => $records->where('status', 'HADIR_ON_SITE')->count(),
            'wfa' => $records->where('status', 'WFA')->count(),
            'tugas_luar' => $records->where('status', 'TUGAS_LUAR')->count(),
            'cuti' => $records->where('status', 'CUTI')->count(),
            'sakit' => $records->where('status', 'SAKIT')->count(),
            'izin' => $records->where('status', 'IZIN')->count(),
            'alpha' => $records->where('status', 'ALPHA')->count(),
            'late_count' => $records->where('is_late', true)->count(),
            'total_overtime_hours' => (int) $records->sum('overtime_hours'),
        ];

        return response()->json([
            'success' => true,
            'summary' => $summary,
            'data' => $records,
        ]);
    }

    // =========================================================================
    // 3. DAILY REPORT - TUGAS PAGI & SORE (DAILY REPORTS)
    // =========================================================================

    public function reportToday(Request $request): JsonResponse
    {
        $user = $request->user();
        $attendance = $this->findOpenAttendanceTodayOrYesterday($user);
        $hasCheckedIn = $attendance !== null && ! empty($attendance->time_in);
        $attendanceDate = $attendance ? Carbon::parse($attendance->date)->toDateString() : now()->toDateString();

        $report = $hasCheckedIn
            ? DailyReport::where('user_id', $user->id)->whereDate('date', $attendanceDate)->first()
            : null;

        $plannedTasksArray = [];
        if ($report && ! empty($report->morning_planned_tasks)) {
            $plannedTasksArray = array_values(array_filter(array_map(function ($line) {
                return trim(preg_replace('/^(\d+[\.\)]\s*|[-*•]\s*)/', '', trim($line)));
            }, preg_split('/\r?\n/', $report->morning_planned_tasks))));
        }

        return response()->json([
            'success' => true,
            'date' => $attendanceDate,
            'has_checked_in' => $hasCheckedIn,
            'has_submitted_morning' => $report !== null,
            'is_completed' => $report?->status === 'COMPLETED',
            'morning_tasks_list' => $plannedTasksArray,
            'data' => $report,
        ]);
    }

    public function reportMorning(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'morning_planned_tasks' => 'required',
        ]);

        $user = $request->user();
        $today = now()->toDateString();

        $attendance = Attendance::where('user_id', $user->id)
            ->whereDate('date', $today)
            ->first();

        if (! $attendance || ! $attendance->time_in) {
            return response()->json([
                'success' => false,
                'message' => 'Anda harus melakukan presensi masuk terlebih dahulu sebelum mengirim rencana tugas pagi.',
            ], 422);
        }

        $existingReport = DailyReport::where('user_id', $user->id)
            ->whereDate('date', $today)
            ->first();

        if ($existingReport && $existingReport->status === 'COMPLETED') {
            return response()->json([
                'success' => false,
                'message' => 'Laporan harian hari ini sudah selesai dan tidak dapat ditimpa ulang dengan laporan pagi.',
            ], 422);
        }

        $tasksText = is_array($validated['morning_planned_tasks'])
            ? implode("\n", array_map('trim', $validated['morning_planned_tasks']))
            : trim((string) $validated['morning_planned_tasks']);

        $report = DailyReport::updateOrCreate(
            [
                'user_id' => $user->id,
                'date' => $today,
            ],
            [
                'morning_submitted_at' => now()->format('H:i:s'),
                'morning_planned_tasks' => $tasksText,
                'status' => 'MORNING_ONLY',
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Rencana tugas pagi berhasil disimpan.',
            'data' => $report,
        ], 201);
    }

    public function reportEvening(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'evening_completed_tasks' => 'nullable',
            'evening_pending_tasks' => 'nullable',
            'evening_additional_tasks' => 'nullable',
        ]);

        $user = $request->user();
        $attendance = $this->findOpenAttendanceTodayOrYesterday($user);

        if (! $attendance || ! $attendance->time_in) {
            return response()->json([
                'success' => false,
                'message' => 'Anda harus melakukan presensi masuk terlebih dahulu sebelum mengisi evaluasi tugas sore.',
            ], 422);
        }

        $attendanceDate = Carbon::parse($attendance->date)->toDateString();

        $report = DailyReport::where('user_id', $user->id)
            ->whereDate('date', $attendanceDate)
            ->first();

        if (! $report) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum mengisi rencana tugas pagi hari ini. Silakan kirim laporan pagi terlebih dahulu.',
            ], 422);
        }

        $completedText = is_array($validated['evening_completed_tasks'] ?? null)
            ? implode("\n", array_map('trim', $validated['evening_completed_tasks']))
            : trim((string) ($validated['evening_completed_tasks'] ?? ''));

        $pendingText = is_array($validated['evening_pending_tasks'] ?? null)
            ? implode("\n", array_map('trim', $validated['evening_pending_tasks']))
            : trim((string) ($validated['evening_pending_tasks'] ?? ''));

        $additionalText = is_array($validated['evening_additional_tasks'] ?? null)
            ? implode("\n", array_map('trim', $validated['evening_additional_tasks']))
            : trim((string) ($validated['evening_additional_tasks'] ?? ''));

        if ($completedText === '' && $pendingText === '') {
            return response()->json([
                'success' => false,
                'message' => 'Harap isi setidaknya daftar tugas yang selesai atau tugas yang tertunda.',
            ], 422);
        }

        $report->update([
            'evening_submitted_at' => now()->format('H:i:s'),
            'evening_completed_tasks' => $completedText !== '' ? $completedText : null,
            'evening_pending_tasks' => $pendingText !== '' ? $pendingText : null,
            'evening_additional_tasks' => $additionalText !== '' ? $additionalText : null,
            'status' => 'COMPLETED',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Evaluasi tugas sore berhasil disimpan. Akses presensi pulang kini terbuka.',
            'can_checkout' => true,
            'data' => $report->fresh(),
        ]);
    }

    public function reportHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        $month = $request->input('month');
        $year = $request->input('year');

        $query = DailyReport::where('user_id', $user->id)->orderBy('date', 'desc');

        if ($month) {
            $query->whereMonth('date', (int) $month);
        }
        if ($year) {
            $query->whereYear('date', (int) $year);
        }

        $reports = $query->limit(60)->get();

        return response()->json([
            'success' => true,
            'total' => $reports->count(),
            'data' => $reports,
        ]);
    }

    // =========================================================================
    // 4. MANAJEMEN PERIZINAN & DYNAMIC APPROVAL (LEAVE REQUESTS)
    // =========================================================================

    public function leavesIndex(Request $request): JsonResponse
    {
        $user = $request->user();

        $leaves = LeaveRequest::with('approver:id,name,email')
            ->where('user_id', $user->id)
            ->orderBy('start_date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'total' => $leaves->count(),
            'data' => $leaves,
        ]);
    }

    private function validateLeavePolicy(User $user, string $type, Carbon $startDate, Carbon $endDate, ?string $ignoreLeaveId = null): ?JsonResponse
    {
        $today = now()->startOfDay();

        $overlappingLeave = LeaveRequest::where('user_id', $user->id)
            ->when($ignoreLeaveId, fn ($q) => $q->where('id', '!=', $ignoreLeaveId))
            ->where(function ($q) use ($type) {
                $q->where('status', 'APPROVED')
                    ->orWhere(function ($sub) use ($type) {
                        $sub->where('status', 'PENDING')->where('type', $type);
                    });
            })
            ->whereDate('start_date', '<=', $endDate->toDateString())
            ->whereDate('end_date', '>=', $startDate->toDateString())
            ->first();

        if ($overlappingLeave) {
            return response()->json([
                'success' => false,
                'message' => 'Rentang tanggal pengajuan bertabrakan dengan pengajuan perizinan lain yang masih aktif atau menunggu persetujuan.',
                'errors' => [
                    'start_date' => ['Rentang tanggal bertabrakan dengan pengajuan perizinan sebelumnya.'],
                ],
            ], 422);
        }

        if ($type === 'CUTI') {
            $minStart = $today->copy()->addDays(7);
            if ($startDate->lt($minStart)) {
                $minFormatted = $minStart->translatedFormat('d M Y');

                return response()->json([
                    'success' => false,
                    'message' => "Pengajuan Cuti harus dilakukan minimal 7 hari (1 minggu) sebelumnya. Tanggal mulai paling cepat adalah {$minFormatted}.",
                    'errors' => [
                        'start_date' => ["Pengajuan Cuti minimal 7 hari sebelumnya (mulai {$minStart->toDateString()})."],
                    ],
                ], 422);
            }
        } elseif ($type === 'IZIN') {
            $minStart = $today->copy()->addDay();
            if ($startDate->lt($minStart)) {
                $minFormatted = $minStart->translatedFormat('d M Y');

                return response()->json([
                    'success' => false,
                    'message' => "Pengajuan Izin harus dilakukan minimal 1 hari sebelumnya. Tanggal mulai paling cepat adalah {$minFormatted}.",
                    'errors' => [
                        'start_date' => ["Pengajuan Izin minimal 1 hari sebelumnya (mulai {$minStart->toDateString()})."],
                    ],
                ], 422);
            }
        } elseif ($type === 'WFA') {
            $minStart = $today->copy()->addDay();
            if ($startDate->lt($minStart)) {
                $minFormatted = $minStart->translatedFormat('d M Y');

                return response()->json([
                    'success' => false,
                    'message' => "Pengajuan WFA harus dilakukan minimal 1 hari sebelumnya. Tanggal mulai paling cepat adalah {$minFormatted}.",
                    'errors' => [
                        'start_date' => ["Pengajuan WFA minimal 1 hari sebelumnya (mulai {$minStart->toDateString()})."],
                    ],
                ], 422);
            }
        } elseif ($type === 'TUGAS_LUAR') {
            if ($startDate->lt($today)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pengajuan Tugas Luar tidak dapat menggunakan tanggal yang sudah lewat.',
                    'errors' => [
                        'start_date' => ["Tanggal mulai Tugas Luar minimal hari ini ({$today->toDateString()})."],
                    ],
                ], 422);
            }
        } elseif ($type === 'SAKIT') {
            $alreadyPresent = Attendance::where('user_id', $user->id)
                ->whereBetween('date', [$startDate->toDateString(), $endDate->toDateString()])
                ->where(function ($q) {
                    $q->whereNotNull('time_in')
                        ->orWhereIn('status', ['CUTI', 'SAKIT', 'IZIN']);
                })
                ->orderBy('date', 'asc')
                ->first();

            if ($alreadyPresent) {
                $conflictDate = Carbon::parse($alreadyPresent->date)->translatedFormat('d M Y');

                return response()->json([
                    'success' => false,
                    'message' => "Pengajuan Sakit tidak dapat dilakukan karena Anda sudah tercatat hadir atau berizin pada tanggal {$conflictDate}.",
                    'errors' => [
                        'start_date' => ["Anda sudah melakukan presensi masuk atau berizin pada tanggal {$conflictDate} sehingga tidak dapat mengajukan Sakit pada tanggal tersebut."],
                    ],
                ], 422);
            }
        }

        return null;
    }

    public function leavesStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => 'required|in:SAKIT,IZIN,WFA,WFH,CUTI,TUGAS_LUAR',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'reason' => 'required|string|max:1000',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120',
        ]);

        $user = $request->user();
        $type = $validated['type'] === 'WFH' ? 'WFA' : $validated['type'];
        $startDate = Carbon::parse($validated['start_date'])->startOfDay();
        $endDate = Carbon::parse($validated['end_date'])->startOfDay();

        if ($policyError = $this->validateLeavePolicy($user, $type, $startDate, $endDate)) {
            return $policyError;
        }

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('leave-attachments/'.now()->format('Y-m'), 'public');
        }

        $isAutoApproved = $type === 'SAKIT';

        $leave = LeaveRequest::create([
            'user_id' => $user->id,
            'type' => $type,
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'],
            'reason' => $validated['reason'],
            'attachment_path' => $attachmentPath,
            'status' => $isAutoApproved ? 'APPROVED' : 'PENDING',
        ]);

        if ($isAutoApproved) {
            $leave->syncAttendances();
        }

        $typeLabel = match ($type) {
            'WFA' => 'WFA',
            'TUGAS_LUAR' => 'Tugas Luar',
            'CUTI' => 'Cuti',
            'SAKIT' => 'Sakit',
            default => 'Izin',
        };

        $message = $isAutoApproved
            ? 'Pengajuan Sakit berhasil dicatat dan langsung disetujui otomatis tanpa perlu persetujuan atasan. Presensi Anda telah diperbarui.'
            : "Pengajuan {$typeLabel} berhasil dikirim dan menunggu persetujuan atasan.";

        return response()->json([
            'success' => true,
            'auto_approved' => $isAutoApproved,
            'message' => $message,
            'data' => $leave,
        ], 201);
    }

    public function leavesUpdate(Request $request, LeaveRequest $leaveRequest): JsonResponse
    {
        $user = $request->user();

        if ($leaveRequest->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk mengubah pengajuan milik pegawai lain.',
            ], 403);
        }

        if ($leaveRequest->status !== 'PENDING') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya pengajuan berstatus Menunggu Persetujuan yang dapat diubah.',
            ], 422);
        }

        $validated = $request->validate([
            'type' => 'required|in:SAKIT,IZIN,WFA,WFH,CUTI,TUGAS_LUAR',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'reason' => 'required|string|max:1000',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120',
        ]);

        $type = $validated['type'] === 'WFH' ? 'WFA' : $validated['type'];
        $startDate = Carbon::parse($validated['start_date'])->startOfDay();
        $endDate = Carbon::parse($validated['end_date'])->startOfDay();

        if ($policyError = $this->validateLeavePolicy($user, $type, $startDate, $endDate, $leaveRequest->id)) {
            return $policyError;
        }

        $attachmentPath = $leaveRequest->attachment_path;
        if ($request->hasFile('attachment')) {
            if ($attachmentPath && Storage::disk('public')->exists($attachmentPath)) {
                Storage::disk('public')->delete($attachmentPath);
            }
            $attachmentPath = $request->file('attachment')->store('leave-attachments/'.now()->format('Y-m'), 'public');
        }

        $isAutoApproved = $type === 'SAKIT';

        $leaveRequest->update([
            'type' => $type,
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'],
            'reason' => $validated['reason'],
            'attachment_path' => $attachmentPath,
            'status' => $isAutoApproved ? 'APPROVED' : 'PENDING',
        ]);

        if ($isAutoApproved) {
            $leaveRequest->syncAttendances();
        }

        return response()->json([
            'success' => true,
            'auto_approved' => $isAutoApproved,
            'message' => $isAutoApproved
                ? 'Pengajuan diperbarui menjadi Sakit dan langsung disetujui otomatis.'
                : 'Pengajuan perizinan berhasil diperbarui.',
            'data' => $leaveRequest->fresh(),
        ]);
    }

    public function leavesDestroy(Request $request, LeaveRequest $leaveRequest): JsonResponse
    {
        $user = $request->user();

        if ($leaveRequest->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk membatalkan pengajuan milik pegawai lain.',
            ], 403);
        }

        if ($leaveRequest->status !== 'PENDING') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya pengajuan berstatus Menunggu Persetujuan yang dapat dibatalkan.',
            ], 422);
        }

        if ($leaveRequest->attachment_path && Storage::disk('public')->exists($leaveRequest->attachment_path)) {
            Storage::disk('public')->delete($leaveRequest->attachment_path);
        }

        $leaveRequest->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan perizinan berhasil dibatalkan.',
        ]);
    }

    public function leavesApprovals(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->can_approve_leaves && ! $user->hasRole('super_admin')) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki wewenang untuk menyetujui permohonan izin/WFA.',
            ], 403);
        }

        $statusFilter = strtoupper((string) $request->input('status', 'PENDING'));
        $query = LeaveRequest::with([
            'user:id,name,email,employment_type',
            'approver:id,name,email',
        ])
            ->where('user_id', '!=', $user->id)
            ->orderBy('created_at', 'desc');

        if (in_array($statusFilter, ['PENDING', 'APPROVED', 'REJECTED'], true)) {
            $query->where('status', $statusFilter);
        }

        $leaves = $query->get();

        return response()->json([
            'success' => true,
            'filter_status' => in_array($statusFilter, ['PENDING', 'APPROVED', 'REJECTED', 'ALL'], true) ? $statusFilter : 'PENDING',
            'total_pending' => LeaveRequest::where('user_id', '!=', $user->id)->where('status', 'PENDING')->count(),
            'total' => $leaves->count(),
            'data' => $leaves,
        ]);
    }

    public function leavesAction(Request $request, LeaveRequest $leaveRequest): JsonResponse
    {
        $user = $request->user();

        if (! $user->can_approve_leaves && ! $user->hasRole('super_admin')) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki wewenang untuk memproses persetujuan pengajuan ini.',
            ], 403);
        }

        if ($leaveRequest->user_id === $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak dapat menyetujui atau menolak pengajuan perizinan milik Anda sendiri.',
            ], 403);
        }

        if ($leaveRequest->status !== 'PENDING') {
            $statusLabel = match ($leaveRequest->status) {
                'APPROVED' => 'Disetujui',
                'REJECTED' => 'Ditolak',
                default => $leaveRequest->status,
            };

            return response()->json([
                'success' => false,
                'message' => "Pengajuan ini sudah diproses sebelumnya dengan status {$statusLabel}.",
            ], 422);
        }

        $validated = $request->validate([
            'status' => 'required|in:APPROVED,REJECTED',
            'rejection_reason' => 'required_if:status,REJECTED|nullable|string|max:500',
        ]);

        if ($validated['status'] === 'APPROVED') {
            $leaveRequest->approve($user);
            $message = "Pengajuan {$leaveRequest->type} disetujui dan tabel presensi otomatis diperbarui.";
        } else {
            $leaveRequest->reject($user, $validated['rejection_reason'] ?? 'Ditolak oleh penyetuju.');
            $message = "Pengajuan {$leaveRequest->type} telah ditolak.";
        }

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $leaveRequest->fresh(['user:id,name,email', 'approver:id,name,email']),
        ]);
    }

    // =========================================================================
    // 5. SANKSI & EVALUASI KEDISIPLINAN (SANCTIONS)
    // =========================================================================

    public function sanctionsIndex(Request $request): JsonResponse
    {
        $user = $request->user();

        $sanctions = EmployeeSanction::with('rule:id,code,name,category')
            ->where('user_id', $user->id)
            ->orderBy('incident_date', 'desc')
            ->get()
            ->map(fn (EmployeeSanction $s) => [
                'id' => $s->id,
                'month' => $s->month,
                'year' => $s->year,
                'incident_date' => $s->incident_date,
                'violation_name' => $s->violation_name,
                'level' => $s->level,
                'level_label' => SanctionRule::levelLabel($s->level),
                'source' => $s->source,
                'occurrence_count' => $s->occurrence_count,
                'reason' => $s->reason,
                'status' => $s->status,
            ]);

        $currentMonthLateCount = Attendance::where('user_id', $user->id)
            ->whereMonth('date', now()->month)
            ->whereYear('date', now()->year)
            ->where('is_late', true)
            ->count();

        return response()->json([
            'success' => true,
            'summary' => [
                'total_sanctions' => $sanctions->count(),
                'active_sanctions' => $sanctions->where('status', 'ACTIVE')->count(),
                'current_month_late_count' => $currentMonthLateCount,
            ],
            'data' => $sanctions,
        ]);
    }

    public function sanctionsShow(Request $request, EmployeeSanction $employeeSanction): JsonResponse
    {
        $user = $request->user();

        if ($employeeSanction->user_id !== $user->id && ! $user->hasRole('super_admin')) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk melihat rincian sanksi ini.',
            ], 403);
        }

        $employeeSanction->loadMissing(['rule:id,code,name,category', 'issuer:id,name']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $employeeSanction->id,
                'month' => $employeeSanction->month,
                'year' => $employeeSanction->year,
                'incident_date' => $employeeSanction->incident_date,
                'violation_name' => $employeeSanction->violation_name,
                'level' => $employeeSanction->level,
                'level_label' => SanctionRule::levelLabel($employeeSanction->level),
                'source' => $employeeSanction->source,
                'occurrence_count' => $employeeSanction->occurrence_count,
                'reason' => $employeeSanction->reason,
                'status' => $employeeSanction->status,
                'rule' => $employeeSanction->rule,
                'issued_by' => $employeeSanction->issuer?->name ?? 'Sistem Otomatis Presensi Makerindo',
                'download_url' => url("/api/sanctions/{$employeeSanction->id}/download"),
            ],
        ]);
    }

    public function sanctionsDownload(Request $request, EmployeeSanction $employeeSanction): Response|JsonResponse
    {
        $user = $request->user();

        if ($employeeSanction->user_id !== $user->id && ! $user->hasRole('super_admin')) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk mengunduh surat sanksi ini.',
            ], 403);
        }

        $employeeSanction->loadMissing(['user', 'rule', 'issuer']);
        $owner = $employeeSanction->user;

        $officeSettings = [
            'name' => Setting::getValue('office_name', 'PT Makerindo Prima Solusi'),
            'address' => Setting::getValue('office_address', 'Kantor PT Makerindo Prima Solusi, Bandung'),
        ];

        $pdf = Pdf::loadView('sanctions.sp_pdf', [
            'sanction' => $employeeSanction,
            'user' => $owner,
            'officeSettings' => $officeSettings,
        ])->setPaper('a4', 'portrait');

        $cleanName = preg_replace('/[^A-Za-z0-9_-]/', '_', $owner->name ?? 'Karyawan');
        $filename = "Surat_Sanksi_{$employeeSanction->level}_{$cleanName}_{$employeeSanction->month}_{$employeeSanction->year}.pdf";

        return $pdf->download($filename);
    }
}
