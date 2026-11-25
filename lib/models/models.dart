class BrandSettings {
  final String appName;
  final String appSlogan;
  final String? logoPath;
  final String? logoUrl;
  final String officeName;

  const BrandSettings({
    this.appName = 'Presensi Makerindo',
    this.appSlogan = 'Sistem Presensi GPS & Foto Makerindo',
    this.logoPath,
    this.logoUrl,
    this.officeName = 'Kantor PT Makerindo Prima Solusi',
  });

  factory BrandSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrandSettings();
    final name = json['app_name']?.toString().trim() ?? '';
    final slogan = json['app_slogan']?.toString().trim() ?? '';
    final logoUrl = json['app_logo_url']?.toString().trim();
    final logoPath = json['app_logo_path']?.toString().trim();
    final office = json['office_name']?.toString().trim() ?? '';

    return BrandSettings(
      appName: name.isNotEmpty ? name : 'Presensi Makerindo',
      appSlogan: slogan.isNotEmpty ? slogan : 'Sistem Presensi GPS & Foto Makerindo',
      logoPath: (logoPath != null && logoPath.isNotEmpty) ? logoPath : null,
      logoUrl: (logoUrl != null && logoUrl.isNotEmpty) ? logoUrl : null,
      officeName: office.isNotEmpty ? office : 'Kantor PT Makerindo Prima Solusi',
    );
  }

  Map<String, dynamic> toJson() => {
        'app_name': appName,
        'app_slogan': appSlogan,
        'app_logo_path': logoPath,
        'app_logo_url': logoUrl,
        'office_name': officeName,
      };
}

class UiFlags {
  final String primaryAttendanceMode;
  final bool showLeaveApprovalMenu;

  const UiFlags({
    required this.primaryAttendanceMode,
    required this.showLeaveApprovalMenu,
  });

  factory UiFlags.fromJson(Map<String, dynamic>? json, bool canApprove) {
    if (json == null) {
      return UiFlags(
        primaryAttendanceMode: 'GPS_PHOTO',
        showLeaveApprovalMenu: canApprove,
      );
    }
    return UiFlags(
      primaryAttendanceMode: json['primary_attendance_mode']?.toString() ?? 'GPS_PHOTO',
      showLeaveApprovalMenu: json['show_leave_approval_menu'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'primary_attendance_mode': primaryAttendanceMode,
        'show_leave_approval_menu': showLeaveApprovalMenu,
      };
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;
  final String employmentType; // KARTAP, PKWT, INTERN
  final bool canApproveLeaves;
  final bool isAttendanceRequired;
  final List<String> roles;
  final List<String> roleDisplayNames;
  final UiFlags uiFlags;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoPath,
    this.profilePhotoUrl,
    required this.employmentType,
    required this.canApproveLeaves,
    required this.isAttendanceRequired,
    required this.roles,
    required this.roleDisplayNames,
    required this.uiFlags,
  });

  bool get isIntern => employmentType.toUpperCase() == 'INTERN';
  bool get isKartap => employmentType.toUpperCase() == 'KARTAP';
  bool get isPkwt => employmentType.toUpperCase() == 'PKWT';

  bool get isAllowedInMobile {
    final normalized = roles.map((r) => r.toLowerCase()).toSet();
    const mobileRoles = {'karyawan', 'intern'};
    return normalized.any(mobileRoles.contains);
  }

  String get employmentLabel {
    switch (employmentType.toUpperCase()) {
      case 'KARTAP':
        return 'Karyawan Tetap (KARTAP)';
      case 'PKWT':
        return 'Karyawan Kontrak (PKWT)';
      case 'INTERN':
        return 'Magang / PKL';
      default:
        return employmentType;
    }
  }

  String get shortEmploymentLabel {
    return employmentType.toUpperCase() == 'INTERN' ? 'MAGANG' : employmentType;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final empType = json['employment_type']?.toString().toUpperCase() ?? 'PKWT';
    final canApprove = json['can_approve_leaves'] == true;
    final rawRoles = (json['roles'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final rawDetails = (json['role_details'] as List<dynamic>? ?? [])
        .map((e) => (e is Map ? (e['display_name'] ?? e['name']) : e).toString())
        .toList();

    final photoPath = json['profile_photo_path']?.toString().trim();
    final photoUrl = json['profile_photo_url']?.toString().trim();

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePhotoPath: (photoPath != null && photoPath.isNotEmpty) ? photoPath : null,
      profilePhotoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
      employmentType: empType,
      canApproveLeaves: canApprove,
      isAttendanceRequired: json['is_attendance_required'] != false,
      roles: rawRoles,
      roleDisplayNames: rawDetails.isNotEmpty ? rawDetails : rawRoles,
      uiFlags: UiFlags.fromJson(json['ui_flags'] as Map<String, dynamic>?, canApprove),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profile_photo_path': profilePhotoPath,
        'profile_photo_url': profilePhotoUrl,
        'employment_type': employmentType,
        'can_approve_leaves': canApproveLeaves,
        'is_attendance_required': isAttendanceRequired,
        'roles': roles,
        'role_details': roleDisplayNames.map((d) => {'display_name': d}).toList(),
        'ui_flags': uiFlags.toJson(),
      };
}

class AttendanceRecord {
  final String id;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final String status;
  final String? method;
  final bool isLate;
  final int overtimeHours;
  final double? latitude;
  final double? longitude;
  final String? faceImagePath;
  final String? faceImageUrl;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.status,
    this.method,
    required this.isLate,
    required this.overtimeHours,
    this.latitude,
    this.longitude,
    this.faceImagePath,
    this.faceImageUrl,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString() ?? '';
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      date: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      timeIn: json['time_in']?.toString(),
      timeOut: json['time_out']?.toString(),
      status: json['status']?.toString() ?? 'ALPHA',
      method: json['method']?.toString(),
      isLate: json['is_late'] == true,
      overtimeHours: _toInt(json['overtime_hours']),
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _toDouble(json['longitude']) : null,
      faceImagePath: json['face_image_path']?.toString(),
      faceImageUrl: json['face_image_url']?.toString(),
    );
  }

  String get displayStatus {
    switch (status.toUpperCase()) {
      case 'HADIR_ON_SITE':
        return 'Hadir Kantor';
      case 'WFA':
      case 'WFH':
        return 'WFA';
      case 'TUGAS_LUAR':
        return 'Tugas Luar';
      case 'CUTI':
        return 'Cuti';
      case 'SAKIT':
        return 'Sakit';
      case 'IZIN':
        return 'Izin';
      case 'ALPHA':
        return 'Alpa';
      default:
        return status;
    }
  }

  String get displayMethod {
    switch ((method ?? '').toUpperCase()) {
      case 'FACIAL_LOCATION':
        return 'GPS & Foto';
      case 'FORM':
        return 'Formulir Izin';
      default:
        return '-';
    }
  }
}

class AttendanceTodayData {
  final String date;
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final bool canCheckout;
  final String? checkoutMode; // MOBILE_FREE or ONSITE_GEOFENCE
  final bool hasApprovedWfaToday;
  final String? wfaRequestTodayStatus; // APPROVED, PENDING, REJECTED, null
  final bool hasApprovedTugasLuarToday;
  final String? tugasLuarRequestTodayStatus; // APPROVED, PENDING, REJECTED, null
  final bool isOnLeaveToday;
  final String? todayLeaveStatus; // CUTI, SAKIT, IZIN, null
  final String? todayLeaveStartDate;
  final String? todayLeaveEndDate;
  final String? todayLeaveReason;
  final bool canMobileCheckIn;
  final bool canOnsiteCheckIn;
  final AttendanceRecord? attendance;
  final bool hasMorningReport;
  final bool hasEveningReport;
  final String? dailyReportStatus;
  final String? morningSubmittedAt;
  final String? eveningSubmittedAt;
  final String officeName;
  final double officeLatitude;
  final double officeLongitude;
  final int officeRadiusMeters;

  const AttendanceTodayData({
    required this.date,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    required this.canCheckout,
    this.checkoutMode,
    required this.hasApprovedWfaToday,
    this.wfaRequestTodayStatus,
    required this.hasApprovedTugasLuarToday,
    this.tugasLuarRequestTodayStatus,
    required this.isOnLeaveToday,
    this.todayLeaveStatus,
    this.todayLeaveStartDate,
    this.todayLeaveEndDate,
    this.todayLeaveReason,
    required this.canMobileCheckIn,
    required this.canOnsiteCheckIn,
    this.attendance,
    required this.hasMorningReport,
    required this.hasEveningReport,
    this.dailyReportStatus,
    this.morningSubmittedAt,
    this.eveningSubmittedAt,
    required this.officeName,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.officeRadiusMeters,
  });

  factory AttendanceTodayData.fromJson(Map<String, dynamic> json) {
    final rawReport = json['daily_report'];
    final report = rawReport is Map ? Map<String, dynamic>.from(rawReport) : <String, dynamic>{};
    final rawOffice = json['office'];
    final office = rawOffice is Map ? Map<String, dynamic>.from(rawOffice) : <String, dynamic>{};
    final rawAtt = json['attendance'];
    final att = rawAtt is Map ? Map<String, dynamic>.from(rawAtt) : null;
    final rawLeaveDetail = json['today_leave_detail'];
    final leaveDetail =
        rawLeaveDetail is Map ? Map<String, dynamic>.from(rawLeaveDetail) : <String, dynamic>{};
    final hasCheckedIn = json['has_checked_in'] == true;
    final hasApprovedWfa = json['has_approved_wfa_today'] == true;
    final hasApprovedTugasLuar = json['has_approved_tugas_luar_today'] == true;

    return AttendanceTodayData(
      date: json['date']?.toString() ?? '',
      hasCheckedIn: hasCheckedIn,
      hasCheckedOut: json['has_checked_out'] == true,
      canCheckout: json['can_checkout'] == true,
      checkoutMode: json['checkout_mode']?.toString(),
      hasApprovedWfaToday: hasApprovedWfa,
      wfaRequestTodayStatus: json['wfa_request_today_status']?.toString(),
      hasApprovedTugasLuarToday: hasApprovedTugasLuar,
      tugasLuarRequestTodayStatus: json['tugas_luar_request_today_status']?.toString(),
      isOnLeaveToday: json['is_on_leave_today'] == true,
      todayLeaveStatus: json['today_leave_status']?.toString(),
      todayLeaveStartDate: leaveDetail['start_date']?.toString(),
      todayLeaveEndDate: leaveDetail['end_date']?.toString(),
      todayLeaveReason: leaveDetail['reason']?.toString(),
      canMobileCheckIn: json['can_mobile_checkin'] == true,
      canOnsiteCheckIn: json['can_onsite_checkin'] == true,
      attendance: att != null ? AttendanceRecord.fromJson(att) : null,
      hasMorningReport: report['has_morning_report'] == true,
      hasEveningReport: report['has_evening_report'] == true,
      dailyReportStatus: report['status']?.toString(),
      morningSubmittedAt: report['morning_submitted_at']?.toString(),
      eveningSubmittedAt: report['evening_submitted_at']?.toString(),
      officeName: office['name']?.toString() ?? 'Kantor PT Makerindo Prima Solusi',
      officeLatitude: _toDouble(office['latitude']),
      officeLongitude: _toDouble(office['longitude']),
      officeRadiusMeters: _toInt(office['radius']) > 0 ? _toInt(office['radius']) : 100,
    );
  }
}

class AttendanceHistoryData {
  final int month;
  final int year;
  final int totalRecords;
  final int hadirOnSite;
  final int wfa;
  final int tugasLuar;
  final int cuti;
  final int sakit;
  final int izin;
  final int alpha;
  final int lateCount;
  final int totalOvertimeHours;
  final List<AttendanceRecord> records;

  const AttendanceHistoryData({
    required this.month,
    required this.year,
    required this.totalRecords,
    required this.hadirOnSite,
    required this.wfa,
    required this.tugasLuar,
    required this.cuti,
    required this.sakit,
    required this.izin,
    required this.alpha,
    required this.lateCount,
    required this.totalOvertimeHours,
    required this.records,
  });

  factory AttendanceHistoryData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return AttendanceHistoryData(
      month: _toInt(summary['month']),
      year: _toInt(summary['year']),
      totalRecords: _toInt(summary['total_records']),
      hadirOnSite: _toInt(summary['hadir_on_site']),
      wfa: _toInt(summary['wfa']),
      tugasLuar: _toInt(summary['tugas_luar']),
      cuti: _toInt(summary['cuti']),
      sakit: _toInt(summary['sakit']),
      izin: _toInt(summary['izin']),
      alpha: _toInt(summary['alpha']),
      lateCount: _toInt(summary['late_count']),
      totalOvertimeHours: _toInt(summary['total_overtime_hours']),
      records: list,
    );
  }
}

class DailyReportModel {
  final String id;
  final String date;
  final String? morningSubmittedAt;
  final String morningPlannedTasks;
  final String? eveningSubmittedAt;
  final String? eveningCompletedTasks;
  final String? eveningPendingTasks;
  final String? eveningAdditionalTasks;
  final String status; // MORNING_ONLY, COMPLETED

  const DailyReportModel({
    required this.id,
    required this.date,
    this.morningSubmittedAt,
    required this.morningPlannedTasks,
    this.eveningSubmittedAt,
    this.eveningCompletedTasks,
    this.eveningPendingTasks,
    this.eveningAdditionalTasks,
    required this.status,
  });

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString() ?? '';
    return DailyReportModel(
      id: json['id']?.toString() ?? '',
      date: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      morningSubmittedAt: json['morning_submitted_at']?.toString(),
      morningPlannedTasks: json['morning_planned_tasks']?.toString() ?? '',
      eveningSubmittedAt: json['evening_submitted_at']?.toString(),
      eveningCompletedTasks: json['evening_completed_tasks']?.toString(),
      eveningPendingTasks: json['evening_pending_tasks']?.toString(),
      eveningAdditionalTasks: json['evening_additional_tasks']?.toString(),
      status: json['status']?.toString() ?? 'MORNING_ONLY',
    );
  }
}

class DailyReportTodayData {
  final String date;
  final bool hasSubmittedMorning;
  final bool isCompleted;
  final List<String> morningTasksList;
  final DailyReportModel? report;

  const DailyReportTodayData({
    required this.date,
    required this.hasSubmittedMorning,
    required this.isCompleted,
    required this.morningTasksList,
    this.report,
  });

  factory DailyReportTodayData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final tasks = (json['morning_tasks_list'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return DailyReportTodayData(
      date: json['date']?.toString() ?? '',
      hasSubmittedMorning: json['has_submitted_morning'] == true,
      isCompleted: json['is_completed'] == true,
      morningTasksList: tasks,
      report: data != null ? DailyReportModel.fromJson(data) : null,
    );
  }
}

class LeaveRequestModel {
  final String id;
  final String userId;
  final String? requesterName;
  final String? requesterEmail;
  final String? requesterEmploymentType;
  final String type; // SAKIT, IZIN, WFA, CUTI, TUGAS_LUAR
  final String startDate;
  final String endDate;
  final String reason;
  final String? attachmentPath;
  final String? attachmentUrl;
  final String status; // PENDING, APPROVED, REJECTED
  final String? approverName;
  final String? rejectionReason;

  const LeaveRequestModel({
    required this.id,
    required this.userId,
    this.requesterName,
    this.requesterEmail,
    this.requesterEmploymentType,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.attachmentPath,
    this.attachmentUrl,
    required this.status,
    this.approverName,
    this.rejectionReason,
  });

  String get displayType {
    switch (type.toUpperCase()) {
      case 'WFA':
      case 'WFH':
        return 'WFA';
      case 'TUGAS_LUAR':
        return 'Tugas Luar';
      case 'CUTI':
        return 'Cuti';
      case 'SAKIT':
        return 'Sakit';
      case 'IZIN':
        return 'Izin';
      default:
        return type;
    }
  }

  String get displayStatus {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      case 'PENDING':
        return 'Menunggu';
      default:
        return status;
    }
  }

  String? get displayRequesterEmploymentType {
    final raw = requesterEmploymentType;
    if (raw == null || raw.isEmpty) return null;
    return raw.toUpperCase() == 'INTERN' ? 'MAGANG' : raw;
  }

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] as Map<String, dynamic>?;
    final approverObj = json['approver'] as Map<String, dynamic>?;

    return LeaveRequestModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      requesterName: userObj?['name']?.toString(),
      requesterEmail: userObj?['email']?.toString(),
      requesterEmploymentType: userObj?['employment_type']?.toString(),
      type: json['type']?.toString() ?? 'IZIN',
      startDate: _cleanDate(json['start_date']),
      endDate: _cleanDate(json['end_date']),
      reason: json['reason']?.toString() ?? '',
      attachmentPath: json['attachment_path']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      approverName: approverObj?['name']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

class SanctionModel {
  final String id;
  final int month;
  final int year;
  final String incidentDate;
  final String violationName;
  final String level;
  final String levelLabel;
  final String? reason;
  final String status;

  const SanctionModel({
    required this.id,
    required this.month,
    required this.year,
    required this.incidentDate,
    required this.violationName,
    required this.level,
    required this.levelLabel,
    this.reason,
    required this.status,
  });

  String get displayStatus {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Aktif';
      case 'RESOLVED':
        return 'Selesai';
      case 'REVOKED':
        return 'Dicabut';
      default:
        return status;
    }
  }

  factory SanctionModel.fromJson(Map<String, dynamic> json) {
    return SanctionModel(
      id: json['id']?.toString() ?? '',
      month: _toInt(json['month']),
      year: _toInt(json['year']),
      incidentDate: _cleanDate(json['incident_date']),
      violationName: json['violation_name']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      levelLabel: json['level_label']?.toString() ?? '',
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _cleanDate(dynamic value) {
  final raw = value?.toString() ?? '';
  return raw.length >= 10 ? raw.substring(0, 10) : raw;
}
