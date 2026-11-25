import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../config/app_version.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_widgets.dart';
import 'attendance_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthController auth;
  final int refreshTick;
  final VoidCallback? onStatusUpdated;

  const ProfileScreen({
    super.key,
    required this.auth,
    this.refreshTick = 0,
    this.onStatusUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _imagePicker = ImagePicker();
  bool _refreshing = true;
  bool _uploadingPhoto = false;
  AttendanceHistoryData? _monthlyHistory;
  int _activeSanctionsCount = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final now = DateTime.now();
      await widget.auth.refreshBranding().catchError((_) {});
      final results = await Future.wait([
        widget.auth.refreshProfile().then<bool>((_) => true).catchError((_) => false),
        widget.auth.api
            .getAttendanceHistory(month: now.month, year: now.year)
            .then<AttendanceHistoryData?>((v) => v)
            .catchError((_) => null),
        widget.auth.api
            .getSanctions()
            .then<int>((v) => v.activeCount)
            .catchError((_) => 0),
      ]);

      if (mounted) {
        setState(() {
          _monthlyHistory = results[1] as AttendanceHistoryData?;
          _activeSanctionsCount = results[2] as int;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } catch (_) {
      // Pertahankan data yang ada jika sementara offline
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _pickAndUploadProfilePhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 82,
        maxWidth: 1080,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      final result = await widget.auth.api.uploadProfilePhoto(File(picked.path));
      await widget.auth.updateUser(result.user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
      widget.onStatusUpdated?.call();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ChronoColors.danger,
            content: Text('Gagal memilih foto profil: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _confirmDeleteProfilePhoto() async {
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Foto Profil?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Foto profil Anda akan dihapus dan kembali menampilkan inisial nama.',
          style: TextStyle(fontSize: 13, color: ChronoColors.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ChronoColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final result = await widget.auth.api.deleteProfilePhoto();
      await widget.auth.updateUser(result.user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
      widget.onStatusUpdated?.call();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _openProfilePhotoPreview(String photoUrl, String userName) {
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
                  Expanded(
                    child: Text(
                      'Foto Profil - $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
              constraints: const BoxConstraints(maxHeight: 420),
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
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
                      'Gagal memuat pratinjau foto profil.',
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

  Future<void> _openProfilePhotoOptions(UserProfile user) async {
    if (_uploadingPhoto) return;
    final hasPhoto = user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ChronoColors.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ChronoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih sumber foto baru (format JPG, PNG, atau WEBP maks. 3 MB).',
                style: TextStyle(fontSize: 12, color: ChronoColors.textMuted),
              ),
              const SizedBox(height: 12),
              if (hasPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_outlined, color: ChronoColors.dark),
                  title: const Text('Lihat Foto Profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openProfilePhotoPreview(user.profilePhotoUrl!, user.name);
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.camera_alt_outlined, color: ChronoColors.sky),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined, color: ChronoColors.sky),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadProfilePhoto(ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline_rounded, color: ChronoColors.danger),
                  title: const Text(
                    'Hapus Foto Profil',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ChronoColors.danger,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmDeleteProfilePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool submitting = false;
    String? errorMsg;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ChronoColors.skyTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ChronoColors.skySoft),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: ChronoColors.sky,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubah Kata Sandi',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: ChronoColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gunakan minimal 6 karakter untuk keamanan akun Anda.',
                            style: TextStyle(
                              fontSize: 12,
                              color: ChronoColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, color: ChronoColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(11),
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
                          color: ChronoColors.danger,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ChronoColors.dangerDark,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text(
                  'KATA SANDI SAAT INI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ChronoColors.slate,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi lama',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                    suffixIcon: IconButton(
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'KATA SANDI BARU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ChronoColors.slate,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    prefixIcon: const Icon(Icons.vpn_key_outlined, size: 19),
                    suffixIcon: IconButton(
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      icon: Icon(
                        obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'KONFIRMASI KATA SANDI BARU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ChronoColors.slate,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Ulangi kata sandi baru',
                    prefixIcon: const Icon(Icons.verified_user_outlined, size: 19),
                    suffixIcon: IconButton(
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                          child: const Text('Batal'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  final curr = currentCtrl.text;
                                  final next = newCtrl.text;
                                  final conf = confirmCtrl.text;

                                  if (curr.isEmpty) {
                                    setDialogState(() {
                                      errorMsg = 'Kata sandi saat ini wajib diisi.';
                                    });
                                    return;
                                  }
                                  if (next.length < 6) {
                                    setDialogState(() {
                                      errorMsg = 'Kata sandi baru minimal 6 karakter.';
                                    });
                                    return;
                                  }
                                  if (next != conf) {
                                    setDialogState(() {
                                      errorMsg = 'Konfirmasi kata sandi baru tidak cocok.';
                                    });
                                    return;
                                  }

                                  setDialogState(() {
                                    submitting = true;
                                    errorMsg = null;
                                  });
                                  try {
                                    final msg = await widget.auth.api.updatePassword(
                                      currentPassword: curr,
                                      newPassword: next,
                                      confirmPassword: conf,
                                    );
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(msg)),
                                      );
                                    }
                                  } on ApiException catch (e) {
                                    setDialogState(() {
                                      submitting = false;
                                      errorMsg = e.message;
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      submitting = false;
                                      errorMsg = 'Gagal memperbarui kata sandi: $e';
                                    });
                                  }
                                },
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan Sandi'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _openSanctionsSheet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _SanctionsScreen(auth: widget.auth)),
    );
    await _refresh();
    widget.onStatusUpdated?.call();
  }

  Future<void> _openAttendanceHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AttendanceHistoryScreen(auth: widget.auth)),
    );
    await _refresh();
    widget.onStatusUpdated?.call();
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
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
              child: const Icon(Icons.logout_rounded, color: ChronoColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keluar dari ${widget.auth.brand.appName}?',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Sesi login Anda pada perangkat ini akan diakhiri.',
          style: TextStyle(fontSize: 13, color: ChronoColors.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ChronoColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.auth.logout();
    }
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : fullName;
  }

  List<_WeekDayItem> _buildCurrentWeekItems() {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final monday = todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    final dateFmt = DateFormat('yyyy-MM-dd');
    const shortDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final byDate = <String, AttendanceRecord>{};
    for (final rec in _monthlyHistory?.records ?? const <AttendanceRecord>[]) {
      byDate[rec.date] = rec;
    }

    return List.generate(6, (i) {
      final d = monday.add(Duration(days: i));
      final key = dateFmt.format(d);
      final rec = byDate[key];
      final isToday = d.year == todayOnly.year &&
          d.month == todayOnly.month &&
          d.day == todayOnly.day;

      return _WeekDayItem(
        dayLabel: '${shortDays[i]} ${d.day}',
        isToday: isToday,
        isFuture: d.isAfter(todayOnly),
        record: rec,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: ChronoColors.background,
        body: ChronoLoadingState(message: 'Memuat profil akun...'),
      );
    }

    if (_refreshing) {
      return const Scaffold(
        backgroundColor: ChronoColors.background,
        body: SafeArea(
          child: ChronoLoadingState(message: 'Memuat data profil terbaru...'),
        ),
      );
    }

    final history = _monthlyHistory;
    final totalPresentMonth =
        (history?.hadirOnSite ?? 0) + (history?.wfa ?? 0) + (history?.tugasLuar ?? 0);
    final totalLateMonth = history?.lateCount ?? 0;
    final totalOvertimeMonth = history?.totalOvertimeHours ?? 0;
    final weekItems = _buildCurrentWeekItems();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: ChronoColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          color: ChronoColors.sky,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. TOP HERO BANNER + OVERLAPPING AVATAR & SUMMARY CARD
                    _buildTopProfileHeader(
                      user: user,
                      totalPresentMonth: totalPresentMonth,
                      totalOvertimeMonth: totalOvertimeMonth,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // 2. DAILY / WEEKLY CHECK-IN STRIP CARD
                          _buildWeeklyAttendanceCard(
                            weekItems: weekItems,
                            monthLabel: '${ChronoFormat.monthName(now.month)} ${now.year}',
                            totalPresentMonth: totalPresentMonth,
                            totalLateMonth: totalLateMonth,
                          ),

                          const SizedBox(height: 20),

                          // 3. SECTION AKUN (grouped clean list tile card)
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 10),
                            child: Text(
                              'Akun',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ChronoColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          ChronoCard(
                            padding: EdgeInsets.zero,
                            radius: 18,
                            child: Column(
                              children: [
                                _AccountMenuTile(
                                  icon: Icons.gavel_outlined,
                                  title: 'Sanksi & Kedisiplinan',
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_activeSanctionsCount > 0) ...[
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 22),
                                          height: 22,
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: ChronoColors.danger,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$_activeSanctionsCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: ChronoColors.textMuted,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  onTap: _openSanctionsSheet,
                                ),
                                const Divider(height: 1, indent: 52, color: ChronoColors.border),
                                _AccountMenuTile(
                                  icon: Icons.calendar_month_outlined,
                                  title: 'Riwayat Presensi Bulanan',
                                  onTap: _openAttendanceHistory,
                                ),
                                const Divider(height: 1, indent: 52, color: ChronoColors.border),
                                _AccountMenuTile(
                                  icon: Icons.my_location_outlined,
                                  title: 'Metode Presensi',
                                  trailing: const ChronoStatusTag(
                                    label: 'GPS & Foto',
                                    tone: BadgeTone.success,
                                  ),
                                  onTap: null,
                                ),
                                const Divider(height: 1, indent: 52, color: ChronoColors.border),
                                _AccountMenuTile(
                                  icon: Icons.camera_alt_outlined,
                                  title: 'Ubah Foto Profil',
                                  onTap: () => _openProfilePhotoOptions(user),
                                ),
                                const Divider(height: 1, indent: 52, color: ChronoColors.border),
                                _AccountMenuTile(
                                  icon: Icons.lock_reset_rounded,
                                  title: 'Ubah Kata Sandi',
                                  onTap: _openChangePasswordDialog,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 4. BOTTOM ACCOUNT & LOGOUT STRIP CARD
                          ChronoCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            radius: 18,
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: ChronoColors.skyTint,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: ChronoColors.skySoft),
                                  ),
                                  child: Icon(
                                    user.uiFlags.showLeaveApprovalMenu
                                        ? Icons.verified_user_outlined
                                        : Icons.badge_outlined,
                                    color: ChronoColors.sky,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.uiFlags.showLeaveApprovalMenu
                                            ? 'Penyetuju Perizinan'
                                            : user.employmentLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: ChronoColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: ChronoTheme.mono(
                                          fontSize: 11.5,
                                          color: ChronoColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: _confirmLogout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ChronoColors.danger,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Keluar',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProfileHeader({
    required UserProfile user,
    required int totalPresentMonth,
    required int totalOvertimeMonth,
  }) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Soft decorative header backdrop
        Container(
          height: topPad + 116,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE2E8F0), Color(0xFFEDF2F7)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -32,
                left: -26,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ChronoColors.sky.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ChronoColors.dark.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating white summary card overlapping the banner
        Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 54, 16, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
            decoration: BoxDecoration(
              color: ChronoColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ChronoColors.border),
              boxShadow: [
                BoxShadow(
                  color: ChronoColors.dark.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Col 1: Greeting + First Name
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hai,',
                          style: TextStyle(
                            fontSize: 12,
                            color: ChronoColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _firstName(user.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: ChronoColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 18, thickness: 1, color: ChronoColors.border),
                  // Col 2: Status Kepegawaian
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: ChronoColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              size: 15,
                              color: ChronoColors.sky,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.shortEmploymentLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: ChronoColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 18, thickness: 1, color: ChronoColors.border),
                  // Col 3: Hadir Bulan Ini
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hadir Bln Ini',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: ChronoColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: ChronoColors.success,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$totalPresentMonth hr',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChronoTheme.mono(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: ChronoColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (totalOvertimeMonth > 0)
                          Text(
                            '+${totalOvertimeMonth}j lembur',
                            style: ChronoTheme.mono(
                              fontSize: 10,
                              color: ChronoColors.sky,
                              fontWeight: FontWeight.w700,
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

        // Overlapping circular avatar badge on top-left of floating card
        Positioned(
          top: topPad + 22,
          left: 30,
          child: GestureDetector(
            onTap: () => _openProfilePhotoOptions(user),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ChronoColors.dark,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: ChronoColors.dark.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: _uploadingPhoto
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: ChronoColors.skyLight,
                          ),
                        )
                      : (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty)
                          ? Image.network(
                              user.profilePhotoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Text(
                                user.initials,
                                style: ChronoTheme.mono(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: ChronoColors.skyLight,
                                ),
                              ),
                            )
                          : Text(
                              user.initials,
                              style: ChronoTheme.mono(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ChronoColors.skyLight,
                              ),
                            ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ChronoColors.sky,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAttendanceCard({
    required List<_WeekDayItem> weekItems,
    required String monthLabel,
    required int totalPresentMonth,
    required int totalLateMonth,
  }) {
    return ChronoCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Presensi Minggu Ini',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: ChronoColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$monthLabel  •  $totalPresentMonth Hadir, $totalLateMonth Terlambat',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChronoColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openAttendanceHistory,
                style: TextButton.styleFrom(
                  foregroundColor: ChronoColors.sky,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(44, 36),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weekItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, idx) => _WeekDayTile(item: weekItems[idx]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayItem {
  final String dayLabel;
  final bool isToday;
  final bool isFuture;
  final AttendanceRecord? record;

  const _WeekDayItem({
    required this.dayLabel,
    required this.isToday,
    required this.isFuture,
    this.record,
  });
}

class _WeekDayTile extends StatelessWidget {
  final _WeekDayItem item;

  const _WeekDayTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final rec = item.record;
    final status = rec?.status.toUpperCase() ?? '';
    final isPresent =
        status == 'HADIR_ON_SITE' || status == 'WFA' || status == 'WFH' || status == 'TUGAS_LUAR';
    final isLeave = status == 'CUTI' || status == 'SAKIT' || status == 'IZIN';

    final IconData icon;
    final Color iconColor;
    final String middleLabel;

    if (isPresent) {
      icon = Icons.check_circle_rounded;
      iconColor = rec!.isLate ? ChronoColors.warning : ChronoColors.success;
      middleLabel = rec.timeIn != null && rec.timeIn!.length >= 5
          ? rec.timeIn!.substring(0, 5)
          : (status == 'WFA' || status == 'WFH' ? 'WFA' : 'Hadir');
    } else if (isLeave) {
      icon = Icons.event_note_rounded;
      iconColor = ChronoColors.sky;
      middleLabel = rec!.displayStatus;
    } else if (item.isToday) {
      icon = Icons.radio_button_checked_rounded;
      iconColor = ChronoColors.sky;
      middleLabel = 'Hari Ini';
    } else {
      icon = Icons.circle_outlined;
      iconColor = ChronoColors.borderStrong;
      middleLabel = item.isFuture ? '-' : 'Kosong';
    }

    final borderColor = item.isToday
        ? ChronoColors.sky
        : (isPresent ? ChronoColors.successBorder : ChronoColors.border);
    final bgColor = item.isToday
        ? ChronoColors.skyTint.withValues(alpha: 0.65)
        : (isPresent ? ChronoColors.successBg.withValues(alpha: 0.55) : ChronoColors.surfaceMuted);

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: item.isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 22, color: iconColor),
          Text(
            middleLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ChronoTheme.mono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: (isPresent || isLeave || item.isToday)
                  ? ChronoColors.textPrimary
                  : ChronoColors.textMuted,
            ),
          ),
          Text(
            item.dayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: item.isToday ? FontWeight.w700 : FontWeight.w500,
              color: item.isToday ? ChronoColors.skyDark : ChronoColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _AccountMenuTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: ChronoColors.dark),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ChronoColors.textPrimary,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ChronoColors.textMuted,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _SanctionsScreen extends StatefulWidget {
  final AuthController auth;

  const _SanctionsScreen({required this.auth});

  @override
  State<_SanctionsScreen> createState() => _SanctionsScreenState();
}

class _SanctionsScreenState extends State<_SanctionsScreen> {
  bool _loading = true;
  String? _error;
  int _activeCount = 0;
  int _lateCount = 0;
  List<SanctionModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.auth.api.getSanctions();
      if (mounted) {
        setState(() {
          _activeCount = res.activeCount;
          _lateCount = res.lateCount;
          _items = res.items;
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
    }
  }

  Future<void> _downloadSp(SanctionModel item) async {
    try {
      final file = await widget.auth.api.downloadSanctionPdf(item.id, item.level);
      await OpenFilex.open(file.path);
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
    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(title: const Text('Sanksi & Kedisiplinan')),
      body: _loading
          ? const ChronoLoadingState(message: 'Memuat data kedisiplinan...')
          : _error != null
              ? ChronoErrorState(
                  title: 'Gagal Memuat Data Sanksi',
                  message: _error!,
                  onRetry: _load,
                )
              : RefreshIndicator(
                  color: ChronoColors.sky,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      ChronoCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sanksi Aktif',
                                    style: TextStyle(fontSize: 12, color: ChronoColors.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_activeCount',
                                    style: ChronoTheme.mono(
                                      fontSize: 22,
                                      color: _activeCount > 0
                                          ? ChronoColors.danger
                                          : ChronoColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Terlambat Bulan Ini',
                                    style: TextStyle(fontSize: 12, color: ChronoColors.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_lateCount kali',
                                    style: ChronoTheme.mono(fontSize: 22),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_items.isEmpty)
                        const ChronoEmptyState(
                          icon: Icons.verified_user_outlined,
                          title: 'Catatan Disiplin Bersih',
                          description: 'Tidak ada sanksi atau surat peringatan pada akun Anda.',
                        )
                      else
                        ..._items.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ChronoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ChronoStatusTag(
                                        label: s.levelLabel.isNotEmpty ? s.levelLabel : s.level,
                                        tone: BadgeTone.danger,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          s.violationName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tanggal: ${ChronoFormat.dateIndo(s.incidentDate)}  |  Status: ${s.displayStatus}',
                                    style:
                                        const TextStyle(fontSize: 12, color: ChronoColors.textMuted),
                                  ),
                                  if (s.reason != null && s.reason!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      s.reason!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: ChronoColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _downloadSp(s),
                                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                                      label: Text(
                                        'Unduh Surat (${s.levelLabel.isNotEmpty ? s.levelLabel : s.level})',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
