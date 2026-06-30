import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide ChartPoint;
import '../../core/models/chart_point.dart';
import '../../core/models/portfolio.dart';
import '../../core/providers/chart_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../features/dashboard/dashboard_context.dart';

class ValueChart extends ConsumerWidget {
  final DashboardContext dashContext;
  final bool isFullScreen;

  const ValueChart({
    super.key,
    required this.dashContext,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(chartDataProvider(dashContext));
    final range = ref.watch(chartRangeProvider);
    final currency = ref.watch(displayCurrencyProvider);
    // Bieżąca wartość (live) doklejana jako punkt „teraz" — świeże zakupy/zmiany widać
    // od razu, nie dopiero po następnym dziennym cron-snapshocie (bug 2). Liczona w tym
    // samym zakresie i walucie co historia.
    final live = ref.watch(portfolioProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nagłówek: tytuł + fullscreen
        Row(
          children: [
            Text(
              AppLocalizations.of(context).valueOverTime,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
            const Spacer(),
            // Fullscreen
            if (!isFullScreen)
              GestureDetector(
                onTap: () => _openFullScreen(context, ref),
                child: const Icon(Icons.fullscreen,
                    color: AppColors.textSecondary, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Wykres
        _ChartArea(
          isFullScreen: isFullScreen,
          child: dataAsync.when(
            loading: () => const _ChartSkeleton(),
            error: (e, _) => Center(
              child: Text('Błąd: $e',
                  style: const TextStyle(color: AppColors.negative, fontSize: 12)),
            ),
            data: (points) {
              final pts = live == null
                  ? points
                  : [
                      ...points,
                      ChartPoint(
                          date: DateTime.now(),
                          value: _scopedValue(live, dashContext)),
                    ];
              return pts.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context).noData,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    )
                  : _SfChart(points: pts, range: range, currency: currency);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Chipy zakresu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ChartRange.values
              .map((r) => _RangeChip(
                    label: r.label,
                    active: r == range,
                    onTap: () =>
                        ref.read(chartRangeProvider.notifier).state = r,
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, WidgetRef ref) {
    // Orientacją steruje wyłącznie _FullScreenChart (initState/dispose),
    // żeby uniknąć sprzecznych żądań w trakcie przejścia (iOS 16+).
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenChart(dashContext: dashContext),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Bieżąca wartość portfela w zakresie wykresu (lustro _filteredValue/_scopedInterest).
double _scopedValue(Portfolio p, DashboardContext ctx) => switch (ctx.level) {
      DashboardLevel.all => p.totalValueCcy,
      DashboardLevel.category => p.valueCcyForCategory(ctx.categoryId!),
      DashboardLevel.asset => p.valueCcyForAsset(ctx.assetId!),
    };

// --- Syncfusion chart ---

class _ChartArea extends StatelessWidget {
  final bool isFullScreen;
  final Widget child;

  const _ChartArea({required this.isFullScreen, required this.child});

  @override
  Widget build(BuildContext context) {
    // Delikatny panel z tłem i miękkim cieniem, żeby wykres ładnie się wyróżniał
    final panel = Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceElevated.withValues(alpha: 0.22),
            AppColors.surface.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

    return isFullScreen
        ? Expanded(child: panel)
        : SizedBox(height: 200, child: panel);
  }
}

class _SfChart extends StatelessWidget {
  final List<ChartPoint> points;
  final ChartRange range;
  final String currency;

  const _SfChart({required this.points, required this.range, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Okno startowe = wybrany zakres. Dane zostają pełne, więc można
    // przesuwać wykres w lewo do wcześniejszej historii.
    final now = DateTime.now();
    final days = range.days;
    final start = days == null ? null : now.subtract(Duration(days: days));
    // Gęstość etykiet osi X dopasowana do długości okna
    final xInterval = switch (range) {
      ChartRange.month => 5.0,
      ChartRange.quarter => 15.0,
      ChartRange.year => 60.0,
      ChartRange.all => null,
    };
    final xFormat = range == ChartRange.month
        ? DateFormat('d.MM')
        : DateFormat('MMM yy');

    return SfCartesianChart(
      // Zmiana zakresu wymusza przebudowę, żeby okno startowe się zaktualizowało
      key: ValueKey(range),
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
        intervalType: DateTimeIntervalType.days,
        interval: xInterval,
        dateFormat: xFormat,
        labelIntersectAction: AxisLabelIntersectAction.hide,
        // Okno startowe wg zakresu; null dla MAX (cała historia)
        initialVisibleMinimum: start,
        initialVisibleMaximum: start == null ? null : now,
      ),
      primaryYAxis: NumericAxis(
        // Y dopasowuje się do aktualnie widocznych punktów (przy zoom/pan)
        anchorRangeToVisiblePoints: true,
        rangePadding: ChartRangePadding.round,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          width: 1,
          color: AppColors.textSecondary.withValues(alpha: 0.08),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
        axisLabelFormatter: (args) =>
            ChartAxisLabel(compactNumber(args.value.toDouble()), null),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        zoomMode: ZoomMode.x,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.vertical,
        lineColor: AppColors.textSecondary.withValues(alpha: 0.4),
        lineWidth: 1,
        // Własny tooltip: data + wartość, żeby user wiedział jaki dzień tapnął
        builder: (context, details) {
          final date = details.point?.x;
          final value = details.point?.y;
          if (date == null || value == null) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moneyCcy(value.toDouble(), currency),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      series: <CartesianSeries>[
        AreaSeries<ChartPoint, DateTime>(
          dataSource: points,
          xValueMapper: (p, _) => p.date,
          yValueMapper: (p, _) => p.value,
          color: AppColors.accent.withValues(alpha: 0.15),
          borderColor: AppColors.accent,
          borderWidth: 2,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              AppColors.accent.withValues(alpha: 0.5),
              AppColors.accent.withValues(alpha: 0.2),
              AppColors.accent.withValues(alpha: 0.02),
            ],
          ),
        ),
      ],
    );
  }

}

// --- Range chip ---

class _RangeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// --- Full screen ---

class _FullScreenChart extends ConsumerWidget {
  final DashboardContext dashContext;

  const _FullScreenChart({required this.dashContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Apka jest zablokowana w pionie — wykres obracamy widgetem zamiast
    // ruszać orientacją urządzenia (to powodowało zacięcia symulatora).
    // Użytkownik obraca telefon fizycznie, treść jest już ułożona poziomo.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RotatedBox(
          quarterTurns: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            children: [
              Row(
                children: [
                  Text(
                    dashContext.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.fullscreen_exit,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueChart(
                  dashContext: dashContext,
                  isFullScreen: true,
                ),
              ),
            ],
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
