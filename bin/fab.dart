import 'dart:io';

import 'package:args/args.dart';
import 'package:fabup/src/config/fab_home.dart';
import 'package:fabup/src/config/fabrc.dart';
import 'package:fabup/src/config/fabrc_local.dart';
import 'package:fabup/src/commands/install_command.dart';
import 'package:fabup/src/commands/use_command.dart';
import 'package:fabup/src/commands/list_command.dart';
import 'package:fabup/src/commands/remove_command.dart';
import 'package:fabup/src/download/github_release.dart';
import 'package:fabup/src/download/platform.dart';
import 'package:fabup/src/shim/command_router.dart';
import 'package:fabup/src/shim/forwarder.dart';
import 'package:fabup/src/version.dart';

const _fabOwner = 'xudshen';
const _fabRepo = 'fab';
const _darticOwner = 'xudshen';
const _darticRepo = 'dartic';

Future<void> main(List<String> args) async {
  final home = FabHome();
  home.ensureStructure();

  // Parse --verbose before routing (strip it from args).
  final verbose = args.contains('--verbose');
  final cleanArgs = args.where((a) => a != '--verbose').toList();

  if (cleanArgs.isEmpty) {
    _printUsage();
    exit(0);
  }

  final first = cleanArgs.first;

  if (first == '--version') {
    stdout.writeln('fab (fabup) $fabupVersion');
    exit(0);
  }

  if (first == '--help' || first == '-h') {
    _printUsage();
    exit(0);
  }

  if (CommandRouter.isManagementCommand(first)) {
    exit(await _runManagement(home, first, cleanArgs.sublist(1),
        verbose: verbose));
  }

  // Forward: resolve version, exec binary
  final version = _resolveVersion(home, verbose: verbose);
  final isDartic = CommandRouter.isDarticCommand(first);
  final forwardArgs = isDartic ? cleanArgs.sublist(1) : cleanArgs;

  // Inject --flutter-sdk for fab-cli (not dartic-cli) and --verbose.
  var enrichedArgs =
      isDartic ? forwardArgs : _injectFlutterSdk(forwardArgs, verbose: verbose);
  if (verbose && !enrichedArgs.contains('--verbose')) {
    enrichedArgs = [...enrichedArgs, '--verbose'];
  }

  final binary = Forwarder.resolveBinary(home, version, isDartic: isDartic);
  if (verbose) {
    stderr.writeln('[fabup] binary: $binary');
    stderr.writeln('[fabup] forward: ${[binary, ...enrichedArgs].join(' ')}');
  }
  final exitCode = await Forwarder.forward(binary, enrichedArgs);
  exit(exitCode);
}

String _resolveVersion(FabHome home, {bool verbose = false}) {
  final projectVersion = Fabrc.findVersion(Directory.current.path);
  if (projectVersion != null) {
    if (verbose) stderr.writeln('[fabup] version: $projectVersion (from .fabrc)');
    return projectVersion;
  }
  final global = home.globalVersion();
  if (global != null) {
    if (verbose) stderr.writeln('[fabup] version: $global (global default)');
    return global;
  }
  stderr.writeln('No FAB version configured.');
  stderr.writeln('Run: fab install <version>');
  exit(1);
}

Future<int> _runManagement(
  FabHome home,
  String command,
  List<String> rest, {
  bool verbose = false,
}) async {
  final token = Platform.environment['GITHUB_TOKEN'];

  try {
    switch (command) {
      case 'install':
        if (rest.isEmpty) {
          stderr.writeln('Usage: fab install <version>');
          return 1;
        }
        final platform = HostPlatform.current();
        final fabClient = GithubReleaseClient(
          owner: _fabOwner, repo: _fabRepo, token: token,
        );
        final darticClient = GithubReleaseClient(
          owner: _darticOwner, repo: _darticRepo, token: token,
        );
        await installVersion(
          home: home,
          version: rest.first,
          fabClient: fabClient,
          darticClient: darticClient,
          platformSuffix: platform.assetSuffix,
          verbose: verbose,
        );
        fabClient.close();
        darticClient.close();
        return 0;

      case 'use':
        if (rest.isEmpty) {
          stderr.writeln('Usage: fab use <version> [--global]');
          return 1;
        }
        final parser = ArgParser()..addFlag('global', defaultsTo: false);
        final results = parser.parse(rest);
        final version =
            results.rest.isNotEmpty ? results.rest.first : rest.first;
        useVersion(
          home: home,
          version: version.replaceFirst(RegExp(r'^v'), ''),
          projectDir: Directory.current.path,
          global: results['global'] as bool,
          verbose: verbose,
        );
        return 0;

      case 'list':
        final parser = ArgParser()
          ..addFlag('remote', defaultsTo: false)
          ..addFlag('all', defaultsTo: false);
        final results = parser.parse(rest);
        if (results['remote'] as bool) {
          final client = GithubReleaseClient(
            owner: _fabOwner, repo: _fabRepo, token: token,
          );
          final tags = await client.listVersions(
            includePreRelease: results['all'] as bool,
          );
          stdout.write(formatRemoteVersions(tags));
          client.close();
        } else {
          final projectVersion = Fabrc.findVersion(Directory.current.path);
          stdout.write(
              formatLocalVersions(home: home, projectVersion: projectVersion));
        }
        return 0;

      case 'remove':
        if (rest.isEmpty) {
          stderr.writeln('Usage: fab remove <version>');
          return 1;
        }
        removeInstalledVersion(home: home, version: rest.first);
        return 0;

      case 'upgrade':
        stderr.writeln('fab upgrade is not yet implemented.');
        return 1;

      default:
        stderr.writeln('Unknown command: $command');
        return 1;
    }
  } on StateError catch (e) {
    stderr.writeln('Error: ${e.message}');
    return 1;
  } catch (e) {
    stderr.writeln('Error: $e');
    return 1;
  }
}

/// Inject `--flutter-sdk` from `.fabrc.local` if the user didn't provide it.
List<String> _injectFlutterSdk(List<String> args, {bool verbose = false}) {
  if (args.any((a) => a.startsWith('--flutter-sdk'))) return args;
  final flutterSdk = FabrcLocal.findFlutterSdk(Directory.current.path);
  if (flutterSdk == null) {
    if (verbose) stderr.writeln('[fabup] .fabrc.local: not found');
    return args;
  }
  if (verbose) {
    stderr.writeln('[fabup] .fabrc.local: flutter_sdk=$flutterSdk');
    stderr.writeln('[fabup] injecting: --flutter-sdk $flutterSdk');
  }
  return [...args, '--flutter-sdk', flutterSdk];
}

void _printUsage() {
  stdout.writeln('fab (fabup) $fabupVersion — FAB version manager');
  stdout.writeln('');
  stdout.writeln('Version management:');
  stdout.writeln('  fab install <version>          Download and install a version');
  stdout.writeln('  fab use <version> [--global]   Set version for project or globally');
  stdout.writeln('  fab list [--remote] [--all]    List installed or available versions');
  stdout.writeln('  fab remove <version>           Remove an installed version');
  stdout.writeln('  fab upgrade                    Upgrade the version manager itself');
  stdout.writeln('');
  stdout.writeln('All other commands are forwarded to the active fab-cli:');
  stdout.writeln('  fab compile, fab run, fab check, ...');
  stdout.writeln('  fab dartic <args>              Forward to dartic-cli');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --verbose                      Enable verbose output');
  stdout.writeln('');
  stdout.writeln('Set GITHUB_TOKEN env var for private repo access.');
}
