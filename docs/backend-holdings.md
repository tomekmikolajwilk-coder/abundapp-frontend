# Dodawanie aktywów — kontrakt dla backendu

Frontend ma już gotowy kreator dodawania aktywa (semi-wizard) i edycję wartości
aktywów manualnych. Działa na **tymczasowym lokalnym merge** (`localHoldingsProvider`)
— aktywa dodane w apce żyją tylko w pamięci sesji. Ten dokument opisuje endpointy,
które backend musi dostarczyć, żeby aktywa trwale zapisywać.

Gdy endpointy będą gotowe: usunąć `localHoldingsProvider` i jego merge w
`livePreferredPortfolioProvider`, a `addHolding` / `updateHolding` / `deleteHolding`
(już są w `lib/core/api/portfolio_api.dart`) podpiąć do submitu kreatora i edytora.

## Kręgosłup: dwie klasy aktywów (`price_source`)

Każdy holding ma pole `price_source`:

- **`market`** — cenę zna backend (krypto, akcje, ETF, metale, waluty). User
  podaje tylko `amount`. Wartość liczy backend z `price_cache`.
- **`manual`** — cenę podaje user (nieruchomości, kosztowności, obligacje, lokaty,
  inne). User podaje `amount` + `unit_value` (w walucie preferowanej). Wartość =
  `amount × unit_value`.

`GET /portfolio` musi w każdej pozycji `holdings_breakdown` zwracać dodatkowo:

```jsonc
{
  "asset_id": "...",          // ticker (market) lub nazwa (manual)
  "category": "real_estate",  // kategoria bazowa
  "amount": 1,
  "price_usd": 0,
  "value_usd": 162500,
  "value_ccy": 650000,
  "price_source": "manual",        // NOWE: market | manual
  "name": "Mieszkanie Kraków",     // NOWE: nazwa custom assetu (manual); null dla market
  "display_category": "bonds",     // NOWE: kategoria wyświetlania (ETF→obligacje); null = jak category
  "interest_rate": 5               // NOWE: roczna stopa % (obligacje); null gdy brak
}
```

Frontend już czyta te pola (z domyślnymi: `price_source` → `market`, reszta null),
więc dodanie ich jest wstecznie kompatybilne.

## Kategorie

- Market: `crypto`, `stock`, `etf`, `metal`, `currency` (są).
- Manual (nowe): `real_estate`, `valuables`, `bonds`, `deposits`, `other`.

## Endpointy

### `POST /holdings`

Dodaje aktywo do portfela zalogowanego usera (user_id z JWT `sub`).

Market:
```json
{ "category": "crypto", "asset_id": "BTC", "amount": 0.5 }
```

Manual:
```json
{
  "category": "real_estate",
  "amount": 1,
  "custom": {
    "name": "Mieszkanie Kraków",
    "unit_value": 650000,
    "currency": "PLN",
    "display_category": null,
    "interest_rate": null
  }
}
```

- ETF z przeniesieniem do innej kategorii: `category: "etf"`, `custom.display_category: "bonds"`.
  (Uwaga: ETF jest market, ale `display_category` go dotyczy — można przyjąć
  `display_category` także poza obiektem `custom` dla aktywów market.)
- Kategoria `other` to furtka na nieobsługiwane aktywa (np. akcja spoza obsługiwanych) —
  jest manual i również przyjmuje `display_category` (user kieruje ją np. do „Akcje").
- Obligacje: `category: "bonds"`, `custom.interest_rate: 5`.

### display_category — uwaga UX (już zrobione na froncie)

Front grupuje aktywa po `display_category ?? category`. Aktywo przeniesione znika
z kategorii natywnej, więc w niej pokazujemy „drogowskaz" (referencję bez wartości)
prowadzący tam, gdzie aktywo się wyświetla. Backend nie musi nic dodawać — wystarczy,
że zwraca `category` (natywną) i `display_category` w każdym holdingu.
- Zwraca utworzony holding (z `id`) albo 201.

### `PATCH /holdings/:id`

Zmiana ilości i/lub wartości jednostki (np. nowa wycena mieszkania):
```json
{ "amount": 1, "unit_value": 720000 }
```

### `DELETE /holdings/:id`

Usuwa holding.

## Obligacje — naliczanie odsetek (DECYZJA: model liniowy)

User podaje `interest_rate` (np. 5 = 5% rocznie). Wartość obligacji **rośnie sama**
(nie dopisujemy do gotówki).

**Model liniowy** (odsetki od nominału, kapitalizacja roczna — jak polskie
obligacje detaliczne):

```
value(dni) = principal × (1 + rate/100 × dni_od_zakupu / 365)
```

Przykład: 100 obligacji × 1 zł = 100 zł, rate 5% → po roku dokładnie 105 zł.

**Krytyczne:** NIE inkrementować wartości co noc (`value += ...`). Pominięty run
crona = utracony dzień, podwójny run = podwójne odsetki. Zamiast tego przechowywać
`principal` + `rate` + `start_date` i **wyliczać wartość od zera** z liczby dni —
deterministycznie, idempotentnie. Cron tylko przelicza bieżącą wartość.

(Wariant alternatywny — składany `principal × (1 + rate/365)^dni` — daje 105,13 zł
po roku. Odrzucony: różnica 13 gr/100 zł nie jest warta komplikacji, a liniowy
lepiej odwzorowuje obligacje detaliczne.)

## Odłożone

- **Dywidendy od akcji** — wymaga danych dywidendowych (yield, daty ex-div), których
  free-tier API nie daje. Parkujemy. Gdy wrócimy: pole `dividend` w `custom`
  (yield % + tryb `accumulate` / `cash`).
