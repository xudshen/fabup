// lib/src/download/github_release.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GithubReleaseClient {
  final String owner;
  final String repo;
  final String apiBaseUrl;
  final http.Client _client;
  final Map<String, String> _headers;

  GithubReleaseClient({
    required this.owner,
    required this.repo,
    this.apiBaseUrl = 'https://api.github.com',
    String? token,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _headers = {
          'Accept': 'application/vnd.github+json',
          if (token != null) 'Authorization': 'Bearer $token',
        };

  /// List release tag names. Strips 'v' prefix is NOT done here — returns raw tags.
  Future<List<String>> listVersions({bool includePreRelease = false}) async {
    final url = Uri.parse('$apiBaseUrl/repos/$owner/$repo/releases');
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to list releases: ${response.statusCode}');
    }
    final releases = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    return releases
        .where((r) => includePreRelease || r['prerelease'] != true)
        .map((r) => r['tag_name'] as String)
        .toList();
  }

  /// Get download URL for a specific asset in a release.
  /// Returns the API URL (works for both public and private repos).
  Future<String?> getAssetUrl(String tag, String assetName) async {
    final url = Uri.parse('$apiBaseUrl/repos/$owner/$repo/releases/tags/$tag');
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Release $tag not found: ${response.statusCode}');
    }
    final release = jsonDecode(response.body) as Map<String, dynamic>;
    final assets = (release['assets'] as List).cast<Map<String, dynamic>>();
    for (final asset in assets) {
      if (asset['name'] == assetName) {
        // Use API URL for private repo compatibility
        final assetId = asset['id'];
        return '$apiBaseUrl/repos/$owner/$repo/releases/assets/$assetId';
      }
    }
    return null;
  }

  /// Download asset bytes from an API URL.
  /// Uses Accept: application/octet-stream for GitHub asset downloads.
  Future<Uint8List> downloadBytes(String url) async {
    final downloadHeaders = Map<String, String>.from(_headers);
    downloadHeaders['Accept'] = 'application/octet-stream';
    final response = await _client.get(Uri.parse(url), headers: downloadHeaders);
    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}
