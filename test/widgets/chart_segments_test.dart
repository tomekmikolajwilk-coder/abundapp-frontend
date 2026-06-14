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

  group('buildChartSegments — poziom ASSET', () {
    test('zwraca pustą listę (brak alokacji do pokazania)', () {
      final segs = buildChartSegments(
          holdings, const DashboardContext.asset('crypto', 'BTC'));
      expect(segs, isEmpty);
    });
  });
}
