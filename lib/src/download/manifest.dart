// lib/src/download/manifest.dart
class Manifest {
  final String fabCliVersion;
  final String darticCliVersion;

  /// Caret constraint for the required Flutter SDK (e.g. `^3.38.0`).
  /// Null for older manifests that don't include SDK requirements.
  final String? requiredFlutterSdk;

  /// Caret constraint for the required Dart SDK (e.g. `^3.10.7`).
  final String? requiredDartSdk;

  Manifest({
    required this.fabCliVersion,
    required this.darticCliVersion,
    this.requiredFlutterSdk,
    this.requiredDartSdk,
  });

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      fabCliVersion: json['fab_cli'] as String,
      darticCliVersion: json['dartic_cli'] as String,
      requiredFlutterSdk: json['required_flutter_sdk'] as String?,
      requiredDartSdk: json['required_dart_sdk'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'fab_cli': fabCliVersion,
        'dartic_cli': darticCliVersion,
        if (requiredFlutterSdk != null)
          'required_flutter_sdk': requiredFlutterSdk,
        if (requiredDartSdk != null) 'required_dart_sdk': requiredDartSdk,
      };
}
