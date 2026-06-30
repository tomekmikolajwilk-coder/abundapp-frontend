import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/holding.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../features/dashboard/dashboard_context.dart';
import 'asset_avatar.dart';
import 'chart_reveal.dart';
import 'chart_segments.dart';
import 'redirect_rows.dart';

class DonutChart extends ConsumerWidget {
  final DashboardContext dashContext;
  final int? selectedIndex;
  final void Function(int idx, String id) onSegmentTap;

  const DonutChart({
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
        final segments = buildChartSegments(portfolio.holdings, dashContext);
        if (segments.isEmpty) return const SizedBox.shrink();

        final total = segments.fold(0.0, (sum, s) => sum + s.value);
        final selected = selectedIndex != null ? segments[selectedIndex!] : null;
        final redirected = dashContext.level == DashboardLevel.category
            ? redirectedHoldings(portfolio.holdings, dashContext.categoryId!)
            : const <Holding>[];

        return ChartReveal(
          child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    PieChartData(
                      sections: segments.asMap().entries.map((e) {
                        final i = e.key;
                        final s = e.value;
                        final isSelected = i == selectedIndex;
                        final color = AppColors.categoryColors[i % AppColors.categoryColors.length];
                        return PieChartSectionData(
                          value: s.value,
                          color: isSelected
                              ? color
                              : color.withValues(alpha: selectedIndex == null ? 1.0 : 0.4),
                          radius: isSelected ? 76 : 64,
                          title: '',
                          borderSide: isSelected
                              ? BorderSide(color: color.withValues(alpha: 0.6), width: 3)
                              : BorderSide.none,
                        );
                      }).toList(),
                      centerSpaceRadius: 60,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final idx = response?.touchedSection?.touchedSectionIndex;
                          if (idx == null || idx < 0) return;
                          onSegmentTap(idx, segments[idx].id);
                        },
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected != null
                        ? _SelectedLabel(
                            key: ValueKey(selected.id),
                            segment: selected,
                            total: total,
                            onGo: () => onSegmentTap(selectedIndex!, selected.id),
                          )
                        : _DefaultLabel(
                            key: const ValueKey('default'),
                            label: dashContext.level == DashboardLevel.all
                                ? 'Portfel'
                                : dashContext.title,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...segments.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final percent = total > 0 ? s.value / total * 100 : 0.0;
              final color = AppColors.categoryColors[i % AppColors.categoryColors.length];
              return _LegendRow(
                color: color,
                label: s.label,
                percent: percent,
                value: s.value,
                currency: portfolio.currency,
                leading: dashContext.level == DashboardLevel.all
                    ? AssetAvatar.category(s.id, size: 28, ringColor: color)
                    : AssetAvatar.asset(
                        assetId: s.id,
                        category: dashContext.categoryId!,
                        size: 28,
                        ringColor: color,
                      ),
                isSelected: i == selectedIndex,
                isDimmed: selectedIndex != null && i != selectedIndex,
                onTap: () => onSegmentTap(i, s.id),
              );
            }),
            // Aktywa przeniesione stąd do innej kategorii — wyszarzone, pod linią.
            if (redirected.isNotEmpty) ...[
              const SizedBox(height: 8),
              const RedirectDivider(),
              ...redirected.map((h) => RedirectRow(holding: h, avatarSize: 28)),
            ],
          ],
        ),
        );
      },
    );
  }
}

// --- Środek wykresu ---

class _DefaultLabel extends StatelessWidget {
  final String label;
  const _DefaultLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '100%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _SelectedLabel extends StatelessWidget {
  final ChartSegment segment;
  final double total;
  final VoidCallback onGo;

  const _SelectedLabel({
    super.key,
    required this.segment,
    required this.total,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? segment.value / total * 100 : 0.0;
    return GestureDetector(
      onTap: onGo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            segment.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Otwórz',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Legenda ---

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  final double value;
  final String currency;
  final Widget leading;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _LegendRow({
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
      opacity: isDimmed ? 0.35 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  // Bezpiecznik na długie nazwy katalogowe (EODHD bywa 60+ znaków) —
                  // maks 2 linie, reszta „…", żeby nie rozsypać wiersza.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                moneyCcy(value, currency),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
