// lib/src/config/fab_home.dart
import 'dart:io';
import 'package:path/path.dart' as p;

class FabHome {
  final String root;

  FabHome({String? root})
      : root = root ?? p.join(Platform.environment['HOME']!, '.fab');

  String get binDir => p.join(root, 'bin');
  String get versionsDir => p.join(root, 'versions');
  String get currentLink => p.join(root, 'current');

  String versionDir(String version) => p.join(versionsDir, version);
  String fabCliBin(String version) => p.join(versionDir(version), 'fab-cli');
  String darticCliBin(String version) => p.join(versionDir(version), 'dartic-cli');
  String manifestPath(String version) => p.join(versionDir(version), 'manifest.json');

  void ensureStructure() {
    Directory(binDir).createSync(recursive: true);
    Directory(versionsDir).createSync(recursive: true);
  }

  List<String> installedVersions() {
    final dir = Directory(versionsDir);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList();
  }

  bool isInstalled(String version) {
    return Directory(versionDir(version)).existsSync();
  }

  String? globalVersion() {
    final link = Link(currentLink);
    if (!link.existsSync()) return null;
    final target = link.targetSync();
    return p.basename(target);
  }

  void setGlobalVersion(String version) {
    final link = Link(currentLink);
    if (link.existsSync()) link.deleteSync();
    link.createSync(versionDir(version));
  }

  void removeVersion(String version) {
    final dir = Directory(versionDir(version));
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
