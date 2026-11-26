import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_logo.dart';
import '../widgets/chrono_widgets.dart';
import 'attendance_history_screen.dart';
import 'mobile_checkin_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final AuthController auth;
  final void Function(int tabIndex) onNavigateTab;
  final int refreshTick;
  final ValueChanged<AttendanceTodayData>? onTodayLoaded;

  const HomeDashboardScreen({
    super.key,
    required this.auth,
    required this.onNavigateTab,
    this.refreshTick = 0,
    this.onTodayLoaded,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  AttendanceTodayData? _today;
  int _pendingApprovals = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await widget.auth.refreshBranding().catchError((_) {});
    await widget.auth.refreshProfile().catchError((_) {});
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!_loading || _error != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = widget.auth.user;
      final todayFuture = widget.auth.api.getAttendanceToday();
      Future<({int totalPending, List<LeaveRequestModel> items})>? approvalsFuture;
      if (user != null && user.uiFlags.showLeaveApprovalMenu) {
        approvalsFuture = widget.auth.api.getLeaveApprovals(status: 'PENDING');
      }

      final today = await todayFuture;
      int pending = 0;
      if (approvalsFuture != null) {
        try {
          final appRes = await approvalsFuture;
          pending = appRes.totalPending;
        } catch (_) {
          // Do not block dashboard if approval badge fails
        }
      }

      widget.onTodayLoaded?.call(today);

      if (mounted) {
        setState(() {
          _today = today;
          _pendingApprovals = pending;
          _loading = false;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.auth.clearSession();
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data kehadiran hari ini: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openCheckIn(AttendanceTodayData today, CheckInMode mode) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          await showLocationRequiredDialog(context, isPermissionDenied: false);
        }
        return;
      }
    } catch (_) {
      // Lanjutkan ke halaman check-in jika pengecekan awal tidak didukung platform
    }

    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MobileCheckInScreen(
          auth: widget.auth,
          mode: mode,
          officeName: today.officeName,
          officeLatitude: today.officeLatitude,
          officeLongitude: today.officeLongitude,
          officeRadiusMeters: today.officeRadiusMeters,
        ),
      ),
    );
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final brand = widget.auth.brand;
    if (user == null) {
      return const ChronoLoadingState(message: 'Menyiapkan data akun...');
    }

    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ChronoLogoMark(size: 32, darkBackground: true, logoUrl: brand.logoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChronoBrandTitle(name: brand.appName, fontSize: 16),
                  Text(
                    brand.appSlogan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: ChronoColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LiveClockBadge(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: ChronoColors.sky,
        onRefresh: () async {
          await widget.auth.refreshBranding().catchError((_) {});
          await widget.auth.refreshProfile().catchError((_) {});
          await _loadData();
        },
        child: _loading
            ? const ChronoLoadingState(message: 'Memuat status presensi hari ini...')
            : _error != null
                ? ChronoErrorState(
                    title: 'Gagal Memuat Dasbor',
                    message: _error!,
                    onRetry: _loadData,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _buildHeroAttendanceCard(user, _today!),
                      const SizedBox(height: 16),
                      _buildDailyReportCard(_today!),
                      const SizedBox(height: 16),
                      _buildAttendanceGuidanceBanner(user),
                      const SizedBox(height: 20),
                      Text(
                        'Akses Cepat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _buildQuickActions(user),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeroAttendanceCard(UserProfile user, AttendanceTodayData today) {
    final att = today.attendance;
    final statusLabel = today.hasCheckedOut
        ? 'Presensi Lengkap'
        : today.hasCheckedIn
            ? (att?.displayStatus ?? 'Sudah Masuk')
            : today.isOnLeaveToday
                ? 'Sedang ${att?.displayStatus ?? today.todayLeaveStatus ?? "Izin"}'
                : 'Belum Presensi Masuk';
    final statusColor = today.hasCheckedOut
        ? ChronoColors.success
        : today.hasCheckedIn
            ? ChronoColors.skyLight
            : today.isOnLeaveToday
                ? ChronoColors.skyLight
                : ChronoColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ChronoColors.dark, ChronoColors.navy],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ChronoColors.slate.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: ChronoColors.skyLight.withValues(alpha: 0.45), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty)
                    ? Image.network(
                        user.profilePhotoUrl!,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          user.initials,
                          style: ChronoTheme.mono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ChronoColors.skyLight,
                          ),
                        ),
                      )
                    : Text(
                        user.initials,
                        style: ChronoTheme.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ChronoColors.skyLight,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ChronoFormat.fullDateIndo(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ChronoColors.sky.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ChronoColors.skyLight.withValues(alpha: 0.4)),
                ),
                child: Text(
                  user.shortEmploymentLabel,
                  style: ChronoTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ChronoColors.skyLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Real-time status strip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (att != null && today.hasCheckedIn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: att.isLate
                              ? ChronoColors.warning.withValues(alpha: 0.25)
                              : ChronoColors.success.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          att.isLate ? 'Terlambat' : 'Tepat Waktu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: att.isLate
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFA7F3D0),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TimeMetricDark(
                        label: 'Jam Masuk',
                        value: ChronoFormat.shortTime(att?.timeIn),
                      ),
                    ),
                    Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.12)),
                    Expanded(
                      child: _TimeMetricDark(
                        label: 'Jam Pulang',
                        value: ChronoFormat.shortTime(att?.timeOut),
                      ),
                    ),
                    Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.12)),
                    Expanded(
                      child: _TimeMetricDark(
                        label: 'Lembur',
                        value: '${att?.overtimeHours ?? 0} jam',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary contextual action button
          _buildPrimaryAttendanceAction(user, today),
        ],
      ),
    );
  }

  Widget _buildPrimaryAttendanceAction(UserProfile user, AttendanceTodayData today) {
    if (today.isOnLeaveToday) {
      final leaveLabel = today.attendance?.displayStatus ?? today.todayLeaveStatus ?? 'Izin';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ChronoColors.sky.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ChronoColors.skyLight.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded, color: ChronoColors.skyLight, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status kehadiran hari ini tercatat sebagai $leaveLabel. Anda tidak perlu melakukan presensi masuk.',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE0F2FE),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!today.hasCheckedIn) {
      if (today.canMobileCheckIn) {
        final mode = today.hasApprovedTugasLuarToday
            ? CheckInMode.approvedTugasLuar
            : today.hasApprovedWfaToday
                ? CheckInMode.approvedWfa
                : CheckInMode.internDaily;
        final label = today.hasApprovedTugasLuarToday
            ? 'Presensi Masuk Tugas Luar (Kamera & GPS)'
            : today.hasApprovedWfaToday
                ? 'Presensi Masuk WFA (Kamera & GPS)'
                : 'Presensi Masuk Magang (Kamera & GPS)';
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _openCheckIn(today, mode),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronoColors.sky,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 19),
            label: Text(label),
          ),
        );
      }

      // Karyawan (KARTAP/PKWT) tanpa izin WFA/Tugas Luar yang disetujui hari ini:
      // 1) Presensi masuk kantor dengan GPS (strict geofence radius kantor) & Foto Selfie
      // 2) Atau ajukan WFA / Tugas Luar / Cuti / Sakit / Izin
      final wfaStatus = today.wfaRequestTodayStatus;
      final tugasLuarStatus = today.tugasLuarRequestTodayStatus;
      final infoMessage = tugasLuarStatus == 'PENDING'
          ? 'Pengajuan Tugas Luar hari ini masih menunggu persetujuan. Jika hadir di kantor, lakukan presensi menggunakan GPS & Foto di dalam radius kantor (${today.officeRadiusMeters} m).'
          : switch (wfaStatus) {
              'PENDING' =>
                'Pengajuan WFA hari ini masih menunggu persetujuan. Jika hadir di kantor, lakukan presensi menggunakan GPS & Foto di dalam radius kantor (${today.officeRadiusMeters} m).',
              'REJECTED' =>
                'Pengajuan WFA hari ini ditolak. Silakan lakukan presensi kantor menggunakan GPS & Foto di dalam radius kantor (${today.officeRadiusMeters} m).',
              _ =>
                'Presensi masuk kantor dilakukan melalui GPS dalam radius kantor (${today.officeRadiusMeters} m) dan verifikasi foto selfie.',
            };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: ChronoColors.skyLight, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    infoMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE2E8F0),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openCheckIn(today, CheckInMode.onsiteOffice),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChronoColors.sky,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 19),
              label: const Text('Presensi Masuk Kantor (GPS & Foto)'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => widget.onNavigateTab(2),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              ),
              icon: const Icon(Icons.event_note_outlined, size: 17),
              label: Text(
                wfaStatus == 'PENDING' || tugasLuarStatus == 'PENDING'
                    ? 'Cek Status Pengajuan'
                    : 'Ajukan Cuti / Tugas Luar / WFA',
              ),
            ),
          ),
        ],
      );
    }

    if (!today.hasCheckedOut) {
      if (!today.canCheckout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => widget.onNavigateTab(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ChronoColors.dark,
                ),
                icon: const Icon(Icons.assignment_outlined, size: 19),
                label: Text(
                  today.hasMorningReport
                      ? 'Isi Evaluasi Sore untuk Buka Presensi Pulang'
                      : 'Isi Laporan Harian Pagi Sekarang',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tombol Presensi Pulang (GPS & Foto) baru terbuka setelah Laporan Harian sore selesai.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
            ),
          ],
        );
      }

      final isOnsiteCheckout = today.checkoutMode == 'ONSITE_GEOFENCE';

      if (isOnsiteCheckout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChronoColors.success.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChronoColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF6EE7B7), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Laporan Harian sore selesai. Lakukan presensi pulang dari dalam radius kantor (${today.officeRadiusMeters} m) dengan verifikasi GPS dan foto selfie.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD1FAE5),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _openCheckIn(today, CheckInMode.checkoutOnsiteOffice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChronoColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 19),
                label: const Text('Presensi Pulang Kantor (GPS & Foto)'),
              ),
            ),
          ],
        );
      }

      final checkoutMode = user.isIntern
          ? CheckInMode.checkoutIntern
          : (today.attendance?.status.toUpperCase() == 'TUGAS_LUAR'
              ? CheckInMode.checkoutTugasLuar
              : CheckInMode.checkoutWfa);
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _openCheckIn(today, checkoutMode),
          style: ElevatedButton.styleFrom(
            backgroundColor: ChronoColors.success,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.camera_alt_outlined, size: 19),
          label: const Text('Presensi Pulang (Kamera & GPS)'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ChronoColors.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChronoColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF6EE7B7), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Presensi hari ini selesai (${ChronoFormat.shortTime(today.attendance?.timeIn)} - ${ChronoFormat.shortTime(today.attendance?.timeOut)} WIB).',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD1FAE5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReportCard(AttendanceTodayData today) {
    final isLocked = !today.hasCheckedIn;
    final hasMorning = !isLocked && today.hasMorningReport;
    final hasEvening = !isLocked && today.hasEveningReport;

    final statusLabel = isLocked
        ? 'Terkunci'
        : hasEvening
            ? 'Selesai'
            : hasMorning
                ? 'Menunggu Sore'
                : 'Menunggu Pagi';
    final statusTone = isLocked
        ? BadgeTone.neutral
        : hasEvening
            ? BadgeTone.success
            : hasMorning
                ? BadgeTone.warning
                : BadgeTone.sky;

    final buttonLabel = isLocked
        ? (today.isOnLeaveToday
            ? 'Sedang Izin / Cuti / Sakit'
            : 'Presensi Masuk Terlebih Dahulu')
        : hasEvening
            ? 'Lihat Ringkasan Laporan Harian'
            : hasMorning
                ? 'Isi Evaluasi Sore (Buka Presensi Pulang)'
                : 'Isi Rencana Pagi Sekarang';

    return ChronoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Status Laporan Harian Hari Ini',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              ChronoStatusTag(
                label: statusLabel,
                tone: statusTone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ReportStepBox(
                  title: 'Laporan Pagi',
                  subtitle: isLocked
                      ? 'Presensi masuk dulu'
                      : hasMorning
                          ? 'Terkirim ${ChronoFormat.shortTime(today.morningSubmittedAt)}'
                          : 'Rencana tugas hari ini',
                  done: hasMorning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportStepBox(
                  title: 'Laporan Sore',
                  subtitle: isLocked || !hasMorning
                      ? 'Setelah Laporan Pagi'
                      : hasEvening
                          ? 'Terkirim ${ChronoFormat.shortTime(today.eveningSubmittedAt)}'
                          : 'Wajib sebelum pulang',
                  done: hasEvening,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLocked ? null : () => widget.onNavigateTab(1),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceGuidanceBanner(UserProfile user) {
    final isIntern = user.isIntern;
    return ChronoCard(
      color: ChronoColors.skyTint,
      borderColor: ChronoColors.skySoft,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ChronoColors.skySoft),
            ),
            child: const Icon(
              Icons.face_retouching_natural_rounded,
              color: ChronoColors.sky,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIntern ? 'Metode Presensi Magang (GPS & Foto)' : 'Metode Presensi Karyawan (GPS & Foto)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChronoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isIntern
                      ? 'Gunakan Kamera Selfie & GPS di aplikasi untuk presensi masuk dan pulang harian.'
                      : 'Gunakan Kamera Selfie & GPS dalam radius kantor untuk hadir di kantor, atau bebas radius saat WFA/Tugas Luar disetujui.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChronoColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(UserProfile user) {
    return Column(
      children: [
        _ActionRowTile(
          icon: Icons.calendar_month_outlined,
          title: 'Riwayat Presensi Bulanan',
          subtitle: 'Rekap kehadiran, keterlambatan, dan jam lembur',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AttendanceHistoryScreen(auth: widget.auth),
              ),
            );
            await _refreshAll();
          },
        ),
        const SizedBox(height: 10),
        _ActionRowTile(
          icon: Icons.event_note_outlined,
          title: user.uiFlags.showLeaveApprovalMenu
              ? 'Perizinan & Persetujuan Tim'
              : 'Pengajuan Cuti, Tugas Luar & Izin',
          subtitle: user.uiFlags.showLeaveApprovalMenu
              ? 'Ajukan izin pribadi dan tinjau pengajuan pegawai lain'
              : 'Cuti (H-7), Izin (H-1), WFA/Tugas Luar, atau Sakit (Otomatis Disetujui)',
          trailingBadge: (user.uiFlags.showLeaveApprovalMenu && _pendingApprovals > 0)
              ? ChronoStatusTag(
                  label: '$_pendingApprovals Menunggu',
                  tone: BadgeTone.warning,
                )
              : null,
          onTap: () => widget.onNavigateTab(2),
        ),
        const SizedBox(height: 10),
        _ActionRowTile(
          icon: Icons.gavel_outlined,
          title: 'Profil & Kedisiplinan',
          subtitle: 'Cek informasi akun, catatan keterlambatan, dan surat peringatan',
          onTap: () => widget.onNavigateTab(3),
        ),
      ],
    );
  }
}

class _TimeMetricDark extends StatelessWidget {
  final String label;
  final String value;

  const _TimeMetricDark({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ChronoTheme.mono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ReportStepBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;

  const _ReportStepBox({
    required this.title,
    required this.subtitle,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? ChronoColors.successBg : ChronoColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? ChronoColors.successBorder : ChronoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: done ? ChronoColors.success : ChronoColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: done ? ChronoColors.successDark : ChronoColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: done ? ChronoColors.successDark : ChronoColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailingBadge;
  final VoidCallback onTap;

  const _ActionRowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChronoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChronoColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ChronoColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ChronoColors.border),
                ),
                child: Icon(icon, color: ChronoColors.dark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: ChronoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChronoColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                trailingBadge!,
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: ChronoColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
