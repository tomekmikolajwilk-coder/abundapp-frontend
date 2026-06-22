import '../../core/models/available_asset.dart';
import '../../core/models/holding.dart';

/// Cena USD jednostki waluty preferowanej (np. ile USD kosztuje 1 PLN) —
/// wyciągnięta z listy aktywów kategorii `currency`. Służy do lokalnego
/// przeliczania value_usd <-> value_ccy. 0 = brak danych (przeliczamy 1:1).
double preferredUsdPrice(
  Map<String, List<AvailableAsset>> marketAssets,
  String preferred,
) {
  final currencies = marketAssets['currency'] ?? const [];
  for (final a in currencies) {
    if (a.assetId == preferred) return a.priceUsd;
  }
  return 0;
}

/// Holding rynkowy: user podaje ilość, cenę zna backend.
/// value_usd = ilość × cena; value_ccy = value_usd / cena_USD_waluty_preferowanej.
Holding buildMarketHolding({
  required String assetId,
  required String category,
  required double amount,
  required double priceUsd,
  required double preferredUsd,
}) {
  final valueUsd = amount * priceUsd;
  final valueCcy = preferredUsd > 0 ? valueUsd / preferredUsd : valueUsd;
  return Holding(
    assetId: assetId,
    category: category,
    amount: amount,
    priceUsd: priceUsd,
    valueUsd: valueUsd,
    valueCcy: valueCcy,
  );
}

/// Holding manualny: user podaje wartość jednostki w walucie preferowanej.
/// value_ccy = ilość × wartość jednostki; value_usd = value_ccy × cena_USD_waluty.
Holding buildManualHolding({
  required String name,
  required String category,
  required double amount,
  required double unitValueCcy,
  required double preferredUsd,
  String? displayCategory,
  double? interestRate,
}) {
  final valueCcy = amount * unitValueCcy;
  final valueUsd = valueCcy * preferredUsd;
  return Holding(
    assetId: name,
    category: category,
    amount: amount,
    priceUsd: unitValueCcy * preferredUsd,
    valueUsd: valueUsd,
    valueCcy: valueCcy,
    priceSource: PriceSource.manual,
    name: name,
    displayCategory: displayCategory,
    interestRate: interestRate,
  );
}

/// Parsuje liczbę z pola tekstowego, tolerując polski przecinek dziesiętny i
/// wąskie spacje. Zwraca null gdy pole jest puste lub niepoprawne.
double? parseAmount(String raw) {
  final cleaned = raw.replaceAll(' ', '').replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
