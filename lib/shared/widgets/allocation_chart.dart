import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/holding.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/dashboard/dashboard_context.dart';
import '../../l10n/app_localizations.dart';
import 'asset_avatar.dart';
import 'chart_reveal.dart';
import 'chart_segments.dart';
import 'redirect_rows.dart';

class AllocationChart extends ConsumerWidget {
  final DashboardContext dashContext;
  final int? selectedIndex;
  final void Function(int idx, String id) onSegmentTap;

  const AllocationChart({
    super.key,
    required this.dashContext,
    required this.selectedIndex,
    required this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);

    return portfolioAsync.when(
      loading: () => const _ChartSkeleton(),
      error: (err, st) => const SizedBox.shrink(),
      data: (portfolio) {
        final segments =
            buildChartSegments(portfolio.holdings, dashContext, AppLocalizations.of(context));
        if (segments.isEmpty) return const SizedBox.shrink();

        final total = segments.fold(0.0, (sum, s) => sum + s.value);

        // Aktywa przeniesione stąd do innej kategorii (display_category) — np.
        // ETF pokazywany w „Obligacje". Dopinamy je do listy wyszarzone, żeby
        // user szukający w kategorii natywnej nie zgubił aktywa.
        final redirected = dashContext.level == DashboardLevel.category
            ? redirectedHoldings(portfolio.holdings, dashContext.categoryId!)
            : const <Holding>[];

        return ChartReveal(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...segments.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final percent = total > 0 ? s.value / total * 100 : 0.0;
                final color = AppColors
                    .categoryColors[i % AppColors.categoryColors.length];
                final isSelected = i == selectedIndex;
                final isDimmed = selectedIndex != null && !isSelected;

                return _BarRow(
                  color: color,
                  label: s.label,
                  percent: percent,
                  value: s.value,
                  currency: portfolio.currency,
                  leading: dashContext.level == DashboardLevel.all
                      ? AssetAvatar.category(s.id, size: 22, ringColor: color)
                      : AssetAvatar.asset(
                          assetId: s.id,
                          category: dashContext.categoryId!,
                          size: 22,
                          ringColor: color,
                        ),
                  isSelected: isSelected,
                  isDimmed: isDimmed,
                  onTap: () => onSegmentTap(i, s.id),
                );
              }),
              if (redirected.isNotEmpty) ...[
                const RedirectDivider(),
                ...redirected.map((h) => RedirectRow(holding: h)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// --- Wiersz słupka ---

class _BarRow extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  final double value;
  final String currency;
  final Widget leading;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _BarRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.value,
    required this.currency,
    required this.leading,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDimmed ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 8),
              // Nazwa — jedna linia z „…", żeby długie jednowyrazowe nazwy
              // (Nieruchomości, Kosztowności) nie łamały się w środku słowa.
              SizedBox(
                width: 76,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Słupek
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(color: AppColors.surfaceElevated),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        widthFactor: percent / 100,
                        alignment: Alignment.centerLeft,
                        child: Container(color: color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Procent
              SizedBox(
                width: 34,
                child: Text(
                  '${percent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
              // Indykator nawigacji
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: isSelected
                    ? const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.arrow_forward_ios,
                            color: AppColors.textSecondary, size: 11),
                      )
                    : const SizedBox(width: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Skeleton ---

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(width: 68, height: 13, color: AppColors.surfaceElevated),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 20, color: AppColors.surfaceElevated)),
              const SizedBox(width: 10),
              Container(width: 34, height: 13, color: AppColors.surfaceElevated),
            ],
          ),
        ),
      ),
    );
  }
}
