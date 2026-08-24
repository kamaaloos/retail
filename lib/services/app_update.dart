import 'dart:convert';
import 'dart:io';

import '../app_info.dart';

/// Remote release metadata from `latest.json`.
class AppReleaseInfo {
  final String version;
  final int build;
  final String downloadUrl;
  final String? notes;
  final String? releaseDate;
  final String? sha256;

  const AppReleaseInfo({
    required this.version,
    required this.build,
    required this.downloadUrl,
    this.notes,
    this.releaseDate,
    this.sha256,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as String?)?.trim() ?? '';
    final buildRaw = json['build'];
    final build = buildRaw is int
        ? buildRaw
        : int.tryParse('$buildRaw') ?? 0;
    final downloadUrl = (json['downloadUrl'] as String?)?.trim() ?? '';
    if (version.isEmpty || downloadUrl.isEmpty) {
      throw const FormatException('latest.json is missing version or downloadUrl');
    }
    return AppReleaseInfo(
      version: version,
      build: build,
      downloadUrl: downloadUrl,
      notes: json['notes'] as String?,
      releaseDate: (json['releaseDate'] ?? json['releasedAt']) as String?,
      sha256: json['sha256'] as String?,
    );
  }
}

enum UpdateCheckStatus { upToDate, updateAvailable, unreachable }

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final AppReleaseInfo? remote;
  final String? error;

  const UpdateCheckResult._(this.status, {this.remote, this.error});

  factory UpdateCheckResult.upToDate(AppReleaseInfo remote) =>
      UpdateCheckResult._(UpdateCheckStatus.upToDate, remote: remote);

  factory UpdateCheckResult.available(AppReleaseInfo remote) =>
      UpdateCheckResult._(UpdateCheckStatus.updateAvailable, remote: remote);

  factory UpdateCheckResult.failed(String error) =>
      UpdateCheckResult._(UpdateCheckStatus.unreachable, error: error);
}

/// Compare and fetch updates from the public manifest.
abstract final class AppUpdateService {
  static const Duration _timeout = Duration(seconds: 12);

  /// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  static int compareSemver(String a, String b) {
    List<int> parts(String v) {
      final core = v.split('+').first.split('-').first;
      return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    }

    final pa = parts(a);
    final pb = parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static bool isNewerThanLocal(
    AppReleaseInfo remote, {
    String localVersion = AppInfo.version,
    int localBuild = AppInfo.build,
  }) {
    if (remote.build != localBuild) return remote.build > localBuild;
    return compareSemver(remote.version, localVersion) > 0;
  }

  static Future<UpdateCheckResult> check({
    String manifestUrl = AppInfo.updateManifestUrl,
    String localVersion = AppInfo.version,
    int localBuild = AppInfo.build,
  }) async {
    try {
      final remote = await fetchManifest(manifestUrl);
      if (isNewerThanLocal(remote, localVersion: localVersion, localBuild: localBuild)) {
        return UpdateCheckResult.available(remote);
      }
      return UpdateCheckResult.upToDate(remote);
    } catch (e) {
      return UpdateCheckResult.failed(e.toString());
    }
  }

  static Future<AppReleaseInfo> fetchManifest(String url) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final body = await response.transform(utf8.decoder).join().timeout(_timeout);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('latest.json root must be an object');
      }
      return AppReleaseInfo.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> openDownload(String url) async {
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url], runInShell: false);
      return;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [url]);
      return;
    }
    await Process.start('xdg-open', [url]);
  }
}
