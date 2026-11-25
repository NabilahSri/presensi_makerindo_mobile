import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_logo.dart';
import '../widgets/chrono_widgets.dart';

class LoginScreen extends StatefulWidget {
  final AuthController auth;

  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.auth.login(_emailController.text, _passwordController.text);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal masuk ke aplikasi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showHelpModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ChronoColors.skyTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ChronoColors.skySoft),
              ),
              child: const Icon(Icons.info_outline_rounded, color: ChronoColors.sky, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bantuan Akses Akun',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi Presensi Makerindo Mobile digunakan oleh Karyawan (KARTAP & PKWT) serta peserta Magang/PKL untuk presensi harian berbasis GPS & foto, laporan harian, perizinan, dan catatan kedisiplinan.',
              style: TextStyle(fontSize: 13, color: ChronoColors.textSecondary, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Jika lupa kata sandi atau akun belum aktif, silakan hubungi Super Admin atau Departemen HR/TI perusahaan Anda.',
              style: TextStyle(fontSize: 13, color: ChronoColors.textSecondary, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ),
        ],
      ),
    );
  }

  void _showServerSettingsModal() {
    final controller = TextEditingController(text: widget.auth.api.baseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Alamat Server API',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan http://10.0.2.2:8000/api untuk Emulator Android, atau IP lokal komputer (misal http://192.168.1.10:8000/api) untuk perangkat fisik.',
              style: TextStyle(fontSize: 12, color: ChronoColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Alamat URL API',
                hintText: 'http://10.0.2.2:8000/api',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                await widget.auth.api.setBaseUrl(value);
                await widget.auth.refreshBranding().catchError((_) {});
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server API diatur ke ${widget.auth.api.baseUrl}')),
                  );
                }
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.auth.brand;

    return Scaffold(
      backgroundColor: ChronoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Centered Brand & Live Chronometer Header
                        Column(
                          children: [
                            ChronoLogoMark(
                              size: 54,
                              darkBackground: true,
                              logoUrl: brand.logoUrl,
                            ),
                            const SizedBox(height: 12),
                            ChronoBrandTitle(name: brand.appName, fontSize: 21),
                            const SizedBox(height: 4),
                            Text(
                              brand.appSlogan,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: ChronoColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ChronoColors.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: ChronoColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      ChronoFormat.fullDateIndo(DateTime.now()),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: ChronoColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: ChronoColors.borderStrong,
                                  ),
                                  const SizedBox(width: 8),
                                  const LiveClockBadge(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        ChronoCard(
                          padding: const EdgeInsets.all(22),
                          radius: 20,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Masuk ke ${brand.appName}',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gunakan email dan kata sandi akun karyawan atau magang Anda.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                ),
                                const SizedBox(height: 20),

                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: ChronoColors.dangerBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: ChronoColors.dangerBorder),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 18,
                                          color: ChronoColors.danger,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: ChronoColors.dangerDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                const Text(
                                  'ALAMAT EMAIL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: ChronoColors.slate,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'email@perusahaan.com',
                                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
                                  ),
                                  validator: (val) {
                                    final v = val?.trim() ?? '';
                                    if (v.isEmpty) return 'Alamat email wajib diisi.';
                                    if (!v.contains('@')) return 'Masukkan format email yang valid.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'KATA SANDI',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: ChronoColors.slate,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: _showHelpModal,
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          'Lupa Kata Sandi?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ChronoColors.sky,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan kata sandi',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Tampilkan kata sandi'
                                          : 'Sembunyikan kata sandi',
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 19,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Kata sandi wajib diisi.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : _handleLogin,
                                    child: _submitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Masuk ke Aplikasi'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Server endpoint bar (useful for local/staging/production setup)
                        ChronoCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          color: ChronoColors.surfaceMuted,
                          child: Row(
                            children: [
                              const Icon(Icons.dns_outlined, size: 18, color: ChronoColors.slate),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Server API Aktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: ChronoColors.slate,
                                      ),
                                    ),
                                    Text(
                                      widget.auth.api.baseUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ChronoTheme.mono(
                                        fontSize: 11.5,
                                        color: ChronoColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _showServerSettingsModal,
                                style: TextButton.styleFrom(
                                  foregroundColor: ChronoColors.sky,
                                  minimumSize: const Size(44, 44),
                                ),
                                child: const Text(
                                  'Ubah',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Versi ${AppVersion.fullLabel}',
                textAlign: TextAlign.center,
                style: ChronoTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ChronoColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
