// lib/src/config/fabrc.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class Fabrc {
  /// Read .fabrc in [dir], return version or null.
  static String? read(String dir) {
    final file = File(p.join(dir, '.fabrc'));
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return json['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Write .fabrc in [dir] with the given version.
  static void write(String dir, String version) {
    final file = File(p.join(dir, '.fabrc'));
    final json = const JsonEncoder.withIndent('  ').convert({'version': version});
    file.writeAsStringSync('$json\n');
  }

  /// Walk up from [startDir] looking for .fabrc, return version or null.
  /// Stops at [stopAt] (exclusive) or filesystem root.
  static String? findVersion(String startDir, {String? stopAt}) {
    var dir = p.normalize(p.absolute(startDir));
    final stop = stopAt != null ? p.normalize(p.absolute(stopAt)) : null;

    while (true) {
      final version = read(dir);
      if (version != null) return version;

      final parent = p.dirname(dir);
      if (parent == dir) break; // reached root
      if (stop != null && dir == stop) break;
      dir = parent;
    }
    return null;
  }
}
