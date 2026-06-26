/// Pojedyncza transakcja z ledgera (append-only). Kierunek to `side`
/// (buy/sell); `amount` jest zawsze dodatnia, a `valueUsd`/`valueCcy` są
/// PODPISANE (+ kupno, − sprzedaż), więc suma za okres = przepływ netto.
class Transaction {
  final String id;
  final String? holdingId;

  /// Ticker (market) albo null dla manuali — wtedy etykietą jest [name].
  final String? assetId;
  final String? name;
  final String category;
  final String side; // 'buy' | 'sell'
  final double amount; // zawsze > 0
  final double execPriceUsd;
  final double valueUsd; // podpisana
  final double valueCcy; // podpisana, w walucie zapytania
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.holdingId,
    required this.assetId,
    required this.name,
    required this.category,
    required this.side,
    required this.amount,
    required this.execPriceUsd,
    required this.valueUsd,
    required this.valueCcy,
    required this.createdAt,
  });

  bool get isBuy => side == 'buy';

  /// Etykieta do pokazania: nazwa custom assetu albo ticker.
  String get displayName => name ?? assetId ?? '—';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      holdingId: json['holding_id'] as String?,
      assetId: json['asset_id'] as String?,
      name: json['name'] as String?,
      category: json['category'] as String,
      side: json['side'] as String,
      amount: (json['amount'] as num).toDouble(),
      execPriceUsd: (json['exec_price_usd'] as num?)?.toDouble() ?? 0,
      valueUsd: (json['value_usd'] as num).toDouble(),
      valueCcy: (json['value_ccy'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
