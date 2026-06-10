import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/donut_chart.dart';
import '../../shared/widgets/pnl_header.dart';
import 'dashboard_context.dart';

class DashboardScreen extends StatefulWidget {
  final DashboardContext context;

  const DashboardScreen({
    super.key,
    this.context = const DashboardContext.all(),
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

                    if (widget.context.level != DashboardLevel.asset)
                      DonutChart(
                        dashContext: widget.context,
                        selectedIndex: _selectedChartIndex,
                        onSegmentTap: (idx, id) {
                          if (_selectedChartIndex == idx) {
                            _navigateDown(ctx, id);
                            _clearSelection();
                          } else {
                            setState(() {
                              _selectedChartIndex = idx;
                              _selectedSegmentId = id;
                            });
                          }
                        },
                      ),

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
