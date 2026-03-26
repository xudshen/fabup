// test/download/manifest_test.dart
import 'package:test/test.dart';
import 'package:fabup/src/download/manifest.dart';

void main() {
  group('Manifest', () {
    test('fromJson parses correctly', () {
      final m = Manifest.fromJson({
        'fab_cli': '1.2.0',
        'dartic_cli': '1.0.3',
      });
      expect(m.fabCliVersion, '1.2.0');
      expect(m.darticCliVersion, '1.0.3');
    });

    test('toJson round-trips', () {
      final m = Manifest(fabCliVersion: '1.2.0', darticCliVersion: '1.0.3');
      final json = m.toJson();
      expect(json['fab_cli'], '1.2.0');
      expect(json['dartic_cli'], '1.0.3');
      expect(Manifest.fromJson(json).fabCliVersion, '1.2.0');
    });

    test('fromJson throws on missing keys', () {
      expect(() => Manifest.fromJson({'fab_cli': '1.0.0'}), throwsA(anything));
    });
  });
}
