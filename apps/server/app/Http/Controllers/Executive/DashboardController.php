<?php

namespace App\Http\Controllers\Executive;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\DailyReport;
use App\Models\EmployeeSanction;
use App\Models\LeaveRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(Request $request): View
    {
        $today = now()->toDateString();
        $currentMonth = (int) now()->month;
        $currentYear = (int) now()->year;
        $perPage = in_array((int) $request->input('per_page'), [5, 10, 15, 25, 50])
            ? (int) $request->input('per_page')
            : 10;

        // 1. TREN KEHADIRAN & KEDISIPLINAN 6 BULAN TERAKHIR
        $attendanceTrend = [];
        $maxMonthlyTotal = 1;

        for ($i = 5; $i >= 0; $i--) {
            $datePoint = Carbon::create($currentYear, $currentMonth, 1)->subMonths($i);
            $m = (int) $datePoint->month;
            $y = (int) $datePoint->year;

            $periodAtt = Attendance::whereMonth('date', $m)
                ->whereYear('date', $y)
                ->get();

            $onsite = $periodAtt->whereIn('status', ['HADIR_ON_SITE', 'TUGAS_LUAR'])->count();
            $wfa = $periodAtt->where('status', 'WFA')->count();
            $absence = $periodAtt->whereIn('status', ['CUTI', 'SAKIT', 'IZIN', 'ALPHA'])->count();
            $late = $periodAtt->where('is_late', true)->count();
            $present = $onsite + $wfa;
            $total = $periodAtt->count();

            if ($total > $maxMonthlyTotal) {
                $maxMonthlyTotal = $total;
            }

            $attendanceTrend[] = [
                'label' => $datePoint->translatedFormat('M Y'),
                'month' => $m,
                'year' => $y,
                'total' => $total,
                'onsite' => $onsite,
                'wfa' => $wfa,
                'absence' => $absence,
                'late' => $late,
                'discipline_pct' => $present > 0 ? round((($present - $late) / $present) * 100, 1) : 100.0,
            ];
        }

        // 2. ANALITIK KEDISIPLINAN & TINGKAT KEHADIRAN (ATTENDANCE ANALYTICS)
        $agg = Attendance::selectRaw("
            COUNT(*) as total_records,
            SUM(CASE WHEN status IN ('HADIR_ON_SITE', 'TUGAS_LUAR') THEN 1 ELSE 0 END) as onsite_count,
            SUM(CASE WHEN status = 'WFA' THEN 1 ELSE 0 END) as wfa_count,
            SUM(CASE WHEN status IN ('CUTI', 'SAKIT', 'IZIN', 'ALPHA') THEN 1 ELSE 0 END) as absence_count,
            SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) as late_count
        ")->first();

        $totalRawRecords = (int) ($agg->total_records ?? 0);
        $totalAttendanceRecords = max(1, $totalRawRecords);
        $onsiteCount = (int) ($agg->onsite_count ?? 0);
        $wfaCount = (int) ($agg->wfa_count ?? 0);
        $sakitIzinAlphaCount = (int) ($agg->absence_count ?? 0);
        $lateCount = (int) ($agg->late_count ?? 0);
        $presentCount = max(1, $onsiteCount + $wfaCount);

        $attendanceAnalytics = [
            'total_records' => $totalRawRecords,
            'onsite_count' => $onsiteCount,
            'onsite_pct' => $totalRawRecords > 0 ? round(($onsiteCount / $totalAttendanceRecords) * 100, 1) : 0,
            'wfa_count' => $wfaCount,
            'wfa_pct' => $totalRawRecords > 0 ? round(($wfaCount / $totalAttendanceRecords) * 100, 1) : 0,
            'absence_count' => $sakitIzinAlphaCount,
            'absence_pct' => $totalRawRecords > 0 ? round(($sakitIzinAlphaCount / $totalAttendanceRecords) * 100, 1) : 0,
            'late_count' => $lateCount,
            'discipline_pct' => ($onsiteCount + $wfaCount) > 0
                ? round((($presentCount - $lateCount) / $presentCount) * 100, 1)
                : 100,
            'late_pct' => ($onsiteCount + $wfaCount) > 0
                ? round(($lateCount / $presentCount) * 100, 1)
                : 0,
            'active_sanctions_count' => EmployeeSanction::where('status', 'ACTIVE')->count(),
            'active_sp_count' => EmployeeSanction::where('status', 'ACTIVE')->whereIn('level', ['SP1', 'SP2', 'SP3'])->count(),
        ];

        // 3. EVALUASI PRODUKTIVITAS & PENYELESAIAN TUGAS (TASK COMPLETION ANALYTICS)
        $obligatedEmployeesCount = User::whereDoesntHave('roles', function ($q) {
            $q->where('is_attendance_required', false);
        })->count();

        $allDailyReports = DailyReport::select([
            'evening_completed_tasks',
            'evening_pending_tasks',
            'evening_additional_tasks',
        ])->get();
        $completedTaskItems = 0;
        $pendingTaskItems = 0;
        $additionalTaskItems = 0;

        foreach ($allDailyReports as $dr) {
            if (! empty($dr->evening_completed_tasks)) {
                $lines = array_filter(array_map('trim', preg_split('/\r?\n/', $dr->evening_completed_tasks)));
                $completedTaskItems += count($lines);
            }
            if (! empty($dr->evening_pending_tasks)) {
                $lines = array_filter(array_map('trim', preg_split('/\r?\n/', $dr->evening_pending_tasks)));
                $pendingTaskItems += count($lines);
            }
            if (! empty($dr->evening_additional_tasks)) {
                $lines = array_filter(array_map('trim', preg_split('/\r?\n/', $dr->evening_additional_tasks)));
                $additionalTaskItems += count($lines);
            }
        }

        $totalTrackedTasks = max(1, $completedTaskItems + $pendingTaskItems);
        $taskCompletionPct = ($completedTaskItems + $pendingTaskItems) > 0
            ? round(($completedTaskItems / $totalTrackedTasks) * 100, 1)
            : 0;

        $todayReports = DailyReport::whereDate('date', $today)->get();
        $taskAnalytics = [
            'obligated_staff' => $obligatedEmployeesCount,
            'today_submitted' => $todayReports->count(),
            'today_completed_reports' => $todayReports->where('status', 'COMPLETED')->count(),
            'completed_items' => $completedTaskItems,
            'pending_items' => $pendingTaskItems,
            'additional_items' => $additionalTaskItems,
            'completion_rate_pct' => $taskCompletionPct,
        ];

        $todayOnsite = Attendance::whereDate('date', $today)->where('status', 'HADIR_ON_SITE')->count();
        $todayWfa = Attendance::whereDate('date', $today)->where('status', 'WFA')->count();
        $todayTugasLuar = Attendance::whereDate('date', $today)->where('status', 'TUGAS_LUAR')->count();

        $stats = [
            'total_employees' => User::count(),
            'kartap_count' => User::where('employment_type', 'KARTAP')->count(),
            'pkwt_count' => User::where('employment_type', 'PKWT')->count(),
            'intern_count' => User::where('employment_type', 'INTERN')->count(),
            'today_onsite' => $todayOnsite,
            'today_wfa' => $todayWfa,
            'today_tugas_luar' => $todayTugasLuar,
            'today_present_total' => $todayOnsite + $todayWfa + $todayTugasLuar,
            'today_leave' => Attendance::whereDate('date', $today)->whereIn('status', ['CUTI', 'SAKIT', 'IZIN'])->count(),
            'pending_leaves' => LeaveRequest::where('status', 'PENDING')->count(),
            'total_month_overtime_hours' => (int) Attendance::whereMonth('date', $currentMonth)->whereYear('date', $currentYear)->sum('overtime_hours'),
        ];

        $recentAttendances = Attendance::with('user')
            ->whereDate('date', $today)
            ->orderBy('time_in', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate($perPage)
            ->withQueryString();

        return view('executive.dashboard', compact(
            'stats',
            'attendanceTrend',
            'maxMonthlyTotal',
            'attendanceAnalytics',
            'taskAnalytics',
            'recentAttendances'
        ));
    }
}
