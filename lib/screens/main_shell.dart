import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_logo.dart';
import '../widgets/chrono_widgets.dart';
import 'daily_report_screen.dart';
import 'home_dashboard_screen.dart';
import 'leaves_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final AuthController auth;
  final AttendanceTodayData? initialTodayOverride;

  const MainShell({
    super.key,
    required this.auth,
    this.initialTodayOverride,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final List<int> _tabRefreshTicks = [0, 0, 0, 0];

  bool _initialChecking = true;
  bool _checkingLock = false;
  AttendanceTodayData? _todayStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialTodayOverride != null) {
      _todayStatus = widget.initialTodayOverride;
      _initialChecking = false;
    } else {
      _syncShellStatus(isInitial: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncShellStatus(alsoRefreshActiveTab: true);
    }
  }

  Future<void> _syncShellStatus({
    bool isInitial = false,
    bool alsoRefreshActiveTab = false,
  }) async {
    if (_checkingLock) return;
    setState(() {
      _checkingLock = true;
      if (isInitial) _initialChecking = true;
    });

    try {
      await Future.wait([
        widget.auth.refreshBranding().catchError((_) {}),
        widget.auth.refreshProfile().catchError((_) {}),
      ]);
      final today = await widget.auth.api.getAttendanceToday();
      if (mounted) {
        setState(() {
          _todayStatus = today;
          _initialChecking = false;
          _checkingLock = false;
          if (alsoRefreshActiveTab && !today.isOnLeaveToday) {
            _tabRefreshTicks[_currentIndex]++;
          }
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.auth.clearSession();
        return;
      }
      if (mounted) {
        setState(() {
          _initialChecking = false;
          _checkingLock = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _initialChecking = false;
          _checkingLock = false;
        });
      }
    }
  }

  void _handleTodayLoaded(AttendanceTodayData today) {
    if (!mounted) return;
    if (_todayStatus?.isOnLeaveToday != today.isOnLeaveToday ||
        _todayStatus?.todayLeaveStatus != today.todayLeaveStatus) {
      setState(() {
        _todayStatus = today;
      });
    } else {
      _todayStatus = today;
    }
  }

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
      _tabRefreshTicks[index]++;
    });
    _syncShellStatus();
  }

  void _handleGlobalStatusChanged() {
    setState(() {
      for (var i = 0; i < _tabRefreshTicks.length; i++) {
        _tabRefreshTicks[i]++;
      }
    });
    _syncShellStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final brand = widget.auth.brand;

    if (_initialChecking) {
      return Scaffold(
        backgroundColor: ChronoColors.background,
        body: ChronoLoadingState(
          message: 'Memeriksa status kehadiran ${brand.appName}...',
        ),
      );
    }

    if (_todayStatus?.isOnLeaveToday == true) {
      return _LeaveLockedScreen(
        auth: widget.auth,
        today: _todayStatus!,
        checking: _checkingLock,
        onRecheck: () => _syncShellStatus(alsoRefreshActiveTab: true),
      );
    }

    final showApproval = user?.uiFlags.showLeaveApprovalMenu ?? false;

    final screens = [
      HomeDashboardScreen(
        auth: widget.auth,
        onNavigateTab: _setTab,
        refreshTick: _tabRefreshTicks[0],
        onTodayLoaded: _handleTodayLoaded,
      ),
      DailyReportScreen(
        auth: widget.auth,
        refreshTick: _tabRefreshTicks[1],
        onStatusUpdated: _handleGlobalStatusChanged,
      ),
      LeavesScreen(
        auth: widget.auth,
        refreshTick: _tabRefreshTicks[2],
        onStatusUpdated: _handleGlobalStatusChanged,
      ),
      ProfileScreen(
        auth: widget.auth,
        refreshTick: _tabRefreshTicks[3],
        onStatusUpdated: _handleGlobalStatusChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ChronoColors.surface,
          border: Border(top: BorderSide(color: ChronoColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _setTab,
            height: 66,
            backgroundColor: ChronoColors.surface,
            indicatorColor: ChronoColors.skyTint,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: ChronoColors.sky),
                label: 'Beranda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded, color: ChronoColors.sky),
                label: 'Laporan',
              ),
              NavigationDestination(
                icon: Icon(showApproval ? Icons.fact_check_outlined : Icons.event_note_outlined),
                selectedIcon: Icon(
                  showApproval ? Icons.fact_check_rounded : Icons.event_note_rounded,
                  color: ChronoColors.sky,
                ),
                label: showApproval ? 'Izin+' : 'Izin',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: ChronoColors.sky),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveLockedScreen extends StatelessWidget {
  final AuthController auth;
  final AttendanceTodayData today;
  final bool checking;
  final Future<void> Function() onRecheck;

  const _LeaveLockedScreen({
    required this.auth,
    required this.today,
    required this.checking,
    required this.onRecheck,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final brand = auth.brand;
    final leaveCode = (today.todayLeaveStatus ?? today.attendance?.status ?? 'IZIN').toUpperCase();
    final leaveLabel = switch (leaveCode) {
      'CUTI' => 'Cuti',
      'SAKIT' => 'Sakit',
      _ => 'Izin',
    };
    final leaveIcon = switch (leaveCode) {
      'CUTI' => Icons.beach_access_rounded,
      'SAKIT' => Icons.local_hospital_rounded,
      _ => Icons.event_busy_rounded,
    };

    final periodText = (today.todayLeaveStartDate != null && today.todayLeaveEndDate != null)
        ? (today.todayLeaveStartDate == today.todayLeaveEndDate
            ? ChronoFormat.dateIndo(today.todayLeaveStartDate)
            : '${ChronoFormat.dateIndo(today.todayLeaveStartDate)} - ${ChronoFormat.dateIndo(today.todayLeaveEndDate)}')
        : ChronoFormat.fullDateIndo(DateTime.now());

    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        onRefresh: onRecheck,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            ChronoCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: ChronoColors.skyTint,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ChronoColors.skySoft),
                    ),
                    child: Icon(leaveIcon, size: 34, color: ChronoColors.sky),
                  ),
                  const SizedBox(height: 16),
                  ChronoStatusTag(
                    label: 'Sedang $leaveLabel Hari Ini',
                    tone: BadgeTone.sky,
                    showStateDot: true,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Akses Aplikasi Dinonaktifkan Sementara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ChronoColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Karena Anda tercatat sedang $leaveLabel pada hari ini, seluruh menu aplikasi (${brand.appName}) tidak dapat diakses untuk sementara waktu. Sesi akun Anda tetap masuk dan akses akan terbuka kembali secara otomatis pada hari kerja berikutnya.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ChronoColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ChronoColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ChronoColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null) ...[
                          _LockInfoRow(label: 'Akun Aktif', value: user.name),
                          const SizedBox(height: 8),
                        ],
                        _LockInfoRow(label: 'Status Hari Ini', value: leaveLabel),
                        const SizedBox(height: 8),
                        _LockInfoRow(label: 'Periode', value: periodText),
                        if (today.todayLeaveReason != null &&
                            today.todayLeaveReason!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _LockInfoRow(
                            label: 'Keterangan',
                            value: today.todayLeaveReason!.trim(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: checking ? null : onRecheck,
                      icon: checking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 19),
                      label: Text(checking ? 'Memeriksa Status...' : 'Periksa Ulang Status'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _LockInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ChronoColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ChronoColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
