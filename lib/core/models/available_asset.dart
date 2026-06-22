/// Aktywo rynkowe dostępne do dodania (z /assets) — ticker, kategoria i cena
/// USD. Cena pozwala policzyć wartość nowego holdingu lokalnie, zanim backend
/// dostanie endpoint dodawania.
class AvailableAsset {
  final String assetId;
  final String category;
  final double priceUsd;

  const AvailableAsset({
    required this.assetId,
    required this.category,
    required this.priceUsd,
  });

  factory AvailableAsset.fromJson(Map<String, dynamic> json) => AvailableAsset(
        assetId: json['asset_id'] as String,
        category: json['category'] as String,
        priceUsd: (json['price_usd'] as num).toDouble(),
      );
}
