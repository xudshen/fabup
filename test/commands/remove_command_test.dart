// test/commands/remove_command_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/commands/remove_command.dart';
import 'package:fabup/src/config/fab_home.dart';

void main() {
  late Directory tempDir;
  late FabHome home;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fabup_remove_test_');
    home = FabHome(root: tempDir.path);
    home.ensureStructure();
    Directory(home.versionDir('1.0.0')).createSync(recursive: true);
    Directory(home.versionDir('1.2.0')).createSync(recursive: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('removeVersion', () {
    test('removes installed version', () {
      removeInstalledVersion(home: home, version: '1.0.0');
      expect(home.isInstalled('1.0.0'), isFalse);
      expect(home.isInstalled('1.2.0'), isTrue);
    });

    test('refuses to remove global version', () {
      home.setGlobalVersion('1.0.0');
      expect(
        () => removeInstalledVersion(home: home, version: '1.0.0'),
        throwsA(isA<StateError>()),
      );
      expect(home.isInstalled('1.0.0'), isTrue);
    });

    test('throws if version not installed', () {
      expect(
        () => removeInstalledVersion(home: home, version: '9.9.9'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
