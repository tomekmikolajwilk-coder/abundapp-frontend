import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/features/dashboard/dashboard_context.dart';

void main() {
  group('categoryLabel', () {
    test('tłumaczy znane kategorie na PL', () {
      expect(categoryLabel('crypto'), 'Krypto');
      expect(categoryLabel('stock'), 'Akcje');
      expect(categoryLabel('etf'), 'ETF-y');
      expect(categoryLabel('metal'), 'Metale');
      expect(categoryLabel('currency'), 'Gotówka');
    });

    test('nieznana kategoria → surowe id (fallback bez crasha)', () {
      expect(categoryLabel('real_estate'), 'real_estate');
    });
  });

  group('DashboardContext', () {
    test('all: top-level, brak category/asset', () {
      const ctx = DashboardContext.all();
      expect(ctx.level, DashboardLevel.all);
      expect(ctx.isTopLevel, true);
      expect(ctx.categoryId, isNull);
      expect(ctx.assetId, isNull);
      expect(ctx.title, 'Mój portfel');
    });

    test('category: tytuł = label kategorii, nie top-level', () {
      const ctx = DashboardContext.category('crypto');
      expect(ctx.level, DashboardLevel.category);
      expect(ctx.isTopLevel, false);
      expect(ctx.categoryId, 'crypto');
      expect(ctx.assetId, isNull);
      expect(ctx.title, 'Krypto');
    });

    test('asset: tytuł = ticker, trzyma kategorię i asset', () {
      const ctx = DashboardContext.asset('crypto', 'BTC');
      expect(ctx.level, DashboardLevel.asset);
      expect(ctx.isTopLevel, false);
      expect(ctx.categoryId, 'crypto');
      expect(ctx.assetId, 'BTC');
      expect(ctx.title, 'BTC');
    });
  });
}
