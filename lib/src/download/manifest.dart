// lib/src/download/manifest.dart
class Manifest {
  final String fabCliVersion;
  final String darticCliVersion;

  Manifest({required this.fabCliVersion, required this.darticCliVersion});

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      fabCliVersion: json['fab_cli'] as String,
      darticCliVersion: json['dartic_cli'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'fab_cli': fabCliVersion,
        'dartic_cli': darticCliVersion,
      };
}
