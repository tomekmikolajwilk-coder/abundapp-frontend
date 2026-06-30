import '../../l10n/app_localizations.dart';

enum DashboardLevel { all, category, asset }

class DashboardContext {
  final DashboardLevel level;
  final String? categoryId; // np. "crypto"
  final String? assetId;    // np. "BTC"

  const DashboardContext.all()
      : level = DashboardLevel.all,
        categoryId = null,
        assetId = null;

  const DashboardContext.category(String category)
      : level = DashboardLevel.category,
        categoryId = category,
        assetId = null;

  const DashboardContext.asset(String category, String asset)
      : level = DashboardLevel.asset,
        categoryId = category,
        assetId = asset;

  String title(AppLocalizations l) => switch (level) {
        DashboardLevel.all => l.myPortfolio,
        DashboardLevel.category => categoryLabel(l, categoryId!),
        DashboardLevel.asset => assetId!,
      };

  bool get isTopLevel => level == DashboardLevel.all;
}

String categoryLabel(AppLocalizations l, String id) => switch (id) {
      'crypto' => l.categoryCrypto,
      'stock' => l.categoryStock,
      'etf' => l.categoryEtf,
      'metal' => l.categoryMetal,
      'currency' => l.categoryCurrency,
      'real_estate' => l.categoryRealEstate,
      'valuables' => l.categoryValuables,
      'bonds' => l.categoryBonds,
      'deposits' => l.categoryDeposits,
      'other' => l.categoryOther,
      // Sentinel z backendu (asset bez kategorii) — nigdy nie pokazuj surowego „unknown" userowi.
      'unknown' => l.categoryOther,
      _ => id,
    };
