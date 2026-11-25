import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/chrono_theme.dart';

/// Custom-painted Presensi Makerindo mark ported directly from the web portal SVG logo
/// (chronometer dial ring, growth bars, checkmark flow).
class ChronoLogoMark extends StatelessWidget {
  final double size;
  final bool darkBackground;
  final String? logoUrl;

  const ChronoLogoMark({
    super.key,
    this.size = 40,
    this.darkBackground = false,
    this.logoUrl,
  });

  bool get _canRenderNetworkImage {
    final url = logoUrl?.trim();
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    // Flutter Image.network handles raster formats (png, jpg, jpeg, webp) natively
    if (lower.endsWith('.svg')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final useCustomLogo = _canRenderNetworkImage;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * (useCustomLogo ? 0.1 : 0.14)),
      decoration: BoxDecoration(
        color: useCustomLogo
            ? Colors.white
            : (darkBackground ? ChronoColors.dark : Colors.white),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: (darkBackground && !useCustomLogo)
              ? ChronoColors.slate.withValues(alpha: 0.6)
              : ChronoColors.border,
        ),
      ),
      child: useCustomLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.16),
              child: Image.network(
                logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => CustomPaint(
                  painter: _ChronoLogoPainter(darkBackground: false),
                ),
              ),
            )
          : CustomPaint(
              painter: _ChronoLogoPainter(darkBackground: darkBackground),
            ),
    );
  }
}

class _ChronoLogoPainter extends CustomPainter {
  final bool darkBackground;

  _ChronoLogoPainter({required this.darkBackground});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64.0;
    final sy = size.height / 64.0;
    canvas.save();
    canvas.scale(sx, sy);

    final primaryBlue = darkBackground ? ChronoColors.skyLight : ChronoColors.sky;
    final checkColor = darkBackground ? Colors.white : ChronoColors.dark;

    // 1. Chronometer dial ring
    final ringPaint = Paint()
      ..color = ChronoColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(const Offset(32, 32), 23, ringPaint);

    // Active top-right quadrant arc
    final arcPaint = Paint()
      ..color = primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(32, 32), radius: 23),
      -math.pi / 2,
      math.pi / 2,
      false,
      arcPaint,
    );

    // 2. Growth bars
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(23, 27, 4.5, 9), const Radius.circular(1.5)),
      Paint()..color = primaryBlue.withValues(alpha: 0.75),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(29.8, 20.5, 4.5, 15.5), const Radius.circular(1.5)),
      Paint()..color = primaryBlue.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(36.5, 14, 4.5, 22), const Radius.circular(1.5)),
      Paint()..color = primaryBlue,
    );

    // 4. Checkmark flow
    final checkPath = Path()
      ..moveTo(21.5, 27.5)
      ..lineTo(29.5, 35.5)
      ..lineTo(45.5, 15.5);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChronoLogoPainter oldDelegate) =>
      oldDelegate.darkBackground != darkBackground;
}

class ChronoBrandTitle extends StatelessWidget {
  final String name;
  final double fontSize;
  final bool lightText;

  const ChronoBrandTitle({
    super.key,
    this.name = 'Presensi Makerindo',
    this.fontSize = 18,
    this.lightText = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim().isEmpty ? 'Presensi Makerindo' : name.trim();
    String prefix = trimmed;
    String? accentSuffix;
    if (trimmed.endsWith('Makerindo') && trimmed.length > 9) {
      prefix = trimmed.substring(0, trimmed.length - 9);
      accentSuffix = 'Makerindo';
    } else if (trimmed.endsWith('HR') && trimmed.length > 2) {
      prefix = trimmed.substring(0, trimmed.length - 2);
      accentSuffix = 'HR';
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: lightText ? Colors.white : ChronoColors.textPrimary,
            ),
        children: [
          TextSpan(text: prefix),
          if (accentSuffix != null)
            TextSpan(
              text: accentSuffix,
              style: TextStyle(
                color: lightText ? ChronoColors.skyLight : ChronoColors.sky,
              ),
            ),
        ],
      ),
    );
  }
}
