import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/transaction.dart';
import 'package:abundapp/shared/widgets/pnl_breakdown.dart';

Transaction _tx({
  required String side,
  required double amount,
  required double valueCcy,
  required DateTime at,
  String? assetId = 'BTC',
  String? holdingId,
  String category = 'crypto',
}) =>
    Transaction(
      id: '$side-$at',
      holdingId: holdingId,
      assetId: assetId,
      name: null,
      category: category,
      side: side,
      amount: amount,
      execPriceUsd: 0,
      valueUsd: valueCcy,
      valueCcy: valueCcy,
      createdAt: at,
    );

void main() {
  final t0 = DateTime.utc(2026, 6, 15);

  group('transactionFlow', () {
    test('kup→sprzedaj→dokup: suma podpisanych = przepływ netto', () {
      // buy 1@100 (+100), sell 0.5@50 (−25), buy 1@25 (+25) → 100
      final txs = [
        _tx(side: 'buy', amount: 1, valueCcy: 100, at: t0),
        _tx(side: 'sell', amount: 0.5, valueCcy: -25, at: t0.add(const Duration(days: 1))),
        _tx(side: 'buy', amount: 1, valueCcy: 25, at: t0.add(const Duration(days: 2))),
      ];
      final flow = transactionFlow(
          txs, t0.subtract(const Duration(days: 1)), (_) => true);
      expect(flow, 100);
    });

    test('okno odcina transakcje sprzed windowStart', () {
      final txs = [
        _tx(side: 'buy', amount: 1, valueCcy: 100, at: t0), // przed oknem
        _tx(side: 'buy', amount: 1, valueCcy: 40, at: t0.add(const Duration(days: 5))),
      ];
      final flow = transactionFlow(
          txs, t0.add(const Duration(days: 1)), (_) => true);
      expect(flow, 40);
    });

    test('predykat filtruje po aktywie', () {
      final txs = [
        _tx(side: 'buy', amount: 1, valueCcy: 100, at: t0, assetId: 'BTC'),
        _tx(side: 'buy', amount: 1, valueCcy: 50, at: t0, assetId: 'ETH'),
      ];
      final flow = transactionFlow(
          txs, t0.subtract(const Duration(days: 1)), (t) => t.assetId == 'BTC');
      expect(flow, 100);
    });

    test('manual bez asset_id — klucz z holding_id', () {
      final txs = [
        _tx(
            side: 'buy',
            amount: 1,
            valueCcy: 500000,
            at: t0,
            assetId: null,
            holdingId: 'h1',
            category: 'real_estate'),
      ];
      final flow = transactionFlow(txs, t0.subtract(const Duration(days: 1)),
          (t) => (t.assetId ?? t.holdingId) == 'h1');
      expect(flow, 500000);
    });
  });
}
