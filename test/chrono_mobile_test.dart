import 'package:presensi_makerindo/main.dart';
import 'package:presensi_makerindo/models/models.dart';
import 'package:presensi_makerindo/screens/login_screen.dart';
import 'package:presensi_makerindo/screens/main_shell.dart';
import 'package:presensi_makerindo/screens/splash_screen.dart';
import 'package:presensi_makerindo/services/api_service.dart';
import 'package:presensi_makerindo/services/auth_controller.dart';
import 'package:presensi_makerindo/theme/chrono_theme.dart';
import 'package:presensi_makerindo/widgets/chrono_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProfile & UI Flags role adaptation', () {
    test('KARTAP employee uses GPS_PHOTO mode and is allowed in mobile', () {
      final user = UserProfile.fromJson({
        'id': 'u-1',
        'name': 'Budi Santoso',
        'email': 'budi@makerindo.test',
        'profile_photo_path': 'profile-photos/budi.jpg',
        'profile_photo_url': 'http://127.0.0.1:8000/storage/profile-photos/budi.jpg',
        'employment_type': 'KARTAP',
        'can_approve_leaves': false,
        'is_attendance_required': true,
        'roles': ['karyawan'],
        'ui_flags': {
          'primary_attendance_mode': 'GPS_PHOTO',
          'show_leave_approval_menu': false,
        },
      });

      expect(user.isAllowedInMobile, isTrue);
      expect(user.isIntern, isFalse);
      expect(user.isKartap, isTrue);
      expect(user.profilePhotoPath, 'profile-photos/budi.jpg');
      expect(user.profilePhotoUrl, 'http://127.0.0.1:8000/storage/profile-photos/budi.jpg');
      expect(user.uiFlags.primaryAttendanceMode, 'GPS_PHOTO');
      expect(user.uiFlags.showLeaveApprovalMenu, isFalse);
    });

    test('INTERN uses GPS_PHOTO primary mode and is allowed in mobile', () {
      final user = UserProfile.fromJson({
        'id': 'u-2',
        'name': 'Nabilah Putri',
        'email': 'nabilah@makerindo.test',
        'employment_type': 'INTERN',
        'can_approve_leaves': false,
        'roles': ['intern'],
        'ui_flags': {
          'primary_attendance_mode': 'GPS_PHOTO',
          'show_leave_approval_menu': false,
        },
      });

      expect(user.isAllowedInMobile, isTrue);
      expect(user.isIntern, isTrue);
      expect(user.uiFlags.primaryAttendanceMode, 'GPS_PHOTO');
      expect(user.uiFlags.showLeaveApprovalMenu, isFalse);
    });

    test('Approver with can_approve_leaves=true enables leave approval menu', () {
      final user = UserProfile.fromJson({
        'id': 'u-3',
        'name': 'Rina Manager',
        'email': 'rina@makerindo.test',
        'employment_type': 'PKWT',
        'can_approve_leaves': true,
        'roles': ['karyawan'],
        'ui_flags': {
          'primary_attendance_mode': 'GPS_PHOTO',
          'show_leave_approval_menu': true,
        },
      });

      expect(user.isAllowedInMobile, isTrue);
      expect(user.canApproveLeaves, isTrue);
      expect(user.uiFlags.showLeaveApprovalMenu, isTrue);
    });

    test('Pure web roles are rejected from mobile access', () {
      for (final roles in [
        ['super_admin'],
        ['ceo'],
      ]) {
        final user = UserProfile.fromJson({
          'id': 'u-web',
          'name': 'Web User',
          'email': 'web@makerindo.test',
          'employment_type': 'KARTAP',
          'roles': roles,
        });
        expect(user.isAllowedInMobile, isFalse);
      }
    });

    test('AttendanceTodayData parses WFA and On-Site GPS gate flags correctly', () {
      final pendingData = AttendanceTodayData.fromJson({
        'date': '2026-11-24',
        'has_checked_in': false,
        'has_checked_out': false,
        'can_checkout': false,
        'checkout_mode': 'ONSITE_GEOFENCE',
        'has_approved_wfa_today': false,
        'wfa_request_today_status': 'PENDING',
        'can_mobile_checkin': false,
        'can_onsite_checkin': true,
        'daily_report': {},
        'office': {
          'name': 'Kantor Pusat',
          'latitude': -6.2088,
          'longitude': 106.8456,
          'radius': 100,
        },
      });

      expect(pendingData.hasApprovedWfaToday, isFalse);
      expect(pendingData.wfaRequestTodayStatus, 'PENDING');
      expect(pendingData.canMobileCheckIn, isFalse);
      expect(pendingData.canOnsiteCheckIn, isTrue);
      expect(pendingData.checkoutMode, 'ONSITE_GEOFENCE');
      expect(pendingData.officeRadiusMeters, 100);
      expect(pendingData.officeLatitude, closeTo(-6.2088, 0.0001));

      final approvedData = AttendanceTodayData.fromJson({
        'date': '2026-11-24',
        'has_checked_in': false,
        'has_checked_out': false,
        'can_checkout': false,
        'checkout_mode': 'MOBILE_FREE',
        'has_approved_wfa_today': true,
        'wfa_request_today_status': 'APPROVED',
        'can_mobile_checkin': true,
        'daily_report': {},
        'office': {'name': 'Kantor Pusat'},
      });

      expect(approvedData.hasApprovedWfaToday, isTrue);
      expect(approvedData.wfaRequestTodayStatus, 'APPROVED');
      expect(approvedData.canMobileCheckIn, isTrue);
      expect(approvedData.checkoutMode, 'MOBILE_FREE');
    });

    test('BrandSettings parses custom app name, slogan, and logo URL from web settings', () {
      final brand = BrandSettings.fromJson({
        'app_name': 'Presensi Makerindo',
        'app_slogan': 'Sistem Presensi GPS & Foto Modern',
        'app_logo_path': 'uploads/branding/logo_test.png',
        'app_logo_url': 'http://192.168.1.5:8000/uploads/branding/logo_test.png',
        'office_name': 'Kantor Makerindo',
      });

      expect(brand.appName, 'Presensi Makerindo');
      expect(brand.appSlogan, 'Sistem Presensi GPS & Foto Modern');
      expect(brand.logoUrl, 'http://192.168.1.5:8000/uploads/branding/logo_test.png');
    });

    test('ChronoFormat.dateIndo formats plain Y-m-d dates without timezone shift', () {
      expect(ChronoFormat.dateIndo('2026-11-26'), '26 Nov 2026');
    });
  });

  group('LoginScreen UI & interactive validation', () {
    testWidgets('renders Presensi Makerindo login form, validates empty submit, and opens dialogs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final api = ApiService();
      await api.init();
      final auth = AuthController(api: api);

      await tester.pumpWidget(
        MaterialApp(
          theme: ChronoTheme.build(),
          home: LoginScreen(auth: auth),
        ),
      );
      await tester.pump();

      expect(find.text('Masuk ke Presensi Makerindo'), findsOneWidget);
      expect(find.text('Masuk ke Aplikasi'), findsOneWidget);

      // Submit empty form -> shows validation messages
      await tester.tap(find.text('Masuk ke Aplikasi'));
      await tester.pump();
      expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);

      // Open & close Help dialog
      await tester.tap(find.text('Lupa Kata Sandi?'));
      await tester.pumpAndSettle();
      expect(find.text('Bantuan Akses Akun'), findsOneWidget);
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Bantuan Akses Akun'), findsNothing);

      // Open & close Server Settings dialog
      await tester.ensureVisible(find.text('Ubah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      expect(find.text('Alamat Server API'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Alamat Server API'), findsNothing);
    });

    testWidgets('MainShell locks all menus on IZIN/CUTI/SAKIT day without auto-logout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final api = ApiService();
      await api.init();
      final auth = AuthController(api: api);

      final leaveToday = AttendanceTodayData.fromJson({
        'date': '2026-11-25',
        'has_checked_in': false,
        'has_checked_out': false,
        'can_checkout': false,
        'has_approved_wfa_today': false,
        'has_approved_tugas_luar_today': false,
        'is_on_leave_today': true,
        'today_leave_status': 'SAKIT',
        'today_leave_detail': {
          'id': 'lv-1',
          'type': 'SAKIT',
          'start_date': '2026-11-25',
          'end_date': '2026-11-25',
          'reason': 'Demam tinggi',
        },
        'can_mobile_checkin': false,
        'can_onsite_checkin': false,
        'daily_report': {},
        'office': {'name': 'Kantor Pusat'},
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ChronoTheme.build(),
          home: MainShell(auth: auth, initialTodayOverride: leaveToday),
        ),
      );
      await tester.pump();

      expect(find.text('Akses Aplikasi Dinonaktifkan Sementara'), findsOneWidget);
      expect(find.text('Sedang Sakit Hari Ini'), findsOneWidget);
      expect(find.text('Demam tinggi'), findsOneWidget);
      expect(find.text('Periksa Ulang Status'), findsOneWidget);

      // Semua menu navigasi harus tidak dapat diakses
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Beranda'), findsNothing);
      expect(find.text('Laporan'), findsNothing);
      expect(find.text('Profil'), findsNothing);
    });

    testWidgets('showLocationRequiredDialog renders GPS inactive pop-up with settings action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ChronoTheme.build(),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showLocationRequiredDialog(context),
                child: const Text('Cek GPS'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cek GPS'));
      await tester.pumpAndSettle();

      expect(find.text('Lokasi (GPS) Tidak Aktif'), findsOneWidget);
      expect(find.text('Aktifkan Lokasi'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Lokasi (GPS) Tidak Aktif'), findsNothing);
    });

    testWidgets('ChronoMobileApp displays SplashScreen first then routes to LoginScreen when logged out',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final api = ApiService();
      final auth = AuthController(api: api);

      await tester.pumpWidget(
        ChronoMobileApp(
          auth: auth,
          splashDuration: const Duration(milliseconds: 200),
        ),
      );
      await tester.pump();

      // SplashScreen tampil terlebih dahulu sebelum login
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Setelah durasi splash selesai, otomatis berpindah ke LoginScreen
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    test('ApiService attaches Cache-Control and Pragma no-cache headers', () async {
      final api = ApiService();
      await api.init();

      final headers = api.buildHeadersForTest();
      expect(headers['Accept'], 'application/json');
      expect(headers['Cache-Control'], contains('no-cache'));
      expect(headers['Cache-Control'], contains('no-store'));
      expect(headers['Pragma'], 'no-cache');
    });

    testWidgets('MainShell reloads latest backend data on AppLifecycleState.resumed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final api = _FakeResumeApiService();
      await api.init();
      await api.setToken('test-token');
      final auth = AuthController(api: api);
      await auth.refreshProfile();
      api.resetCounters();

      await tester.pumpWidget(
        MaterialApp(
          theme: ChronoTheme.build(),
          home: MainShell(auth: auth),
        ),
      );
      await tester.pumpAndSettle();

      final initialBranding = api.brandingCalls;
      final initialProfile = api.profileCalls;
      final initialToday = api.todayCalls;
      expect(initialBranding, greaterThanOrEqualTo(1));
      expect(initialProfile, greaterThanOrEqualTo(1));
      expect(initialToday, greaterThanOrEqualTo(1));
      expect(find.text('Karyawan Uji'), findsOneWidget);

      // Simulasikan pembaruan data di backend lalu aplikasi kembali dari background (resumed)
      api.dynamicName = 'Karyawan Terbaru';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(api.brandingCalls, greaterThan(initialBranding));
      expect(api.profileCalls, greaterThan(initialProfile));
      expect(api.todayCalls, greaterThan(initialToday));
      expect(find.text('Karyawan Terbaru'), findsOneWidget);
    });
  });
}

class _FakeResumeApiService extends ApiService {
  int brandingCalls = 0;
  int profileCalls = 0;
  int todayCalls = 0;
  String dynamicName = 'Karyawan Uji';

  void resetCounters() {
    brandingCalls = 0;
    profileCalls = 0;
    todayCalls = 0;
  }

  @override
  Future<BrandSettings> getBranding() async {
    brandingCalls++;
    return const BrandSettings(
      appName: 'Presensi Makerindo',
      appSlogan: 'Slogan Uji',
      officeName: 'Kantor Uji',
    );
  }

  @override
  Future<UserProfile> getProfile() async {
    profileCalls++;
    return UserProfile.fromJson({
      'id': 'u-test',
      'name': dynamicName,
      'email': 'uji@makerindo.test',
      'employment_type': 'KARTAP',
      'can_approve_leaves': false,
      'is_attendance_required': true,
      'roles': ['karyawan'],
      'ui_flags': {
        'primary_attendance_mode': 'GPS_PHOTO',
        'show_leave_approval_menu': false,
      },
    });
  }

  @override
  Future<AttendanceTodayData> getAttendanceToday() async {
    todayCalls++;
    return AttendanceTodayData.fromJson({
      'date': '2026-11-27',
      'has_checked_in': false,
      'has_checked_out': false,
      'can_checkout': false,
      'has_approved_wfa_today': false,
      'has_approved_tugas_luar_today': false,
      'is_on_leave_today': false,
      'can_mobile_checkin': false,
      'can_onsite_checkin': false,
      'daily_report': {},
      'office': {'name': 'Kantor Uji'},
    });
  }

  @override
  Future<AttendanceHistoryData> getAttendanceHistory({required int month, required int year}) async {
    return AttendanceHistoryData.fromJson({
      'month': month,
      'year': year,
      'summary': {
        'present_days': 0,
        'late_days': 0,
        'leave_days': 0,
        'total_overtime_hours': 0,
      },
      'records': [],
    });
  }

  @override
  Future<DailyReportTodayData> getReportToday() async {
    return DailyReportTodayData.fromJson({
      'date': '2026-11-27',
      'has_morning_report': false,
      'has_evening_report': false,
    });
  }

  @override
  Future<List<LeaveRequestModel>> getMyLeaves() async => [];

  @override
  Future<({int activeCount, int lateCount, List<SanctionModel> items})> getSanctions() async {
    return (activeCount: 0, lateCount: 0, items: <SanctionModel>[]);
  }
}
