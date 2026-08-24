import 'package:flutter_test/flutter_test.dart';
import 'package:retail_manager/services/app_update.dart';

void main() {
  group('AppUpdateService.compareSemver', () {
    test('orders major.minor.patch', () {
      expect(AppUpdateService.compareSemver('0.1.0', '0.2.0'), lessThan(0));
      expect(AppUpdateService.compareSemver('1.0.0', '0.9.9'), greaterThan(0));
      expect(AppUpdateService.compareSemver('1.2.3', '1.2.3'), 0);
    });
  });

  group('AppUpdateService.isNewerThanLocal', () {
    test('build number wins', () {
      const remote = AppReleaseInfo(
        version: '0.1.0',
        build: 2,
        downloadUrl: 'https://example.com/a.exe',
      );
      expect(AppUpdateService.isNewerThanLocal(remote, localVersion: '0.1.0', localBuild: 1), isTrue);
      expect(AppUpdateService.isNewerThanLocal(remote, localVersion: '0.1.0', localBuild: 2), isFalse);
    });

    test('same build compares version', () {
      const remote = AppReleaseInfo(
        version: '0.2.0',
        build: 1,
        downloadUrl: 'https://example.com/a.exe',
      );
      expect(AppUpdateService.isNewerThanLocal(remote, localVersion: '0.1.0', localBuild: 1), isTrue);
      expect(AppUpdateService.isNewerThanLocal(remote, localVersion: '0.2.0', localBuild: 1), isFalse);
    });
  });

  group('AppReleaseInfo.fromJson', () {
    test('parses build as int or string', () {
      final a = AppReleaseInfo.fromJson({
        'version': '1.0.0',
        'build': 3,
        'downloadUrl': 'https://example.com/x.exe',
      });
      expect(a.build, 3);
      final b = AppReleaseInfo.fromJson({
        'version': '1.0.0',
        'build': '4',
        'downloadUrl': 'https://example.com/x.exe',
      });
      expect(b.build, 4);
    });
  });
}
