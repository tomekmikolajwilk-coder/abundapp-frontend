import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/portfolio_api.dart';
import '../models/holding.dart';
import '../models/top_mover.dart';
import '../../features/dashboard/dashboard_context.dart';
import 'portfolio_provider.dart';

/// Top movers dla danego kontekstu dashboardu, liczone względem snapshotu
/// z aktualnie wybranego okresu (ten sam selektor co PnL).
///
/// - ALL → pojedyncze aktywa z całego portfela
/// - CATEGORY → aktywa z tej kategorii
/// - ASSET → pusta lista (jeden walor nie ma „moverów"; widget chowa sekcję)
///
/// Sortowanie: malejąco po sile ruchu (|pricePct|); nowe aktywa na końcu.
final topMoversProvider =
    Provider.family<List<TopMover>, DashboardContext>((ref, ctx) {
  if (ctx.level == DashboardLevel.asset) return const [];

  final current = ref.watch(portfolioProvider).valueOrNull;
  final snapshot = ref.watch(periodSnapshotProvider).valueOrNull;
  if (current == null) return const [];

  // Holdingi widoczne w tym kontekście.
  final holdings = current.holdings.where((h) {
    if (ctx.level == DashboardLevel.category) return h.category == ctx.categoryId;
    return true;
  });

  // Indeks snapshotu po assetId — do szybkiego dopasowania „przedtem".
  final thenById = <String, Holding>{
    for (final h in (snapshot?.holdings ?? const <Holding>[])) h.assetId: h,
  };

  final movers = holdings.map((h) {
    final then = thenById[h.assetId];
    final pricePct = (then != null && then.priceUsd > 0)
        ? (h.priceUsd - then.priceUsd) / then.priceUsd * 100
        : null;
    final valueDelta = then != null ? h.valueCcy - then.valueCcy : null;
    return TopMover(
      assetId: h.assetId,
      label: h.assetId,
      category: h.category,
      valueNow: h.valueCcy,
      pricePct: pricePct,
      valueDelta: valueDelta,
    );
  }).toList();

  // Najpierw te z ruchem (po |%|), nowe (bez odniesienia) na końcu.
  movers.sort((a, b) {
    if (a.isNew != b.isNew) return a.isNew ? 1 : -1;
    return (b.pricePct?.abs() ?? 0).compareTo(a.pricePct?.abs() ?? 0);
  });

  return movers;
});

/// Mini-seria wartości pojedynczego aktywa (~30 ostatnich punktów) do
/// narysowania sparkline na karcie movera. Jeden lekki request per aktywo.
final moverSparklineProvider =
    FutureProvider.family<List<double>, String>((ref, assetId) async {
  final raw = await fetchSnapshotHistory(categoryId: null, assetId: assetId);
  final values = raw.map((r) => (r['value'] as num).toDouble()).toList();
  if (values.length > 30) return values.sublist(values.length - 30);
  return values;
});
