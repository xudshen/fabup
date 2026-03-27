// lib/src/commands/use_command.dart
import 'dart:convert';
import 'dart:io';
import 'package:fabup/src/config/fab_home.dart';
import 'package:fabup/src/config/fabrc.dart';
import 'package:fabup/src/config/fabrc_local.dart';
import 'package:fabup/src/sdk/flutter_sdk_discovery.dart';

void useVersion({
  required FabHome home,
  required String version,
  required String projectDir,
  required bool global,
}) {
  if (!home.isInstalled(version)) {
    throw StateError('Version $version is not installed. Run: fab install $version');
  }

  if (global) {
    home.setGlobalVersion(version);
    stderr.writeln('Using $version as global default.');
  } else {
    Fabrc.write(projectDir, version);
    stderr.writeln('Using $version in this project (.fabrc written).');
  }

  // Discover Flutter SDK and write .fabrc.local.
  _resolveAndWriteFlutterSdk(home, version, projectDir);
}

/// Read the manifest to get requiredFlutterSdk, discover a matching
/// Flutter SDK, and write the path to .fabrc.local.
void _resolveAndWriteFlutterSdk(
  FabHome home,
  String version,
  String projectDir,
) {
  final manifestFile = File(home.manifestPath(version));
  if (!manifestFile.existsSync()) return;

  String? constraint;
  try {
    final json =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    constraint = json['required_flutter_sdk'] as String?;
  } catch (_) {
    return;
  }

  final flutterSdk = FlutterSdkDiscovery.discover(constraint: constraint);
  if (flutterSdk == null) {
    stderr.writeln('');
    stderr.writeln('⚠ Could not find Flutter SDK'
        '${constraint != null ? ' satisfying $constraint' : ''}.');
    stderr.writeln('  Commands may fall back to PATH or fail.');
    stderr.writeln('  To fix: fvm install <version> && fvm use <version>');
    return;
  }

  final flutterVersion = FlutterSdkDiscovery.readVersion(flutterSdk) ?? '?';
  FabrcLocal.write(projectDir, flutterSdk: flutterSdk);
  stderr.writeln('Flutter SDK $flutterVersion ($flutterSdk)');
  stderr.writeln('.fabrc.local written.');
}
