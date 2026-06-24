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
  /// Id wiersza w portfelu (z backendu) — do PATCH/DELETE. null dla pozycji
  /// lokalnych/snapshotów bez tego pola.
  final String? id;

  /// Ticker (market) albo — gdy backend nie zwraca asset_id (manual) — id wiersza.
  /// Zawsze niepuste, służy jako klucz tożsamości w UI (drill-down, wykresy).
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

  /// Natywna wartość jednostki i jej waluta (z /portfolio) — w nich aktywo jest
  /// trzymane na backendzie. Gdy obecne, edytor pozwala zmienić wartość w tej
  /// walucie (niezależnie od podglądu). null = backend ich (jeszcze) nie zwraca.
  final double? unitValueNative;
  final String? unitCurrency;

  const Holding({
    required this.assetId,
    required this.category,
    required this.amount,
    required this.priceUsd,
    required this.valueUsd,
    required this.valueCcy,
    this.id,
    this.priceSource = PriceSource.market,
    this.name,
    this.displayCategory,
    this.interestRate,
    this.unitValueNative,
    this.unitCurrency,
  });

  /// Aktywo z ręcznie podaną wartością (user updatuje sam, np. nieruchomość).
  bool get isManual => priceSource == PriceSource.manual;

  /// Kategoria użyta do grupowania w UI — zastępcza, jeśli podana.
  String get groupCategory => displayCategory ?? category;

  /// Etykieta do pokazania userowi (nazwa custom assetu albo ticker).
  String get displayName => name ?? assetId;

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'] as String?,
      // Manual nie ma asset_id — używamy id wiersza jako klucza tożsamości.
      assetId: (json['asset_id'] ?? json['id']) as String? ?? '',
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      priceUsd: (json['price_usd'] as num).toDouble(),
      valueUsd: (json['value_usd'] as num).toDouble(),
      valueCcy: (json['value_ccy'] as num).toDouble(),
      priceSource: json['price_source'] as String? ?? PriceSource.market,
      name: json['name'] as String?,
      displayCategory: json['display_category'] as String?,
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      unitValueNative: (json['unit_value'] as num?)?.toDouble(),
      unitCurrency: json['unit_currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
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
