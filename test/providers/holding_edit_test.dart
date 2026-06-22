import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/holding.dart';
import 'package:abundapp/core/providers/portfolio_provider.dart';

Holding _h({
  required double amount,
  required double valueUsd,
  required double valueCcy,
  String source = PriceSource.market,
}) =>
    Holding(
      assetId: 'X',
      category: 'crypto',
      amount: amount,
      priceUsd: amount == 0 ? 0 : valueUsd / amount,
      valueUsd: valueUsd,
      valueCcy: valueCcy,
      priceSource: source,
    );

void main() {
  group('applyHoldingEdit', () {
    test('zmiana ilości skaluje value_ccy i value_usd proporcjonalnie', () {
      // 0,5 @ value_usd=100, value_ccy=400 → 1,0 podwaja wartości.
      final h = _h(amount: 0.5, valueUsd: 100, valueCcy: 400);
      final out = applyHoldingEdit(h, amount: 1);
      expect(out.amount, 1);
      expect(out.valueUsd, 200);
      expect(out.valueCcy, 800);
      // cena jednostkowa USD bez zmian (kurs ten sam).
      expect(out.priceUsd, closeTo(200, 1e-9));
    });

    test('zmiana wartości jednostki (manual) ustawia value_ccy = ilość×wartość',
        () {
      // 1 szt, value_ccy=650000; nowa wartość jednostki 720000.
      final h = _h(
          amount: 1, valueUsd: 162500, valueCcy: 650000, source: PriceSource.manual);
      final out = applyHoldingEdit(h, amount: 1, unitValueCcy: 720000);
      expect(out.valueCcy, 720000);
      // value_usd skaluje się tym samym kursem (162500/650000 = 0,25).
      expect(out.valueUsd, closeTo(180000, 1e-6));
    });

    test('brak zmian → wartości jak były', () {
      final h = _h(amount: 2, valueUsd: 50, valueCcy: 200);
      final out = applyHoldingEdit(h);
      expect(out.amount, 2);
      expect(out.valueCcy, 200);
      expect(out.valueUsd, 50);
    });
  });
}
