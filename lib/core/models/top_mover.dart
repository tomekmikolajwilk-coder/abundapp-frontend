/// Pojedynczy „mover" — aktywo i jego ruch w wybranym okresie.
///
/// `pricePct` liczymy z ceny (price_usd), żeby izolować ruch RYNKU od dopłat
/// (dokupienie zwiększa wartość, ale to nie jest performance aktywa).
/// `valueDelta` to wpływ na portfel w walucie usera (Δ value_ccy).
class TopMover {
  final String assetId;
  final String label;
  final String category;
  final double valueNow;

  /// Zmiana ceny w % względem snapshotu. null = brak punktu odniesienia
  /// (aktywo świeżo dokupione — nie było w snapshocie).
  final double? pricePct;

  /// Zmiana wartości w walucie usera. null gdy aktywo jest nowe.
  final double? valueDelta;

  const TopMover({
    required this.assetId,
    required this.label,
    required this.category,
    required this.valueNow,
    required this.pricePct,
    required this.valueDelta,
  });

  bool get isNew => pricePct == null;
  bool get isPositive => (pricePct ?? 0) >= 0;
}
