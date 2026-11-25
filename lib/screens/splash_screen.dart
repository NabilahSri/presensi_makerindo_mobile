import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../models/models.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_logo.dart';

class SplashScreen extends StatefulWidget {
  final BrandSettings brand;
  final String statusText;

  const SplashScreen({
    super.key,
    required this.brand,
    this.statusText = 'Menyiapkan aplikasi...',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ChronoColors.dark, ChronoColors.navy],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: ChronoLogoMark(
                        size: 80,
                        darkBackground: true,
                        logoUrl: widget.brand.logoUrl,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ChronoBrandTitle(
                      name: widget.brand.appName,
                      fontSize: 24,
                      lightText: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.brand.appSlogan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                    const Spacer(flex: 3),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: ChronoColors.skyLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppVersion.fullLabel,
                      style: ChronoTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
