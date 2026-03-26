// test/commands/list_command_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/commands/list_command.dart';
import 'package:fabup/src/config/fab_home.dart';

void main() {
  late Directory tempDir;
  late FabHome home;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fabup_list_test_');
    home = FabHome(root: tempDir.path);
    home.ensureStructure();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('formatLocalVersions', () {
    test('empty when no versions installed', () {
      final output = formatLocalVersions(home: home, projectVersion: null);
      expect(output, isEmpty);
    });

    test('marks global version', () {
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      Directory(home.versionDir('1.2.0')).createSync(recursive: true);
      home.setGlobalVersion('1.2.0');
      final output = formatLocalVersions(home: home, projectVersion: null);
      expect(output, contains('1.2.0 (global)'));
      expect(output, contains('1.0.0'));
      expect(output.indexOf('1.2.0'), lessThan(output.indexOf('1.0.0')));
    });

    test('marks project version with *', () {
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      Directory(home.versionDir('1.2.0')).createSync(recursive: true);
      home.setGlobalVersion('1.0.0');
      final output = formatLocalVersions(home: home, projectVersion: '1.2.0');
      expect(output, contains('* 1.2.0'));
      expect(output, contains('1.0.0 (global)'));
    });
  });
}
