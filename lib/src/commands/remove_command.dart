// lib/src/commands/remove_command.dart
import 'dart:io';
import 'package:fabup/src/config/fab_home.dart';

void removeInstalledVersion({
  required FabHome home,
  required String version,
}) {
  if (!home.isInstalled(version)) {
    throw StateError('Version $version is not installed.');
  }
  if (home.globalVersion() == version) {
    throw StateError(
      'Cannot remove $version — it is the current global version.\n'
      'Run: fab use <other-version> --global first.',
    );
  }
  home.removeVersion(version);
  stderr.writeln('Removed $version.');
}
