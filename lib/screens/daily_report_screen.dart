import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_widgets.dart';

class DailyReportScreen extends StatefulWidget {
  final AuthController auth;
  final int refreshTick;
  final VoidCallback? onStatusUpdated;

  const DailyReportScreen({
    super.key,
    required this.auth,
    this.refreshTick = 0,
    this.onStatusUpdated,
  });

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  int _segmentIndex = 0; // 0 = Hari Ini, 1 = Arsip

  bool _loadingToday = true;
  String? _todayError;
  AttendanceTodayData? _attendanceToday;
  DailyReportTodayData? _reportToday;

  // Morning planning state
  final List<TextEditingController> _morningTaskControllers = [TextEditingController()];
  bool _submittingMorning = false;

  // Evening evaluation state
  final Map<int, bool> _completedMap = {};
  final List<TextEditingController> _additionalTaskControllers = [];
  bool _submittingEvening = false;

  // History state
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _loadingHistory = false;
  String? _historyError;
  List<DailyReportModel> _history = [];

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void didUpdateWidget(covariant DailyReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      if (_segmentIndex == 0) {
        _loadToday();
      } else {
        _loadHistory();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _morningTaskControllers) {
      c.dispose();
    }
    for (final c in _additionalTaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadToday() async {
    setState(() {
      _loadingToday = true;
      _todayError = null;
    });

    try {
      final results = await Future.wait([
        widget.auth.api.getAttendanceToday(),
        widget.auth.api.getReportToday(),
      ]);

      final att = results[0] as AttendanceTodayData;
      final rep = results[1] as DailyReportTodayData;

      final previousCompleted = Map<int, bool>.from(_completedMap);
      _completedMap.clear();
      for (var i = 0; i < rep.morningTasksList.length; i++) {
        _completedMap[i] = previousCompleted[i] ?? false;
      }

      if (mounted) {
        setState(() {
          _attendanceToday = att;
          _reportToday = rep;
          _loadingToday = false;
          _todayError = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _todayError = e.message;
          _loadingToday = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _todayError = 'Gagal memuat Laporan Harian: $e';
          _loadingToday = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final list = await widget.auth.api.getReportHistory(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          _history = list;
          _loadingHistory = false;
          _historyError = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.message;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = 'Gagal memuat arsip laporan: $e';
          _loadingHistory = false;
        });
      }
    }
  }

  String _stripLeadingNumber(String text) {
    return text.trim().replaceFirst(RegExp(r'^(\d+[\.\)]\s*|[-*•]\s*)'), '').trim();
  }

  List<String> _formatNumberedTasks(List<String> rawTasks) {
    final cleaned = rawTasks
        .map(_stripLeadingNumber)
        .where((t) => t.isNotEmpty)
        .toList();
    return List.generate(cleaned.length, (i) => '${i + 1}. ${cleaned[i]}');
  }

  Future<void> _submitMorning() async {
    final tasks = _formatNumberedTasks(
      _morningTaskControllers.map((c) => c.text).toList(),
    );

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ChronoColors.danger,
          content: Text('Isi minimal satu rencana pekerjaan hari ini.'),
        ),
      );
      return;
    }

    setState(() => _submittingMorning = true);
    try {
      final msg = await widget.auth.api.submitMorningReport(tasks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _loadToday();
        widget.onStatusUpdated?.call();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingMorning = false);
      }
    }
  }

  Future<void> _submitEvening() async {
    final morningTasks = _reportToday?.morningTasksList ?? [];
    final completedRaw = <String>[];
    final pendingRaw = <String>[];

    for (var i = 0; i < morningTasks.length; i++) {
      if (_completedMap[i] == true) {
        completedRaw.add(morningTasks[i]);
      } else {
        pendingRaw.add(morningTasks[i]);
      }
    }

    final completed = _formatNumberedTasks(completedRaw);
    final pending = _formatNumberedTasks(pendingRaw);
    final additional = _formatNumberedTasks(
      _additionalTaskControllers.map((c) => c.text).toList(),
    );

    if (completed.isEmpty && pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ChronoColors.danger,
          content: Text('Tidak ada daftar tugas pagi yang dapat dievaluasi.'),
        ),
      );
      return;
    }

    setState(() => _submittingEvening = true);
    try {
      final msg = await widget.auth.api.submitEveningReport(
        completedTasks: completed,
        pendingTasks: pending,
        additionalTasks: additional,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await _loadToday();
        widget.onStatusUpdated?.call();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingEvening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(
        title: const Text('Laporan Harian'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: ChronoColors.surface,
              border: Border(bottom: BorderSide(color: ChronoColors.border)),
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Laporan Hari Ini')),
                ButtonSegment(value: 1, label: Text('Arsip Bulanan')),
              ],
              selected: {_segmentIndex},
              onSelectionChanged: (v) {
                setState(() => _segmentIndex = v.first);
                if (v.first == 0) {
                  _loadToday();
                } else {
                  _loadHistory();
                }
              },
            ),
          ),
          Expanded(
            child: _segmentIndex == 0 ? _buildTodayBody() : _buildHistoryBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBody() {
    if (_loadingToday) {
      return const ChronoLoadingState(message: 'Memuat status Laporan Harian hari ini...');
    }
    if (_todayError != null) {
      return ChronoErrorState(
        title: 'Gagal Memuat Laporan',
        message: _todayError!,
        onRetry: _loadToday,
      );
    }

    final att = _attendanceToday!;
    final rep = _reportToday!;

    return RefreshIndicator(
      color: ChronoColors.sky,
      onRefresh: _loadToday,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (!att.hasCheckedIn)
            const ChronoEmptyState(
              icon: Icons.login_rounded,
              title: 'Presensi Masuk Diperlukan',
              description:
                  'Lakukan presensi masuk terlebih dahulu menggunakan GPS & Foto dari Beranda sebelum mengisi rencana tugas pagi.',
            )
          else if (!rep.hasSubmittedMorning)
            _buildMorningForm()
          else if (!rep.isCompleted)
            _buildEveningForm(rep)
          else
            _buildCompletedSummary(rep.report!),
        ],
      ),
    );
  }

  Widget _buildMorningForm() {
    return ChronoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ChronoStatusTag(label: 'Tahap 1: Pagi', tone: BadgeTone.sky),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Laporan Pagi (Rencana Kerja)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tuliskan daftar rencana pekerjaan yang akan Anda kerjakan hari ini.',
            style: TextStyle(fontSize: 12.5, color: ChronoColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...List.generate(_morningTaskControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ChronoColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ChronoColors.border),
                    ),
                    child: Text(
                      '${index + 1}.',
                      style: ChronoTheme.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ChronoColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _morningTaskControllers[index],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Tulis rencana pekerjaan...',
                      ),
                    ),
                  ),
                  if (_morningTaskControllers.length > 1) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Hapus tugas',
                      onPressed: () {
                        setState(() {
                          final removed = _morningTaskControllers.removeAt(index);
                          removed.dispose();
                        });
                      },
                      icon: const Icon(Icons.close_rounded, color: ChronoColors.danger),
                    ),
                  ],
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _morningTaskControllers.add(TextEditingController()));
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Baris Tugas'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submittingMorning ? null : _submitMorning,
              child: _submittingMorning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kirim Laporan Pagi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEveningForm(DailyReportTodayData rep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChronoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  ChronoStatusTag(label: 'Tahap 2: Sore', tone: BadgeTone.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Laporan Sore (Evaluasi)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Centang tugas pagi yang sudah selesai. Tugas yang tidak dicentang akan otomatis dicatat sebagai tertunda.',
                style: TextStyle(fontSize: 12.5, color: ChronoColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 12),
              ...List.generate(rep.morningTasksList.length, (index) {
                final task = rep.morningTasksList[index];
                final isDone = _completedMap[index] == true;
                return CheckboxListTile(
                  value: isDone,
                  activeColor: ChronoColors.success,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    '${index + 1}. $task',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: ChronoColors.textPrimary,
                      decoration: isDone ? TextDecoration.none : null,
                    ),
                  ),
                  subtitle: Text(
                    isDone ? 'Status: Selesai' : 'Status: Tertunda',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDone ? ChronoColors.success : ChronoColors.warning,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _completedMap[index] = val ?? false);
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ChronoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tugas Tambahan / Tak Terduga (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Catat pekerjaan tambahan di luar rencana pagi yang Anda selesaikan hari ini.',
                style: TextStyle(fontSize: 12, color: ChronoColors.textMuted),
              ),
              const SizedBox(height: 12),
              ...List.generate(_additionalTaskControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ChronoColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ChronoColors.border),
                        ),
                        child: Text(
                          '${index + 1}.',
                          style: ChronoTheme.mono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ChronoColors.dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _additionalTaskControllers[index],
                          decoration: const InputDecoration(
                            hintText: 'Tulis tugas tambahan...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Hapus',
                        onPressed: () {
                          setState(() {
                            final removed = _additionalTaskControllers.removeAt(index);
                            removed.dispose();
                          });
                        },
                        icon: const Icon(Icons.close_rounded, color: ChronoColors.danger),
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _additionalTaskControllers.add(TextEditingController()));
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Tugas Tak Terduga'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submittingEvening ? null : _submitEvening,
            child: _submittingEvening
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Evaluasi Sore & Buka Presensi Pulang'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSummary(DailyReportModel report) {
    return ChronoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Laporan Harian Hari Ini Selesai',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const ChronoStatusTag(label: 'SELESAI', tone: BadgeTone.success),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pagi: ${ChronoFormat.shortTime(report.morningSubmittedAt)} WIB  |  Sore: ${ChronoFormat.shortTime(report.eveningSubmittedAt)} WIB',
            style: ChronoTheme.mono(fontSize: 11.5, color: ChronoColors.textMuted),
          ),
          const SizedBox(height: 14),
          _TaskBlock(
            title: 'Tugas Selesai',
            content: report.eveningCompletedTasks,
            tone: BadgeTone.success,
          ),
          const SizedBox(height: 10),
          _TaskBlock(
            title: 'Tugas Tertunda',
            content: report.eveningPendingTasks,
            tone: BadgeTone.warning,
          ),
          if (report.eveningAdditionalTasks != null &&
              report.eveningAdditionalTasks!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _TaskBlock(
              title: 'Tugas Tambahan',
              content: report.eveningAdditionalTasks,
              tone: BadgeTone.sky,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryBody() {
    final now = DateTime.now();
    final years = List.generate(3, (i) => now.year - i);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
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
                      setState(() => _selectedMonth = v);
                      _loadHistory();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Tahun',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: years
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedYear = v);
                      _loadHistory();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingHistory
              ? const ChronoLoadingState(message: 'Memuat arsip Laporan Harian...')
              : _historyError != null
                  ? ChronoErrorState(
                      title: 'Gagal Memuat Arsip',
                      message: _historyError!,
                      onRetry: _loadHistory,
                    )
                  : _history.isEmpty
                      ? ChronoEmptyState(
                          icon: Icons.description_outlined,
                          title: 'Belum Ada Arsip Laporan',
                          description:
                              'Tidak ditemukan Laporan Harian pada ${ChronoFormat.monthName(_selectedMonth)} $_selectedYear.',
                        )
                      : RefreshIndicator(
                          color: ChronoColors.sky,
                          onRefresh: _loadHistory,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                            itemCount: _history.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final item = _history[index];
                              return ChronoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ChronoFormat.dateIndo(item.date),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        ChronoStatusTag(
                                          label: item.isCompleted ? 'SELESAI' : 'PAGI SAJA',
                                          tone: item.isCompleted
                                              ? BadgeTone.success
                                              : BadgeTone.warning,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _TaskBlock(
                                      title: 'Rencana Pagi',
                                      content: item.morningPlannedTasks,
                                      tone: BadgeTone.neutral,
                                    ),
                                    if (item.eveningCompletedTasks != null &&
                                        item.eveningCompletedTasks!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _TaskBlock(
                                        title: 'Selesai',
                                        content: item.eveningCompletedTasks,
                                        tone: BadgeTone.success,
                                      ),
                                    ],
                                    if (item.eveningPendingTasks != null &&
                                        item.eveningPendingTasks!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _TaskBlock(
                                        title: 'Tertunda',
                                        content: item.eveningPendingTasks,
                                        tone: BadgeTone.warning,
                                      ),
                                    ],
                                    if (item.eveningAdditionalTasks != null &&
                                        item.eveningAdditionalTasks!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _TaskBlock(
                                        title: 'Tambahan',
                                        content: item.eveningAdditionalTasks,
                                        tone: BadgeTone.sky,
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
}

class _TaskBlock extends StatelessWidget {
  final String title;
  final String? content;
  final BadgeTone tone;

  const _TaskBlock({
    required this.title,
    required this.content,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final text = (content == null || content!.trim().isEmpty) ? '-' : content!.trim();
    final (bg, border) = switch (tone) {
      BadgeTone.success => (ChronoColors.successBg, ChronoColors.successBorder),
      BadgeTone.warning => (ChronoColors.warningBg, ChronoColors.warningBorder),
      BadgeTone.sky => (ChronoColors.skyTint, ChronoColors.skySoft),
      _ => (ChronoColors.background, ChronoColors.border),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: ChronoColors.slate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: ChronoColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
