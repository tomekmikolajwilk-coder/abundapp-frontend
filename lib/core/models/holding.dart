class Holding {
  final String assetId;
  final String category;
  final double amount;
  final double priceUsd;
  final double valueUsd;
  final double valueCcy;

  const Holding({
    required this.assetId,
    required this.category,
    required this.amount,
    required this.priceUsd,
    required this.valueUsd,
    required this.valueCcy,
  });

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      assetId: json['asset_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      priceUsd: (json['price_usd'] as num).toDouble(),
      valueUsd: (json['value_usd'] as num).toDouble(),
      valueCcy: (json['value_ccy'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'asset_id': assetId,
        'category': category,
        'amount': amount,
        'price_usd': priceUsd,
        'value_usd': valueUsd,
        'value_ccy': valueCcy,
      };
}
