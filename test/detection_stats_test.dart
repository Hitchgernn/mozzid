import 'package:flutter_test/flutter_test.dart';
import 'package:mozzid/domain/models/detection.dart';
import 'package:mozzid/domain/stats/detection_stats.dart';

Detection _d(String sp, DateTime ts) =>
    Detection(speciesId: sp, confidence: 80, wingbeatHz: 500, timestamp: ts);

void main() {
  group('computeStats', () {
    test('empty log yields empty stats', () {
      final stats = computeStats(const []);
      expect(stats.total, 0);
      expect(stats.breakdown, isEmpty);
      expect(stats.peakWindow, isNull);
    });

    test('counts totals and sorts breakdown by frequency', () {
      final log = [
        _d('aedes', DateTime(2026, 7, 1, 23)),
        _d('aedes', DateTime(2026, 7, 1, 22)),
        _d('aedes', DateTime(2026, 7, 1, 6)),
        _d('culex', DateTime(2026, 7, 1, 22)),
        _d('anopheles', DateTime(2026, 7, 1, 2)),
      ];
      final stats = computeStats(log);

      expect(stats.total, 5);
      expect(stats.breakdown.first.speciesId, 'aedes');
      expect(stats.breakdown.first.count, 3);
      expect(stats.breakdown.first.percent, 60);
      // Shares sum to a sensible total (rounding aside).
      final sum = stats.breakdown.fold<int>(0, (a, b) => a + b.percent);
      expect(sum, inInclusiveRange(99, 101));
    });

    test('peak window is the busiest 2-hour bucket', () {
      final log = [
        _d('aedes', DateTime(2026, 7, 1, 22, 10)), // 22:00 bucket
        _d('culex', DateTime(2026, 7, 1, 23, 40)), // 22:00 bucket
        _d('aedes', DateTime(2026, 7, 1, 3, 0)), // 02:00 bucket
      ];
      expect(computeStats(log).peakWindow, '10PM–12AM');
    });
  });

  group('formatWindow', () {
    test('formats 2-hour windows in 12h clock', () {
      expect(formatWindow(22), '10PM–12AM');
      expect(formatWindow(0), '12AM–2AM');
      expect(formatWindow(12), '12PM–2PM');
      expect(formatWindow(18), '6PM–8PM');
    });
  });
}
