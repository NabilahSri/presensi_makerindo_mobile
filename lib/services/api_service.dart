import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  static const String _baseUrlPrefKey = 'chrono_api_base_url';
  static const String _tokenPrefKey = 'chrono_auth_token';

  /// Default base URL uses Android emulator loopback on Android, localhost elsewhere.
  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  String _baseUrl = defaultBaseUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlPrefKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = _normalizeUrl(savedUrl);
    }
    _token = prefs.getString(_tokenPrefKey);
  }

  Future<void> setBaseUrl(String url) async {
    final clean = _normalizeUrl(url);
    _baseUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, clean);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenPrefKey);
    } else {
      await prefs.setString(_tokenPrefKey, token);
    }
  }

  String _normalizeUrl(String raw) {
    var clean = raw.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.endsWith('/api')) {
      clean = '$clean/api';
    }
    return clean;
  }

  Map<String, String> _headers({bool jsonContent = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$cleanPath');
    return query != null && query.isNotEmpty ? uri.replace(queryParameters: query) : uri;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        if (response.statusCode >= 400) {
          throw ApiException(
            'Server mengembalikan respons tidak valid (HTTP ${response.statusCode}).',
            statusCode: response.statusCode,
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = body['message']?.toString() ?? 'Permintaan gagal diproses (HTTP ${response.statusCode}).';
    final errors = body['errors'] as Map<String, dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      final firstVal = errors.values.first;
      if (firstVal is List && firstVal.isNotEmpty) {
        message = firstVal.first.toString();
      }
    }

    throw ApiException(message, statusCode: response.statusCode, errors: errors);
  }

  Future<Map<String, dynamic>> _safeRequest(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(const Duration(seconds: 25));
      return _decodeResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu koneksi ke server habis. Silakan periksa jaringan Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException(
        'Tidak dapat terhubung ke server Presensi Makerindo. Periksa koneksi internet atau alamat server API.',
      );
    } on HttpException {
      throw const ApiException('Terjadi gangguan komunikasi HTTP dengan server.');
    } catch (e) {
      throw ApiException('Gagal menghubungi server: $e');
    }
  }

  // ===========================================================================
  // 0. BRANDING (PUBLIC)
  // ===========================================================================

  Future<BrandSettings> getBranding() async {
    final json = await _safeRequest(() => http.get(_uri('/branding'), headers: _headers()));
    final raw = json['data'];
    return BrandSettings.fromJson(raw is Map ? Map<String, dynamic>.from(raw) : null);
  }

  // ===========================================================================
  // 1. AUTH & PROFILE
  // ===========================================================================

  Future<({String token, UserProfile user})> login({
    required String email,
    required String password,
    String deviceName = 'PresensiMakerindo-Flutter',
  }) async {
    final json = await _safeRequest(
      () => http.post(
        _uri('/login'),
        headers: _headers(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'device_name': deviceName,
        }),
      ),
    );

    final token = json['access_token']?.toString() ?? '';
    final user = UserProfile.fromJson(json['user'] as Map<String, dynamic>);
    await setToken(token);
    return (token: token, user: user);
  }

  Future<void> logout() async {
    try {
      if (_token != null && _token!.isNotEmpty) {
        await _safeRequest(() => http.post(_uri('/logout'), headers: _headers()));
      }
    } finally {
      await setToken(null);
    }
  }

  Future<UserProfile> getProfile() async {
    final json = await _safeRequest(() => http.get(_uri('/profile'), headers: _headers()));
    return UserProfile.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<({String message, UserProfile user})> uploadProfilePhoto(File photo) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/profile/photo'));
      request.headers.addAll(_headers(jsonContent: false));
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final json = _decodeResponse(response);
      return (
        message: json['message']?.toString() ?? 'Foto profil berhasil diperbarui.',
        user: UserProfile.fromJson(json['data'] as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu koneksi ke server habis. Silakan periksa jaringan Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server saat mengunggah foto profil.');
    } catch (e) {
      throw ApiException('Gagal mengunggah foto profil: $e');
    }
  }

  Future<({String message, UserProfile user})> deleteProfilePhoto() async {
    final json = await _safeRequest(
      () => http.delete(_uri('/profile/photo'), headers: _headers()),
    );
    return (
      message: json['message']?.toString() ?? 'Foto profil berhasil dihapus.',
      user: UserProfile.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final json = await _safeRequest(
      () => http.put(
        _uri('/profile/password'),
        headers: _headers(),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      ),
    );
    return json['message']?.toString() ?? 'Kata sandi berhasil diperbarui.';
  }

  // ===========================================================================
  // 2. ATTENDANCE
  // ===========================================================================

  Future<AttendanceTodayData> getAttendanceToday() async {
    final json = await _safeRequest(() => http.get(_uri('/attendance/today'), headers: _headers()));
    return AttendanceTodayData.fromJson(json);
  }

  Future<String> submitMobileCheckIn({
    required double latitude,
    required double longitude,
    required File faceImage,
    String? presenceType,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/attendance/wfa'));
      request.headers.addAll(_headers(jsonContent: false));
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      if (presenceType != null && presenceType.isNotEmpty) {
        request.fields['presence_type'] = presenceType;
      }
      request.files.add(await http.MultipartFile.fromPath('face_image', faceImage.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final json = _decodeResponse(response);
      return json['message']?.toString() ?? 'Presensi masuk berhasil dicatat.';
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu koneksi ke server habis. Silakan periksa jaringan Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server saat mengirim foto presensi.');
    } catch (e) {
      throw ApiException('Gagal mengirim presensi: $e');
    }
  }

  Future<({String message, int overtimeHours})> submitCheckout({
    required double latitude,
    required double longitude,
    required File faceImage,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/attendance/checkout'));
      request.headers.addAll(_headers(jsonContent: false));
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('face_image', faceImage.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final json = _decodeResponse(response);
      return (
        message: json['message']?.toString() ?? 'Presensi pulang berhasil dicatat.',
        overtimeHours: (json['overtime_hours'] as num?)?.toInt() ?? 0,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu koneksi ke server habis. Silakan periksa jaringan Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server saat mengirim foto presensi pulang.');
    } catch (e) {
      throw ApiException('Gagal mengirim presensi pulang: $e');
    }
  }

  Future<AttendanceHistoryData> getAttendanceHistory({required int month, required int year}) async {
    final json = await _safeRequest(
      () => http.get(
        _uri('/attendance/history', {'month': '$month', 'year': '$year'}),
        headers: _headers(),
      ),
    );
    return AttendanceHistoryData.fromJson(json);
  }

  // ===========================================================================
  // 3. DAILY REPORTS
  // ===========================================================================

  Future<DailyReportTodayData> getReportToday() async {
    final json = await _safeRequest(() => http.get(_uri('/reports/today'), headers: _headers()));
    return DailyReportTodayData.fromJson(json);
  }

  Future<String> submitMorningReport(List<String> tasks) async {
    final json = await _safeRequest(
      () => http.post(
        _uri('/reports/morning'),
        headers: _headers(),
        body: jsonEncode({'morning_planned_tasks': tasks}),
      ),
    );
    return json['message']?.toString() ?? 'Rencana tugas pagi berhasil disimpan.';
  }

  Future<String> submitEveningReport({
    required List<String> completedTasks,
    required List<String> pendingTasks,
    required List<String> additionalTasks,
  }) async {
    final json = await _safeRequest(
      () => http.post(
        _uri('/reports/evening'),
        headers: _headers(),
        body: jsonEncode({
          'evening_completed_tasks': completedTasks,
          'evening_pending_tasks': pendingTasks,
          'evening_additional_tasks': additionalTasks,
        }),
      ),
    );
    return json['message']?.toString() ?? 'Evaluasi tugas sore berhasil disimpan.';
  }

  Future<List<DailyReportModel>> getReportHistory({int? month, int? year}) async {
    final query = <String, String>{};
    if (month != null) query['month'] = '$month';
    if (year != null) query['year'] = '$year';

    final json = await _safeRequest(
      () => http.get(_uri('/reports/history', query), headers: _headers()),
    );
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => DailyReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================================================================
  // 4. LEAVES & DYNAMIC APPROVALS
  // ===========================================================================

  Future<List<LeaveRequestModel>> getMyLeaves() async {
    final json = await _safeRequest(() => http.get(_uri('/leaves'), headers: _headers()));
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> submitLeaveRequest({
    required String type, // SAKIT, IZIN, WFA, CUTI, TUGAS_LUAR
    required String startDate,
    required String endDate,
    required String reason,
    File? attachment,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/leaves'));
      request.headers.addAll(_headers(jsonContent: false));
      request.fields['type'] = type;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason.trim();
      if (attachment != null) {
        request.files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final json = _decodeResponse(response);
      return json['message']?.toString() ?? 'Pengajuan berhasil dikirim.';
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu koneksi ke server habis. Silakan periksa jaringan Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server saat mengirim pengajuan.');
    } catch (e) {
      throw ApiException('Gagal mengirim pengajuan: $e');
    }
  }

  Future<String> updateLeaveRequest({
    required String leaveId,
    required String type, // SAKIT, IZIN, WFA, CUTI, TUGAS_LUAR
    required String startDate,
    required String endDate,
    required String reason,
    File? attachment,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri('/leaves/$leaveId/update'));
      request.headers.addAll(_headers(jsonContent: false));
      request.fields['type'] = type;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason.trim();
      if (attachment != null) {
        request.files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final json = _decodeResponse(response);
      return json['message']?.toString() ?? 'Pengajuan perizinan berhasil diperbarui.';
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Waktu koneksi ke server habis. Silakan periksa jaringan Anda dan coba lagi.',
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server saat memperbarui pengajuan.');
    } catch (e) {
      throw ApiException('Gagal memperbarui pengajuan: $e');
    }
  }

  Future<String> cancelLeaveRequest(String leaveId) async {
    final json = await _safeRequest(
      () => http.delete(
        _uri('/leaves/$leaveId'),
        headers: _headers(),
      ),
    );
    return json['message']?.toString() ?? 'Pengajuan perizinan berhasil dibatalkan.';
  }

  Future<({int totalPending, List<LeaveRequestModel> items})> getLeaveApprovals({
    String status = 'PENDING',
  }) async {
    final json = await _safeRequest(
      () => http.get(_uri('/leaves/approvals', {'status': status}), headers: _headers()),
    );
    final items = (json['data'] as List<dynamic>? ?? [])
        .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      totalPending: (json['total_pending'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<String> processLeaveApproval({
    required String leaveId,
    required String status, // APPROVED or REJECTED
    String? rejectionReason,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
      body['rejection_reason'] = rejectionReason.trim();
    }
    final json = await _safeRequest(
      () => http.post(
        _uri('/leaves/$leaveId/action'),
        headers: _headers(),
        body: jsonEncode(body),
      ),
    );
    return json['message']?.toString() ?? 'Keputusan persetujuan berhasil disimpan.';
  }

  // ===========================================================================
  // 5. SANCTIONS
  // ===========================================================================

  Future<({int activeCount, int lateCount, List<SanctionModel> items})> getSanctions() async {
    final json = await _safeRequest(() => http.get(_uri('/sanctions'), headers: _headers()));
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final items = (json['data'] as List<dynamic>? ?? [])
        .map((e) => SanctionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      activeCount: (summary['active_sanctions'] as num?)?.toInt() ?? 0,
      lateCount: (summary['current_month_late_count'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<File> downloadSanctionPdf(String sanctionId, String level) async {
    final response = await http
        .get(_uri('/sanctions/$sanctionId/download'), headers: _headers(jsonContent: false))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      _decodeResponse(response);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Surat_Sanksi_${level}_$sanctionId.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }
}
