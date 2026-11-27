/// Versi aplikasi Mobile Presensi Makerindo.
/// Diperbarui saat rilis versi aplikasi (menggunakan tag mobile-v* pada branch mobile).
class AppVersion {
  AppVersion._();

  static const String version = '1.0.0';
  static const int buildNumber = 1;
  static const String commitSha = 'local';
  static const String updatedAt = '2026-11-25';

  static String get label => 'v$version+$buildNumber';
  static String get fullLabel => 'v$version (Rilis $buildNumber)';
}
