# Bugi — abundapp (tracker)

## 🐛 Otwarte
- (brak)

## ✅ Naprawione (ta sesja)

| # | Bug | Fix |
|---|-----|-----|
| 1 | Portfel pada po dniu (token 401) | front `_freshHeaders` (`d0913ea`) |
| 2a | Obligacje „Transakcje +0" | back holding_id (`6569197`) |
| 2b | Obligacje 3-podział (+ Odsetki) | back `b636522` + front `e8bf63a` |
| 2c | „Od wczoraj" Ruch ceny −8997 | front captured_at okna (`420d4a0`) |
| — baseline wizyty gubił odsetki | front `979a007` |
| 5 | CoinGecko 429 (mail) | naprawione w backendzie |
| 6 | Podgląd USD → 400 | back `aa42443` |
| 7 | 2× AAPL (duplikaty market) | back merge (`3e5792c`) |
| 8 | Wykres bez bieżącej wartości | front punkt „teraz" (`6f07095`) |
| 9 | Wykres pozycji manual = 0 | back value-history `(asset_id ?? id)` (`3e5792c`) |
| 10/12 | Logout z asset/kategorii → 400 | front navigatorKey + popUntil |
| 11 | Akcja eodhd (Bogdanka): 0 + brak ledgera | back on-demand EODHD (`1b2a3bd`) |

## 🧹 Do ręcznego sprzątnięcia w apce (dane, nie kod)
- **Duplikaty AAPL** sprzed fixu #7 — skasuj nadmiarowe pozycje (przyszłe dodania już się sumują).
- **Bogdanka dodana przed #11** — bez wpisu w ledgerze; usuń i dodaj ponownie (po deployu `1b2a3bd`).

## 🔁 Do ponownego przetestowania na świeżym buildzie
- Wykres „wartość w czasie" (świeże konta / dane demo) — robiliśmy dużo zmian (punkt „teraz" #8,
  value-history dla manuali #9, snapshoty z interest_ratio). Wcześniejsze obserwacje (brak danych dla
  nowego konta, prosta linia demo2) — przetestować od nowa, bo kontekst się zmienił.

## ⚠️ Znana łagodna degradacja (nie blokuje)
- 3-podział PnL „od wczoraj/tygodnia…" dla obligacji jest dokładny dopiero od snapshotów zapisanych
  PO deployu `interest_ratio`. Stare snapshoty/baseline bez tego pola → odsetki w oknie mogą być
  zawyżone (kompensowane w „ruchu ceny"). „Od początku" zawsze dokładne. Wyrówna się z czasem.
