// lib/src/shim/command_router.dart
class CommandRouter {
  static const _managementCommands = {
    'install',
    'use',
    'list',
    'remove',
    'upgrade',
    '--version',
    '--help',
    '-h',
  };

  /// Returns true if the first argument is a management command (handled by fabup).
  /// Returns true for null (no args -> show help).
  static bool isManagementCommand(String? firstArg) {
    if (firstArg == null) return true;
    return _managementCommands.contains(firstArg);
  }

  /// Returns true if the first argument is 'dartic' (forwarded to dartic-cli).
  static bool isDarticCommand(String? firstArg) {
    return firstArg == 'dartic';
  }
}
