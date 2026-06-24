/// Waluty wspierane przez backend dla wartości manualnych aktywów. Inna →
/// backend zwróci 400, więc picker ograniczamy do tej listy.
const supportedCurrencies = ['PLN', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'USD'];

/// Waluty do wyboru przy wpisywaniu wartości custom-assetu — preferowana na
/// początku, potem pozostałe wspierane. Backend trzyma `unit_value` natywnie w
/// wybranej walucie i sam przelicza na value_usd/value_ccy.
List<String> currencyValueOptions(String preferred) {
  return [preferred, ...supportedCurrencies.where((c) => c != preferred)];
}

/// Parsuje liczbę z pola tekstowego, tolerując polski przecinek dziesiętny i
/// wąskie spacje. Zwraca null gdy pole jest puste lub niepoprawne.
double? parseAmount(String raw) {
  final cleaned = raw.replaceAll(' ', '').replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
