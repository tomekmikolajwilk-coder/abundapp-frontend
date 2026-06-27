import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/portfolio_api.dart';
import '../models/available_asset.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../models/portfolio.dart';
import '../models/pnl_period.dart';
import 'preferences_provider.dart';

// --- Wybrana waluta wyświetlania ---
//
// null = waluta preferowana usera (domyślny, niezmieniony tryb).
// Inna wartość = jednorazowy podgląd majątku w tej walucie (po dzisiejszym
// kursie). Nie zmienia preferred_currency na backendzie.
final selectedCurrencyProvider = StateProvider<String?>((ref) => null);

// Lista walut dostępna w pickerze.
final currenciesProvider = FutureProvider<List<String>>((ref) async {
  return fetchCurrencies();
});

// Aktywa rynkowe (cena z backendu) pogrupowane po kategorii — zasila picker
// w kreatorze dodawania aktywa.
final marketAssetsProvider =
    FutureProvider<Map<String, List<AvailableAsset>>>((ref) async {
  return fetchMarketAssets();
});

// --- Dane z API ---

// Portfel zawsze w walucie preferowanej — źródło baseline'u "ostatniej wizyty"
// oraz bazowych value_usd. Trzymany osobno, żeby podgląd w innej walucie nie
// zatruł zapisywanego baseline'u.
final livePreferredPortfolioProvider = FutureProvider<Portfolio>((ref) async {
  return fetchPortfolio();
});

/// Odświeża portfel po dodaniu/edycji/usunięciu aktywa (oba tryby waluty).
void refreshPortfolio(WidgetRef ref) {
  ref.invalidate(livePreferredPortfolioProvider);
  ref.invalidate(portfolioProvider);
  ref.invalidate(transactionsProvider);
}

// Ledger transakcji w walucie wyświetlania (preferowana albo wybrana).
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final sel = ref.watch(selectedCurrencyProvider);
  return fetchTransactions(currency: sel);
});

// Portfel do wyświetlenia: preferowany albo przeliczony na wybraną walutę.
final portfolioProvider = FutureProvider<Portfolio>((ref) async {
  final sel = ref.watch(selectedCurrencyProvider);
  if (sel == null) return ref.watch(livePreferredPortfolioProvider.future);
  return fetchPortfolio(currency: sel);
});

// Etykieta waluty wyświetlania — dla miejsc bez dostępu do modelu (np. tooltip
// wykresu).
final displayCurrencyProvider = Provider<String>((ref) {
  final sel = ref.watch(selectedCurrencyProvider);
  if (sel != null) return sel;
  return ref.watch(portfolioProvider).valueOrNull?.currency ?? 'PLN';
});

// Przelicza portfel trzymany w walucie preferowanej na wybraną walutę,
// korzystając z jednolitego dzisiejszego kursu (value_usd × rate).
Portfolio _toSelectedCurrency(Portfolio p, String currency, double rate) {
  return Portfolio(
    currency: currency,
    holdings: p.holdings
        .map((h) => Holding(
              assetId: h.assetId,
              category: h.category,
              amount: h.amount,
              priceUsd: h.priceUsd,
              valueUsd: h.valueUsd,
              valueCcy: h.valueUsd * rate,
              // interestRatio jest walutowo-niezmienny — przenosimy, inaczej baseline
              // w wybranej walucie gubił odsetki (Ruch ceny od ostatniej wizyty na minus).
              interestRatio: h.interestRatio,
            ))
        .toList(),
  );
}

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
  static const _kJsonBase = 'visit_baseline_json';

  bool _recordedThisSession = false;

  /// Kiedy zamrożony baseline został zapisany (poprzednia sesja) — okno do
  /// liczenia rozbicia PnL „od ostatniej wizyty" to [capturedAt, teraz].
  /// Zamrożone w build(), zanim recordVisit nadpisze znacznik dla następnej sesji.
  DateTime? _capturedAt;
  DateTime? get capturedAt => _capturedAt;

  // Klucz baseline'u jest per-user — inaczej baseline jednego usera wyciekłby do
  // drugiego po przelogowaniu (PnL liczony względem cudzego portfela). Gdy nie ma
  // sesji (np. w testach bez Supabase.initialize), spadamy do bazowego klucza.
  String get _key {
    final uid = _safeUid();
    return uid == null ? _kJsonBase : '${_kJsonBase}_$uid';
  }

  String get _tsKey => '${_key}_ts';

  // Supabase.instance rzuca, jeśli SDK nie zostało zainicjowane (testy) — łapiemy
  // i zwracamy null, żeby baseline działał na bazowym kluczu.
  String? _safeUid() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Portfolio? build() {
    // Baseline z poprzedniej sesji — zamrażamy na bieżącą sesję.
    final prefs = ref.read(sharedPreferencesProvider);
    final ts = prefs.getString(_tsKey);
    _capturedAt = ts == null ? null : DateTime.tryParse(ts);
    final json = prefs.getString(_key);
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
        .setString(_key, jsonEncode(current.toJson()));
    ref
        .read(sharedPreferencesProvider)
        .setString(_tsKey, DateTime.now().toUtc().toIso8601String());
  }
}

/// Znacznik czasu zamrożonego baseline'u „od ostatniej wizyty" — okno do
/// rozbicia PnL na transakcje vs ruch ceny. Odświeża się razem z baseline'em.
final visitBaselineCapturedAtProvider = Provider<DateTime?>((ref) {
  ref.watch(visitBaselineProvider);
  return ref.read(visitBaselineProvider.notifier).capturedAt;
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
    if (period == PnlPeriod.allTime) return true; // od zera, nie wymaga snapshotu

    final needed = period.snapshotDate(now);
    if (needed == null) return false;
    return dates.contains(needed);
  }).toList();
});

// --- Snapshot dla wybranego okresu ---

final periodSnapshotProvider = FutureProvider<Portfolio?>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final sel = ref.watch(selectedCurrencyProvider);
  final now = DateTime.now();

  if (period == PnlPeriod.lastVisit) {
    // Lokalny baseline zamiast zatrutego backendowego /last-visit.
    final baseline = ref.watch(visitBaselineProvider);
    if (baseline == null || sel == null) return baseline;
    // Baseline trzymany jest w walucie preferowanej — przeliczamy go na wybraną
    // walutę dzisiejszym kursem wyprowadzonym z bieżącego portfela (kurs jest
    // jednolity: totalValueCcy_selected / totalValueUsd).
    final live = ref.watch(portfolioProvider).valueOrNull;
    if (live == null || live.totalValueUsd == 0) return null;
    final rate = live.totalValueCcy / live.totalValueUsd;
    return _toSelectedCurrency(baseline, sel, rate);
  }

  if (period == PnlPeriod.allTime) {
    // „Od początku" = od zera (przed jakimkolwiek posiadaniem). Baseline pusty,
    // więc PnL = cała obecna wartość; rozbicie pokaże ile z transakcji, ile z ceny.
    final cur = ref.watch(portfolioProvider).valueOrNull;
    return Portfolio(currency: cur?.currency ?? sel ?? 'PLN', holdings: const []);
  }

  final date = period.snapshotDate(now);
  if (date == null) return null;
  return fetchPortfolioSnapshot(date, currency: sel);
});

// --- PnL: aktualna wartość minus snapshot z wybranego okresu ---

final pnlProvider = Provider<double?>((ref) {
  final current = ref.watch(portfolioProvider).valueOrNull;
  final snapshot = ref.watch(periodSnapshotProvider).valueOrNull;

  if (current == null) return null;
  // Brak baseline'u (null = nigdy nie zapisany, pierwsza sesja) → PnL 0.
  // Pusty, ale ISTNIEJĄCY baseline (np. nowe konto: poprzednia wizyta = pusty
  // portfel) jest legalny → PnL = wartość obecna − 0.
  if (snapshot == null) return 0;
  return current.totalValueCcy - snapshot.totalValueCcy;
});

// --- Okno czasowe wybranego okresu — do rozbicia PnL na transakcje vs ruch ceny ---
//
// Transakcje z [windowStart, teraz] sumujemy jako składową „transakcje"; reszta
// PnL to ruch ceny. null = nie da się policzyć okna (brak baseline'u/snapshotu).
final pnlWindowStartProvider = Provider<DateTime?>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  if (period == PnlPeriod.lastVisit) {
    return ref.watch(visitBaselineCapturedAtProvider);
  }
  // „Od początku" = od zera: okno obejmuje WSZYSTKIE transakcje.
  if (period == PnlPeriod.allTime) return DateTime.utc(1970);

  // Okno = faktyczny `captured_at` baseline-snapshotu, nie sztywne 07:00. Inaczej
  // transakcje sprzed uchwycenia snapshotu (ale po 07:00) podwajały się z wartością
  // już odzwierciedloną w baseline → ujemny „ruch ceny" (bug 2c). null gdy snapshot
  // jeszcze się ładuje → rozbicie chwilowo ukryte.
  return ref.watch(periodSnapshotProvider).valueOrNull?.capturedAt;
});
