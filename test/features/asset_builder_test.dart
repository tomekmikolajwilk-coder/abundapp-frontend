import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/available_asset.dart';
import 'package:abundapp/core/models/holding.dart';
import 'package:abundapp/features/add_asset/asset_builder.dart';

void main() {
  group('preferredUsdPrice', () {
    final assets = {
      'currency': [
        const AvailableAsset(assetId: 'PLN', category: 'currency', priceUsd: 0.25),
        const AvailableAsset(assetId: 'EUR', category: 'currency', priceUsd: 1.08),
      ],
    };

    test('zwraca cenę USD waluty preferowanej', () {
      expect(preferredUsdPrice(assets, 'PLN'), 0.25);
      expect(preferredUsdPrice(assets, 'EUR'), 1.08);
    });

    test('brak waluty / brak danych → 0 (przelicznik 1:1)', () {
      expect(preferredUsdPrice(assets, 'GBP'), 0);
      expect(preferredUsdPrice(const {}, 'PLN'), 0);
    });
  });

  group('buildMarketHolding', () {
    test('value_usd = ilość×cena, value_ccy = value_usd / cena_USD_waluty', () {
      // 0,5 BTC po 60000 USD, PLN = 0,25 USD → 30000 USD = 120000 PLN
      final h = buildMarketHolding(
        assetId: 'BTC',
        category: 'crypto',
        amount: 0.5,
        priceUsd: 60000,
        preferredUsd: 0.25,
      );
      expect(h.valueUsd, 30000);
      expect(h.valueCcy, 120000);
      expect(h.priceSource, PriceSource.market);
      expect(h.isManual, isFalse);
    });

    test('preferredUsd == 0 → przelicznik 1:1 (value_ccy = value_usd)', () {
      final h = buildMarketHolding(
        assetId: 'AAPL',
        category: 'stock',
        amount: 10,
        priceUsd: 200,
        preferredUsd: 0,
      );
      expect(h.valueUsd, 2000);
      expect(h.valueCcy, 2000);
    });
  });

  group('buildManualHolding', () {
    test('value_ccy = ilość×wartość, value_usd = value_ccy × cena_USD_waluty', () {
      // 1 mieszkanie warte 650000 PLN, PLN = 0,25 USD → 162500 USD
      final h = buildManualHolding(
        name: 'Mieszkanie Kraków',
        category: 'real_estate',
        amount: 1,
        unitValueCcy: 650000,
        preferredUsd: 0.25,
      );
      expect(h.valueCcy, 650000);
      expect(h.valueUsd, 162500);
      expect(h.isManual, isTrue);
      expect(h.name, 'Mieszkanie Kraków');
      expect(h.assetId, 'Mieszkanie Kraków');
    });

    test('obligacje: stopa i display_category przechodzą do holdingu', () {
      final h = buildManualHolding(
        name: 'EDO',
        category: 'bonds',
        amount: 100,
        unitValueCcy: 1,
        preferredUsd: 0.25,
        interestRate: 5,
      );
      expect(h.valueCcy, 100);
      expect(h.interestRate, 5);
      expect(h.groupCategory, 'bonds');
    });

    test('display_category nadpisuje grupowanie (ETF→obligacje)', () {
      final h = buildManualHolding(
        name: 'Fundusz X',
        category: 'other',
        amount: 1,
        unitValueCcy: 100,
        preferredUsd: 0,
        displayCategory: 'bonds',
      );
      expect(h.groupCategory, 'bonds');
    });
  });

  group('parseAmount', () {
    test('przecinek dziesiętny i spacje', () {
      expect(parseAmount('0,5'), 0.5);
      expect(parseAmount('1 000,25'), 1000.25);
      expect(parseAmount('10'), 10);
    });

    test('puste / niepoprawne → null', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
    });
  });
}
