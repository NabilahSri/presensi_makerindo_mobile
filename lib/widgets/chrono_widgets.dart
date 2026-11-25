import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../theme/chrono_theme.dart';

/// Pop-up peringatan ketika layanan GPS/Lokasi mati atau izin lokasi ditolak.
Future<void> showLocationRequiredDialog(
  BuildContext context, {
  bool isPermissionDenied = false,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ChronoColors.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ChronoColors.dangerBorder),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: ChronoColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPermissionDenied ? 'Izin Lokasi Diperlukan' : 'Lokasi (GPS) Tidak Aktif',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Text(
        isPermissionDenied
            ? 'Aplikasi membutuhkan izin akses lokasi (GPS) untuk memverifikasi kehadiran Anda. Silakan aktifkan izin lokasi di pengaturan aplikasi.'
            : 'Layanan lokasi (GPS) pada perangkat Anda sedang tidak aktif. Aktifkan lokasi terlebih dahulu sebelum melakukan presensi.',
        style: const TextStyle(
          fontSize: 13,
          color: ChronoColors.textSecondary,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(ctx).pop();
            if (isPermissionDenied) {
              await Geolocator.openAppSettings();
            } else {
              await Geolocator.openLocationSettings();
            }
          },
          icon: const Icon(Icons.settings_outlined, size: 17),
          label: const Text('Aktifkan Lokasi'),
        ),
      ],
    ),
  );
}

class ChronoFormat {
  ChronoFormat._();

  static String shortTime(String? hhmmss) {
    if (hhmmss == null || hhmmss.trim().isEmpty) return '--:--';
    return hhmmss.length >= 5 ? hhmmss.substring(0, 5) : hhmmss;
  }

  static String dateIndo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(isoDate);
      final dt = parsed.isUtc ? parsed.toLocal() : parsed;
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String fullDateIndo(DateTime dt) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(dt);
    }
  }

  static String monthName(int month) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (month < 1 || month > 12) return '$month';
    return names[month - 1];
  }
}

/// Standard Presensi Makerindo white card with slate-200 border matching the web portal.
class ChronoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;

  const ChronoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color = ChronoColors.surface,
    this.borderColor = ChronoColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

enum BadgeTone { neutral, sky, success, warning, danger, dark }

/// Functional status tag (not decorative) using the Presensi Makerindo semantic palette.
class ChronoStatusTag extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final bool showStateDot;

  const ChronoStatusTag({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.showStateDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      BadgeTone.sky => (ChronoColors.skyTint, ChronoColors.skySoft, ChronoColors.skyDark),
      BadgeTone.success => (ChronoColors.successBg, ChronoColors.successBorder, ChronoColors.successDark),
      BadgeTone.warning => (ChronoColors.warningBg, ChronoColors.warningBorder, ChronoColors.warningDark),
      BadgeTone.danger => (ChronoColors.dangerBg, ChronoColors.dangerBorder, ChronoColors.dangerDark),
      BadgeTone.dark => (ChronoColors.dark, ChronoColors.slate, Colors.white),
      BadgeTone.neutral => (ChronoColors.surfaceMuted, ChronoColors.border, ChronoColors.slate),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStateDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// Real-time precision WIB clock matching Presensi Makerindo web header & login page.
class LiveClockBadge extends StatefulWidget {
  final bool darkSurface;

  const LiveClockBadge({super.key, this.darkSurface = false});

  @override
  State<LiveClockBadge> createState() => _LiveClockBadgeState();
}

class _LiveClockBadgeState extends State<LiveClockBadge> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final ss = _now.second.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.darkSurface
            ? Colors.white.withValues(alpha: 0.08)
            : ChronoColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.darkSurface
              ? Colors.white.withValues(alpha: 0.14)
              : ChronoColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ChronoColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$hh:$mm:$ss',
            style: ChronoTheme.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.darkSurface ? Colors.white : ChronoColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'WIB',
            style: ChronoTheme.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: widget.darkSurface ? ChronoColors.skyLight : ChronoColors.sky,
            ),
          ),
        ],
      ),
    );
  }
}

/// Purposeful loading state telling the user what is being fetched (R-27).
class ChronoLoadingState extends StatelessWidget {
  final String message;

  const ChronoLoadingState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ChronoColors.sky,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ChronoColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Purposeful error state naming what failed and giving a retry action (R-27).
class ChronoErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ChronoErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChronoCard(
          color: ChronoColors.dangerBg,
          borderColor: ChronoColors.dangerBorder,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: ChronoColors.danger, size: 32),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ChronoColors.dangerDark,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ChronoColors.dangerDark,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Purposeful empty state naming why it is empty and the next action (R-27).
class ChronoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ChronoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChronoCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ChronoColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ChronoColors.border),
                ),
                child: Icon(icon, color: ChronoColors.slate, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
