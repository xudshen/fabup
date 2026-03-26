// test/shim/command_router_test.dart
import 'package:test/test.dart';
import 'package:fabup/src/shim/command_router.dart';

void main() {
  group('CommandRouter', () {
    test('management commands are recognized', () {
      expect(CommandRouter.isManagementCommand('install'), isTrue);
      expect(CommandRouter.isManagementCommand('use'), isTrue);
      expect(CommandRouter.isManagementCommand('list'), isTrue);
      expect(CommandRouter.isManagementCommand('remove'), isTrue);
      expect(CommandRouter.isManagementCommand('upgrade'), isTrue);
    });

    test('other commands are forwarded', () {
      expect(CommandRouter.isManagementCommand('compile'), isFalse);
      expect(CommandRouter.isManagementCommand('run'), isFalse);
      expect(CommandRouter.isManagementCommand('check'), isFalse);
    });

    test('dartic is a forward command', () {
      expect(CommandRouter.isManagementCommand('dartic'), isFalse);
      expect(CommandRouter.isDarticCommand('dartic'), isTrue);
    });

    test('empty args is management (shows help)', () {
      expect(CommandRouter.isManagementCommand(null), isTrue);
    });

    test('--version flag is management', () {
      expect(CommandRouter.isManagementCommand('--version'), isTrue);
    });

    test('--help flag is management', () {
      expect(CommandRouter.isManagementCommand('--help'), isTrue);
    });
  });
}
