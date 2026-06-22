import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/portfolio_api.dart';
import '../models/available_asset.dart';
import '../models/holding.dart';
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
  final base = await fetchPortfolio();
  // Aktywa dodane lokalnie (kreator) + lokalne edycje ilości/wartości — zanim
  // backend ma endpointy. Patrz [localHoldingsProvider], [holdingOverridesProvider].
  final local = ref.watch(localHoldingsProvider);
  final overrides = ref.watch(holdingOverridesProvider);
  if (local.isEmpty && overrides.isEmpty) return base;

  var holdings = [...base.holdings, ...local];
  if (overrides.isNotEmpty) {
    holdings = holdings.map((h) {
      final e = overrides[h.assetId];
      return e == null
          ? h
          : applyHoldingEdit(h, amount: e.amount, unitValueCcy: e.unitValueCcy);
    }).toList();
  }
  return Portfolio(currency: base.currency, holdings: holdings);
});

// --- Lokalnie dodane holdingi (TYMCZASOWE) ---
//
// TODO(backend): gdy POST /holdings będzie gotowy, ten provider znika — aktywa
// wrócą prosto z /portfolio. Na teraz trzymamy je w pamięci sesji, żeby kreator
// dawał natychmiastowy efekt „aktywo wlatuje do portfela". Holdingi są w walucie
// preferowanej; podgląd w innej walucie ich (na razie) nie pokazuje.
final localHoldingsProvider =
    NotifierProvider<LocalHoldingsNotifier, List<Holding>>(
        LocalHoldingsNotifier.new);

class LocalHoldingsNotifier extends Notifier<List<Holding>> {
  @override
  List<Holding> build() => const [];

  void add(Holding holding) => state = [...state, holding];
}

// --- Lokalne edycje ilości / wartości (TYMCZASOWE) ---
//
// Override'y po assetId nakładane na portfel w [livePreferredPortfolioProvider].
// Pozwalają edytować ilość/wartość KAŻDEGO aktywa (też seedowanego z backendu),
// zanim powstanie PATCH /holdings. unitValueCcy == null → zmieniamy tylko ilość
// (cena rynkowa zostaje), wartość skaluje się proporcjonalnie.
typedef HoldingEdit = ({double amount, double? unitValueCcy});

final holdingOverridesProvider =
    NotifierProvider<HoldingOverridesNotifier, Map<String, HoldingEdit>>(
        HoldingOverridesNotifier.new);

class HoldingOverridesNotifier extends Notifier<Map<String, HoldingEdit>> {
  @override
  Map<String, HoldingEdit> build() => const {};

  void set(String assetId, {required double amount, double? unitValueCcy}) {
    state = {
      ...state,
      assetId: (amount: amount, unitValueCcy: unitValueCcy),
    };
  }
}

/// Nakłada edycję ilości/wartości na holding. value_usd skaluje się
/// proporcjonalnie do zmiany value_ccy (ten sam kurs).
Holding applyHoldingEdit(Holding h, {double? amount, double? unitValueCcy}) {
  final newAmount = amount ?? h.amount;
  final oldUnit = h.amount == 0 ? h.valueCcy : h.valueCcy / h.amount;
  final newUnit = unitValueCcy ?? oldUnit;
  final newValueCcy = newAmount * newUnit;
  final ratio = h.valueCcy == 0 ? 1 : newValueCcy / h.valueCcy;
  final newValueUsd = h.valueUsd * ratio;
  return Holding(
    assetId: h.assetId,
    category: h.category,
    amount: newAmount,
    priceUsd: newAmount == 0 ? h.priceUsd : newValueUsd / newAmount,
    valueUsd: newValueUsd,
    valueCcy: newValueCcy,
    priceSource: h.priceSource,
    name: h.name,
    displayCategory: h.displayCategory,
    interestRate: h.interestRate,
  );
}

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

  // Klucz baseline'u jest per-user — inaczej baseline jednego usera wyciekłby do
  // drugiego po przelogowaniu (PnL liczony względem cudzego portfela). Gdy nie ma
  // sesji (np. w testach bez Supabase.initialize), spadamy do bazowego klucza.
  String get _key {
    final uid = _safeUid();
    return uid == null ? _kJsonBase : '${_kJsonBase}_$uid';
  }

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
    final dates = await ref.watch(snapshotDatesProvider.future);
    if (dates.isEmpty) return null;
    return fetchPortfolioSnapshot(dates.last, currency: sel); // najstarsza data
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
  // Brak snapshotu (pierwsze uruchomienie) LUB snapshot bez pozycji (pusty/błędny
  // last-visit) → PnL 0. Inaczej pusty snapshot dałby PnL = cała wartość portfela.
  if (snapshot == null || snapshot.holdings.isEmpty) return 0;
  return current.totalValueCcy - snapshot.totalValueCcy;
});
