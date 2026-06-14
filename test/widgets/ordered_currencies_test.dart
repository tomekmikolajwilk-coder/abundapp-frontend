import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/features/dashboard/dashboard_screen.dart';

void main() {
  group('orderedCurrencies', () {
    test('preferowana ląduje na górze', () {
      final out = orderedCurrencies(['EUR', 'PLN', 'USD'], 'PLN');
      expect(out.first, 'PLN');
      expect(out, ['PLN', 'EUR', 'USD']);
    });

    test('preferowana nie duplikuje się', () {
      final out = orderedCurrencies(['EUR', 'PLN', 'USD'], 'PLN');
      expect(out.where((c) => c == 'PLN').length, 1);
      expect(out.length, 3);
    });

    test('preferowana == null → kolejność bez zmian', () {
      final out = orderedCurrencies(['EUR', 'PLN', 'USD'], null);
      expect(out, ['EUR', 'PLN', 'USD']);
    });

    test('preferowana spoza listy → nie dodaje jej', () {
      final out = orderedCurrencies(['EUR', 'USD'], 'GBP');
      expect(out, ['EUR', 'USD']);
    });

    test('zachowuje względną kolejność reszty (alfabetyczną z API)', () {
      final out = orderedCurrencies(['AUD', 'CHF', 'EUR', 'USD'], 'EUR');
      expect(out, ['EUR', 'AUD', 'CHF', 'USD']);
    });
  });
}
