import 'package:flutter_test/flutter_test.dart';
import 'package:mozzid/domain/models/detection.dart';
import 'package:mozzid/domain/stats/log_filters.dart';

Detection _d(String sp, DateTime ts) =>
    Detection(speciesId: sp, confidence: 80, wingbeatHz: 500, timestamp: ts);

void main() {
  final now = DateTime(2026, 7, 18, 12);
  final log = [
    _d('aedes', now.subtract(const Duration(hours: 1))),
    _d('culex', now.subtract(const Duration(days: 2))),
    _d('aedes', now.subtract(const Duration(days: 10))),
    _d('anopheles', now.subtract(const Duration(days: 3))),
  ];

  test('default filter passes everything', () {
    final out = applyFilters(log, const LogFilter(), now: now);
    expect(out.length, 4);
  });

  test('species filter keeps only that species', () {
    final out = applyFilters(log, const LogFilter(speciesId: 'aedes'), now: now);
    expect(out.length, 2);
    expect(out.every((d) => d.speciesId == 'aedes'), isTrue);
  });

  test('"all" species id is treated as no species filter', () {
    final out = applyFilters(log, const LogFilter(speciesId: 'all'), now: now);
    expect(out.length, 4);
  });

  test('week range drops detections older than 7 days', () {
    final out = applyFilters(log, const LogFilter(range: DateRange.week), now: now);
    expect(out.length, 3); // the 10-day-old one is excluded
    expect(out.any((d) => d.timestamp == now.subtract(const Duration(days: 10))), isFalse);
  });

  test('species + week combine', () {
    final out = applyFilters(
      log,
      const LogFilter(speciesId: 'aedes', range: DateRange.week),
      now: now,
    );
    expect(out.length, 1); // only the 1-hour-old aedes
  });
}
