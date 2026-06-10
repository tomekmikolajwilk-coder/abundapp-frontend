import 'holding.dart';

class Portfolio {
  final String currency;
  final List<Holding> holdings;

  const Portfolio({
    required this.currency,
    required this.holdings,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final list = json['holdings_breakdown'] as List<dynamic>;
    return Portfolio(
      currency: json['currency'] as String,
      holdings: list.map((h) => Holding.fromJson(h as Map<String, dynamic>)).toList(),
    );
  }

  double get totalValueUsd =>
      holdings.fold(0, (sum, h) => sum + h.valueUsd);

  double get totalValueCcy =>
      holdings.fold(0, (sum, h) => sum + h.valueCcy);

  double valueCcyForCategory(String categoryId) => holdings
      .where((h) => h.category == categoryId)
      .fold(0, (sum, h) => sum + h.valueCcy);

  double valueCcyForAsset(String assetId) => holdings
      .where((h) => h.assetId == assetId)
      .fold(0, (sum, h) => sum + h.valueCcy);
}
