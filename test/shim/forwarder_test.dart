// test/shim/forwarder_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/shim/forwarder.dart';
import 'package:fabup/src/config/fab_home.dart';

void main() {
  late Directory tempDir;
  late FabHome home;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fabup_forwarder_test_');
    home = FabHome(root: tempDir.path);
    home.ensureStructure();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('Forwarder', () {
    test('resolveBinary returns fab-cli path for non-dartic', () {
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      File(home.fabCliBin('1.0.0')).writeAsStringSync('');
      final path = Forwarder.resolveBinary(home, '1.0.0', isDartic: false);
      expect(path, home.fabCliBin('1.0.0'));
    });

    test('resolveBinary returns dartic-cli path for dartic', () {
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      File(home.darticCliBin('1.0.0')).writeAsStringSync('');
      final path = Forwarder.resolveBinary(home, '1.0.0', isDartic: true);
      expect(path, home.darticCliBin('1.0.0'));
    });

    test('resolveBinary throws when version not installed', () {
      expect(
        () => Forwarder.resolveBinary(home, '9.9.9', isDartic: false),
        throwsA(isA<StateError>()),
      );
    });
  });
}
