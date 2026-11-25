import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../theme/chrono_theme.dart';
import '../widgets/chrono_widgets.dart';

enum CheckInMode {
  approvedWfa,
  approvedTugasLuar,
  internDaily,
  onsiteOffice,
  checkoutWfa,
  checkoutTugasLuar,
  checkoutIntern,
  checkoutOnsiteOffice,
}

class MobileCheckInScreen extends StatefulWidget {
  final AuthController auth;
  final CheckInMode mode;
  final String officeName;
  final double officeLatitude;
  final double officeLongitude;
  final int officeRadiusMeters;

  const MobileCheckInScreen({
    super.key,
    required this.auth,
    required this.mode,
    required this.officeName,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.officeRadiusMeters,
  });

  @override
  State<MobileCheckInScreen> createState() => _MobileCheckInScreenState();
}

class _MobileCheckInScreenState extends State<MobileCheckInScreen>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();

  Position? _position;
  double? _distanceMeters;
  bool _loadingLocation = true;
  String? _locationError;

  File? _selfieFile;
  bool _submitting = false;

  bool get _isCheckout =>
      widget.mode == CheckInMode.checkoutWfa ||
      widget.mode == CheckInMode.checkoutTugasLuar ||
      widget.mode == CheckInMode.checkoutIntern ||
      widget.mode == CheckInMode.checkoutOnsiteOffice;

  bool get _isStrictGeofence =>
      widget.mode == CheckInMode.onsiteOffice ||
      widget.mode == CheckInMode.checkoutOnsiteOffice;

  bool get _isWithinOfficeRadius {
    if (!_isStrictGeofence) return true;
    if (_distanceMeters == null) return false;
    return _distanceMeters! <= widget.officeRadiusMeters;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _position == null && !_loadingLocation) {
      _fetchLocation(showPopupOnError: false);
    }
  }

  Future<void> _fetchLocation({bool showPopupOnError = true}) async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'Layanan GPS perangkat tidak aktif. Aktifkan lokasi terlebih dahulu.';
            _loadingLocation = false;
          });
          if (showPopupOnError) {
            await showLocationRequiredDialog(context, isPermissionDenied: false);
          }
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError =
                'Izin lokasi ditolak. Berikan izin akses GPS di pengaturan aplikasi untuk melanjutkan.';
            _loadingLocation = false;
          });
          if (showPopupOnError) {
            await showLocationRequiredDialog(context, isPermissionDenied: true);
          }
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.officeLatitude,
        widget.officeLongitude,
      );

      if (mounted) {
        setState(() {
          _position = pos;
          _distanceMeters = dist;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Gagal mengambil koordinat GPS: $e';
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (picked != null && mounted) {
        setState(() => _selfieFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ChronoColors.danger,
            content: Text('Kamera tidak dapat dibuka: $e'),
          ),
        );
      }
    }
  }

  Future<void> _submitCheckIn() async {
    if (_position == null) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled().catchError((_) => false);
      if (!serviceEnabled) {
        if (mounted) {
          await showLocationRequiredDialog(context, isPermissionDenied: false);
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ChronoColors.danger,
            content: Text('Koordinat GPS belum tersedia. Tekan Perbarui Lokasi.'),
          ),
        );
      }
      return;
    }

    if (_isStrictGeofence && !_isWithinOfficeRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ChronoColors.danger,
          content: Text(
            'Anda berada di luar radius kantor (${_distanceMeters!.toStringAsFixed(0)} m, batas ${widget.officeRadiusMeters} m). Presensi kantor hanya dapat dilakukan di area kantor.',
          ),
        ),
      );
      return;
    }

    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: ChronoColors.danger,
          content: Text('Foto selfie wajah wajib diambil sebagai bukti kehadiran.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final String message;
      if (_isCheckout) {
        final result = await widget.auth.api.submitCheckout(
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          faceImage: _selfieFile!,
        );
        message = result.message;
      } else {
        final presenceType = switch (widget.mode) {
          CheckInMode.onsiteOffice => 'ON_SITE',
          CheckInMode.approvedWfa => 'WFA',
          CheckInMode.approvedTugasLuar => 'TUGAS_LUAR',
          _ => null,
        };
        message = await widget.auth.api.submitMobileCheckIn(
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          faceImage: _selfieFile!,
          presenceType: presenceType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: ChronoColors.danger, content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (appBarTitle, bannerTitle, bannerDesc, bannerBg, bannerBorder, bannerFg, bannerIcon) =
        switch (widget.mode) {
      CheckInMode.approvedWfa => (
          'Presensi Masuk WFA',
          'Pengajuan WFA Disetujui',
          'Presensi masuk ini akan dicatat sebagai WFA menggunakan koordinat GPS (tanpa batasan radius) dan foto selfie Anda.',
          ChronoColors.skyTint,
          ChronoColors.skySoft,
          ChronoColors.skyDark,
          Icons.verified_outlined,
        ),
      CheckInMode.approvedTugasLuar => (
          'Presensi Masuk Tugas Luar',
          'Pengajuan Tugas Luar Disetujui',
          'Presensi masuk ini akan dicatat sebagai Tugas Luar menggunakan koordinat GPS (tanpa batasan radius) dan foto selfie Anda.',
          ChronoColors.skyTint,
          ChronoColors.skySoft,
          ChronoColors.skyDark,
          Icons.work_outline_rounded,
        ),
      CheckInMode.internDaily => (
          'Presensi Masuk Magang',
          'Presensi Harian Magang',
          'Presensi masuk dicatat otomatis menggunakan koordinat GPS (tanpa batasan radius) dan foto selfie wajah Anda.',
          ChronoColors.successBg,
          ChronoColors.successBorder,
          ChronoColors.successDark,
          Icons.face_retouching_natural_rounded,
        ),
      CheckInMode.onsiteOffice => (
          'Presensi Masuk Kantor',
          'Presensi Kantor (GPS & Foto)',
          'Khusus kehadiran langsung di ${widget.officeName}. Posisi GPS wajib berada di dalam radius ${widget.officeRadiusMeters} meter dari kantor dan disertai foto selfie.',
          ChronoColors.skyTint,
          ChronoColors.skySoft,
          ChronoColors.skyDark,
          Icons.location_on_outlined,
        ),
      CheckInMode.checkoutWfa => (
          'Presensi Pulang WFA',
          'Presensi Pulang WFA (Kamera & GPS)',
          'Laporan Harian sore sudah selesai. Ambil foto selfie dan koordinat GPS untuk mencatat jam pulang WFA (tanpa batasan radius).',
          ChronoColors.skyTint,
          ChronoColors.skySoft,
          ChronoColors.skyDark,
          Icons.logout_rounded,
        ),
      CheckInMode.checkoutTugasLuar => (
          'Presensi Pulang Tugas Luar',
          'Presensi Pulang Tugas Luar (Kamera & GPS)',
          'Laporan Harian sore sudah selesai. Ambil foto selfie dan koordinat GPS untuk mencatat jam pulang Tugas Luar (tanpa batasan radius).',
          ChronoColors.skyTint,
          ChronoColors.skySoft,
          ChronoColors.skyDark,
          Icons.logout_rounded,
        ),
      CheckInMode.checkoutIntern => (
          'Presensi Pulang Magang',
          'Presensi Pulang Magang (Kamera & GPS)',
          'Laporan Harian sore sudah selesai. Ambil foto selfie dan koordinat GPS untuk mencatat jam pulang Anda.',
          ChronoColors.successBg,
          ChronoColors.successBorder,
          ChronoColors.successDark,
          Icons.logout_rounded,
        ),
      CheckInMode.checkoutOnsiteOffice => (
          'Presensi Pulang Kantor',
          'Presensi Pulang Kantor (GPS & Foto)',
          'Laporan Harian sore sudah selesai. Posisi GPS wajib berada di dalam radius ${widget.officeRadiusMeters} meter dari ${widget.officeName} disertai foto selfie.',
          ChronoColors.successBg,
          ChronoColors.successBorder,
          ChronoColors.successDark,
          Icons.location_on_outlined,
        ),
    };

    final canSubmit = !_submitting &&
        !_loadingLocation &&
        _position != null &&
        (!_isStrictGeofence || _isWithinOfficeRadius);

    return Scaffold(
      backgroundColor: ChronoColors.background,
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LiveClockBadge(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Status context banner
          ChronoCard(
            color: bannerBg,
            borderColor: bannerBorder,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(bannerIcon, color: bannerFg, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bannerTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: bannerFg,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bannerDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: bannerFg,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. GPS Coordinate & Geofence Card
          ChronoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 19, color: ChronoColors.sky),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Titik Koordinat GPS',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadingLocation ? null : _fetchLocation,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Perbarui'),
                      style: TextButton.styleFrom(
                        foregroundColor: ChronoColors.sky,
                        minimumSize: const Size(44, 40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingLocation)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ChronoColors.sky),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Mengambil koordinat GPS perangkat...',
                          style: TextStyle(fontSize: 12.5, color: ChronoColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else if (_locationError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ChronoColors.dangerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ChronoColors.dangerBorder),
                    ),
                    child: Text(
                      _locationError!,
                      style: const TextStyle(fontSize: 12.5, color: ChronoColors.dangerDark),
                    ),
                  )
                else if (_position != null)
                  _buildGpsResultBox(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Selfie Verification Card
          ChronoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_front_outlined, size: 19, color: ChronoColors.dark),
                    SizedBox(width: 8),
                    Text(
                      'Foto Selfie Wajah (Wajib)',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pastikan wajah terlihat jelas di tempat yang cukup cahaya sebagai bukti autentikasi kehadiran.',
                  style: TextStyle(fontSize: 12, color: ChronoColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 14),
                if (_selfieFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.file(_selfieFile!, fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ChronoColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ChronoColors.borderStrong),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_pin_circle_outlined, size: 42, color: ChronoColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada foto selfie diambil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ChronoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _captureSelfie,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(_selfieFile == null ? 'Buka Kamera Selfie' : 'Ambil Ulang Foto'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? _submitCheckIn : null,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isCheckout
                    ? (_isStrictGeofence
                        ? 'Kirim Presensi Pulang Kantor'
                        : 'Kirim Presensi Pulang')
                    : (_isStrictGeofence
                        ? 'Kirim Presensi Masuk Kantor'
                        : 'Kirim Presensi Masuk'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsResultBox() {
    final pos = _position!;
    final isBlockedOutside = _isStrictGeofence && !_isWithinOfficeRadius;

    final bg = isBlockedOutside ? ChronoColors.dangerBg : ChronoColors.successBg;
    final border = isBlockedOutside ? ChronoColors.dangerBorder : ChronoColors.successBorder;
    final fg = isBlockedOutside ? ChronoColors.dangerDark : ChronoColors.successDark;
    final icon = isBlockedOutside ? Icons.wrong_location_outlined : Icons.check_circle_rounded;
    final iconColor = isBlockedOutside ? ChronoColors.danger : ChronoColors.success;

    final String subtitle;
    if (_isStrictGeofence && _distanceMeters != null) {
      final distText = '${_distanceMeters!.toStringAsFixed(0)} m';
      subtitle = _isWithinOfficeRadius
          ? 'Dalam radius kantor ($distText dari kantor, batas ${widget.officeRadiusMeters} m)'
          : 'Di luar radius kantor ($distText dari kantor, batas ${widget.officeRadiusMeters} m). Presensi kantor hanya berlaku di area kantor.';
    } else {
      subtitle =
          'Akurasi sekitar ${pos.accuracy.toStringAsFixed(0)} m (tanpa batasan radius lokasi)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
                  style: ChronoTheme.mono(fontSize: 12.5, color: fg),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: fg, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
