import 'package:flutter_test/flutter_test.dart';
import 'package:mozzid/domain/models/detection.dart';

void main() {
  test('Detection round-trips through toMap/fromMap', () {
    final ts = DateTime(2026, 7, 18, 23, 42);
    final original = Detection(
      id: 7,
      speciesId: 'aedes',
      confidence: 87,
      wingbeatHz: 612,
      timestamp: ts,
      latitude: -6.2,
      longitude: 106.8,
      locationLabel: 'Bedroom',
    );

    final restored = Detection.fromMap(original.toMap());

    expect(restored.id, 7);
    expect(restored.speciesId, 'aedes');
    expect(restored.confidence, 87);
    expect(restored.wingbeatHz, 612);
    expect(restored.timestamp, ts);
    expect(restored.latitude, -6.2);
    expect(restored.longitude, 106.8);
    expect(restored.locationLabel, 'Bedroom');
  });

  test('toMap omits null id so SQLite can autoincrement', () {
    final d = Detection(
      speciesId: 'culex',
      confidence: 70,
      wingbeatHz: 350,
      timestamp: DateTime(2026, 7, 18),
    );
    expect(d.toMap().containsKey('id'), isFalse);
  });

  test('nullable GPS survives the round-trip', () {
    final d = Detection(
      speciesId: 'culex',
      confidence: 70,
      wingbeatHz: 350,
      timestamp: DateTime(2026, 7, 18),
    );
    final restored = Detection.fromMap(d.toMap());
    expect(restored.latitude, isNull);
    expect(restored.longitude, isNull);
  });
}
