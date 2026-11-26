<?php

namespace App\Http\Controllers\Approval;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class LeaveApprovalController extends Controller
{
    private function authorizeApprover(): void
    {
        $user = auth()->user();

        if (! $user || (! $user->can_approve_leaves && ! $user->hasRole('super_admin'))) {
            abort(403, 'Anda tidak memiliki wewenang untuk mengakses persetujuan perizinan.');
        }
    }

    public function index(Request $request): View
    {
        $this->authorizeApprover();

        $search = $request->input('search');
        $userId = $request->input('user_id');
        $type = $request->input('type');
        $status = $request->input('status');

        $pendingQuery = LeaveRequest::with('user')
            ->where('status', 'PENDING')
            ->where('user_id', '!=', auth()->id());

        $historyQuery = LeaveRequest::with(['user', 'approver'])
            ->whereIn('status', ['APPROVED', 'REJECTED']);

        if ($userId) {
            $pendingQuery->where('user_id', $userId);
            $historyQuery->where('user_id', $userId);
        }

        if ($search) {
            $pendingQuery->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
            $historyQuery->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($type) {
            $pendingQuery->where('type', $type);
            $historyQuery->where('type', $type);
        }

        if ($status && in_array($status, ['APPROVED', 'REJECTED'])) {
            $historyQuery->where('status', $status);
        }

        $perPage = in_array((int) $request->input('per_page'), [5, 10, 15, 25, 50])
            ? (int) $request->input('per_page')
            : 10;

        $pendingLeaves = $pendingQuery->latest()->paginate(6, ['*'], 'pending_page')->withQueryString();
        $historyLeaves = $historyQuery->latest('updated_at')->paginate($perPage)->withQueryString();
        $users = User::orderBy('name')->get(['id', 'name', 'email', 'employment_type']);

        return view('approvals.index', compact(
            'pendingLeaves',
            'historyLeaves',
            'users',
            'userId',
            'search',
            'type',
            'status'
        ));
    }

    public function approve(LeaveRequest $leaveRequest): RedirectResponse
    {
        $this->authorizeApprover();

        if ($leaveRequest->user_id === auth()->id()) {
            abort(403, 'Anda tidak dapat menyetujui pengajuan perizinan milik Anda sendiri.');
        }

        if ($leaveRequest->status !== 'PENDING') {
            return back()->with('error', "Pengajuan {$leaveRequest->type} sudah diproses sebelumnya.");
        }

        $leaveRequest->approve(auth()->user());

        return back()->with('success', "Pengajuan {$leaveRequest->type} berhasil disetujui dan data presensi otomatis di-generate.");
    }

    public function reject(Request $request, LeaveRequest $leaveRequest): RedirectResponse
    {
        $this->authorizeApprover();

        if ($leaveRequest->user_id === auth()->id()) {
            abort(403, 'Anda tidak dapat menolak pengajuan perizinan milik Anda sendiri.');
        }

        if ($leaveRequest->status !== 'PENDING') {
            return back()->with('error', "Pengajuan {$leaveRequest->type} sudah diproses sebelumnya.");
        }

        $request->validate([
            'rejection_reason' => 'required|string|max:500',
        ]);

        $leaveRequest->reject(auth()->user(), $request->input('rejection_reason'));

        return back()->with('success', 'Pengajuan cuti/izin telah ditolak.');
    }
}
