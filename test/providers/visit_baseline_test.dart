import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abundapp/core/models/holding.dart';
import 'package:abundapp/core/models/portfolio.dart';
import 'package:abundapp/core/providers/portfolio_provider.dart';
import 'package:abundapp/core/providers/preferences_provider.dart';

const _key = 'visit_baseline_json';

Portfolio _portfolio(double valueCcy) => Portfolio(
      currency: 'PLN',
      holdings: [
        Holding(
          assetId: 'BTC',
          category: 'crypto',
          amount: 0.25,
          priceUsd: 66928,
          valueUsd: valueCcy,
          valueCcy: valueCcy,
        ),
      ],
    );

ProviderContainer _containerWith(SharedPreferences prefs) {
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build() bez zapisanego baseline → null', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _containerWith(prefs);
    addTearDown(c.dispose);

    expect(c.read(visitBaselineProvider), isNull);
  });

  test('build() z zapisanym baseline → parsuje portfel', () async {
    final stored = jsonEncode(_portfolio(500).toJson());
    SharedPreferences.setMockInitialValues({_key: stored});
    final prefs = await SharedPreferences.getInstance();
    final c = _containerWith(prefs);
    addTearDown(c.dispose);

    final baseline = c.read(visitBaselineProvider);
    expect(baseline, isNotNull);
    expect(baseline!.totalValueCcy, 500);
  });

  test('build() z uszkodzonym JSON → null (bez crasha)', () async {
    SharedPreferences.setMockInitialValues({_key: 'to-nie-json'});
    final prefs = await SharedPreferences.getInstance();
    final c = _containerWith(prefs);
    addTearDown(c.dispose);

    expect(c.read(visitBaselineProvider), isNull);
  });

  test('recordVisit zapisuje portfel do prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _containerWith(prefs);
    addTearDown(c.dispose);

    c.read(visitBaselineProvider.notifier).recordVisit(_portfolio(700));

    final saved = prefs.getString(_key);
    expect(saved, isNotNull);
    final restored =
        Portfolio.fromJson(jsonDecode(saved!) as Map<String, dynamic>);
    expect(restored.totalValueCcy, 700);
  });

  test('recordVisit działa raz na sesję — drugi zapis ignorowany', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = _containerWith(prefs);
    addTearDown(c.dispose);

    final notifier = c.read(visitBaselineProvider.notifier);
    notifier.recordVisit(_portfolio(700));
    notifier.recordVisit(_portfolio(999)); // powinno być zignorowane

    final restored = Portfolio.fromJson(
        jsonDecode(prefs.getString(_key)!) as Map<String, dynamic>);
    expect(restored.totalValueCcy, 700); // nadal pierwszy zapis
  });
}
