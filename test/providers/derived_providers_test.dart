import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abundapp/core/models/holding.dart';
import 'package:abundapp/core/models/portfolio.dart';
import 'package:abundapp/core/providers/portfolio_provider.dart';
import 'package:abundapp/core/providers/top_movers_provider.dart';
import 'package:abundapp/features/dashboard/dashboard_context.dart';

Holding _h(String id, String cat, double priceUsd, double valueCcy) => Holding(
      assetId: id,
      category: cat,
      amount: 1,
      priceUsd: priceUsd,
      valueUsd: valueCcy,
      valueCcy: valueCcy,
    );

Portfolio _portfolio(String currency, List<Holding> holdings) =>
    Portfolio(currency: currency, holdings: holdings);

void main() {
  group('displayCurrencyProvider', () {
    test('sel != null → zwraca wybraną walutę', () {
      final c = ProviderContainer(overrides: [
        selectedCurrencyProvider.overrideWith((ref) => 'EUR'),
      ]);
      addTearDown(c.dispose);
      expect(c.read(displayCurrencyProvider), 'EUR');
    });

    test('sel == null → waluta z portfela', () async {
      final c = ProviderContainer(overrides: [
        portfolioProvider.overrideWith((ref) async => _portfolio('USD', [])),
      ]);
      addTearDown(c.dispose);
      await c.read(portfolioProvider.future);
      expect(c.read(displayCurrencyProvider), 'USD');
    });

    test('sel == null i portfel jeszcze nie załadowany → fallback PLN', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      // portfolioProvider próbowałby sieci, ale nie awaitujemy — valueOrNull null.
      expect(c.read(displayCurrencyProvider), 'PLN');
    });
  });

  group('pnlProvider', () {
    test('current null → null', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(pnlProvider), isNull);
    });

    test('brak snapshotu → 0 (pierwsze uruchomienie)', () async {
      final c = ProviderContainer(overrides: [
        portfolioProvider.overrideWith(
            (ref) async => _portfolio('PLN', [_h('BTC', 'crypto', 100, 500)])),
        periodSnapshotProvider.overrideWith((ref) async => null),
      ]);
      addTearDown(c.dispose);
      await c.read(portfolioProvider.future);
      await c.read(periodSnapshotProvider.future);
      expect(c.read(pnlProvider), 0);
    });

    test('snapshot bez pozycji (pusty last-visit) → 0, nie cała wartość',
        () async {
      final c = ProviderContainer(overrides: [
        portfolioProvider.overrideWith(
            (ref) async => _portfolio('PLN', [_h('BTC', 'crypto', 100, 500)])),
        periodSnapshotProvider.overrideWith((ref) async => _portfolio('PLN', [])),
      ]);
      addTearDown(c.dispose);
      await c.read(portfolioProvider.future);
      await c.read(periodSnapshotProvider.future);
      expect(c.read(pnlProvider), 0);
    });

    test('current - snapshot (po totalValueCcy)', () async {
      final c = ProviderContainer(overrides: [
        portfolioProvider.overrideWith(
            (ref) async => _portfolio('PLN', [_h('BTC', 'crypto', 110, 550)])),
        periodSnapshotProvider.overrideWith(
            (ref) async => _portfolio('PLN', [_h('BTC', 'crypto', 100, 500)])),
      ]);
      addTearDown(c.dispose);
      await c.read(portfolioProvider.future);
      await c.read(periodSnapshotProvider.future);
      expect(c.read(pnlProvider), 50);
    });
  });

  group('topMoversProvider', () {
    test('poziom ASSET → pusta lista', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final movers =
          c.read(topMoversProvider(const DashboardContext.asset('crypto', 'BTC')));
      expect(movers, isEmpty);
    });

    test('liczy pricePct vs snapshot; nowe aktywa na końcu', () async {
      final c = ProviderContainer(overrides: [
        portfolioProvider.overrideWith((ref) async => _portfolio('PLN', [
              _h('BTC', 'crypto', 110, 550), // +10%
              _h('ETH', 'crypto', 90, 450), // -10%
              _h('NEW', 'crypto', 5, 5), // brak w snapshocie → isNew
            ])),
        periodSnapshotProvider.overrideWith((ref) async => _portfolio('PLN', [
              _h('BTC', 'crypto', 100, 500),
              _h('ETH', 'crypto', 100, 500),
            ])),
      ]);
      addTearDown(c.dispose);
      await c.read(portfolioProvider.future);
      await c.read(periodSnapshotProvider.future);

      final movers = c.read(topMoversProvider(const DashboardContext.all()));
      expect(movers.length, 3);
      // Nowe aktywo (bez odniesienia) na końcu.
      expect(movers.last.assetId, 'NEW');
      expect(movers.last.isNew, true);
      // Pozostałe mają policzone pricePct.
      final btc = movers.firstWhere((m) => m.assetId == 'BTC');
      final eth = movers.firstWhere((m) => m.assetId == 'ETH');
      expect(btc.pricePct, closeTo(10, 1e-9));
      expect(eth.pricePct, closeTo(-10, 1e-9));
    });

    test('poziom CATEGORY filtruje aktywa po kategorii', () async {
      final c = ProviderContainer(overrides: [
        portfolioProvider.overrideWith((ref) async => _portfolio('PLN', [
              _h('BTC', 'crypto', 110, 550),
              _h('AAPL', 'stock', 90, 450),
            ])),
        periodSnapshotProvider.overrideWith((ref) async => _portfolio('PLN', [
              _h('BTC', 'crypto', 100, 500),
              _h('AAPL', 'stock', 100, 500),
            ])),
      ]);
      addTearDown(c.dispose);
      await c.read(portfolioProvider.future);
      await c.read(periodSnapshotProvider.future);

      final movers =
          c.read(topMoversProvider(const DashboardContext.category('crypto')));
      expect(movers.map((m) => m.assetId).toList(), ['BTC']);
    });
  });
}
