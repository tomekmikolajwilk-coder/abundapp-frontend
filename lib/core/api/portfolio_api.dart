import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/portfolio.dart';

const _baseUrl = functionsBaseUrl;

// Edge Functions są zabezpieczone JWT — user_id wyprowadzają z `sub` tokena,
// więc nie wysyłamy go już w query. Liczy się access token zalogowanego usera
// w nagłówku Authorization (fallback do anon key tylko dla publicznych zasobów
// jak /assets, gdy sesji jeszcze nie ma).
Map<String, String> get _headers {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
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
  final response = await http.get(uri, headers: _headers);

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
  final response = await http.get(uri, headers: _headers);

  if (response.statusCode == 200) {
    var json = jsonDecode(response.body) as Map<String, dynamic>;
    if (currency != null) json = remapSelectedCurrency(json, currency);
    return Portfolio.fromJson(json);
  }
  if (response.statusCode == 404) return null;
  throw Exception('Failed to load snapshot: ${response.statusCode}');
}

/// Lista dostępnych walut (kategoria `currency` z /assets) — do pickera.
Future<List<String>> fetchCurrencies() async {
  final uri = Uri.parse('$_baseUrl/assets');
  final response = await http.get(uri, headers: _headers);
  if (response.statusCode != 200) return [];

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final list = (json['currency'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>()
      .map((c) => c['asset_id'] as String)
      .toList()
    ..sort();
  return list;
}

Future<List<String>> fetchSnapshotDates() async {
  final uri = Uri.parse('$_baseUrl/snapshot-dates');
  final response = await http.get(uri, headers: _headers);

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
  final response = await http.get(uri, headers: _headers);
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
