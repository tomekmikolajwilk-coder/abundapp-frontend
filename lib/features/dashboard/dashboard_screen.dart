import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/allocation_chart.dart';
import '../../shared/widgets/donut_chart.dart';
import '../../shared/widgets/pnl_header.dart';
import '../../shared/widgets/top_movers.dart';
import '../../shared/widgets/value_chart.dart';
import 'dashboard_context.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final DashboardContext context;

  const DashboardScreen({
    super.key,
    this.context = const DashboardContext.all(),
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _selectedChartIndex;
  String? _selectedSegmentId;

  @override
  Widget build(BuildContext ctx) {
    // Gdy portfel się załaduje, utrwalamy go jako baseline "ostatniej wizyty"
    // dla przyszłych sesji (raz na dobę; bieżący baseline pozostaje zamrożony).
    // Zawsze z wersji w walucie preferowanej — żeby podgląd w innej walucie nie
    // zatruł zapisywanego baseline'u.
    ref.listen(livePreferredPortfolioProvider, (_, next) {
      next.whenData(
        (p) => ref.read(visitBaselineProvider.notifier).recordVisit(p),
      );
    });

    return GestureDetector(
      onTap: _clearSelection,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                floating: true,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    if (!widget.context.isTopLevel)
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_back_ios,
                              color: AppColors.textPrimary, size: 18),
                        ),
                      ),
                    Text(
                      widget.context.title,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    if (widget.context.isTopLevel) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary, size: 20),
                    ],
                  ],
                ),
                actions: [
                  const _CurrencyButton(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    PnlHeader(
                      context: widget.context,
                      selectedSegmentId: _selectedSegmentId,
                    ),
                    const SizedBox(height: 32),

                    if (widget.context.level != DashboardLevel.asset) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: const _ChartTypePicker(),
                      ),
                      const SizedBox(height: 12),
                      _buildChart(ctx),
                    ],

                    const SizedBox(height: 24),
                    ValueChart(dashContext: widget.context),
                    const SizedBox(height: 24),
                    TopMovers(dashContext: widget.context),
                  ]),
                ),
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext ctx) {
    final chartType = ref.watch(preferencesProvider.select((p) => p['chart_type']));

    void onSegmentTap(int idx, String id) {
      if (_selectedChartIndex == idx) {
        _navigateDown(ctx, id);
        _clearSelection();
      } else {
        setState(() {
          _selectedChartIndex = idx;
          _selectedSegmentId = id;
        });
      }
    }

    return chartType == 'donut'
        ? DonutChart(
            dashContext: widget.context,
            selectedIndex: _selectedChartIndex,
            onSegmentTap: onSegmentTap,
          )
        : AllocationChart(
            dashContext: widget.context,
            selectedIndex: _selectedChartIndex,
            onSegmentTap: onSegmentTap,
          );
  }

  void _clearSelection() =>
      setState(() {
        _selectedChartIndex = null;
        _selectedSegmentId = null;
      });

  void _navigateDown(BuildContext ctx, String id) {
    final next = switch (widget.context.level) {
      DashboardLevel.all => DashboardContext.category(id),
      DashboardLevel.category =>
        DashboardContext.asset(widget.context.categoryId!, id),
      DashboardLevel.asset => null,
    };

    if (next != null) {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(context: next),
        ),
      );
    }
  }
}

class _ChartTypePicker extends ConsumerWidget {
  const _ChartTypePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(preferencesProvider.select((p) => p['chart_type']));
    final notifier = ref.read(preferencesProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypeButton(
          icon: Icons.bar_chart,
          active: current == 'bar',
          onTap: () => notifier.setChartType('bar'),
        ),
        _TypeButton(
          icon: Icons.donut_large_outlined,
          active: current == 'donut',
          onTap: () => notifier.setChartType('donut'),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TypeButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Icon(
          icon,
          color: active ? AppColors.textPrimary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

// --- Picker waluty wyświetlania ---
//
// Jednorazowy podgląd majątku w wybranej walucie (po dzisiejszym kursie).
// Pokazuje aktualną walutę; tap otwiera listę. Wybór waluty preferowanej
// resetuje podgląd (selectedCurrency = null).
class _CurrencyButton extends ConsumerWidget {
  const _CurrencyButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(displayCurrencyProvider);

    return GestureDetector(
      onTap: () => _openPicker(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CurrencySheet(),
    );
  }
}

class _CurrencySheet extends ConsumerWidget {
  const _CurrencySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currenciesAsync = ref.watch(currenciesProvider);
    final preferred =
        ref.watch(livePreferredPortfolioProvider).valueOrNull?.currency;
    final selected = ref.watch(selectedCurrencyProvider);
    // Walutą aktywną jest wybrana, a gdy brak — preferowana.
    final active = selected ?? preferred;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Pokaż wartość w walucie',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Przeliczenie po dzisiejszym kursie. Historia na wykresie jest '
                'projekcją bieżącego kursu, nie wartością z przeszłości.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            Flexible(
              child: currenciesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nie udało się pobrać walut',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                data: (currencies) {
                  // Preferowana na górze, reszta w kolejności alfabetycznej.
                  final ordered = [
                    if (preferred != null && currencies.contains(preferred))
                      preferred,
                    ...currencies.where((c) => c != preferred),
                  ];
                  return ListView(
                    shrinkWrap: true,
                    children: ordered
                        .map((c) => _CurrencyRow(
                              code: c,
                              isActive: c == active,
                              isPreferred: c == preferred,
                              onTap: () {
                                // Wybór waluty preferowanej = reset podglądu.
                                ref
                                    .read(selectedCurrencyProvider.notifier)
                                    .state = c == preferred ? null : c;
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final String code;
  final bool isActive;
  final bool isPreferred;
  final VoidCallback onTap;

  const _CurrencyRow({
    required this.code,
    required this.isActive,
    required this.isPreferred,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(
              code,
              style: TextStyle(
                color: isActive ? AppColors.accent : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isPreferred) ...[
              const SizedBox(width: 8),
              const Text(
                'preferowana',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
            const Spacer(),
            if (isActive)
              const Icon(Icons.check, color: AppColors.accent, size: 18),
          ],
        ),
      ),
    );
  }
}

