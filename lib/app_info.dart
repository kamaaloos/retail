/// App identity + public update channel (keep in sync with pubspec.yaml).
abstract final class AppInfo {
  static const String name = 'MayleSoft retail';
  static const String version = '0.1.0';
  static const int build = 1;

  /// Manifest hosted next to the Windows installer.
  static const String updateManifestUrl = 'https://retail.maylesoft.com/latest.json';

  static String get versionLabel => 'v$version+$build';
}
