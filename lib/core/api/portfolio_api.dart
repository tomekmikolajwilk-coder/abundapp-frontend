import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/portfolio.dart';

const _baseUrl = 'https://mrcjjyaljautuylpsssp.supabase.co/functions/v1';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yY2pqeWFsamF1dHV5bHBzc3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NjIxNjIsImV4cCI6MjA2NDUzODE2Mn0.9Fv4-e-4ntnxHXHFkRrnqFsqrXeq3VHCWdwKzGQhRLs';

// TODO: zastąpić user_id tokenem JWT gdy auth będzie gotowy
const _testUserId = '4ff2377f-a833-4a05-9930-391d84d4182d';

Map<String, String> get _headers => {
      'Authorization': 'Bearer $_anonKey',
      'Content-Type': 'application/json',
    };

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
  final params = {'user_id': _testUserId, 'currency': ?currency};
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
    'user_id': _testUserId,
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
  final uri = Uri.parse('$_baseUrl/snapshot-dates?user_id=$_testUserId');
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
    'user_id': _testUserId,
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
