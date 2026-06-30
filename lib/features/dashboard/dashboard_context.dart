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

  String get title => switch (level) {
        DashboardLevel.all => 'Mój portfel',
        DashboardLevel.category => categoryLabel(categoryId!),
        DashboardLevel.asset => assetId!,
      };

  bool get isTopLevel => level == DashboardLevel.all;
}

String categoryLabel(String id) => switch (id) {
      'crypto' => 'Krypto',
      'stock' => 'Akcje',
      'etf' => 'ETF-y',
      'metal' => 'Metale',
      'currency' => 'Gotówka',
      'real_estate' => 'Nieruchomości',
      'valuables' => 'Kosztowności',
      'bonds' => 'Obligacje',
      'deposits' => 'Lokaty',
      'other' => 'Inne',
      // Sentinel z backendu (asset bez kategorii) — nigdy nie pokazuj surowego „unknown" userowi.
      'unknown' => 'Inne',
      _ => id,
    };
