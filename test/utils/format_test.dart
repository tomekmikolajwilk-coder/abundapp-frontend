import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/core/utils/format.dart';

// Separator tysięcy używany w format.dart to wąska spacja (U+202F).
const nbsp = ' ';

void main() {
  group('money', () {
    test('zaokrągla i grupuje tysiące', () {
      expect(money(127513.93), '127${nbsp}514');
    });

    test('bez separatora poniżej 1000', () {
      expect(money(999), '999');
      expect(money(0), '0');
    });

    test('próg tysiąca', () {
      expect(money(1000), '1${nbsp}000');
    });

    test('miliony — wiele grup', () {
      expect(money(1234567), '1${nbsp}234${nbsp}567');
    });

    test('liczby ujemne dostają minus', () {
      expect(money(-1234.4), '-1${nbsp}234');
    });

    test('ties zaokrąglane od zera', () {
      expect(money(2.5), '3');
      expect(money(-2.5), '-3');
    });
  });

  group('moneyCcy', () {
    test('dokleja walutę po wąskiej spacji', () {
      expect(moneyCcy(127513.93, 'PLN'), '127${nbsp}514${nbsp}PLN');
    });
  });

  group('moneySigned', () {
    test('dodatnie z plusem', () {
      expect(moneySigned(1234, 'PLN'), '+1${nbsp}234${nbsp}PLN');
    });

    test('ujemne z minusem', () {
      expect(moneySigned(-1234, 'PLN'), '-1${nbsp}234${nbsp}PLN');
    });

    test('zero traktowane jako dodatnie', () {
      expect(moneySigned(0, 'USD'), '+0${nbsp}USD');
    });
  });

  group('moneyPreciseCcy', () {
    test('grosze z przecinkiem dziesiętnym', () {
      expect(moneyPreciseCcy(127513.93, 'PLN'), '127${nbsp}513,93${nbsp}PLN');
    });

    test('dopełnia grosze do dwóch cyfr', () {
      expect(moneyPreciseCcy(1.5, 'USD'), '1,50${nbsp}USD');
      expect(moneyPreciseCcy(2, 'USD'), '2,00${nbsp}USD');
    });

    test('liczby ujemne', () {
      expect(moneyPreciseCcy(-5.05, 'EUR'), '-5,05${nbsp}EUR');
    });
  });

  group('compactNumber', () {
    test('tysiące → k z jednym miejscem', () {
      expect(compactNumber(100552), '100.6k');
      expect(compactNumber(1000), '1.0k');
    });

    test('miliony → M', () {
      expect(compactNumber(1200000), '1.2M');
    });

    test('poniżej tysiąca bez skrótu', () {
      expect(compactNumber(500), '500');
      expect(compactNumber(999), '999');
      expect(compactNumber(0), '0');
    });

    test('ujemne zachowują znak', () {
      expect(compactNumber(-2500), '-2.5k');
    });
  });
}
