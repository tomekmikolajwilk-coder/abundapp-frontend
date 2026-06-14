import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/api/portfolio_api.dart';

void main() {
  group('remapSelectedCurrency', () {
    test('podmienia value_ccy na value_selected i ustawia walutę', () {
      final json = {
        'currency': 'PLN',
        'holdings_breakdown': [
          {
            'asset_id': 'BTC',
            'category': 'crypto',
            'amount': 0.25,
            'price_usd': 66928,
            'value_usd': 16732,
            'value_ccy': 61125.93,
            'value_selected': 14418.42,
          },
        ],
      };

      final out = remapSelectedCurrency(json, 'EUR');

      expect(out['currency'], 'EUR');
      final h = (out['holdings_breakdown'] as List).first as Map;
      expect(h['value_ccy'], 14418.42); // przyjęło value_selected
      expect(h['value_usd'], 16732); // value_usd nietknięte
    });

    test('gdy brak value_selected — zostawia oryginalne value_ccy', () {
      final json = {
        'currency': 'PLN',
        'holdings_breakdown': [
          {
            'asset_id': 'BTC',
            'category': 'crypto',
            'amount': 0.25,
            'price_usd': 66928,
            'value_usd': 16732,
            'value_ccy': 61125.93,
          },
        ],
      };

      final out = remapSelectedCurrency(json, 'EUR');
      final h = (out['holdings_breakdown'] as List).first as Map;
      expect(h['value_ccy'], 61125.93);
    });

    test('nie mutuje oryginalnego json', () {
      final json = {
        'currency': 'PLN',
        'holdings_breakdown': [
          {'value_ccy': 100.0, 'value_selected': 25.0},
        ],
      };

      remapSelectedCurrency(json, 'USD');

      expect(json['currency'], 'PLN');
      expect((json['holdings_breakdown'] as List).first, {
        'value_ccy': 100.0,
        'value_selected': 25.0,
      });
    });
  });

  group('parseHistoryPoints', () {
    final json = {
      'currency': 'PLN',
      'points': [
        {'date': '2026-06-03', 'value': 100.0, 'value_selected': 25.0},
        {'date': '2026-06-01', 'value': 90.0, 'value_selected': 22.0},
        {'date': '2026-06-02', 'value': 95.0, 'value_selected': 23.0},
      ],
    };

    test('tryb preferowany: bierze value i currency z odpowiedzi', () {
      final points = parseHistoryPoints(json, null);
      expect(points.map((p) => p['date']).toList(),
          ['2026-06-01', '2026-06-02', '2026-06-03']); // posortowane rosnąco
      expect(points.first['value'], 90.0);
      expect(points.first['currency'], 'PLN');
    });

    test('tryb wybranej waluty: bierze value_selected i etykietę waluty', () {
      final points = parseHistoryPoints(json, 'EUR');
      expect(points.first['value'], 22.0); // value_selected
      expect(points.first['currency'], 'EUR');
      expect(points.last['value'], 25.0);
    });

    test('sortuje rosnąco po dacie', () {
      final points = parseHistoryPoints(json, null);
      final dates = points.map((p) => p['date'] as String).toList();
      final sorted = [...dates]..sort();
      expect(dates, sorted);
    });

    test('pusta lista punktów → pusty wynik', () {
      final points = parseHistoryPoints({'currency': 'PLN', 'points': []}, null);
      expect(points, isEmpty);
    });
  });
}
