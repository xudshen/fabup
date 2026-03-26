// test/download/platform_test.dart
import 'package:test/test.dart';
import 'package:fabup/src/download/platform.dart';

void main() {
  group('HostPlatform', () {
    test('assetSuffix returns darwin-arm64 or linux-x64', () {
      // We can only test the current platform
      final p = HostPlatform.current();
      expect(p.assetSuffix, matches(RegExp(r'^(darwin-arm64|linux-x64)$')));
    });

    test('fromComponents constructs correctly', () {
      final p = HostPlatform(os: 'darwin', arch: 'arm64');
      expect(p.assetSuffix, 'darwin-arm64');
    });

    test('fromComponents linux x64', () {
      final p = HostPlatform(os: 'linux', arch: 'x64');
      expect(p.assetSuffix, 'linux-x64');
    });

    test('unsupported arch throws', () {
      expect(
        () => HostPlatform(os: 'darwin', arch: 'x86'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('unsupported os throws', () {
      expect(
        () => HostPlatform(os: 'windows', arch: 'x64'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
