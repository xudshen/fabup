// lib/src/commands/install_command.dart
import 'dart:convert';
import 'dart:io';
import 'package:fabup/src/config/fab_home.dart';
import 'package:fabup/src/download/github_release.dart';
import 'package:fabup/src/download/manifest.dart';

/// Core install logic, separated from CLI arg parsing for testability.
Future<void> installVersion({
  required FabHome home,
  required String version,
  required GithubReleaseClient fabClient,
  required GithubReleaseClient darticClient,
  required String platformSuffix,
}) async {
  if (home.isInstalled(version)) {
    stderr.writeln('Version $version is already installed.');
    return;
  }

  final tag = 'v$version';

  // 1. Download manifest
  stderr.writeln('Downloading manifest for $version...');
  final manifestUrl = await fabClient.getAssetUrl(tag, 'manifest.json');
  if (manifestUrl == null) {
    throw Exception('manifest.json not found in release $tag');
  }
  final manifestBytes = await fabClient.downloadBytes(manifestUrl);
  final manifest = Manifest.fromJson(
    jsonDecode(String.fromCharCodes(manifestBytes)) as Map<String, dynamic>,
  );

  // 2. Download binaries in parallel
  final fabAssetName = 'fab-cli-$platformSuffix';
  final darticAssetName = 'dartic-cli-$platformSuffix';
  final darticTag = 'v${manifest.darticCliVersion}';

  stderr.writeln('Downloading fab-cli $version and dartic-cli ${manifest.darticCliVersion}...');

  final fabUrlFuture = fabClient.getAssetUrl(tag, fabAssetName);
  final darticUrlFuture = darticClient.getAssetUrl(darticTag, darticAssetName);
  final results = await Future.wait([fabUrlFuture, darticUrlFuture]);

  final fabUrl = results[0];
  final darticUrl = results[1];
  if (fabUrl == null) throw Exception('$fabAssetName not found in release $tag');
  if (darticUrl == null) throw Exception('$darticAssetName not found in release $darticTag');

  final downloads = await Future.wait([
    fabClient.downloadBytes(fabUrl),
    darticClient.downloadBytes(darticUrl),
  ]);

  // 3. Write to disk
  final versionDir = Directory(home.versionDir(version));
  versionDir.createSync(recursive: true);

  final fabCliFile = File(home.fabCliBin(version));
  fabCliFile.writeAsBytesSync(downloads[0]);
  Process.runSync('chmod', ['+x', fabCliFile.path]);

  final darticCliFile = File(home.darticCliBin(version));
  darticCliFile.writeAsBytesSync(downloads[1]);
  Process.runSync('chmod', ['+x', darticCliFile.path]);

  File(home.manifestPath(version)).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );

  stderr.writeln('Installed $version.');

  // 4. Auto-set global if first install
  if (home.globalVersion() == null) {
    home.setGlobalVersion(version);
    stderr.writeln('Set $version as global default.');
  }
}
