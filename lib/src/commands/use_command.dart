// lib/src/commands/use_command.dart
import 'dart:io';
import 'package:fabup/src/config/fab_home.dart';
import 'package:fabup/src/config/fabrc.dart';

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
}
