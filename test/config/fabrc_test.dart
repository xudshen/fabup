// test/config/fabrc_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/config/fabrc.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fabup_fabrc_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('Fabrc', () {
    test('read returns null when .fabrc does not exist', () {
      expect(Fabrc.read(tempDir.path), isNull);
    });

    test('read parses version from .fabrc', () {
      File('${tempDir.path}/.fabrc').writeAsStringSync('{"version": "1.2.0"}');
      expect(Fabrc.read(tempDir.path), '1.2.0');
    });

    test('write creates .fabrc with version', () {
      Fabrc.write(tempDir.path, '1.2.0');
      final content = File('${tempDir.path}/.fabrc').readAsStringSync();
      expect(content, contains('"version": "1.2.0"'));
    });

    test('findVersion walks up directories', () {
      final sub = Directory('${tempDir.path}/a/b/c')..createSync(recursive: true);
      File('${tempDir.path}/a/.fabrc').writeAsStringSync('{"version": "0.5.0"}');
      expect(Fabrc.findVersion(sub.path), '0.5.0');
    });

    test('findVersion returns null when no .fabrc found', () {
      final sub = Directory('${tempDir.path}/a/b/c')..createSync(recursive: true);
      expect(Fabrc.findVersion(sub.path, stopAt: tempDir.path), isNull);
    });
  });
}
