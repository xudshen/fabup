// test/commands/use_command_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/commands/use_command.dart';
import 'package:fabup/src/config/fab_home.dart';
import 'package:fabup/src/config/fabrc.dart';

void main() {
  late Directory tempDir;
  late FabHome home;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fabup_use_test_');
    home = FabHome(root: tempDir.path);
    home.ensureStructure();
    Directory(home.versionDir('1.2.0')).createSync(recursive: true);
    File(home.darticCliBin('1.2.0')).writeAsStringSync('');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('useVersion', () {
    test('project-level writes .fabrc', () {
      final projectDir = Directory('${tempDir.path}/project')..createSync();
      useVersion(home: home, version: '1.2.0', projectDir: projectDir.path, global: false);
      expect(Fabrc.read(projectDir.path), '1.2.0');
    });

    test('global sets current symlink', () {
      useVersion(home: home, version: '1.2.0', projectDir: tempDir.path, global: true);
      expect(home.globalVersion(), '1.2.0');
    });

    test('throws if version not installed', () {
      expect(
        () => useVersion(home: home, version: '9.9.9', projectDir: tempDir.path, global: false),
        throwsA(isA<StateError>()),
      );
    });
  });
}
