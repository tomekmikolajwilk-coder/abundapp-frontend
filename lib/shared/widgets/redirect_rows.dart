import 'package:flutter/material.dart';
import '../../core/models/holding.dart';
import '../../core/theme/app_theme.dart';
import '../../features/dashboard/dashboard_context.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../l10n/app_localizations.dart';
import 'asset_avatar.dart';

/// Aktywa natywne kategorii [categoryId], ale przeniesione do wyświetlania
/// w innej kategorii (display_category) — np. ETF pokazywany w „Obligacje".
/// Współdzielone przez listę słupkową i legendę donuta.
List<Holding> redirectedHoldings(List<Holding> holdings, String categoryId) =>
    holdings
        .where((h) => h.category == categoryId && h.groupCategory != categoryId)
        .toList();

/// Cienka linia z labelką oddzielająca aktywa pokazywane gdzie indziej.
class RedirectDivider extends StatelessWidget {
  const RedirectDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.surfaceElevated, height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('pokazywane w innych kategoriach',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
          Expanded(child: Divider(color: AppColors.surfaceElevated, height: 1)),
        ],
      ),
    );
  }
}

/// Wyszarzony wiersz-drogowskaz: aktywo natywne tej kategorii, ale wyświetlane
/// w innej. Klik przenosi do aktywa tam, gdzie się pokazuje.
class RedirectRow extends StatelessWidget {
  final Holding holding;
  final double avatarSize;
  const RedirectRow({super.key, required this.holding, this.avatarSize = 22});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              context: DashboardContext.asset(
                  holding.groupCategory, holding.assetId),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              AssetAvatar.asset(
                  assetId: holding.assetId,
                  category: holding.category,
                  size: avatarSize),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${holding.displayName}  →  ${categoryLabel(AppLocalizations.of(context), holding.groupCategory)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
