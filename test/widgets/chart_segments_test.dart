import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/holding.dart';
import 'package:abundapp/features/dashboard/dashboard_context.dart';
import 'package:abundapp/shared/widgets/chart_segments.dart';

Holding h(String id, String cat, double ccy) => Holding(
      assetId: id,
      category: cat,
      amount: 1,
      priceUsd: 1,
      valueUsd: ccy,
      valueCcy: ccy,
    );

void main() {
  final holdings = [
    h('BTC', 'crypto', 100),
    h('ETH', 'crypto', 50),
    h('AAPL', 'stock', 200),
    h('XAU', 'metal', 30),
  ];

  group('buildChartSegments — poziom ALL', () {
    test('agreguje po kategorii i sortuje malejąco', () {
      final segs = buildChartSegments(holdings, const DashboardContext.all());
      // crypto=150, stock=200, metal=30 → stock, crypto, metal.
      expect(segs.map((s) => s.id).toList(), ['stock', 'crypto', 'metal']);
      expect(segs.map((s) => s.value).toList(), [200, 150, 30]);
    });

    test('label kategorii jest przetłumaczony', () {
      final segs = buildChartSegments(holdings, const DashboardContext.all());
      final crypto = segs.firstWhere((s) => s.id == 'crypto');
      expect(crypto.label, 'Krypto');
    });
  });

  group('buildChartSegments — poziom CATEGORY', () {
    test('filtruje aktywa danej kategorii i sortuje malejąco', () {
      final segs =
          buildChartSegments(holdings, const DashboardContext.category('crypto'));
      expect(segs.map((s) => s.id).toList(), ['BTC', 'ETH']);
      expect(segs.map((s) => s.value).toList(), [100, 50]);
      // label = ticker.
      expect(segs.first.label, 'BTC');
    });

    test('nieznana kategoria → pusto', () {
      final segs = buildChartSegments(
          holdings, const DashboardContext.category('nieistnieje'));
      expect(segs, isEmpty);
    });
  });

  group('buildChartSegments — display_category (ETF→obligacje)', () {
    final etfBond = Holding(
      assetId: 'OBLI',
      category: 'etf',
      amount: 1,
      priceUsd: 1,
      valueUsd: 40,
      valueCcy: 40,
      displayCategory: 'bonds',
    );

    test('ALL: ETF z display_category liczy się w docelowej kategorii', () {
      final segs = buildChartSegments(
          [...holdings, etfBond], const DashboardContext.all());
      final ids = segs.map((s) => s.id).toList();
      expect(ids, contains('bonds'));
      expect(ids, isNot(contains('etf')));
      expect(segs.firstWhere((s) => s.id == 'bonds').value, 40);
    });

    test('CATEGORY=bonds zawiera ETF mimo category=etf', () {
      final segs = buildChartSegments(
          [...holdings, etfBond], const DashboardContext.category('bonds'));
      expect(segs.map((s) => s.id).toList(), ['OBLI']);
    });
  });

  group('buildChartSegments — poziom ASSET', () {
    test('zwraca pustą listę (brak alokacji do pokazania)', () {
      final segs = buildChartSegments(
          holdings, const DashboardContext.asset('crypto', 'BTC'));
      expect(segs, isEmpty);
    });
  });
}
