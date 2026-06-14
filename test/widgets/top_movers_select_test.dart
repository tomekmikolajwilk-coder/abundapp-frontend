import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/models/top_mover.dart';
import 'package:abundapp/shared/widgets/top_movers.dart';

TopMover m(String id, double? pct) => TopMover(
      assetId: id,
      label: id,
      category: 'crypto',
      valueNow: 100,
      pricePct: pct,
      valueDelta: pct,
    );

void main() {
  group('selectTopMovers', () {
    test('mniej niż 2 aktywa → pusto', () {
      expect(selectTopMovers([]), isEmpty);
      expect(selectTopMovers([m('BTC', 5)]), isEmpty);
    });

    test('2-3 aktywa → cel 2 karty (po 1 z każdej strony)', () {
      final out = selectTopMovers([
        m('UP1', 10),
        m('UP2', 5),
        m('DN1', -8),
      ]);
      expect(out.length, 2);
      // 1 gainer (najmocniejszy) + 1 loser.
      expect(out[0].assetId, 'UP1');
      expect(out[1].assetId, 'DN1');
    });

    test('≥4 aktywa → cel 4 karty (po 2 z każdej strony)', () {
      final out = selectTopMovers([
        m('UP1', 10),
        m('UP2', 7),
        m('UP3', 3),
        m('DN1', -4),
        m('DN2', -9),
      ]);
      expect(out.length, 4);
      // Gainery najpierw (malejąco), potem losery (najmocniejszy spadek).
      expect(out.map((x) => x.assetId).toList(), ['UP1', 'UP2', 'DN2', 'DN1']);
    });

    test('dopełnia mocniejszą stroną gdy brakuje loserów', () {
      // 4 aktywa, ale tylko 1 loser → cel 4, dopełnij gainerami.
      final out = selectTopMovers([
        m('UP1', 12),
        m('UP2', 8),
        m('UP3', 4),
        m('DN1', -2),
      ]);
      expect(out.length, 4);
      // 2 gainery + 1 loser + dopełnienie 3. gainerem; finalnie gainery przed loserem.
      expect(out.map((x) => x.assetId).toList(), ['UP1', 'UP2', 'UP3', 'DN1']);
    });

    test('ignoruje aktywa bez ruchu (pricePct == null lub 0)', () {
      final out = selectTopMovers([
        m('UP1', 6),
        m('FLAT', 0),
        m('NEW', null),
        m('DN1', -6),
      ]);
      // FLAT (0) i NEW (null) nie są ani gainerem ani loserem.
      expect(out.map((x) => x.assetId).toSet(), {'UP1', 'DN1'});
    });

    test('finalna kolejność: wszystkie gainery przed loserami', () {
      final out = selectTopMovers([
        m('DN1', -3),
        m('UP1', 9),
        m('DN2', -7),
        m('UP2', 2),
      ]);
      final firstLoserIdx = out.indexWhere((x) => x.pricePct! < 0);
      final lastGainerIdx =
          out.lastIndexWhere((x) => x.pricePct! > 0);
      expect(lastGainerIdx, lessThan(firstLoserIdx));
    });
  });
}
