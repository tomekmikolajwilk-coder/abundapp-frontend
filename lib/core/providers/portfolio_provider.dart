import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/portfolio_api.dart';
import '../models/portfolio.dart';
import '../models/pnl_period.dart';
import 'preferences_provider.dart';

// --- Dane z API ---

final portfolioProvider = FutureProvider<Portfolio>((ref) async {
  return fetchPortfolio();
});

// --- Lokalny baseline "od ostatniej wizyty" ---
//
// Backend nadpisuje swój visit-snapshot przy każdym /portfolio (każde
// odświeżenie apki), więc /last-visit zawsze pokazuje "teraz" → PnL = 0.
// Dlatego prowadzimy baseline lokalnie: pełny portfel z POPRZEDNIEJ sesji
// zapisany w SharedPreferences, zamrożony na bieżącą sesję.
//
// Roll następuje raz na SESJĘ (cold start), nie raz na dobę — dzięki temu
// każde uruchomienie apki przesuwa punkt odniesienia ("od ostatniej wizyty"),
// ale odświeżenia w obrębie tej samej sesji już go nie ruszają.

final visitBaselineProvider =
    NotifierProvider<VisitBaselineNotifier, Portfolio?>(
        VisitBaselineNotifier.new);

class VisitBaselineNotifier extends Notifier<Portfolio?> {
  static const _kJson = 'visit_baseline_json';

  bool _recordedThisSession = false;

  @override
  Portfolio? build() {
    // Baseline z poprzedniej sesji — zamrażamy na bieżącą sesję.
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(_kJson);
    if (json == null) return null;
    try {
      return Portfolio.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Zapisuje bieżący portfel jako baseline dla NASTĘPNEJ sesji — dokładnie raz
  /// na uruchomienie apki. Kolejne odświeżenia w tej samej sesji są ignorowane,
  /// więc wyświetlany baseline pozostaje zamrożony (nie resetuje się do 0).
  void recordVisit(Portfolio current) {
    if (_recordedThisSession) return;
    _recordedThisSession = true;
    ref
        .read(sharedPreferencesProvider)
        .setString(_kJson, jsonEncode(current.toJson()));
  }
}

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
    // Lokalny baseline zamiast zatrutego backendowego /last-visit
    return ref.watch(visitBaselineProvider);
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
