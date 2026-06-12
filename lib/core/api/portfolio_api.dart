import 'dart:convert';
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

Future<Portfolio> fetchPortfolio() async {
  final uri = Uri.parse('$_baseUrl/portfolio?user_id=$_testUserId');
  final response = await http.get(uri, headers: _headers);

  if (response.statusCode == 200) {
    return Portfolio.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Failed to load portfolio: ${response.statusCode}');
}

Future<Portfolio?> fetchPortfolioSnapshot(String date) async {
  final uri = Uri.parse('$_baseUrl/portfolio?user_id=$_testUserId&date=$date');
  final response = await http.get(uri, headers: _headers);

  if (response.statusCode == 200) {
    return Portfolio.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  if (response.statusCode == 404) return null;
  throw Exception('Failed to load snapshot: ${response.statusCode}');
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
}) async {
  // Jeden endpoint zwraca całą serię czasową — zamiast N osobnych requestów.
  final params = {
    'user_id': _testUserId,
    'category_id': ?categoryId,
    'asset_id': ?assetId,
  };
  final uri = Uri.parse('$_baseUrl/value-history').replace(queryParameters: params);
  final response = await http.get(uri, headers: _headers);
  if (response.statusCode != 200) return [];

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final currency = json['currency'] as String?;
  final points = (json['points'] as List<dynamic>).cast<Map<String, dynamic>>();

  return points
      .map((p) => {
            'date': p['date'] as String,
            'value': (p['value'] as num).toDouble(),
            'currency': currency,
          })
      .toList()
    ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
}
