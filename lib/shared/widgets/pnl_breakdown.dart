import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../features/dashboard/dashboard_context.dart';

/// Składowa „transakcje" rozbicia PnL: suma PODPISANYCH value_ccy transakcji
/// w oknie (windowStart, teraz], pasujących do predykatu. Buy dodatnie, sell
/// ujemne — więc kup→sprzedaj→dokup wychodzi z sumy sam.
double transactionFlow(
  List<Transaction> txs,
  DateTime windowStart,
  bool Function(Transaction) matches,
) {
  var sum = 0.0;
  for (final t in txs) {
    if (t.createdAt.isAfter(windowStart) && matches(t)) sum += t.valueCcy;
  }
  return sum;
}

/// Rozbicie zmiany wartości (PnL okresu) na: transakcje (przepływ netto) vs
/// ruch ceny (reszta). Składane — domyślnie zwinięte. Chowa się, gdy nie da się
/// wyznaczyć okna (brak baseline'u/snapshotu) albo brak danych transakcji.
class PnlBreakdown extends ConsumerStatefulWidget {
  final DashboardContext context;
  final String? selectedSegmentId;

  /// ΔWartość = aktualna − snapshot, już przefiltrowana wg kontekstu/segmentu.
  final double deltaValue;
  final String currency;

  const PnlBreakdown({
    super.key,
    required this.context,
    required this.selectedSegmentId,
    required this.deltaValue,
    required this.currency,
  });

  @override
  ConsumerState<PnlBreakdown> createState() => _PnlBreakdownState();
}

class _PnlBreakdownState extends ConsumerState<PnlBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final windowStart = ref.watch(pnlWindowStartProvider);
    final txs = ref.watch(transactionsProvider).valueOrNull;
    if (windowStart == null || txs == null) return const SizedBox.shrink();

    final txComponent = transactionFlow(txs, windowStart, _matcher());
    final priceComponent = widget.deltaValue - txComponent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Skład zmiany',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          _line('Transakcje', txComponent),
          const SizedBox(height: 6),
          _line('Ruch ceny', priceComponent),
        ],
      ],
    );
  }

  Widget _line(String label, double value) {
    final positive = value >= 0;
    return Row(
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(
          moneySigned(value, widget.currency),
          style: TextStyle(
            color: positive ? AppColors.positive : AppColors.negative,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Predykat dopasowania transakcji do bieżącego kontekstu/segmentu — lustro
  /// logiki _filteredValue z PnlHeader. Klucz aktywa = asset_id (market) albo
  /// holding_id (manual, bez asset_id). Kategoria dopasowywana natywnie.
  bool Function(Transaction) _matcher() {
    final seg = widget.selectedSegmentId;
    if (seg != null) {
      return switch (widget.context.level) {
        DashboardLevel.all => (t) => t.category == seg,
        DashboardLevel.category => (t) => _assetKey(t) == seg,
        DashboardLevel.asset => (t) => true,
      };
    }
    return switch (widget.context.level) {
      DashboardLevel.all => (t) => true,
      DashboardLevel.category => (t) => t.category == widget.context.categoryId,
      DashboardLevel.asset => (t) => _assetKey(t) == widget.context.assetId,
    };
  }

  String? _assetKey(Transaction t) => t.assetId ?? t.holdingId;
}
