/// Źródło ceny aktywa:
/// - `market`  — cenę zna backend (krypto, akcje, ETF, metale, waluty),
///   user podaje tylko ilość;
/// - `manual`  — cenę podaje user (nieruchomości, kosztowności, obligacje,
///   inne), wartość = ilość × wartość jednostki.
class PriceSource {
  static const market = 'market';
  static const manual = 'manual';
}

class Holding {
  final String assetId;
  final String category;
  final double amount;
  final double priceUsd;
  final double valueUsd;
  final double valueCcy;

  /// `market` albo `manual` — patrz [PriceSource]. Domyślnie `market`, żeby
  /// starsze odpowiedzi backendu (bez tego pola) zachowywały się jak dotąd.
  final String priceSource;

  /// Czytelna nazwa custom assetu (np. „Mieszkanie Kraków"). Dla aktywów market
  /// null — etykietą jest wtedy [assetId] (ticker).
  final String? name;

  /// Kategoria zastępcza do wyświetlania (np. ETF na obligacje, który user chce
  /// widzieć w „Obligacje"). null → grupujemy po [category].
  final String? displayCategory;

  /// Roczna stopa procentowa (obligacje) — wartość rośnie o tyle rocznie.
  /// Naliczaniem zajmuje się backend; frontend tylko przechowuje pole.
  final double? interestRate;

  const Holding({
    required this.assetId,
    required this.category,
    required this.amount,
    required this.priceUsd,
    required this.valueUsd,
    required this.valueCcy,
    this.priceSource = PriceSource.market,
    this.name,
    this.displayCategory,
    this.interestRate,
  });

  /// Aktywo z ręcznie podaną wartością (user updatuje sam, np. nieruchomość).
  bool get isManual => priceSource == PriceSource.manual;

  /// Kategoria użyta do grupowania w UI — zastępcza, jeśli podana.
  String get groupCategory => displayCategory ?? category;

  /// Etykieta do pokazania userowi (nazwa custom assetu albo ticker).
  String get displayName => name ?? assetId;

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      assetId: json['asset_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      priceUsd: (json['price_usd'] as num).toDouble(),
      valueUsd: (json['value_usd'] as num).toDouble(),
      valueCcy: (json['value_ccy'] as num).toDouble(),
      priceSource: json['price_source'] as String? ?? PriceSource.market,
      name: json['name'] as String?,
      displayCategory: json['display_category'] as String?,
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'asset_id': assetId,
        'category': category,
        'amount': amount,
        'price_usd': priceUsd,
        'value_usd': valueUsd,
        'value_ccy': valueCcy,
        'price_source': priceSource,
        if (name != null) 'name': name,
        if (displayCategory != null) 'display_category': displayCategory,
        if (interestRate != null) 'interest_rate': interestRate,
      };
}
