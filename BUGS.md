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

## 5. `fetch-crypto`: CoinGecko HTTP 429 (mail alertowy) — 🐛 do naprawy (backend)
Cron `fetch-crypto` (CoinGecko top-100, co 5 min) dostał **429 Too Many Requests** i wysłał alert.
Przyczyna: limit free CoinGecko (public/demo). Możliwe: brak klucza demo (`x-cg-demo-api-key`),
za częsty cron, albo współdzielone IP. Kierunki naprawy (backend, sesja EODHD/providerów):
- dodać sekret `COINGECKO_API_KEY` (demo plan) + nagłówek → wyższy limit;
- ew. rzadszy cron (co 10 min) albo backoff/retry na 429;
- **alert powinien tolerować przejściowe 429** — nie mailować przy pojedynczym rate-limicie
  (jak `damaged_assets` dla Twelve Data), tylko gdy utrzymuje się N prób (inaczej spam).
Uwaga: krypto i tak może iść do wymiany źródła razem z cutoverem providerów.
