// lib/src/shim/forwarder.dart
import 'dart:io';
import 'package:fabup/src/config/fab_home.dart';

class Forwarder {
  /// Resolve the binary path for a given version.
  static String resolveBinary(FabHome home, String version, {required bool isDartic}) {
    if (!home.isInstalled(version)) {
      throw StateError('Version $version is not installed. Run: fab install $version');
    }
    return isDartic ? home.darticCliBin(version) : home.fabCliBin(version);
  }

  /// Forward execution to the resolved binary. Replaces current process on Unix.
  static Future<int> forward(String binary, List<String> args) async {
    final result = await Process.start(
      binary,
      args,
      mode: ProcessStartMode.inheritStdio,
    );
    return result.exitCode;
  }
}
