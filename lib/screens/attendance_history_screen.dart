import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_widgets.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final AuthController auth;

  const AttendanceHistoryScreen({super.key, required this.auth});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with WidgetsBindingObserver {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _loading = true;
  String? _error;
  AttendanceHistoryData? _history;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.auth.api.getAttendanceHistory(month: _month, year: _year);
      if (mounted) {
        setState(() {
          _history = data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat riwayat presensi: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(3, (i) => now.year - i);

    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(title: const Text('Riwayat Presensi')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: ChronoColors.surface,
              border: Border(bottom: BorderSide(color: ChronoColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(ChronoFormat.monthName(i + 1)),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _month = v);
                        _load();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: years
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _year = v);
                        _load();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const ChronoLoadingState(message: 'Memuat rekap presensi bulanan...')
                : _error != null
                    ? ChronoErrorState(
                        title: 'Gagal Memuat Riwayat',
                        message: _error!,
                        onRetry: _load,
                      )
                    : RefreshIndicator(
                        color: ChronoColors.sky,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          children: [
                            _buildSummaryCard(_history!),
                            const SizedBox(height: 16),
                            if (_history!.records.isEmpty)
                              ChronoEmptyState(
                                icon: Icons.event_busy_outlined,
                                title: 'Belum Ada Catatan Presensi',
                                description:
                                    'Tidak ada log kehadiran pada ${ChronoFormat.monthName(_month)} $_year.',
                              )
                            else
                              ..._history!.records.map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AttendanceLogCard(record: r),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AttendanceHistoryData data) {
    return ChronoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekap ${ChronoFormat.monthName(_month)} $_year',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChronoStatusTag(label: 'Kantor: ${data.hadirOnSite}', tone: BadgeTone.success),
              ChronoStatusTag(label: 'WFA: ${data.wfa}', tone: BadgeTone.sky),
              if (data.tugasLuar > 0)
                ChronoStatusTag(label: 'Tugas Luar: ${data.tugasLuar}', tone: BadgeTone.sky),
              if (data.cuti > 0)
                ChronoStatusTag(label: 'Cuti: ${data.cuti}', tone: BadgeTone.success),
              ChronoStatusTag(label: 'Terlambat: ${data.lateCount}', tone: BadgeTone.warning),
              ChronoStatusTag(
                label: 'Lembur: ${data.totalOvertimeHours} jam',
                tone: BadgeTone.dark,
              ),
              if (data.sakit > 0)
                ChronoStatusTag(label: 'Sakit: ${data.sakit}', tone: BadgeTone.danger),
              if (data.izin > 0)
                ChronoStatusTag(label: 'Izin: ${data.izin}', tone: BadgeTone.neutral),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceLogCard extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceLogCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final tone = switch (record.status.toUpperCase()) {
      'HADIR_ON_SITE' => BadgeTone.success,
      'WFA' || 'TUGAS_LUAR' => BadgeTone.sky,
      'CUTI' => BadgeTone.success,
      'SAKIT' => BadgeTone.danger,
      'IZIN' => BadgeTone.warning,
      _ => BadgeTone.neutral,
    };

    return ChronoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ChronoFormat.dateIndo(record.date),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              ChronoStatusTag(label: record.displayStatus, tone: tone),
              if (record.isLate) ...[
                const SizedBox(width: 6),
                const ChronoStatusTag(label: 'Terlambat', tone: BadgeTone.warning),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Masuk: ${ChronoFormat.shortTime(record.timeIn)}',
                  style: ChronoTheme.mono(fontSize: 12, color: ChronoColors.textPrimary),
                ),
              ),
              Expanded(
                child: Text(
                  'Pulang: ${ChronoFormat.shortTime(record.timeOut)}',
                  style: ChronoTheme.mono(fontSize: 12, color: ChronoColors.textPrimary),
                ),
              ),
              Text(
                record.overtimeHours > 0 ? '+${record.overtimeHours}j' : record.displayMethod,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: record.overtimeHours > 0 ? ChronoColors.sky : ChronoColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
