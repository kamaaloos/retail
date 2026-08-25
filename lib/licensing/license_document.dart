import 'dart:convert';

/// Parsed contents of a MayleSoft offline license.
class LicenseDocument {
  final int version;
  final String customer;
  final String? email;
  final String issued;
  final String? expires;
  final String? machineId;
  final String? notes;

  const LicenseDocument({
    required this.version,
    required this.customer,
    required this.issued,
    this.email,
    this.expires,
    this.machineId,
    this.notes,
  });

  factory LicenseDocument.fromJson(Map<String, dynamic> json) {
    return LicenseDocument(
      version: json['v'] as int? ?? 1,
      customer: (json['customer'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim(),
      issued: (json['issued'] as String?)?.trim() ?? '',
      expires: (json['expires'] as String?)?.trim(),
      machineId: (json['machineId'] as String?)?.trim(),
      notes: (json['notes'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'v': version,
        'customer': customer,
        if (email != null && email!.isNotEmpty) 'email': email,
        'issued': issued,
        if (expires != null && expires!.isNotEmpty) 'expires': expires,
        if (machineId != null && machineId!.isNotEmpty) 'machineId': machineId,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  /// Canonical bytes used for signing / verifying (stable key order).
  List<int> canonicalBytes() {
    final map = <String, dynamic>{
      'v': version,
      'customer': customer,
      if (email != null && email!.isNotEmpty) 'email': email,
      'issued': issued,
      if (expires != null && expires!.isNotEmpty) 'expires': expires,
      if (machineId != null && machineId!.isNotEmpty) 'machineId': machineId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
    return utf8.encode(jsonEncode(map));
  }

  DateTime? get expiresAt {
    final raw = expires;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool isExpiredOn(DateTime when) {
    final end = expiresAt;
    if (end == null) return false;
    final day = DateTime(when.year, when.month, when.day);
    final last = DateTime(end.year, end.month, end.day);
    return day.isAfter(last);
  }
}

enum LicenseAccessKind { licensed, trial, blocked }

class LicenseStatus {
  final LicenseAccessKind kind;
  final LicenseDocument? document;
  final DateTime? trialEndsAt;
  final int? trialDaysLeft;
  final String? message;

  const LicenseStatus({
    required this.kind,
    this.document,
    this.trialEndsAt,
    this.trialDaysLeft,
    this.message,
  });

  bool get allowsUse => kind == LicenseAccessKind.licensed || kind == LicenseAccessKind.trial;
  bool get isLicensed => kind == LicenseAccessKind.licensed;
  bool get isTrial => kind == LicenseAccessKind.trial;
  bool get isBlocked => kind == LicenseAccessKind.blocked;
}
