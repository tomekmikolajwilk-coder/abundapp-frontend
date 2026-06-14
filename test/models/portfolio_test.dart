import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/holding.dart';
import 'package:abundapp/core/models/portfolio.dart';

Map<String, dynamic> _holdingJson({
  String assetId = 'BTC',
  String category = 'crypto',
  double amount = 0.25,
  double priceUsd = 66928,
  double valueUsd = 16732,
  double valueCcy = 61125.93,
}) =>
    {
      'asset_id': assetId,
      'category': category,
      'amount': amount,
      'price_usd': priceUsd,
      'value_usd': valueUsd,
      'value_ccy': valueCcy,
    };

void main() {
  group('Holding', () {
    test('fromJson mapuje wszystkie pola', () {
      final h = Holding.fromJson(_holdingJson());
      expect(h.assetId, 'BTC');
      expect(h.category, 'crypto');
      expect(h.amount, 0.25);
      expect(h.priceUsd, 66928);
      expect(h.valueUsd, 16732);
      expect(h.valueCcy, 61125.93);
    });

    test('fromJson konwertuje int na double (num.toDouble)', () {
      final h = Holding.fromJson(_holdingJson(amount: 10, valueUsd: 3163));
      expect(h.amount, isA<double>());
      expect(h.amount, 10.0);
      expect(h.valueUsd, 3163.0);
    });

    test('toJson → fromJson round-trip zachowuje wartości', () {
      final original = Holding.fromJson(_holdingJson());
      final restored = Holding.fromJson(original.toJson());
      expect(restored.assetId, original.assetId);
      expect(restored.category, original.category);
      expect(restored.amount, original.amount);
      expect(restored.priceUsd, original.priceUsd);
      expect(restored.valueUsd, original.valueUsd);
      expect(restored.valueCcy, original.valueCcy);
    });
  });

  group('Portfolio', () {
    final portfolio = Portfolio.fromJson({
      'currency': 'PLN',
      'holdings_breakdown': [
        _holdingJson(
            assetId: 'BTC', category: 'crypto', valueUsd: 16732, valueCcy: 61000),
        _holdingJson(
            assetId: 'AAPL', category: 'stock', valueUsd: 3163, valueCcy: 11500),
        _holdingJson(
            assetId: 'XAU', category: 'metal', valueUsd: 8896, valueCcy: 32000),
      ],
    });

    test('fromJson czyta walutę i holdingi', () {
      expect(portfolio.currency, 'PLN');
      expect(portfolio.holdings.length, 3);
    });

    test('totalValueUsd sumuje value_usd', () {
      expect(portfolio.totalValueUsd, 16732 + 3163 + 8896);
    });

    test('totalValueCcy sumuje value_ccy', () {
      expect(portfolio.totalValueCcy, 61000 + 11500 + 32000);
    });

    test('valueCcyForCategory filtruje po kategorii', () {
      expect(portfolio.valueCcyForCategory('crypto'), 61000);
      expect(portfolio.valueCcyForCategory('stock'), 11500);
      expect(portfolio.valueCcyForCategory('nieistniejaca'), 0);
    });

    test('valueCcyForAsset filtruje po assetId', () {
      expect(portfolio.valueCcyForAsset('XAU'), 32000);
      expect(portfolio.valueCcyForAsset('DOGE'), 0);
    });

    test('pusty portfel ma zerowe sumy', () {
      final empty =
          Portfolio.fromJson({'currency': 'USD', 'holdings_breakdown': []});
      expect(empty.totalValueUsd, 0);
      expect(empty.totalValueCcy, 0);
    });
  });
}
