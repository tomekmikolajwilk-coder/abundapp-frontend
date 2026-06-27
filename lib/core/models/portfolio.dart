import 'holding.dart';

class Portfolio {
  final String currency;
  final List<Holding> holdings;

  /// Moment uchwycenia snapshotu (z `?date=` — pole `captured_at`). null dla
  /// portfela live. Używany jako początek okna rozbicia PnL, żeby przepływy
  /// liczyć dokładnie od momentu, który odzwierciedla baseline (bug 2c).
  final DateTime? capturedAt;

  const Portfolio({
    required this.currency,
    required this.holdings,
    this.capturedAt,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final list = json['holdings_breakdown'] as List<dynamic>;
    final ts = json['captured_at'] as String?;
    return Portfolio(
      currency: json['currency'] as String,
      holdings: list.map((h) => Holding.fromJson(h as Map<String, dynamic>)).toList(),
      capturedAt: ts == null ? null : DateTime.tryParse(ts),
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'holdings_breakdown': holdings.map((h) => h.toJson()).toList(),
      };

  double get totalValueUsd =>
      holdings.fold(0, (sum, h) => sum + h.valueUsd);

  double get totalValueCcy =>
      holdings.fold(0, (sum, h) => sum + h.valueCcy);

  double valueCcyForCategory(String categoryId) => holdings
      .where((h) => h.groupCategory == categoryId)
      .fold(0, (sum, h) => sum + h.valueCcy);

  double valueCcyForAsset(String assetId) => holdings
      .where((h) => h.assetId == assetId)
      .fold(0, (sum, h) => sum + h.valueCcy);
}
