import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/portfolio_api.dart';
import '../models/chart_point.dart';
import '../../features/dashboard/dashboard_context.dart';
import 'portfolio_provider.dart';

// Wybrany rolling zakres wykresu — zapamiętany globalnie
final chartRangeProvider =
    StateProvider<ChartRange>((ref) => ChartRange.month);

// Provider danych wykresu — zależy od kontekstu dashboardu
final chartDataProvider = FutureProvider.family<List<ChartPoint>, DashboardContext>(
  (ref, dashContext) async {
    final raw = await fetchSnapshotHistory(
      categoryId: dashContext.categoryId,
      assetId: dashContext.assetId,
      currency: ref.watch(selectedCurrencyProvider),
    );

    // Zawsze zwracamy CAŁĄ historię — zakres czasu (1M/3M/1R/MAX) ustawia tylko
    // widoczne okno wykresu, dzięki czemu można przesuwać w lewo do starszych
    // danych zamiast je odcinać.
    return raw.map((r) {
      final date = DateTime.parse(r['date'] as String);
      final value = (r['value'] as num).toDouble();
      return ChartPoint(date: date, value: value);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  },
);
