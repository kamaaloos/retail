/// App identity + public update channel (keep in sync with pubspec.yaml).
abstract final class AppInfo {
  static const String name = 'MayleSoft retail';
  static const String version = '0.1.1';
  static const int build = 2;

  /// Manifest hosted next to the Windows installer.
  static const String updateManifestUrl = 'https://retail.maylesoft.com/latest.json';

  /// Online license activation (code + machineId → signed .lic).
  static const String licenseActivateUrl = 'https://retail.maylesoft.com/api/activate';

  static String get versionLabel => 'v$version+$build';
}
