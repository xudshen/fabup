// lib/src/commands/list_command.dart
import 'package:fabup/src/config/fab_home.dart';
import 'package:pub_semver/pub_semver.dart';

/// Format installed versions for display.
String formatLocalVersions({
  required FabHome home,
  required String? projectVersion,
}) {
  final versions = home.installedVersions();
  if (versions.isEmpty) return '';

  // Sort by semver, newest first
  versions.sort((a, b) {
    try {
      return Version.parse(b).compareTo(Version.parse(a));
    } catch (_) {
      return b.compareTo(a);
    }
  });

  final global = home.globalVersion();
  final buf = StringBuffer();

  for (final v in versions) {
    final isProject = v == projectVersion;
    final isGlobal = v == global;
    final prefix = isProject ? '* ' : '  ';
    final suffix = isGlobal ? ' (global)' : '';
    buf.writeln('$prefix$v$suffix');
  }

  return buf.toString();
}

/// Format remote versions for display.
String formatRemoteVersions(List<String> tags) {
  final buf = StringBuffer();
  for (final tag in tags) {
    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    final preRelease = tag.contains('-');
    final suffix = preRelease ? '  (pre-release)' : '';
    buf.writeln('  $version$suffix');
  }
  return buf.toString();
}
