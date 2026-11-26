<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\DailyReport;
use App\Models\EmployeeSanction;
use App\Models\LeaveRequest;
use App\Models\Setting;
use App\Models\User;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $today = now()->toDateString();

        $totalUsers = User::count();
        $approverCount = User::where('can_approve_leaves', true)->count();

        $stats = [
            'total_users' => $totalUsers,
            'approvers_count' => $approverCount,
            'kartap' => User::where('employment_type', 'KARTAP')->count(),
            'pkwt' => User::where('employment_type', 'PKWT')->count(),
            'intern' => User::where('employment_type', 'INTERN')->count(),
            'today_onsite' => Attendance::whereDate('date', $today)->where('status', 'HADIR_ON_SITE')->count(),
            'today_wfa' => Attendance::whereDate('date', $today)->where('status', 'WFA')->count(),
            'today_tugas_luar' => Attendance::whereDate('date', $today)->where('status', 'TUGAS_LUAR')->count(),
            'today_late' => Attendance::whereDate('date', $today)->where('is_late', true)->count(),
            'today_photo_verified' => Attendance::whereDate('date', $today)->whereNotNull('face_image_path')->count(),
            'pending_leaves_count' => LeaveRequest::where('status', 'PENDING')->count(),
            'today_reports_count' => DailyReport::whereDate('date', $today)->count(),
            'active_sanctions_count' => EmployeeSanction::where('status', 'ACTIVE')->count(),
        ];

        $settings = Setting::pluck('value', 'key')->toArray();
        $tolerances = [
            'work_start' => $settings['work_start_time'] ?? '08:00',
            'work_end' => $settings['work_end_time'] ?? '17:00',
            'late' => $settings['late_tolerance_minutes'] ?? '15',
            'overtime' => $settings['overtime_tolerance_minutes'] ?? '30',
        ];

        $office = [
            'name' => $settings['office_name'] ?? 'Kantor PT Makerindo Prima Solusi',
            'address' => $settings['office_address'] ?? 'Kantor PT Makerindo Prima Solusi, Bandung',
            'latitude' => $settings['office_latitude'] ?? '-6.20880000',
            'longitude' => $settings['office_longitude'] ?? '106.84560000',
            'radius' => $settings['office_radius_meters'] ?? '100',
        ];

        $recentUsers = User::with('roles')->latest()->take(6)->get();

        $recentAttendances = Attendance::with('user')
            ->whereDate('date', $today)
            ->latest('updated_at')
            ->take(6)
            ->get();

        $recentLeaves = LeaveRequest::with('user')
            ->latest()
            ->take(5)
            ->get();

        return view('admin.dashboard', compact(
            'stats',
            'tolerances',
            'office',
            'recentUsers',
            'recentAttendances',
            'recentLeaves'
        ));
    }
}
