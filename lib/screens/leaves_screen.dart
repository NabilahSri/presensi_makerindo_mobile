import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_widgets.dart';

class LeavesScreen extends StatefulWidget {
  final AuthController auth;
  final int refreshTick;
  final VoidCallback? onStatusUpdated;

  const LeavesScreen({
    super.key,
    required this.auth,
    this.refreshTick = 0,
    this.onStatusUpdated,
  });

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  int _segment = 0; // 0 = Pengajuan Saya, 1 = Persetujuan Tim (if approver)

  // My leaves
  bool _loadingMyLeaves = true;
  String? _myLeavesError;
  List<LeaveRequestModel> _myLeaves = [];
  bool _hasCheckedInToday = false;

  // Team approvals
  String _approvalFilter = 'PENDING';
  bool _loadingApprovals = false;
  String? _approvalsError;
  int _totalPending = 0;
  List<LeaveRequestModel> _approvals = [];

  bool get _canApprove => widget.auth.user?.uiFlags.showLeaveApprovalMenu ?? false;

  @override
  void initState() {
    super.initState();
    _loadMyLeaves();
    if (_canApprove) {
      _loadApprovals();
    }
  }

  @override
  void didUpdateWidget(covariant LeavesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_canApprove && _segment != 0) {
      setState(() => _segment = 0);
    }
    if (widget.refreshTick != oldWidget.refreshTick) {
      _loadMyLeaves();
      if (_canApprove) {
        _loadApprovals();
      }
    }
  }

  Future<void> _loadMyLeaves() async {
    setState(() {
      _loadingMyLeaves = true;
      _myLeavesError = null;
    });
    try {
      final results = await Future.wait([
        widget.auth.api.getMyLeaves(),
        widget.auth.api
            .getAttendanceToday()
            .then<AttendanceTodayData?>((v) => v)
            .catchError((_) => null),
      ]);
      final list = results[0] as List<LeaveRequestModel>;
      final today = results[1] as AttendanceTodayData?;
      if (mounted) {
        setState(() {
          _myLeaves = list;
          if (today != null) {
            _hasCheckedInToday = today.hasCheckedIn;
          }
          _loadingMyLeaves = false;
          _myLeavesError = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _myLeavesError = e.message;
          _loadingMyLeaves = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myLeavesError = 'Gagal memuat daftar pengajuan: $e';
          _loadingMyLeaves = false;
        });
      }
    }
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _loadingApprovals = true;
      _approvalsError = null;
    });
    try {
      final res = await widget.auth.api.getLeaveApprovals(status: _approvalFilter);
      if (mounted) {
        setState(() {
          _totalPending = res.totalPending;
          _approvals = res.items;
          _loadingApprovals = false;
          _approvalsError = null;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        await widget.auth.refreshProfile().catchError((_) {});
        if (mounted) {
          setState(() {
            _segment = 0;
            _loadingApprovals = false;
            _approvalsError = null;
          });
          await _loadMyLeaves();
        }
        return;
      }
      if (mounted) {
        setState(() {
          _approvalsError = e.message;
          _loadingApprovals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _approvalsError = 'Gagal memuat antrean persetujuan: $e';
          _loadingApprovals = false;
        });
      }
    }
  }

  Future<void> _openCreateLeaveSheet({LeaveRequestModel? existingLeave}) async {
    try {
      final today = await widget.auth.api.getAttendanceToday();
      if (mounted) {
        setState(() => _hasCheckedInToday = today.hasCheckedIn);
      }
    } catch (_) {
      // Gunakan status terakhir jika pengecekan gagal
    }
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateLeaveSheet(
        auth: widget.auth,
        hasCheckedInToday: _hasCheckedInToday,
        existingLeave: existingLeave,
      ),
    );
    await _loadMyLeaves();
    if (saved == true) {
      widget.onStatusUpdated?.call();
    }
  }

  Future<void> _confirmCancelLeave(LeaveRequestModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ChronoColors.dangerBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: ChronoColors.dangerBorder),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: ChronoColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Batalkan Pengajuan?',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          'Pengajuan ${item.displayType} pada ${ChronoFormat.dateIndo(item.startDate)} - ${ChronoFormat.dateIndo(item.endDate)} akan dibatalkan dan dihapus dari daftar tunggu persetujuan.',
          style: const TextStyle(
            fontSize: 13,
            color: ChronoColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ChronoColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final msg = await widget.auth.api.cancelLeaveRequest(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _loadMyLeaves();
        widget.onStatusUpdated?.call();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    }
  }

  void _openAttachmentPreview(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ChronoColors.dark,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lampiran Bukti Perizinan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 440),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: ChronoColors.skyLight),
                    );
                  },
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Pratinjau gambar tidak tersedia atau berkas berformat PDF.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprovalDecision(LeaveRequestModel item, String status) async {
    String? rejectionReason;
    if (status == 'REJECTED') {
      final controller = TextEditingController();
      final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Alasan Penolakan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan Penolakan (Wajib)',
              hintText: 'Jelaskan alasan penolakan pengajuan ini',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ChronoColors.danger),
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Tolak Pengajuan'),
            ),
          ],
        ),
      );
      if (submitted != true) return;
      rejectionReason = controller.text.trim();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Setujui Pengajuan?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Pengajuan ${item.displayType} dari ${item.requesterName ?? "pegawai"} (${ChronoFormat.dateIndo(item.startDate)} - ${ChronoFormat.dateIndo(item.endDate)}) akan disetujui dan otomatis tercatat pada presensi.',
            style: const TextStyle(fontSize: 13, color: ChronoColors.textSecondary, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ChronoColors.success),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Ya, Setujui'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final msg = await widget.auth.api.processLeaveApproval(
        leaveId: item.id,
        status: status,
        rejectionReason: rejectionReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _loadApprovals();
        widget.onStatusUpdated?.call();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSegment = _canApprove ? _segment : 0;

    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(
        title: Text(_canApprove ? 'Perizinan & Persetujuan' : 'Pengajuan Saya'),
        actions: [
          if (activeSegment == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _openCreateLeaveSheet,
                style: TextButton.styleFrom(
                  foregroundColor: ChronoColors.sky,
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Ajukan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_canApprove)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: ChronoColors.surface,
                border: Border(bottom: BorderSide(color: ChronoColors.border)),
              ),
              child: SegmentedButton<int>(
                segments: [
                  const ButtonSegment(value: 0, label: Text('Pengajuan Saya')),
                  ButtonSegment(
                    value: 1,
                    label: Text(
                      _totalPending > 0 ? 'Persetujuan ($_totalPending)' : 'Persetujuan',
                    ),
                  ),
                ],
                selected: {activeSegment},
                onSelectionChanged: (v) {
                  setState(() => _segment = v.first);
                  if (v.first == 0) {
                    _loadMyLeaves();
                  } else {
                    _loadApprovals();
                  }
                },
              ),
            ),
          Expanded(
            child: activeSegment == 0 ? _buildMyLeavesList() : _buildApprovalsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLeavesList() {
    if (_loadingMyLeaves) {
      return const ChronoLoadingState(message: 'Memuat riwayat pengajuan perizinan...');
    }
    if (_myLeavesError != null) {
      return ChronoErrorState(
        title: 'Gagal Memuat Perizinan',
        message: _myLeavesError!,
        onRetry: _loadMyLeaves,
      );
    }
    if (_myLeaves.isEmpty) {
      return ChronoEmptyState(
        icon: Icons.event_available_outlined,
        title: 'Belum Ada Pengajuan Izin',
        description:
            'Anda belum pernah mengajukan Cuti, Tugas Luar, Sakit, Izin, atau WFA. Buat pengajuan baru lengkap dengan unggah bukti bila diperlukan.',
        actionLabel: 'Ajukan Perizinan Baru',
        onAction: _openCreateLeaveSheet,
      );
    }

    return RefreshIndicator(
      color: ChronoColors.sky,
      onRefresh: _loadMyLeaves,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _myLeaves.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, idx) {
          final item = _myLeaves[idx];
          return ChronoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChronoStatusTag(
                      label: item.displayType,
                      tone: _typeTone(item.type),
                    ),
                    const Spacer(),
                    ChronoStatusTag(
                      label: item.displayStatus,
                      tone: _statusTone(item.status),
                      showStateDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${ChronoFormat.dateIndo(item.startDate)} - ${ChronoFormat.dateIndo(item.endDate)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ChronoColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (item.approverName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        item.status == 'APPROVED'
                            ? Icons.verified_outlined
                            : (item.status == 'REJECTED'
                                ? Icons.cancel_outlined
                                : Icons.person_outline_rounded),
                        size: 14,
                        color: item.status == 'APPROVED'
                            ? ChronoColors.successDark
                            : (item.status == 'REJECTED'
                                ? ChronoColors.dangerDark
                                : ChronoColors.textMuted),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.status == 'APPROVED'
                              ? 'Disetujui oleh: ${item.approverName}'
                              : (item.status == 'REJECTED'
                                  ? 'Ditolak oleh: ${item.approverName}'
                                  : 'Ditinjau oleh: ${item.approverName}'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: item.status == 'APPROVED'
                                ? ChronoColors.successDark
                                : (item.status == 'REJECTED'
                                    ? ChronoColors.dangerDark
                                    : ChronoColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (item.status == 'APPROVED' && item.type == 'SAKIT') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Otomatis disetujui (tanpa perlu persetujuan atasan)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: ChronoColors.successDark,
                    ),
                  ),
                ],
                if (item.rejectionReason != null && item.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ChronoColors.dangerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ChronoColors.dangerBorder),
                    ),
                    child: Text(
                      'Alasan penolakan: ${item.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ChronoColors.dangerDark,
                      ),
                    ),
                  ),
                ],
                if (item.attachmentUrl != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openAttachmentPreview(item.attachmentUrl!),
                    icon: const Icon(Icons.attachment_rounded, size: 17),
                    label: const Text('Lihat Lampiran Bukti'),
                  ),
                ],
                if (item.status.toUpperCase() == 'PENDING') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: ChronoColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () => _openCreateLeaveSheet(existingLeave: item),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Ubah'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmCancelLeave(item),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ChronoColors.danger,
                              side: const BorderSide(color: ChronoColors.dangerBorder),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Batalkan'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovalsView() {
    const filters = [
      ('PENDING', 'Menunggu'),
      ('APPROVED', 'Disetujui'),
      ('REJECTED', 'Ditolak'),
      ('ALL', 'Semua'),
    ];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: filters.map((f) {
              final selected = _approvalFilter == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.$2),
                  selected: selected,
                  selectedColor: ChronoColors.dark,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: selected ? Colors.white : ChronoColors.slate,
                  ),
                  onSelected: (_) {
                    setState(() => _approvalFilter = f.$1);
                    _loadApprovals();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loadingApprovals
              ? const ChronoLoadingState(message: 'Memuat daftar persetujuan izin...')
              : _approvalsError != null
                  ? ChronoErrorState(
                      title: 'Gagal Memuat Persetujuan',
                      message: _approvalsError!,
                      onRetry: _loadApprovals,
                    )
                  : _approvals.isEmpty
                      ? ChronoEmptyState(
                          icon: Icons.task_alt_rounded,
                          title: 'Antrean Persetujuan Kosong',
                          description: _approvalFilter == 'PENDING'
                              ? 'Semua pengajuan perizinan pegawai sudah diproses.'
                              : 'Tidak ada pengajuan dengan status terpilih.',
                        )
                      : RefreshIndicator(
                          color: ChronoColors.sky,
                          onRefresh: _loadApprovals,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                            itemCount: _approvals.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, idx) {
                              final item = _approvals[idx];
                              return ChronoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.requesterName ?? 'Pegawai',
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (item.requesterEmploymentType != null)
                                                Text(
                                                  item.displayRequesterEmploymentType ??
                                                      item.requesterEmploymentType!,
                                                  style: ChronoTheme.mono(
                                                    fontSize: 11,
                                                    color: ChronoColors.sky,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        ChronoStatusTag(
                                          label: item.displayType,
                                          tone: _typeTone(item.type),
                                        ),
                                        const SizedBox(width: 6),
                                        ChronoStatusTag(
                                          label: item.displayStatus,
                                          tone: _statusTone(item.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${ChronoFormat.dateIndo(item.startDate)} - ${ChronoFormat.dateIndo(item.endDate)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.reason,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: ChronoColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (item.status == 'APPROVED' && item.approverName != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.verified_outlined,
                                            size: 14,
                                            color: ChronoColors.successDark,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Disetujui oleh: ${item.approverName}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: ChronoColors.successDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (item.status == 'APPROVED' && item.type == 'SAKIT') ...[
                                      const SizedBox(height: 8),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.verified_outlined,
                                            size: 14,
                                            color: ChronoColors.successDark,
                                          ),
                                          SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Otomatis disetujui (Sakit)',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: ChronoColors.successDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (item.status == 'REJECTED' &&
                                        item.approverName != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.cancel_outlined,
                                            size: 14,
                                            color: ChronoColors.dangerDark,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Ditolak oleh: ${item.approverName}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: ChronoColors.dangerDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (item.rejectionReason != null &&
                                        item.rejectionReason!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: ChronoColors.dangerBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: ChronoColors.dangerBorder),
                                        ),
                                        child: Text(
                                          'Alasan penolakan: ${item.rejectionReason}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: ChronoColors.dangerDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (item.attachmentUrl != null) ...[
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _openAttachmentPreview(item.attachmentUrl!),
                                        icon: const Icon(Icons.visibility_outlined, size: 17),
                                        label: const Text('Periksa Berkas Bukti'),
                                      ),
                                    ],
                                    if (item.status == 'PENDING') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _handleApprovalDecision(item, 'REJECTED'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: ChronoColors.danger,
                                                side: const BorderSide(
                                                  color: ChronoColors.dangerBorder,
                                                ),
                                              ),
                                              child: const Text('Tolak'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _handleApprovalDecision(item, 'APPROVED'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: ChronoColors.success,
                                              ),
                                              child: const Text('Setujui'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  BadgeTone _typeTone(String type) {
    switch (type.toUpperCase()) {
      case 'WFA':
      case 'WFH':
      case 'TUGAS_LUAR':
        return BadgeTone.sky;
      case 'SAKIT':
        return BadgeTone.danger;
      case 'CUTI':
        return BadgeTone.success;
      default:
        return BadgeTone.warning;
    }
  }

  BadgeTone _statusTone(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return BadgeTone.success;
      case 'REJECTED':
        return BadgeTone.danger;
      default:
        return BadgeTone.warning;
    }
  }
}

class _CreateLeaveSheet extends StatefulWidget {
  final AuthController auth;
  final bool hasCheckedInToday;
  final LeaveRequestModel? existingLeave;

  const _CreateLeaveSheet({
    required this.auth,
    this.hasCheckedInToday = false,
    this.existingLeave,
  });

  @override
  State<_CreateLeaveSheet> createState() => _CreateLeaveSheetState();
}

class _CreateLeaveSheetState extends State<_CreateLeaveSheet> {
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();

  String _type = 'WFA';
  late DateTime _startDate;
  late DateTime _endDate;
  File? _attachment;
  bool _submitting = false;

  static const _leaveTypes = [
    ('SAKIT', 'Sakit'),
    ('IZIN', 'Izin'),
    ('WFA', 'WFA'),
    ('CUTI', 'Cuti'),
    ('TUGAS_LUAR', 'Tugas Luar'),
  ];

  DateTime get _todayOnly {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _minStartDateForType(String type) {
    return switch (type) {
      'CUTI' => _todayOnly.add(const Duration(days: 7)),
      'IZIN' => _todayOnly.add(const Duration(days: 1)),
      'TUGAS_LUAR' || 'WFA' => _todayOnly,
      _ => DateTime(2020, 1, 1), // SAKIT fleksibel tanpa batas 7 hari
    };
  }

  DateTime _defaultStartDateForType(String type) {
    return switch (type) {
      'CUTI' => _todayOnly.add(const Duration(days: 7)),
      'IZIN' => _todayOnly.add(const Duration(days: 1)),
      _ => _todayOnly,
    };
  }

  (String message, bool isAutoApproved) _policyNoticeForType(String type) {
    return switch (type) {
      'CUTI' => (
          'Pengajuan Cuti wajib minimal 7 hari (1 minggu) sebelumnya dan menunggu persetujuan atasan.',
          false,
        ),
      'IZIN' => (
          'Pengajuan Izin wajib minimal 1 hari sebelumnya dan menunggu persetujuan atasan.',
          false,
        ),
      'WFA' => (
          'Pengajuan WFA dapat diajukan mulai hari ini dan menunggu persetujuan atasan. Setelah disetujui, presensi dapat dilakukan melalui Kamera & GPS.',
          false,
        ),
      'TUGAS_LUAR' => (
          'Pengajuan Tugas Luar dapat diajukan mulai hari ini dan menunggu persetujuan atasan. Setelah disetujui, presensi dapat dilakukan melalui Kamera & GPS.',
          false,
        ),
      _ => (
          'Pengajuan Sakit langsung disetujui otomatis tanpa perlu menunggu persetujuan atasan dan langsung tercatat pada presensi.',
          true,
        ),
    };
  }

  bool get _isEditing => widget.existingLeave != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLeave;
    if (existing != null) {
      final rawType = existing.type.toUpperCase();
      _type = rawType == 'WFH' ? 'WFA' : rawType;
      _startDate = DateTime.tryParse(existing.startDate) ?? _defaultStartDateForType(_type);
      _endDate = DateTime.tryParse(existing.endDate) ?? _startDate;
      _reasonController.text = existing.reason;
    } else {
      _startDate = _defaultStartDateForType(_type);
      _endDate = _startDate;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    final minDate = _minStartDateForType(newType);
    final defDate = _defaultStartDateForType(newType);
    setState(() {
      _type = newType;
      if (_startDate.isBefore(minDate) ||
          newType == 'SAKIT' ||
          newType == 'TUGAS_LUAR' ||
          newType == 'WFA') {
        _startDate = defDate;
        _endDate = defDate;
      } else if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final minDate = isStart ? _minStartDateForType(_type) : _startDate;
    var initial = isStart ? _startDate : _endDate;
    if (initial.isBefore(minDate)) {
      initial = minDate;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: _todayOnly.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1400);
      if (file != null && mounted) {
        setState(() => _attachment = File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text('Gagal memilih berkas: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ChronoColors.danger,
          content: Text('Alasan pengajuan wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final String msg;
      if (_isEditing) {
        msg = await widget.auth.api.updateLeaveRequest(
          leaveId: widget.existingLeave!.id,
          type: _type,
          startDate: fmt.format(_startDate),
          endDate: fmt.format(_endDate),
          reason: _reasonController.text.trim(),
          attachment: _attachment,
        );
      } else {
        msg = await widget.auth.api.submitLeaveRequest(
          type: _type,
          startDate: fmt.format(_startDate),
          endDate: fmt.format(_endDate),
          reason: _reasonController.text.trim(),
          attachment: _attachment,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Ubah Pengajuan Perizinan' : 'Formulir Pengajuan Perizinan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _leaveTypes.map((t) {
                final selected = _type == t.$1;
                final isDisabled = t.$1 == 'SAKIT' && widget.hasCheckedInToday;
                return ChoiceChip(
                  label: Text(t.$2),
                  selected: selected,
                  selectedColor: ChronoColors.dark,
                  backgroundColor:
                      isDisabled ? ChronoColors.surfaceMuted : ChronoColors.background,
                  disabledColor: ChronoColors.surfaceMuted,
                  side: BorderSide(
                    color: selected
                        ? ChronoColors.dark
                        : (isDisabled ? ChronoColors.border : ChronoColors.borderStrong),
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: selected
                        ? Colors.white
                        : (isDisabled ? ChronoColors.textMuted : ChronoColors.slate),
                  ),
                  onSelected: isDisabled ? null : (_) => _onTypeChanged(t.$1),
                );
              }).toList(),
            ),
            if (widget.hasCheckedInToday) ...[
              const SizedBox(height: 8),
              const Text(
                'Opsi Sakit dinonaktifkan hari ini karena Anda sudah melakukan presensi masuk.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ChronoColors.warningDark,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Builder(
              builder: (_) {
                final (noticeText, isAutoApproved) = _policyNoticeForType(_type);
                return Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: isAutoApproved ? ChronoColors.successBg : ChronoColors.skyTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAutoApproved ? ChronoColors.successBorder : ChronoColors.skySoft,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isAutoApproved ? Icons.verified_outlined : Icons.info_outline_rounded,
                        size: 17,
                        color: isAutoApproved ? ChronoColors.successDark : ChronoColors.skyDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          noticeText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: isAutoApproved ? ChronoColors.successDark : ChronoColors.skyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(dateFmt.format(_startDate)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('s/d', style: TextStyle(fontSize: 12, color: ChronoColors.textMuted)),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(dateFmt.format(_endDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan / Keterangan',
                hintText: 'Tuliskan alasan pengajuan secara singkat dan jelas',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Foto Bukti / Surat Keterangan Dokter (Opsional)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_attachment == null && widget.existingLeave?.attachmentUrl != null) ...[
              const Text(
                'Lampiran sebelumnya tersimpan. Pilih foto baru hanya jika ingin menggantinya.',
                style: TextStyle(fontSize: 11.5, color: ChronoColors.textMuted),
              ),
              const SizedBox(height: 8),
            ],
            if (_attachment != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Image.file(_attachment!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAttachment(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 17),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAttachment(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 17),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _type == 'SAKIT'
                            ? 'Kirim Laporan Sakit (Otomatis Disetujui)'
                            : (_isEditing ? 'Simpan Perubahan' : 'Kirim Pengajuan'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
