/// Aktywo rynkowe dostępne do dodania. Pochodzi z dwóch źródeł o tym samym
/// kształcie metadanych:
///   • `/assets` (bulk, małe katalogi: crypto/currency/metal) — ma `priceUsd`,
///   • `/assets/search` (search-as-you-type, stock/ETF) — `priceUsd == null`
///     (kurs nie jest potrzebny do wyboru; held assety z ceną idą przez /portfolio).
class AvailableAsset {
  final String assetId;
  final String category;
  final double? priceUsd; // null gdy z /assets/search (metadane bez kursu)
  final String? displayName;
  final String? exchange;
  final String? country;

  const AvailableAsset({
    required this.assetId,
    required this.category,
    this.priceUsd,
    this.displayName,
    this.exchange,
    this.country,
  });

  /// Nazwa do wyświetlenia — pełna nazwa jeśli jest, inaczej ticker.
  String get label => displayName ?? assetId;

  factory AvailableAsset.fromJson(Map<String, dynamic> json) => AvailableAsset(
        assetId: json['asset_id'] as String,
        category: json['category'] as String,
        priceUsd: (json['price_usd'] as num?)?.toDouble(),
        displayName: json['display_name'] as String?,
        exchange: json['exchange'] as String?,
        country: json['country'] as String?,
      );
}
