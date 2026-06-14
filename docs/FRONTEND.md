# abundapp — dokumentacja frontendu

Aplikacja mobilna/desktopowa (Flutter) inteligentnego portfela cyfrowego —
śledzenie całego majątku w jednym miejscu: gotówka, akcje, ETF-y, złoto, krypto.

> **Zakres.** Ten dokument opisuje **frontend**: architekturę, zarządzanie stanem,
> sposób konsumowania API, modele, ekrany i komponenty oraz testy/CI.
> Kontrakty endpointów, model danych w bazie, joby cron i deployment backendu są
> opisane osobno w [BACKEND.md](https://github.com/tomekmikolajwilk-coder/abundapp-backend/blob/main/docs/BACKEND.md)
> i **nie są tu powielane** — odwołujemy się do nich tam, gdzie to potrzebne.

---

## Spis treści

1. [Stack i zależności](#1-stack-i-zależności)
2. [Struktura katalogów](#2-struktura-katalogów)
3. [Architektura — warstwy](#3-architektura--warstwy)
4. [Warstwa API — wykorzystane endpointy](#4-warstwa-api--wykorzystane-endpointy)
5. [Modele](#5-modele)
6. [Zarządzanie stanem (Riverpod)](#6-zarządzanie-stanem-riverpod)
7. [Nawigacja i drill-down (DashboardContext)](#7-nawigacja-i-drill-down-dashboardcontext)
8. [Kluczowe funkcje](#8-kluczowe-funkcje)
9. [Komponenty UI](#9-komponenty-ui)
10. [Zasoby (ikony krypto, flagi)](#10-zasoby-ikony-krypto-flagi)
11. [Motyw i formatowanie](#11-motyw-i-formatowanie)
12. [Testy i CI](#12-testy-i-ci)
13. [Uruchomienie lokalne](#13-uruchomienie-lokalne)
14. [Znane ograniczenia / TODO](#14-znane-ograniczenia--todo)

---

## 1. Stack i zależności

- **Flutter** (Dart SDK `^3.12.1`), Material 3, dark theme.
- **flutter_riverpod** `^2.6.1` — zarządzanie stanem (+ `riverpod_annotation`,
  `riverpod_generator` w dev).
- **http** `^1.2.2` — wywołania REST do Edge Functions backendu.
- **syncfusion_flutter_charts** `^33.2.12` — interaktywny wykres wartości w czasie
  (zoom/pan/trackball).
- **fl_chart** `^1.2.0` — wykres kołowy (donut) alokacji.
- **shared_preferences** `^2.5.5` — lokalna pamięć (baseline „ostatniej wizyty",
  preferencje typu wykresu).
- **intl** `^0.20.2` — formatowanie dat na osi/tooltipie wykresu.
- **supabase_flutter** `^2.8.4` — obecne jako zależność; docelowo do auth (na
  razie API wołane bezpośrednio przez `http`, patrz §4).

> **Licencja Syncfusion** — biblioteka wykresów działa na Community License; to
> jedyna potencjalnie płatna zależność frontendu (szczegóły kosztów w BACKEND.md).

---

## 2. Struktura katalogów

```
lib/
  main.dart                      # bootstrap: SharedPreferences + ProviderScope
  app.dart                       # MaterialApp + theme + home = DashboardScreen
  core/
    api/
      portfolio_api.dart         # warstwa HTTP — wszystkie wywołania backendu
    models/
      portfolio.dart             # Portfolio (waluta + lista holdingów + sumy)
      holding.dart               # pojedyncze aktywo w portfelu
      top_mover.dart             # aktywo + jego ruch w okresie
      chart_point.dart           # punkt serii czasowej + enum ChartRange
      pnl_period.dart            # enum okresów PnL + logika dat snapshotów
    providers/
      portfolio_provider.dart    # rdzeń stanu: portfel, waluta, baseline, PnL
      chart_provider.dart        # dane wykresu wartości w czasie + zakres
      top_movers_provider.dart   # ranking moverów + sparkline
      preferences_provider.dart  # SharedPreferences + typ wykresu
    theme/
      app_theme.dart             # AppColors + buildAppTheme()
    utils/
      format.dart                # formatowanie kwot/liczb (czyste funkcje)
  features/
    dashboard/
      dashboard_screen.dart      # główny ekran + picker waluty
      dashboard_context.dart     # poziom widoku (all/category/asset) + labelki
  shared/
    widgets/
      asset_avatar.dart          # okrągła ikonka aktywa/kategorii (fallback chain)
      allocation_chart.dart      # wykres słupkowy alokacji (bar)
      donut_chart.dart           # wykres kołowy alokacji (donut)
      chart_segments.dart        # współdzielona logika segmentów (bar+donut)
      value_chart.dart           # wykres wartości w czasie (Syncfusion)
      top_movers.dart            # sekcja „Top movers" + selectTopMovers()
      pnl_header.dart            # nagłówek z PnL i wartością
      period_selector.dart       # wybór okresu PnL (bottom sheet)
      chart_reveal.dart          # animacja wejścia wykresów (fade + slide)
assets/
  crypto/                        # logo krypto (PNG, offline)
  flags/                         # flagi walut (PNG, offline)
  ATTRIBUTION.md                 # atrybucja źródeł grafik
test/                            # patrz §12
.github/workflows/test.yml       # CI
docs/FRONTEND.md                 # ten plik
```

---

## 3. Architektura — warstwy

Przepływ jednokierunkowy, klasyczny dla Riverpoda:

```
Edge Functions (backend)
        │  HTTP (http package)
        ▼
core/api/portfolio_api.dart      ← jedyne miejsce z wywołaniami sieciowymi
        │  zwraca modele / mapy
        ▼
core/providers/*                 ← stan, kombinowanie danych, logika domenowa
        │  ref.watch(...)
        ▼
features/ + shared/widgets/*     ← UI (ConsumerWidget / ConsumerStatefulWidget)
```

Zasady:
- **Widgety nie wołają HTTP** — czytają tylko providery.
- **Logika domenowa = czyste funkcje** tam, gdzie się da (formatowanie, dobór
  moverów, budowa segmentów, remap waluty) — łatwe do testowania bez sieci/UI.
- **Stan globalny** trzymany w providerach; lokalny stan UI (np. zaznaczony
  wycinek wykresu) w `State` ekranu.

`main.dart` wstrzykuje gotową instancję `SharedPreferences` przez override:

```dart
ProviderScope(
  overrides: [ sharedPreferencesProvider.overrideWithValue(prefs) ],
  child: const AbundApp(),
)
```

---

## 4. Warstwa API — wykorzystane endpointy

Wszystkie wywołania są w `core/api/portfolio_api.dart`. Base URL i klucz anon
Supabase są tam zaszyte; `user_id` jest na razie stałym `_testUserId`
(auth dojdzie później — patrz §14). **Kontrakty odpowiedzi opisuje BACKEND.md** —
poniżej tylko jak frontend ich używa.

| Funkcja w `portfolio_api.dart` | Endpoint | Po co frontendowi |
|---|---|---|
| `fetchPortfolio({currency})` | `GET /portfolio` | bieżący portfel; `?currency=` → podgląd w innej walucie |
| `fetchPortfolioSnapshot(date, {currency})` | `GET /portfolio?date=` | portfel historyczny dla okresu PnL |
| `fetchCurrencies()` | `GET /assets` | lista walut do pickera (kategoria `currency`) |
| `fetchSnapshotDates()` | `GET /snapshot-dates` | które okresy PnL są dostępne |
| `fetchSnapshotHistory({categoryId, assetId, currency})` | `GET /value-history` | seria czasowa do wykresu wartości + sparkline |

### Parametry wysyłane przez frontend

- `user_id` — stały test user (Dart 3 null-aware map entry: `'currency': ?currency`
  pomija klucz, gdy `null`).
- `currency` — dodawany tylko w trybie podglądu w wybranej walucie.
- `date` — `YYYY-MM-DD` dla okresów; dla `allTime` używana najstarsza dostępna data.
- `category_id` / `asset_id` — zawężają serię czasową do kategorii/aktywa.

### „Remap trick" — wybrana waluta bez zmian w modelach

Backend dla `?currency=X` dokłada do każdego holdingu pole `value_selected`
(wartość w wybranej walucie po **dzisiejszym** kursie). Żeby reszta aplikacji nie
musiała znać tego pola, `remapSelectedCurrency()` podmienia w JSON-ie
`value_ccy ← value_selected` i ustawia `currency = X` **przed** parsowaniem modelu:

```dart
// pseudo
holding['value_ccy'] = holding['value_selected'] ?? holding['value_ccy'];
json['currency'] = 'EUR';
```

Dzięki temu modele i widgety działają identycznie w obu trybach. Analogicznie
`parseHistoryPoints()` dla wykresu wybiera `value_selected` zamiast `value`.

> **Konsekwencja metodologiczna:** w trybie wybranej waluty cała historia jest
> *projekcją po dzisiejszym kursie*, a nie wartością z przeszłości. Picker waluty
> komunikuje to użytkownikowi disclaimerem.

---

## 5. Modele

- **`Portfolio`** — `currency` + `List<Holding>`; gettery sum:
  `totalValueUsd`, `totalValueCcy`, `valueCcyForCategory(id)`,
  `valueCcyForAsset(id)`. Ma `toJson()` (do zapisu baseline w SharedPreferences).
- **`Holding`** — `assetId`, `category`, `amount`, `priceUsd`, `valueUsd`,
  `valueCcy`. `value_usd` to wspólny mianownik (bazowa jednostka); `value_ccy`
  to wartość w aktualnie wyświetlanej walucie.
- **`TopMover`** — `assetId`, `category`, `valueNow`, `pricePct` (zmiana **ceny**
  w %, izoluje ruch rynku od dopłat), `valueDelta`. `isNew` = brak punktu
  odniesienia; `isPositive` = `pricePct >= 0`.
- **`ChartPoint`** — `{date, value}`; `ChartRange` (`1M/3M/1R/MAX`) steruje tylko
  oknem startowym wykresu (pełna historia zostaje załadowana → można przesuwać
  w lewo).
- **`PnlPeriod`** — `lastVisit / yesterday / weekStart / monthStart / yearStart /
  allTime`; `snapshotDate(now)` zwraca datę snapshotu (tydzień liczony od
  poniedziałku).

---

## 6. Zarządzanie stanem (Riverpod)

### Portfel i waluta (`portfolio_provider.dart`)

- **`selectedCurrencyProvider`** `StateProvider<String?>` — `null` = waluta
  preferowana usera (tryb domyślny), wartość = jednorazowy podgląd w tej walucie.
- **`livePreferredPortfolioProvider`** `FutureProvider<Portfolio>` — portfel
  **zawsze** w walucie preferowanej. Źródło baseline'u i bazowych `value_usd`.
  Trzymany osobno, żeby podgląd w innej walucie nie „zatruł" baseline'u.
- **`portfolioProvider`** `FutureProvider<Portfolio>` — to, co pokazujemy:
  preferowany (gdy `sel == null`) albo pobrany z `?currency=sel`.
- **`displayCurrencyProvider`** `Provider<String>` — etykieta waluty dla miejsc
  bez dostępu do modelu (np. tooltip wykresu); fallback `PLN`.
- **`currenciesProvider`** `FutureProvider<List<String>>` — lista do pickera.

### Baseline „od ostatniej wizyty"

Backendowy `/last-visit` jest nadpisywany przy każdym `/portfolio`, więc do PnL
„od ostatniej wizyty" prowadzimy **lokalny** baseline:

- **`visitBaselineProvider`** (`NotifierProvider`) — czyta z SharedPreferences
  portfel zapisany w **poprzedniej** sesji i zamraża go na bieżącą.
- `recordVisit()` zapisuje bieżący portfel jako baseline dla **następnej** sesji —
  dokładnie **raz na uruchomienie** apki (kolejne odświeżenia w tej samej sesji
  są ignorowane, żeby PnL nie spadało do 0). Roll następuje na cold start.
- Baseline jest neutralny walutowo (trzyma `value_usd`); w trybie wybranej waluty
  przeliczany na bieżąco jednolitym kursem `totalValueCcy / totalValueUsd`.

### Okresy i PnL

- **`selectedPeriodProvider`** `StateProvider<PnlPeriod>` — wybrany okres.
- **`snapshotDatesProvider`** — dostępne daty snapshotów z backendu.
- **`availablePeriodsProvider`** — filtruje okresy do tych, dla których jest
  snapshot (`lastVisit` zawsze; `allTime` gdy są jakiekolwiek snapshoty).
- **`periodSnapshotProvider`** `FutureProvider<Portfolio?>` — portfel z wybranego
  okresu (lokalny baseline dla `lastVisit`, inaczej `fetchPortfolioSnapshot`).
- **`pnlProvider`** `Provider<double?>` — `bieżący − snapshot` po `totalValueCcy`;
  `null` gdy brak portfela, `0` gdy brak snapshotu (pierwsze uruchomienie).

### Wykres i movery

- **`chartRangeProvider`** — wybrany rolling zakres (`1M/3M/1R/MAX`).
- **`chartDataProvider`** `FutureProvider.family<…, DashboardContext>` — pełna
  seria czasowa dla kontekstu (zawęża po kategorii/aktywie, uwzględnia walutę).
- **`topMoversProvider`** `Provider.family<…, DashboardContext>` — liczy `pricePct`
  względem snapshotu wybranego okresu; nowe aktywa (bez odniesienia) na końcu.
- **`moverSparklineProvider`** `FutureProvider.family<…, String>` — ~30 ostatnich
  punktów wartości aktywa na mini-wykres na karcie.

### Preferencje

- **`sharedPreferencesProvider`** — wstrzykiwany w `main.dart` (w testach
  nadpisywany mockiem).
- **`preferencesProvider`** (`NotifierProvider`) — np. `chart_type` (`bar`/`donut`).

---

## 7. Nawigacja i drill-down (DashboardContext)

`DashboardContext` opisuje **poziom widoku**:

- `DashboardLevel.all` — cały portfel (agregacja po kategoriach),
- `DashboardLevel.category` — jedna kategoria (lista aktywów),
- `DashboardLevel.asset` — pojedyncze aktywo.

Ten sam `DashboardScreen` renderuje wszystkie poziomy — różni je tylko `context`.
Tap w wycinek wykresu/legendę robi drill-down: `all → category → asset` przez
`Navigator.push` z nowym `DashboardScreen(context: next)`. Większość providerów
to `family` kluczowane `DashboardContext`, więc każdy poziom ma własne dane.

`categoryLabel(id)` tłumaczy kategorie na PL (`crypto→Krypto`, `stock→Akcje`,
`etf→ETF-y`, `metal→Metale`, `currency→Gotówka`); nieznane id → surowa wartość
(fallback bez crasha — nowa kategoria z backendu działa od ręki).

---

## 8. Kluczowe funkcje

### Jednorazowy podgląd w wybranej walucie
Akcja w app barze (`_CurrencyButton`) otwiera bottom sheet z listą walut
(preferowana przypięta na górze — `orderedCurrencies()`). Wybór ustawia
`selectedCurrencyProvider`; total, PnL, wykres kołowy i wykres wartości
przeliczają się po dzisiejszym kursie. Wybór waluty preferowanej = reset podglądu
(`sel = null`). Nie zmienia `preferred_currency` na backendzie.

### PnL z wyborem okresu
`PnlHeader` pokazuje zmianę wartości i % względem snapshotu wybranego okresu.
Gdy na wykresie zaznaczony jest segment, nagłówek pokazuje dane tej
kategorii/aktywa (`selectedSegmentId`).

### Alokacja — donut lub bar
Przełączane `_ChartTypePicker` (zapisywane w preferencjach). Oba czytają te same
segmenty (`buildChartSegments()`), wspólny zestaw kolorów (`AppColors.categoryColors`)
i te same awatary. Zaznaczenie wycinka podświetla wiersz legendy i umożliwia
drill-down.

### Top movers
Sekcja kart 2×2 (gainery u góry, losery na dole) ze sparkline i % zmiany.
Dobór kart: `selectTopMovers()` — ≥4 aktywa → po 2 z każdej strony, mniej → po 1;
brakujące sloty dopełniane mocniejszą stroną (po `|%|`). Tap → drill-down do aktywa.

### Wykres wartości w czasie
`ValueChart` (Syncfusion `SfCartesianChart`): area series, zoom/pan po osi X,
trackball z własnym tooltipem (data + kwota), tryb pełnoekranowy (obrót
**widgetem** `RotatedBox`, bez zmiany orientacji urządzenia). Zakres steruje
oknem startowym, oś Y dopasowuje się do widocznych punktów.

---

## 9. Komponenty UI

- **`AssetAvatar`** — okrągła ikonka z łańcuchem fallbacków:
  `logo krypto (assets/crypto/) → flaga waluty (assets/flags/) → ikona kategorii
  (Material) → inicjały tickera`. Konstruktor `.asset(...)` (tryb aktywa) lub
  `.category(...)` (tryb kategorii). Obwódka w kolorze kategorii/metalu lub
  nadpisana `ringColor` (np. kolor wycinka wykresu). Metale mają charakterystyczne
  barwy (złoto/srebro/platyna/pallad). Brak pliku PNG → fallback bez błędu.
- **`ChartReveal`** — jednorazowa animacja wejścia (fade + delikatny ruch w górę);
  kolejne przebudowy jej nie wznawiają.
- **`PeriodSelector`** — bottom sheet z dostępnymi okresami PnL.
- **`PnlHeader`**, **`AllocationChart`**, **`DonutChart`**, **`TopMovers`**,
  **`ValueChart`** — opisane w §8. Wszystkie mają skeletony na czas ładowania.

---

## 10. Zasoby (ikony krypto, flagi)

- `assets/crypto/` — ~80 logo krypto (PNG), nazwa = lowercase ticker (`btc.png`).
- `assets/flags/` — flagi walut (PNG), nazwa = lowercase kod waluty (`pln.png`).
- Wszystko **bundlowane offline** — brak runtime'owych pobrań. Aktywa bez pliku
  spadają na inicjały/ikonę kategorii.
- Łączna waga ≈ 0,5 MB (kilka % buildu, koszt stały). Źródła i licencje:
  `assets/ATTRIBUTION.md`.
- Rejestracja w `pubspec.yaml` → `flutter: assets: [assets/crypto/, assets/flags/]`.

---

## 11. Motyw i formatowanie

- **`AppColors`** — paleta dark (tła, tekst, akcenty positive/negative/accent)
  oraz `categoryColors` dla wycinków wykresu. `buildAppTheme()` buduje `ThemeData`
  (Material 3 dark, `TextTheme`).
- **`format.dart`** (czyste funkcje):
  - `money` / `moneyCcy` — kwota zaokrąglona, grupowanie tysięcy **wąską spacją**
    (U+202F), opcjonalnie z walutą.
  - `moneySigned` — zawsze ze znakiem (do PnL).
  - `moneyPreciseCcy` — z groszami (przecinek dziesiętny).
  - `compactNumber` — skrót na osi wykresu (`100.6k`, `1.2M`).

---

## 12. Testy i CI

### Testy
Pakiet **92 testów** (`flutter test`), bez sieci, ułożony w `test/`:

```
test/
  utils/    format_test, portfolio_api_test (remap + parsowanie historii)
  models/   portfolio_test, dashboard_context_test, pnl_period_test, top_mover_test
  widgets/  chart_segments_test, top_movers_select_test, ordered_currencies_test,
            asset_avatar_test (widget test)
  providers/ derived_providers_test (display currency / PnL / top movers),
             visit_baseline_test (SharedPreferences mock)
```

Strategia:
- **Czyste funkcje** testowane wprost (formatowanie, `selectTopMovers`,
  `buildChartSegments`, `remapSelectedCurrency`, `parseHistoryPoints`,
  `orderedCurrencies`) — część wystawiona `@visibleForTesting`.
- **Providery** testowane przez `ProviderContainer` z **override'em
  providerów-zależności** (bez mockowania HTTP) oraz mockiem SharedPreferences.
- **Widgety** — `AssetAvatar` w izolacji (ikony, fallback inicjałów, kolor obwódki).

### CI (`.github/workflows/test.yml`)
Na każdy **push do `main`** i każdy **PR** do `main`:
`flutter pub get → flutter analyze → flutter test` (Flutter 3.44.1 stable, cache SDK).
Status widoczny w zakładce **Actions** repo i przy PR-ach.

---

## 13. Uruchomienie lokalne

```bash
flutter pub get
flutter run            # uruchom na podłączonym urządzeniu/emulatorze
flutter analyze        # analiza statyczna
flutter test           # testy
```

Aplikacja startuje od `DashboardScreen` (poziom `all`). Backend musi być dostępny
pod adresem zaszytym w `portfolio_api.dart` (publiczne GET-y, bez auth).

---

## 14. Znane ograniczenia / TODO

- **Auth** — `user_id` to na razie stały test user; docelowo JWT z Supabase Auth
  (zależność `supabase_flutter` już jest). Wtedy `portfolio_api.dart` przejdzie na
  token zamiast query param.
- **Warstwa HTTP bez DI** — wywołania to funkcje top-level z globalnym `http`.
  Pełne testy ścieżki sieciowej (np. `portfolioProvider` w trybie wybranej waluty)
  wymagałyby wstrzykiwanego klienta (`httpClientProvider`). Obecnie pokryte przez
  czyste funkcje + override providerów.
- **FAB / Ustawienia** — przyciski `+` i koło zębate są w UI, ale akcje jeszcze
  niepodpięte.
- **Historia w wybranej walucie** — projekcja po dzisiejszym kursie (świadomy
  kompromis, zakomunikowany w pickerze).
