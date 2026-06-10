import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/allocation_chart.dart';
import '../../shared/widgets/donut_chart.dart';
import '../../shared/widgets/pnl_header.dart';
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
                    _SectionPlaceholder(label: 'Wykres wartości w czasie'),
                    const SizedBox(height: 16),
                    _SectionPlaceholder(label: 'Top movers'),
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

class _SectionPlaceholder extends StatelessWidget {
  final String label;

  const _SectionPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated, width: 1),
      ),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
      ),
    );
  }
}
