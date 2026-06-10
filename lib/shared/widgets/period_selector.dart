import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pnl_period.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPeriodProvider);
    final available = ref.watch(availablePeriodsProvider);

    return GestureDetector(
      onTap: () => _showPicker(context, ref, selected, available),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    PnlPeriod selected,
    List<PnlPeriod> available,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...available.map((period) => ListTile(
                  title: Text(
                    period.label,
                    style: TextStyle(
                      color: period == selected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                      fontWeight: period == selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: period == selected
                      ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                      : null,
                  onTap: () {
                    ref.read(selectedPeriodProvider.notifier).state = period;
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
