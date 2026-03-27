// lib/src/config/fabrc_local.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Manages `.fabrc.local` — machine-specific SDK bindings (gitignored).
///
/// Written by `fab use`, read during command forwarding to inject
/// `--flutter-sdk` into forwarded commands.
class FabrcLocal {
  /// Read `.fabrc.local` in [dir], return the flutter_sdk path or null.
  static String? readFlutterSdk(String dir) {
    final file = File(p.join(dir, '.fabrc.local'));
    if (!file.existsSync()) return null;
    try {
      final json =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return json['flutter_sdk'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Write `.fabrc.local` in [dir] with the Flutter SDK path.
  static void write(String dir, {required String flutterSdk}) {
    final file = File(p.join(dir, '.fabrc.local'));
    final json = const JsonEncoder.withIndent('  ')
        .convert({'flutter_sdk': flutterSdk});
    file.writeAsStringSync('$json\n');
  }

  /// Walk up from [startDir] looking for `.fabrc.local`, return flutter_sdk or null.
  static String? findFlutterSdk(String startDir) {
    var dir = p.normalize(p.absolute(startDir));
    while (true) {
      final sdk = readFlutterSdk(dir);
      if (sdk != null) return sdk;
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
    return null;
  }
}
