import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/features/dashboard/dashboard_context.dart';
import 'package:abundapp/l10n/app_localizations_pl.dart';

void main() {
  final l = AppLocalizationsPl();

  group('categoryLabel', () {
    test('tłumaczy znane kategorie na PL', () {
      expect(categoryLabel(l, 'crypto'), 'Krypto');
      expect(categoryLabel(l, 'stock'), 'Akcje');
      expect(categoryLabel(l, 'etf'), 'ETF-y');
      expect(categoryLabel(l, 'metal'), 'Metale');
      expect(categoryLabel(l, 'currency'), 'Gotówka');
    });

    test('kategorie manualne mają polskie etykiety', () {
      expect(categoryLabel(l, 'real_estate'), 'Nieruchomości');
      expect(categoryLabel(l, 'bonds'), 'Obligacje');
    });

    test('nieznana kategoria → surowe id (fallback bez crasha)', () {
      expect(categoryLabel(l, 'zzz_unknown'), 'zzz_unknown');
    });
  });

  group('DashboardContext', () {
    test('all: top-level, brak category/asset', () {
      const ctx = DashboardContext.all();
      expect(ctx.level, DashboardLevel.all);
      expect(ctx.isTopLevel, true);
      expect(ctx.categoryId, isNull);
      expect(ctx.assetId, isNull);
      expect(ctx.title(l), 'Mój portfel');
    });

    test('category: tytuł = label kategorii, nie top-level', () {
      const ctx = DashboardContext.category('crypto');
      expect(ctx.level, DashboardLevel.category);
      expect(ctx.isTopLevel, false);
      expect(ctx.categoryId, 'crypto');
      expect(ctx.assetId, isNull);
      expect(ctx.title(l), 'Krypto');
    });

    test('asset: tytuł = ticker, trzyma kategorię i asset', () {
      const ctx = DashboardContext.asset('crypto', 'BTC');
      expect(ctx.level, DashboardLevel.asset);
      expect(ctx.isTopLevel, false);
      expect(ctx.categoryId, 'crypto');
      expect(ctx.assetId, 'BTC');
      expect(ctx.title(l), 'BTC');
    });
  });
}
