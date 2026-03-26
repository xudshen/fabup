// test/config/fab_home_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/config/fab_home.dart';

void main() {
  late Directory tempDir;
  late FabHome home;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fabup_test_');
    home = FabHome(root: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('FabHome', () {
    test('paths are correct', () {
      expect(home.binDir, '${tempDir.path}/bin');
      expect(home.versionsDir, '${tempDir.path}/versions');
      expect(home.currentLink, '${tempDir.path}/current');
    });

    test('versionDir returns correct path', () {
      expect(home.versionDir('1.2.0'), '${tempDir.path}/versions/1.2.0');
    });

    test('fabCliBin returns path inside version dir', () {
      expect(home.fabCliBin('1.2.0'), '${tempDir.path}/versions/1.2.0/fab-cli');
    });

    test('darticCliBin returns path inside version dir', () {
      expect(home.darticCliBin('1.2.0'), '${tempDir.path}/versions/1.2.0/dartic-cli');
    });

    test('manifestPath returns path inside version dir', () {
      expect(home.manifestPath('1.2.0'), '${tempDir.path}/versions/1.2.0/manifest.json');
    });

    test('ensureStructure creates directories', () {
      home.ensureStructure();
      expect(Directory(home.binDir).existsSync(), isTrue);
      expect(Directory(home.versionsDir).existsSync(), isTrue);
    });

    test('installedVersions returns empty list when no versions', () {
      home.ensureStructure();
      expect(home.installedVersions(), isEmpty);
    });

    test('installedVersions lists version directories', () {
      home.ensureStructure();
      Directory('${home.versionDir('1.0.0')}').createSync(recursive: true);
      Directory('${home.versionDir('1.2.0')}').createSync(recursive: true);
      final versions = home.installedVersions();
      expect(versions, unorderedEquals(['1.0.0', '1.2.0']));
    });

    test('isInstalled returns true/false', () {
      home.ensureStructure();
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      expect(home.isInstalled('1.0.0'), isTrue);
      expect(home.isInstalled('2.0.0'), isFalse);
    });

    test('globalVersion returns null when no current link', () {
      home.ensureStructure();
      expect(home.globalVersion(), isNull);
    });

    test('setGlobalVersion creates current symlink', () {
      home.ensureStructure();
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      home.setGlobalVersion('1.0.0');
      expect(home.globalVersion(), '1.0.0');
      expect(Link(home.currentLink).existsSync(), isTrue);
    });

    test('setGlobalVersion replaces existing symlink', () {
      home.ensureStructure();
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      Directory(home.versionDir('1.2.0')).createSync(recursive: true);
      home.setGlobalVersion('1.0.0');
      home.setGlobalVersion('1.2.0');
      expect(home.globalVersion(), '1.2.0');
    });

    test('removeVersion deletes version directory', () {
      home.ensureStructure();
      Directory(home.versionDir('1.0.0')).createSync(recursive: true);
      home.removeVersion('1.0.0');
      expect(home.isInstalled('1.0.0'), isFalse);
    });
  });
}
