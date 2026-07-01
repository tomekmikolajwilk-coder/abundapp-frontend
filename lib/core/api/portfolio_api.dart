import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/available_asset.dart';
import '../models/portfolio.dart';
import '../models/transaction.dart';

const _baseUrl = functionsBaseUrl;

// Edge Functions są zabezpieczone JWT — user_id wyprowadzają z `sub` tokena,
// więc nie wysyłamy go już w query. Liczy się access token zalogowanego usera
// w nagłówku Authorization (fallback do anon key tylko dla publicznych zasobów
// jak /assets, gdy sesji jeszcze nie ma).
// Buduje nagłówki z aktualnym tokenem. Gdy access token wygasł (apka otwarta po
// dłuższym czasie — domyślny token żyje ~1h), najpierw odświeża sesję refresh-tokenem.
// Bez tego pierwszy request po wygaśnięciu leciał starym tokenem → 401 → „Failed to
// load portfolio" do czasu ręcznego re-logowania (bug #1).
Future<Map<String, String>> _freshHeaders() async {
  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await auth.refreshSession();
    } catch (_) {
      // Refresh-token też mógł wygasnąć — wtedy request dostanie 401, a AuthGate wyloguje.
    }
  }
  final token = auth.currentSession?.accessToken;
  return {
    'Authorization': 'Bearer ${token ?? supabaseAnonKey}',
    'apikey': supabaseAnonKey,
    'Content-Type': 'application/json',
  };
}

// Gdy poprosimy backend o ?currency=X, każdy holding dostaje dodatkowe pole
// `value_selected` (wartość w wybranej walucie, po dzisiejszym kursie). Aby
// reszta apki nie musiała znać tego pola, podmieniamy je na miejscu: value_ccy
// staje się wartością w wybranej walucie, a etykieta `currency` — wybraną
// walutą. Dzięki temu modele i widgety działają bez zmian.
@visibleForTesting
Map<String, dynamic> remapSelectedCurrency(
  Map<String, dynamic> json,
  String currency,
) {
  final holdings = (json['holdings_breakdown'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((h) => {
            ...h,
            'value_ccy': (h['value_selected'] as num?) ?? h['value_ccy'],
          })
      .toList();
  return {...json, 'currency': currency, 'holdings_breakdown': holdings};
}

Future<Portfolio> fetchPortfolio({String? currency}) async {
  final params = {'currency': ?currency};
  final uri =
      Uri.parse('$_baseUrl/portfolio').replace(queryParameters: params);
  final response = await http.get(uri, headers: await _freshHeaders());

  if (response.statusCode == 200) {
    var json = jsonDecode(response.body) as Map<String, dynamic>;
    if (currency != null) json = remapSelectedCurrency(json, currency);
    return Portfolio.fromJson(json);
  }
  throw Exception('Failed to load portfolio: ${response.statusCode}');
}

Future<Portfolio?> fetchPortfolioSnapshot(String date, {String? currency}) async {
  final params = {
    'date': date,
    'currency': ?currency,
  };
  final uri =
      Uri.parse('$_baseUrl/portfolio').replace(queryParameters: params);
  final response = await http.get(uri, headers: await _freshHeaders());

  if (response.statusCode == 200) {
    var json = jsonDecode(response.body) as Map<String, dynamic>;
    if (currency != null) json = remapSelectedCurrency(json, currency);
    return Portfolio.fromJson(json);
  }
  if (response.statusCode == 404) return null;
  throw Exception('Failed to load snapshot: ${response.statusCode}');
}

/// Aktywa rynkowe (cena znana backendowi) pogrupowane po kategorii — zasila
/// picker w kreatorze dodawania. Klucz = kategoria (`crypto`, `stock`, `etf`,
/// `metal`, `currency`), wartość = lista aktywów z ceną, posortowana po tickerze.
Future<Map<String, List<AvailableAsset>>> fetchMarketAssets() async {
  final uri = Uri.parse('$_baseUrl/assets');
  final response = await http.get(uri, headers: await _freshHeaders());
  if (response.statusCode != 200) return {};

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final result = <String, List<AvailableAsset>>{};
  for (final entry in json.entries) {
    if (entry.value is! List) continue;
    result[entry.key] = (entry.value as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(AvailableAsset.fromJson)
        .toList()
      ..sort((a, b) => a.assetId.compareTo(b.assetId));
  }
  return result;
}

/// Strona wyników `/assets/search` — lista + flaga `has_more` do paginacji.
class AssetSearchPage {
  final List<AvailableAsset> results;
  final bool hasMore;
  const AssetSearchPage({required this.results, required this.hasMore});
}

/// Search-as-you-type po katalogu aktywów (`/assets/search`, Faza 3). Używany
/// dla dużych katalogów (stock/ETF), gdzie `/assets` nie zwraca całości — tylko
/// to, co ma kurs w cache. Zwraca **metadane bez kursu** (held assety z ceną idą
/// przez /portfolio). Backend wymaga `q` (≥2 znaki) lub `category`.
Future<AssetSearchPage> searchAssets({
  String? q,
  String? category,
  String? exchange,
  int limit = 20,
  int offset = 0,
}) async {
  final params = {
    'q': ?q,
    'category': ?category,
    'exchange': ?exchange,
    'limit': '$limit',
    'offset': '$offset',
  };
  final uri =
      Uri.parse('$_baseUrl/assets/search').replace(queryParameters: params);
  final response = await http.get(uri, headers: await _freshHeaders());
  if (response.statusCode != 200) throw _apiException(response);

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final results = (json['results'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>()
      .map(AvailableAsset.fromJson)
      .toList();
  return AssetSearchPage(results: results, hasMore: json['has_more'] == true);
}

/// Błąd HTTP z naszego API — niesie kod statusu oraz maszynowy `code` (np.
/// "price_unavailable"), po którym UI mapuje błąd na ZLOKALIZOWANY komunikat.
/// `message` to human-readable fallback (może być po polsku — nie pokazujemy go userowi).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  ApiException(this.statusCode, this.message, [this.code]);
  @override
  String toString() => message;
}

/// Buduje ApiException z odpowiedzi: wyciąga `error`/`message` i maszynowy `code`.
ApiException _apiException(http.Response r) {
  String message = r.body.isNotEmpty ? r.body : 'HTTP ${r.statusCode}';
  String? code;
  try {
    final json = jsonDecode(r.body);
    if (json is Map) {
      final m = json['error'] ?? json['message'];
      if (m != null) message = m.toString();
      code = json['code'] as String?;
    }
  } catch (_) {}
  return ApiException(r.statusCode, message, code);
}

/// Dodaje aktywo do portfela i zwraca utworzony wiersz (zawiera `id`).
/// Market: `{ category, asset_id, amount, display_category? }`.
/// Manual:  `{ category, amount, custom: { name, unit_value, currency, ... } }`.
Future<Map<String, dynamic>> addHolding(Map<String, dynamic> body) async {
  final uri = Uri.parse('$_baseUrl/holdings');
  final response =
      await http.post(uri, headers: await _freshHeaders(), body: jsonEncode(body));
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw _apiException(response);
}

/// Aktualizuje ilość i/lub wartość jednostki holdingu. PATCH /holdings/:id.
/// `unit_value` tylko dla pozycji manual (na market backend zwróci 400).
Future<void> updateHolding(String id, Map<String, dynamic> body) async {
  final uri = Uri.parse('$_baseUrl/holdings/$id');
  final response =
      await http.patch(uri, headers: await _freshHeaders(), body: jsonEncode(body));
  if (response.statusCode >= 200 && response.statusCode < 300) return;
  throw _apiException(response);
}

/// Usuwa holding z portfela. DELETE /holdings/:id.
Future<void> deleteHolding(String id) async {
  final uri = Uri.parse('$_baseUrl/holdings/$id');
  final response = await http.delete(uri, headers: await _freshHeaders());
  if (response.statusCode >= 200 && response.statusCode < 300) return;
  throw _apiException(response);
}

/// Ledger transakcji (malejąco po dacie). `value_ccy` jest podpisana (buy +,
/// sell −) i w walucie `currency` (domyślnie preferowanej). Suma za okres =
/// przepływ netto; Ruch ceny = ΔWartość − Σ value_ccy.
Future<List<Transaction>> fetchTransactions({String? currency}) async {
  final params = {'currency': ?currency};
  final uri =
      Uri.parse('$_baseUrl/transactions').replace(queryParameters: params);
  final response = await http.get(uri, headers: await _freshHeaders());
  if (response.statusCode != 200) return [];

  final json = jsonDecode(response.body);
  final list = json is List
      ? json
      : (json as Map<String, dynamic>)['transactions'] as List<dynamic>? ?? [];
  return list
      .cast<Map<String, dynamic>>()
      .map(Transaction.fromJson)
      .toList();
}

/// Lista dostępnych walut (kategoria `currency` z /assets) — do pickera.
Future<List<String>> fetchCurrencies() async {
  final uri = Uri.parse('$_baseUrl/assets');
  final response = await http.get(uri, headers: await _freshHeaders());
  if (response.statusCode != 200) return [];

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final list = (json['currency'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>()
      .map((c) => c['asset_id'] as String)
      .toList();
  // USD jest walutą bazową — nie ma go w katalogu `currency`, ale backend
  // wspiera podgląd w USD, więc dokładamy go ręcznie.
  if (!list.contains('USD')) list.add('USD');
  list.sort();
  return list;
}

Future<List<String>> fetchSnapshotDates() async {
  final uri = Uri.parse('$_baseUrl/snapshot-dates');
  final response = await http.get(uri, headers: await _freshHeaders());

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['dates'] as List<dynamic>).cast<String>();
  }
  throw Exception('Failed to load snapshot dates: ${response.statusCode}');
}

Future<List<Map<String, dynamic>>> fetchSnapshotHistory({
  required String? categoryId,
  required String? assetId,
  String? currency,
}) async {
  // Jeden endpoint zwraca całą serię czasową — zamiast N osobnych requestów.
  final params = {
    'category_id': ?categoryId,
    'asset_id': ?assetId,
    'currency': ?currency,
  };
  final uri = Uri.parse('$_baseUrl/value-history').replace(queryParameters: params);
  final response = await http.get(uri, headers: await _freshHeaders());
  if (response.statusCode != 200) return [];

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return parseHistoryPoints(json, currency);
}

/// Przekształca surową odpowiedź /value-history na posortowaną listę punktów
/// {date, value, currency}. W trybie wybranej waluty (`currency != null`)
/// wartości i etykieta pochodzą z `value_selected`, w przeciwnym razie z
/// `value` i pola `currency` z odpowiedzi.
@visibleForTesting
List<Map<String, dynamic>> parseHistoryPoints(
  Map<String, dynamic> json,
  String? currency,
) {
  // W trybie wybranej waluty etykieta osi i wartości pochodzą z value_selected.
  final label = currency ?? json['currency'] as String?;
  final points = (json['points'] as List<dynamic>).cast<Map<String, dynamic>>();

  return points
      .map((p) => {
            'date': p['date'] as String,
            'value': ((currency != null ? p['value_selected'] : p['value']) as num)
                .toDouble(),
            'currency': label,
          })
      .toList()
    ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
}
