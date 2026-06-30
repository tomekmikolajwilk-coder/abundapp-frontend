import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/pnl_period.dart';
import 'package:abundapp/l10n/app_localizations_pl.dart';

void main() {
  group('PnlPeriod.snapshotDate', () {
    // Środa, 2026-06-10.
    final now = DateTime(2026, 6, 10);

    test('lastVisit i allTime nie wymagają daty', () {
      expect(PnlPeriod.lastVisit.snapshotDate(now), isNull);
      expect(PnlPeriod.allTime.snapshotDate(now), isNull);
    });

    test('yesterday → dzień wcześniej', () {
      expect(PnlPeriod.yesterday.snapshotDate(now), '2026-06-09');
    });

    test('monthStart → pierwszy dzień miesiąca', () {
      expect(PnlPeriod.monthStart.snapshotDate(now), '2026-06-01');
    });

    test('yearStart → 1 stycznia', () {
      expect(PnlPeriod.yearStart.snapshotDate(now), '2026-01-01');
    });

    test('weekStart → poniedziałek tego tygodnia', () {
      // 2026-06-10 to środa → poniedziałek = 2026-06-08.
      expect(PnlPeriod.weekStart.snapshotDate(now), '2026-06-08');
    });

    test('weekStart gdy now to poniedziałek → ten sam dzień', () {
      final monday = DateTime(2026, 6, 8);
      expect(PnlPeriod.weekStart.snapshotDate(monday), '2026-06-08');
    });

    test('weekStart gdy now to niedziela → poprzedni poniedziałek', () {
      final sunday = DateTime(2026, 6, 14); // niedziela
      expect(PnlPeriod.weekStart.snapshotDate(sunday), '2026-06-08');
    });

    test('formatuje z zerami wiodącymi', () {
      final jan = DateTime(2026, 1, 5);
      expect(PnlPeriod.yesterday.snapshotDate(jan), '2026-01-04');
    });
  });

  group('PnlPeriod.label', () {
    test('każdy okres ma niepustą etykietę', () {
      final l = AppLocalizationsPl();
      for (final p in PnlPeriod.values) {
        expect(p.label(l), isNotEmpty);
      }
    });
  });
}
