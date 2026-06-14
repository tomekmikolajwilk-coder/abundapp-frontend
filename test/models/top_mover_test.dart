import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/top_mover.dart';

TopMover _mover({double? pricePct, double? valueDelta}) => TopMover(
      assetId: 'BTC',
      label: 'BTC',
      category: 'crypto',
      valueNow: 100,
      pricePct: pricePct,
      valueDelta: valueDelta,
    );

void main() {
  group('TopMover', () {
    test('isNew gdy brak pricePct (aktywo bez odniesienia)', () {
      expect(_mover(pricePct: null).isNew, true);
      expect(_mover(pricePct: 1.0).isNew, false);
    });

    test('isPositive: dodatnie i zero → true, ujemne → false', () {
      expect(_mover(pricePct: 5).isPositive, true);
      expect(_mover(pricePct: 0).isPositive, true);
      expect(_mover(pricePct: -3).isPositive, false);
    });

    test('isPositive: null traktowane jako 0 → true', () {
      expect(_mover(pricePct: null).isPositive, true);
    });
  });
}
