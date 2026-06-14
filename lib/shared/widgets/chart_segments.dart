import '../../core/models/holding.dart';
import '../../features/dashboard/dashboard_context.dart';

/// Pojedynczy wycinek wykresu alokacji (kategoria na poziomie ALL, aktywo na
/// poziomie CATEGORY). Współdzielony przez donut i bar chart.
class ChartSegment {
  final String id;
  final String label;
  final double value;

  const ChartSegment({
    required this.id,
    required this.label,
    required this.value,
  });
}

/// Buduje segmenty dla danego kontekstu, posortowane malejąco po wartości:
/// - ALL → agregacja po kategorii (label = nazwa PL kategorii),
/// - CATEGORY → poszczególne aktywa danej kategorii (label = ticker),
/// - ASSET → pusta lista (brak alokacji do pokazania).
List<ChartSegment> buildChartSegments(
  List<Holding> holdings,
  DashboardContext ctx,
) {
  if (ctx.level == DashboardLevel.all) {
    final map = <String, double>{};
    for (final h in holdings) {
      map[h.category] = (map[h.category] ?? 0) + h.valueCcy;
    }
    return map.entries
        .map((e) =>
            ChartSegment(id: e.key, label: categoryLabel(e.key), value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  if (ctx.level == DashboardLevel.category) {
    return holdings
        .where((h) => h.category == ctx.categoryId)
        .map((h) =>
            ChartSegment(id: h.assetId, label: h.assetId, value: h.valueCcy))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  return [];
}
