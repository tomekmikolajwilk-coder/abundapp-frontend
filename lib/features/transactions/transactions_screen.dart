import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/asset_avatar.dart';

/// Read-only ledger transakcji — lista zapisanych kupna/sprzedaży (cena + data).
/// Append-only: nic tu nie edytujemy ani nie usuwamy.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final ccy = ref.watch(displayCurrencyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context).txTitle,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: txAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
              child: Text(AppLocalizations.of(context).txLoadError,
                  style: const TextStyle(color: AppColors.textSecondary))),
          data: (txs) => txs.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: txs.length,
                  itemBuilder: (_, i) => _TxRow(tx: txs[i], currency: ccy),
                  separatorBuilder: (_, _) => const Divider(
                      height: 1, color: AppColors.surface, indent: 68),
                ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  final String currency;
  const _TxRow({required this.tx, required this.currency});

  @override
  Widget build(BuildContext context) {
    final color = tx.isBuy ? AppColors.positive : AppColors.negative;
    // Cena jednostki w walucie wyświetlania = |value_ccy| / ilość.
    final unitPrice = tx.amount == 0 ? 0.0 : tx.valueCcy.abs() / tx.amount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AssetAvatar.asset(
              assetId: tx.assetId ?? tx.displayName,
              category: tx.category,
              size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_formatDate(tx.createdAt, Localizations.localeOf(context).languageCode),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.isBuy ? '+' : '−'}${_fmtAmount(tx.amount)}',
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(AppLocalizations.of(context).txAtPrice(moneyCcy(unitPrice, currency)),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(l.txEmpty,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(l.txEmptyHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

String _fmtAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

// Data w formacie zależnym od locale (skróty miesięcy z intl — symbole ładuje
// flutter_localizations dla aktywnego języka). np. PL „1 lip 2026", EN „Jul 1, 2026".
String _formatDate(DateTime d, String locale) =>
    DateFormat.yMMMd(locale).format(d.toLocal());
