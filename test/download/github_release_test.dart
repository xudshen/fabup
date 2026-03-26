// test/download/github_release_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:fabup/src/download/github_release.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://localhost:${server.port}';
    server.listen((req) {
      if (req.uri.path == '/repos/owner/fab/releases/tags/v1.2.0') {
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'tag_name': 'v1.2.0',
            'prerelease': false,
            'assets': [
              {
                'name': 'manifest.json',
                'browser_download_url': '$baseUrl/download/manifest.json',
              },
              {
                'name': 'fab-cli-darwin-arm64',
                'browser_download_url': '$baseUrl/download/fab-cli-darwin-arm64',
              },
            ],
          }))
          ..close();
      } else if (req.uri.path == '/repos/owner/fab/releases') {
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode([
            {'tag_name': 'v1.2.0', 'prerelease': false},
            {'tag_name': 'v1.0.0', 'prerelease': false},
            {'tag_name': 'v1.2.0-snapshot.20260326', 'prerelease': true},
          ]))
          ..close();
      } else if (req.uri.path == '/download/manifest.json') {
        req.response
          ..headers.contentType = ContentType.json
          ..write('{"fab_cli":"1.2.0","dartic_cli":"1.0.3"}')
          ..close();
      } else if (req.uri.path == '/download/fab-cli-darwin-arm64') {
        req.response
          ..write('FAKE_BINARY_CONTENT')
          ..close();
      } else {
        req.response
          ..statusCode = 404
          ..close();
      }
    });
  });

  tearDown(() async {
    await server.close();
  });

  group('GithubReleaseClient', () {
    test('listVersions returns stable versions', () async {
      final client = GithubReleaseClient(
        owner: 'owner',
        repo: 'fab',
        apiBaseUrl: baseUrl,
      );
      final versions = await client.listVersions(includePreRelease: false);
      expect(versions, ['v1.2.0', 'v1.0.0']);
    });

    test('listVersions with pre-release', () async {
      final client = GithubReleaseClient(
        owner: 'owner',
        repo: 'fab',
        apiBaseUrl: baseUrl,
      );
      final versions = await client.listVersions(includePreRelease: true);
      expect(versions, hasLength(3));
    });

    test('getAssetUrl finds asset by name', () async {
      final client = GithubReleaseClient(
        owner: 'owner',
        repo: 'fab',
        apiBaseUrl: baseUrl,
      );
      final url = await client.getAssetUrl('v1.2.0', 'manifest.json');
      expect(url, '$baseUrl/download/manifest.json');
    });

    test('getAssetUrl returns null for missing asset', () async {
      final client = GithubReleaseClient(
        owner: 'owner',
        repo: 'fab',
        apiBaseUrl: baseUrl,
      );
      final url = await client.getAssetUrl('v1.2.0', 'nonexistent');
      expect(url, isNull);
    });

    test('downloadAsset returns bytes', () async {
      final client = GithubReleaseClient(
        owner: 'owner',
        repo: 'fab',
        apiBaseUrl: baseUrl,
      );
      final bytes = await client.downloadBytes('$baseUrl/download/fab-cli-darwin-arm64');
      expect(String.fromCharCodes(bytes), 'FAKE_BINARY_CONTENT');
    });
  });
}
