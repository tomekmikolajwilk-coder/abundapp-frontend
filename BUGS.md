# Bugi — abundapp (tracker)

Status: ✅ zrobiony · ⏳ feature/decyzja · 🐛 do naprawy · 🔍 do weryfikacji danych · ❓ brak info

## 1. „Failed to load portfolio" po dniu (token 401) — ✅ `d0913ea`
Access token (~1h) wygasał; pierwszy request po wznowieniu leciał starym tokenem → 401.
`portfolio_api._freshHeaders()` odświeża sesję, gdy token wygasły.

## 2a. Obligacje: „Transakcje +0" w rozbiciu PnL — ✅ backend `6569197`
`/transactions` nie odsyłał `holding_id` (klucz pozycji manual) → matcher nie dopinał transakcji.

## 2b. Obligacje: 3-podział (transakcje / ruch ceny / odsetki) — ✅ `b636522` (back) + `e8bf63a` (front)
Backend zwraca per-pozycja `interest_ratio` (walutowo-niezmienny); front liczy bucket
„Odsetki" = teraz − baseline w zakresie. Degradacja łagodna dla starych snapshotów.

## 2c. „Od wczoraj": Ruch ceny −8997 (podwójne liczenie) — ✅ `420d4a0`
`windowStart` był sztywno `data+07:00`; teraz = faktyczny `captured_at` baseline-snapshotu.

## 6. Podgląd w USD → „Failed to load portfolio: 400" — ✅ backend `aa42443`
`resolveSelectedCurrency` nie obsługiwał USD (waluta bazowa, brak w price_cache). Dodane
`if (param === 'USD') return { ok:true, price:1 }` — naprawia /portfolio, /last-visit, /value-history.

---

## 3. Brak wykresu „wartość w czasie" dla `tomekmikolajwilk+c@gmail.com` — 🔍 weryfikacja (backend)
`/value-history` pusty → „Brak danych". Hipoteza: świeże konto bez cron-snapshotów (cron 7:00 UTC).
Sprawdzić: `select count(*) from portfolio_snapshots where user_id=… and source='cron'`. Render OK.

## 4. Zła linia „wartość w czasie" dla `demo2@gmail.com` (idealnie prosta) — 🔍 weryfikacja (dane)
Front mapuje punkty 1:1 bez interpolacji → prosta linia = dane są liniowe (syntetyczny seed demo2).
Nie bug renderu. Fix = poprawić seed (backend) albo zignorować (konto demo).

---

## Nowe — test na `tomekmikolajwilk+c@gmail.com` (2026-06-28)

## 7. 2× AAPL w portfelu (duplikaty pozycji market) — 🐛 do naprawy (backend)
POST /holdings market robi `insert()` nowego wiersza — brak merge po `(user, asset_id)`. Dodanie
AAPL drugi raz → dwie osobne pozycje. Fix (backend): market upsertuje/inkrementuje istniejącą pozycję
gdy `(user_id, asset_id)` już jest (jak PATCH delta), zamiast tworzyć duplikat. Alternatywa: front
agreguje pozycje market po `asset_id` (gorzej — komplikuje edycję/usuwanie per wiersz).
Plik: `supabase/functions/holdings/index.ts` (createHolding, gałąź MARKET).

## 8. Wykres „wartość w czasie" nie pokazuje bieżącej wartości — ✅ front (czeka na build/deploy)
Kupno (211k→252k) nie odbijało się na wykresie — `chartDataProvider` brał TYLKO historię cron-snapshotów
(ostatni punkt = wczoraj). Fix: `ValueChart` dokleja punkt „teraz" z żywego portfela
(`_scopedValue(live, dashContext)`), w tym samym zakresie i walucie. Plik: `lib/shared/widgets/value_chart.dart`.

## 9. Wykres pozycji MANUAL = 0 (nieruchomość) — 🐛 do naprawy (backend)
`/value-history?asset_id=<id>` filtruje `h.asset_id === assetIdParam`, ale pozycja manual ma w snapshotach
`asset_id=null` (tożsamość to `id` wiersza). Front pyta po id holdingu → nigdy nie matchuje → wykres 0.
Ten sam rozjazd tożsamości co #2a. Fix (backend): filtr `(h.asset_id ?? h.id) === assetIdParam`
(lustro frontowego `assetId = asset_id ?? id`). Plik: `supabase/functions/value-history/index.ts` (~linia 72).
Uwaga: punkt „teraz" z #8 pokaże bieżącą wartość, ale HISTORIA będzie 0 do czasu tego fixu.

## 10. „Failed to load portfolio" po wylogowaniu — ✅ okazało się #12 (patrz niżej)
Na świeżym buildzie wróciło, ale tylko z ekranów asset/kategoria → to #12, nie token.

## 11. Akcja GPW (Bogdanka, eodhd): wartość 0 + BRAK transakcji w ledgerze — 🐛 backend, decyzja
Bogdanka (`LWB.WAR`, `api_source='eodhd'`) wyceniana standalone cronem `fetch-eod` (godzinowy, EOD,
demand-driven). Brak `eodhd` w rejestrze on-demand (`_shared/price_providers/index.ts` ma tylko twelve_data).
W `resolveMarketPrice`: `getProvider('eodhd')=undefined` → `{price:null, blocked:false}` → pozycja
utworzona, ale `recordTransaction` POMINIĘTY (guard `if price!=null`). Skutki:
- (A) wartość 0 do najbliższego runu `fetch-eod` (≤1h) — latencja, samo się naprawia.
- (B) **BRAK wpisu buy w ledgerze NA ZAWSZE** — nawet gdy cena przyjdzie. To realny bug
  (PnL/transakcje gubią zakup). Dotyczy każdego źródła z własnym cronem, gdy asset nie jest jeszcze w cache.
Fix (decyzja): albo **on-demand single-fetch eodhd przy dodaniu** (real-time `${EODHD_BASE}/real-time/
{symbol}` + konwersja FX z price_cache; symbol z `exchange` via EXCHANGE_MAP) → cena i ledger od razu;
albo **backfill ledgera w cronie** gdy pojawi się cena dla trzymanej pozycji bez transakcji. Rekomendacja: on-demand.

## 12. Logout z ekranu asset/kategoria → 400 „Failed to load portfolio" — ✅ `app.dart`
Ekrany asset/kategoria są PUSHNIĘTE na stos. Po wylogowaniu AuthGate przełącza swój home na ekran
logowania, ale pushnięte ekrany zostają na wierzchu i odpytują portfel bez sesji → 400. Z ekranu głównego
(niepushnięty) było OK. Fix: globalny `navigatorKey` + `popUntil(isFirst)` przy `session==null`.
