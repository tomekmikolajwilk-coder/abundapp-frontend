import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/features/add_asset/asset_builder.dart';

void main() {
  group('currencyValueOptions', () {
    test('preferowana na początku, potem reszta wspieranych', () {
      final opts = currencyValueOptions('PLN');
      expect(opts.first, 'PLN');
      expect(opts.toSet(), supportedCurrencies.toSet());
      // brak duplikatu preferowanej
      expect(opts.where((c) => c == 'PLN').length, 1);
    });

    test('preferowana = USD → USD pierwszy, bez duplikatu', () {
      final opts = currencyValueOptions('USD');
      expect(opts.first, 'USD');
      expect(opts.where((c) => c == 'USD').length, 1);
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
