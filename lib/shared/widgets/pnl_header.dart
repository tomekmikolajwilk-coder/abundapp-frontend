import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/portfolio.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../features/dashboard/dashboard_context.dart';
import 'period_selector.dart';

class PnlHeader extends ConsumerWidget {
  final DashboardContext context;

  /// Gdy ustawione (segment zaznaczony na wykresie) — nadpisuje kontekst
  /// i pokazuje dane dla tej kategorii/assetu zamiast dla całego kontekstu.
  final String? selectedSegmentId;

  const PnlHeader({
    super.key,
    required this.context,
    this.selectedSegmentId,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final snapshotAsync = ref.watch(periodSnapshotProvider);

    return portfolioAsync.when(
      loading: () => const _PnlSkeleton(),
      error: (e, _) =>
          Text('Błąd: $e', style: const TextStyle(color: AppColors.negative)),
      data: (portfolio) {
        final snapshot = snapshotAsync.valueOrNull;

        final currentValue = _filteredValue(portfolio);
        final snapshotValue =
            snapshot != null ? _filteredValue(snapshot) : null;

        final effectivePnl =
            snapshotValue != null ? currentValue - snapshotValue : 0.0;
        final isPositive = effectivePnl >= 0;
        final base = currentValue - effectivePnl;
        final pnlPercent = base != 0 ? (effectivePnl / base) * 100 : 0.0;

        final valueLabel = _valueLabel();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PnL
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  moneySigned(effectivePnl, portfolio.currency),
                  style: Theme.of(ctx).textTheme.displayLarge?.copyWith(
                        color: isPositive
                            ? AppColors.positive
                            : AppColors.negative,
                      ),
                ),
                const SizedBox(width: 10),
                _PnlBadge(percent: pnlPercent, isPositive: isPositive),
              ],
            ),
            const SizedBox(height: 8),
            const PeriodSelector(),

            const SizedBox(height: 16),

            Text(valueLabel, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              moneyCcy(currentValue, portfolio.currency),
              style: Theme.of(ctx).textTheme.displayMedium,
            ),
          ],
        );
      },
    );
  }

  /// Wartość przefiltrowana wg aktualnego kontekstu + zaznaczonego segmentu
  double _filteredValue(Portfolio p) {
    // Segment zaznaczony na wykresie nadpisuje kontekst
    if (selectedSegmentId != null) {
      return switch (context.level) {
        DashboardLevel.all =>
          p.valueCcyForCategory(selectedSegmentId!),
        DashboardLevel.category =>
          p.valueCcyForAsset(selectedSegmentId!),
        DashboardLevel.asset => p.totalValueCcy,
      };
    }

    return switch (context.level) {
      DashboardLevel.all => p.totalValueCcy,
      DashboardLevel.category =>
        p.valueCcyForCategory(context.categoryId!),
      DashboardLevel.asset =>
        p.valueCcyForAsset(context.assetId!),
    };
  }

  String _valueLabel() {
    if (selectedSegmentId != null) {
      return switch (context.level) {
        DashboardLevel.all => 'Wartość kategorii $selectedSegmentId',
        DashboardLevel.category => 'Wartość $selectedSegmentId',
        DashboardLevel.asset => 'Wartość portfela',
      };
    }
    return switch (context.level) {
      DashboardLevel.all => 'Wartość portfela',
      DashboardLevel.category => 'Wartość ${context.title}',
      DashboardLevel.asset => 'Wartość ${context.assetId}',
    };
  }
}

class _PnlBadge extends StatelessWidget {
  final double percent;
  final bool isPositive;

  const _PnlBadge({required this.percent, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.positive : AppColors.negative)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPositive ? AppColors.positive : AppColors.negative,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              color: isPositive ? AppColors.positive : AppColors.negative,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PnlSkeleton extends StatelessWidget {
  const _PnlSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 160, height: 32),
        SizedBox(height: 12),
        _SkeletonBox(width: 220, height: 40),
        SizedBox(height: 16),
        _SkeletonBox(width: 100, height: 13),
        SizedBox(height: 4),
        _SkeletonBox(width: 180, height: 28),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
