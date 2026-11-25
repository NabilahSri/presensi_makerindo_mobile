import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_service.dart';

class AuthController extends ChangeNotifier {
  static const String _userCacheKey = 'chrono_cached_user';
  static const String _brandCacheKey = 'chrono_cached_brand';

  final ApiService api;
  UserProfile? _user;
  BrandSettings _brand = const BrandSettings();
  bool _initialized = false;
  bool _loading = false;
  int _sessionVersion = 0;

  AuthController({required this.api});

  UserProfile? get user => _user;
  BrandSettings get brand => _brand;
  bool get isAuthenticated => _user != null && api.token != null && api.token!.isNotEmpty;
  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  int get sessionVersion => _sessionVersion;

  Future<void> bootstrap() async {
    await api.init();
    final prefs = await SharedPreferences.getInstance();

    final cachedBrand = prefs.getString(_brandCacheKey);
    if (cachedBrand != null) {
      try {
        _brand = BrandSettings.fromJson(jsonDecode(cachedBrand) as Map<String, dynamic>);
      } catch (_) {
        _brand = const BrandSettings();
      }
    }

    final cached = prefs.getString(_userCacheKey);
    if (cached != null && api.token != null && api.token!.isNotEmpty) {
      try {
        final parsed = UserProfile.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        _user = parsed.isAllowedInMobile ? parsed : null;
        if (_user == null) {
          await api.setToken(null);
          await prefs.remove(_userCacheKey);
        }
      } catch (_) {
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();

    // Sync latest branding from web settings in background
    refreshBranding().catchError((_) {});

    if (isAuthenticated) {
      try {
        await refreshProfile();
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          await clearSession();
        }
      } catch (_) {
        // Keep cached session when offline
      }
    }
  }

  Future<void> refreshBranding() async {
    final fresh = await api.getBranding();
    _brand = fresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brandCacheKey, jsonEncode(fresh.toJson()));
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await api.login(email: email, password: password);
      if (!result.user.isAllowedInMobile) {
        await clearSession();
        throw const ApiException(
          'Akses ditolak. Aplikasi Presensi Makerindo Mobile hanya untuk Karyawan Regular dan Magang. Silakan masuk melalui Portal Web Presensi Makerindo.',
          statusCode: 403,
        );
      }
      _user = result.user;
      await _persistUser(result.user);
      // Setiap login wajib mengambil data profil & branding terbaru dari server
      await Future.wait([
        refreshBranding().catchError((_) {}),
        refreshProfile().catchError((_) {}),
      ]);
      _sessionVersion++;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    final fresh = await api.getProfile();
    if (!fresh.isAllowedInMobile) {
      await clearSession();
      throw const ApiException(
        'Akses ditolak. Aplikasi Presensi Makerindo Mobile hanya untuk Karyawan Regular dan Magang.',
        statusCode: 403,
      );
    }
    _user = fresh;
    await _persistUser(fresh);
    notifyListeners();
  }

  Future<void> updateUser(UserProfile updated) async {
    _user = updated;
    await _persistUser(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await api.logout();
    } finally {
      await clearSession();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearSession() async {
    _user = null;
    _sessionVersion++;
    await api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
    notifyListeners();
  }

  Future<void> _persistUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
  }
}
