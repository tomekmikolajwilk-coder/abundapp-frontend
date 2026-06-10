import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/portfolio_api.dart';
import '../models/portfolio.dart';
import '../models/pnl_period.dart';

// --- Dane z API ---

final portfolioProvider = FutureProvider<Portfolio>((ref) async {
  return fetchPortfolio();
});

final lastVisitProvider = FutureProvider<Portfolio?>((ref) async {
  return fetchLastVisit();
});

final snapshotDatesProvider = FutureProvider<List<String>>((ref) async {
  return fetchSnapshotDates();
});

// --- Wybrany okres PnL ---

final selectedPeriodProvider =
    StateProvider<PnlPeriod>((ref) => PnlPeriod.lastVisit);

// --- Dostępne okresy (tylko te dla których są snapshoty) ---

final availablePeriodsProvider = Provider<List<PnlPeriod>>((ref) {
  final datesAsync = ref.watch(snapshotDatesProvider);
  final dates = datesAsync.valueOrNull ?? [];
  final now = DateTime.now();

  return PnlPeriod.values.where((period) {
    if (period == PnlPeriod.lastVisit) return true; // zawsze dostępny
    if (period == PnlPeriod.allTime) return dates.isNotEmpty;

    final needed = period.snapshotDate(now);
    if (needed == null) return false;
    return dates.contains(needed);
  }).toList();
});

// --- Snapshot dla wybranego okresu ---

final periodSnapshotProvider = FutureProvider<Portfolio?>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final now = DateTime.now();

  if (period == PnlPeriod.lastVisit) {
    return ref.watch(lastVisitProvider.future);
  }

  if (period == PnlPeriod.allTime) {
    final dates = await ref.watch(snapshotDatesProvider.future);
    if (dates.isEmpty) return null;
    return fetchPortfolioSnapshot(dates.last); // najstarsza data
  }

  final date = period.snapshotDate(now);
  if (date == null) return null;
  return fetchPortfolioSnapshot(date);
});

// --- PnL: aktualna wartość minus snapshot z wybranego okresu ---

final pnlProvider = Provider<double?>((ref) {
  final current = ref.watch(portfolioProvider).valueOrNull;
  final snapshot = ref.watch(periodSnapshotProvider).valueOrNull;

  if (current == null) return null;
  // brak snapshotu (pierwsze uruchomienie) → 0
  if (snapshot == null) return 0;
  return current.totalValueCcy - snapshot.totalValueCcy;
});
