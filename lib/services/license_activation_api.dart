import 'dart:convert';
import 'dart:io';

import '../app_info.dart';

class LicenseActivationException implements Exception {
  final String message;
  final int? statusCode;

  const LicenseActivationException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Calls MayleSoft activate API: code + machineId → signed .lic JSON.
abstract final class LicenseActivationApi {
  static const Duration _timeout = Duration(seconds: 20);

  /// Returns raw license file bytes (JSON envelope).
  static Future<List<int>> activate({
    required String code,
    required String machineId,
    String? appVersion,
    String url = AppInfo.licenseActivateUrl,
  }) async {
    final trimmed = code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (trimmed.isEmpty) {
      throw const LicenseActivationException('Enter an activation code');
    }
    if (machineId.trim().isEmpty) {
      throw const LicenseActivationException('Machine ID is missing');
    }

    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse(url);
      final request = await client.postUrl(uri).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.add(utf8.encode(jsonEncode({
        'code': trimmed,
        'machineId': machineId.trim(),
        'appVersion': appVersion ?? AppInfo.versionLabel,
      })));
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join().timeout(_timeout);

      Map<String, dynamic>? map;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {}

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final err = map?['error'] as String? ??
            map?['message'] as String? ??
            'HTTP ${response.statusCode}';
        throw LicenseActivationException(err, statusCode: response.statusCode);
      }

      // Prefer nested "license" object, else whole body is the .lic envelope.
      final license = map?['license'];
      if (license is Map<String, dynamic>) {
        return utf8.encode(const JsonEncoder.withIndent('  ').convert(license));
      }
      if (map != null && map['payload'] is Map && map['sig'] is String) {
        return utf8.encode(const JsonEncoder.withIndent('  ').convert(map));
      }
      throw const LicenseActivationException('Server did not return a license');
    } on LicenseActivationException {
      rethrow;
    } on SocketException catch (e) {
      throw LicenseActivationException('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw LicenseActivationException('Network error: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }
}
