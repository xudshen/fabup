// test/commands/install_command_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/commands/install_command.dart';
import 'package:fabup/src/config/fab_home.dart';
import 'package:fabup/src/download/github_release.dart';

void main() {
  late Directory tempDir;
  late FabHome home;
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('fabup_install_test_');
    home = FabHome(root: tempDir.path);
    home.ensureStructure();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://localhost:${server.port}';
    server.listen((req) {
      if (req.uri.path.contains('releases/tags/v1.2.0')) {
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'tag_name': 'v1.2.0',
            'prerelease': false,
            'assets': [
              {'id': 201, 'name': 'manifest.json', 'browser_download_url': '$baseUrl/manifest.json'},
              {'id': 202, 'name': 'fab-cli-darwin-arm64', 'browser_download_url': '$baseUrl/fab-cli'},
            ],
          }))
          ..close();
      } else if (req.uri.path.contains('releases/tags/v1.0.3')) {
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'tag_name': 'v1.0.3',
            'prerelease': false,
            'assets': [
              {'id': 301, 'name': 'dartic-cli-darwin-arm64', 'browser_download_url': '$baseUrl/dartic-cli'},
            ],
          }))
          ..close();
      } else if (req.uri.path == '/manifest.json' ||
                 req.uri.path.endsWith('/assets/201')) {
        req.response
          ..write('{"fab_cli":"1.2.0","dartic_cli":"1.0.3"}')
          ..close();
      } else if (req.uri.path == '/fab-cli' ||
                 req.uri.path.endsWith('/assets/202')) {
        req.response
          ..write('FAKE_FAB_CLI')
          ..close();
      } else if (req.uri.path == '/dartic-cli' ||
                 req.uri.path.endsWith('/assets/301')) {
        req.response
          ..write('FAKE_DARTIC_CLI')
          ..close();
      } else {
        req.response..statusCode = 404..close();
      }
    });
  });

  tearDown(() async {
    await server.close();
    tempDir.deleteSync(recursive: true);
  });

  group('InstallCommand', () {
    test('installs version with fab-cli and dartic-cli', () async {
      final fabClient = GithubReleaseClient(
        owner: 'owner', repo: 'fab', apiBaseUrl: baseUrl,
      );
      final darticClient = GithubReleaseClient(
        owner: 'owner', repo: 'dartic', apiBaseUrl: baseUrl,
      );

      await installVersion(
        home: home,
        version: '1.2.0',
        fabClient: fabClient,
        darticClient: darticClient,
        platformSuffix: 'darwin-arm64',
      );

      expect(home.isInstalled('1.2.0'), isTrue);
      expect(File(home.fabCliBin('1.2.0')).existsSync(), isTrue);
      expect(File(home.darticCliBin('1.2.0')).existsSync(), isTrue);
      expect(File(home.manifestPath('1.2.0')).existsSync(), isTrue);
    });

    test('skips if already installed', () async {
      Directory(home.versionDir('1.2.0')).createSync(recursive: true);

      final fabClient = GithubReleaseClient(
        owner: 'owner', repo: 'fab', apiBaseUrl: baseUrl,
      );
      final darticClient = GithubReleaseClient(
        owner: 'owner', repo: 'dartic', apiBaseUrl: baseUrl,
      );

      // Should not throw, just skip
      await installVersion(
        home: home,
        version: '1.2.0',
        fabClient: fabClient,
        darticClient: darticClient,
        platformSuffix: 'darwin-arm64',
      );
    });

    test('sets global version if no current', () async {
      final fabClient = GithubReleaseClient(
        owner: 'owner', repo: 'fab', apiBaseUrl: baseUrl,
      );
      final darticClient = GithubReleaseClient(
        owner: 'owner', repo: 'dartic', apiBaseUrl: baseUrl,
      );

      await installVersion(
        home: home,
        version: '1.2.0',
        fabClient: fabClient,
        darticClient: darticClient,
        platformSuffix: 'darwin-arm64',
      );

      expect(home.globalVersion(), '1.2.0');
    });
  });
}
