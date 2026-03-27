// lib/src/sdk/flutter_sdk_discovery.dart
import 'dart:io';

/// Lightweight Flutter SDK discovery for fabup.
///
/// Discovers Flutter SDK from FVM config or environment, validates
/// the version against a caret constraint, and returns the SDK path.
/// This is a standalone implementation — fabup doesn't depend on
/// dartic_compiler or fab_cli.
class FlutterSdkDiscovery {
  /// Discover a Flutter SDK that satisfies [constraint] (e.g. `^3.38.0`).
  ///
  /// Returns the SDK path, or null if none found.
  /// Discovery chain: FAB_FLUTTER_SDK env → .fvmrc → .fvm/fvm_config.json
  /// → .flutter-version → which flutter.
  static String? discover({String? constraint}) {
    // 1. FAB_FLUTTER_SDK environment variable
    final fabEnv = Platform.environment['FAB_FLUTTER_SDK'];
    if (fabEnv != null && Directory(fabEnv).existsSync()) {
      if (constraint == null || _validateVersion(fabEnv, constraint)) {
        return fabEnv;
      }
    }

    // 2-4: FVM config files → version string → FVM cache
    for (final version in [
      _findFvmrcVersion(),
      _findFvm2Version(),
      _findFlutterVersionFile(),
    ]) {
      if (version == null) continue;
      if (constraint != null && !_satisfiesCaret(version, constraint)) {
        continue;
      }
      final path = _fvmCachePath(version);
      if (path != null) return path;
    }

    // 5. which flutter → resolve symlinks → two levels up
    try {
      final result = Process.runSync('which', ['flutter']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty) {
          final resolved = File(path).resolveSymbolicLinksSync();
          final sdkPath = File(resolved).parent.parent.path;
          if (Directory(sdkPath).existsSync()) {
            if (constraint == null || _validateVersion(sdkPath, constraint)) {
              return sdkPath;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Read Flutter version from `flutter --version` output at [sdkPath].
  static String? readVersion(String sdkPath) {
    // Flutter SDK embeds Dart SDK; the Flutter version is in the
    // FVM cache directory name. Try to extract from path first.
    final match = RegExp(r'versions[/\\](\d+\.\d+\.\d+)').firstMatch(sdkPath);
    if (match != null) return match.group(1);

    // Fallback: run flutter --version (slow).
    try {
      final bin = '$sdkPath/bin/flutter';
      final result = Process.runSync(bin, ['--version', '--machine'],
          stdoutEncoding: const SystemEncoding());
      if (result.exitCode == 0) {
        final vMatch = RegExp(r'"frameworkVersion"\s*:\s*"([^"]+)"')
            .firstMatch(result.stdout as String);
        if (vMatch != null) return vMatch.group(1);
      }
    } catch (_) {}
    return null;
  }

  static bool _validateVersion(String sdkPath, String constraint) {
    final version = readVersion(sdkPath);
    if (version == null) return false;
    return _satisfiesCaret(version, constraint);
  }

  /// Simple caret constraint check: ^X.Y.Z means >= X.Y.Z and < (X+1).0.0
  static bool _satisfiesCaret(String version, String constraint) {
    if (!constraint.startsWith('^')) return false;
    final min = _parseVersion(constraint.substring(1));
    final act = _parseVersion(version);
    if (act[0] != min[0]) return false;
    if (act[1] > min[1]) return true;
    if (act[1] < min[1]) return false;
    return act[2] >= min[2];
  }

  static List<int> _parseVersion(String v) {
    var clean = v;
    final dash = clean.indexOf('-');
    if (dash != -1) clean = clean.substring(0, dash);
    final plus = clean.indexOf('+');
    if (plus != -1) clean = clean.substring(0, plus);
    final parts = clean.split('.');
    return [
      int.parse(parts[0]),
      if (parts.length > 1) int.parse(parts[1]) else 0,
      if (parts.length > 2) int.parse(parts[2]) else 0,
    ];
  }

  static String? _findFvmrcVersion() {
    var dir = Directory.current;
    while (true) {
      final f = File('${dir.path}/.fvmrc');
      if (f.existsSync()) {
        final m = RegExp(r'"flutter"\s*:\s*"([^"]+)"')
            .firstMatch(f.readAsStringSync());
        if (m != null) return m.group(1);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  static String? _findFvm2Version() {
    var dir = Directory.current;
    while (true) {
      final f = File('${dir.path}/.fvm/fvm_config.json');
      if (f.existsSync()) {
        final m = RegExp(r'"flutterSdkVersion"\s*:\s*"([^"]+)"')
            .firstMatch(f.readAsStringSync());
        if (m != null) return m.group(1);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  static String? _findFlutterVersionFile() {
    var dir = Directory.current;
    while (true) {
      final f = File('${dir.path}/.flutter-version');
      if (f.existsSync()) return f.readAsStringSync().trim();
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  static String? _fvmCachePath(String version) {
    final home = Platform.environment['HOME'] ?? '';
    final path = '$home/.fvm_cache/versions/$version';
    if (Directory(path).existsSync()) return path;
    final legacy = '$home/fvm/versions/$version';
    if (Directory(legacy).existsSync()) return legacy;
    return null;
  }
}
