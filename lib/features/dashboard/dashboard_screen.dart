import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/portfolio_api.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/models/holding.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../add_asset/add_asset_screen.dart';
import '../add_asset/asset_builder.dart';
import '../../shared/widgets/allocation_chart.dart';
import '../../shared/widgets/asset_avatar.dart';
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

    // Pusty portfel na poziomie głównym (np. świeżo zarejestrowany user) →
    // zamiast zer i pustych wykresów pokazujemy zachętę do dodania aktywów.
    final portfolio = ref.watch(portfolioProvider).valueOrNull;
    final showEmptyState =
        widget.context.isTopLevel && portfolio != null && portfolio.holdings.isEmpty;

    // Tytuł ekranu aktywa = nazwa custom assetu (a nie surowe id, którym jest
    // assetId dla manuali). Dla market i pozostałych poziomów — jak dotąd.
    var screenTitle = widget.context.title;
    if (widget.context.level == DashboardLevel.asset && portfolio != null) {
      for (final h in portfolio.holdings) {
        if (h.assetId == widget.context.assetId) {
          screenTitle = h.displayName;
          break;
        }
      }
    }

    // Email zalogowanego konta — do pokazania w menu (diagnostyka „kto jest
    // zalogowany"). ref.watch(sessionProvider) wymusza odświeżenie po zmianie
    // sesji.
    ref.watch(sessionProvider);
    final userEmail = ref.read(authRepositoryProvider).currentUser?.email;

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
                    if (widget.context.level == DashboardLevel.category) ...[
                      AssetAvatar.category(widget.context.categoryId!,
                          size: 30),
                      const SizedBox(width: 10),
                    ] else if (widget.context.level ==
                        DashboardLevel.asset) ...[
                      AssetAvatar.asset(
                        assetId: widget.context.assetId!,
                        category: widget.context.categoryId!,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        screenTitle,
                        style: Theme.of(ctx).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textSecondary),
                    color: AppColors.surfaceElevated,
                    onSelected: (value) {
                      if (value == 'logout') {
                        ref.read(authRepositoryProvider).signOut();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Zalogowano jako',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(userEmail ?? '—',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18,
                                color: AppColors.textPrimary),
                            SizedBox(width: 10),
                            Text('Wyloguj się',
                                style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (showEmptyState)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyPortfolio(onAdd: () => _openAddAsset(ctx)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PnlHeader(
                        context: widget.context,
                        selectedSegmentId: _selectedSegmentId,
                        showValueBlock:
                            widget.context.level != DashboardLevel.asset,
                      ),
                      SizedBox(
                          height: widget.context.level == DashboardLevel.asset
                              ? 16
                              : 32),

                      if (widget.context.level == DashboardLevel.asset)
                        _HoldingDetailCard(assetId: widget.context.assetId!),

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

        floatingActionButton: showEmptyState
            ? null
            : FloatingActionButton(
                onPressed: () => _openAddAsset(ctx),
                backgroundColor: AppColors.positive,
                foregroundColor: Colors.black,
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.add, size: 28),
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

  void _openAddAsset(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const AddAssetScreen()),
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

/// Stan pustego portfela — pokazywany nowemu userowi bez aktywów.
/// CTA na razie bez akcji (placeholder pod przyszły flow dodawania aktywów).
class _EmptyPortfolio extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPortfolio({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text('Twój portfel jest pusty',
              style: theme.textTheme.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Dodaj pierwsze aktywo — gotówkę, akcje, złoto albo krypto — '
            'a zobaczysz tutaj wartość całego majątku.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Dodaj aktywa',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
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
            AssetAvatar.asset(
                assetId: label, category: 'currency', size: 22),
            const SizedBox(width: 6),
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

/// Kolejność walut w pickerze: preferowana na górze (jeśli istnieje na liście),
/// reszta w dotychczasowej kolejności (lista z API jest już alfabetyczna).
List<String> orderedCurrencies(List<String> currencies, String? preferred) {
  return [
    if (preferred != null && currencies.contains(preferred)) preferred,
    ...currencies.where((c) => c != preferred),
  ];
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
                  final ordered = orderedCurrencies(currencies, preferred);
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
            AssetAvatar.asset(assetId: code, category: 'currency', size: 26),
            const SizedBox(width: 12),
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

/// Format ilości: liczba całkowita bez zer po przecinku, ułamki skrócone.
String _fmtAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// Ekran aktywa: „Twoje BTC w portfelu — X sztuk o wartości Y PLN", a pod
/// spodem przycisk edycji (market → ilość, manual → ilość i wartość).
class _HoldingDetailCard extends ConsumerWidget {
  final String assetId;
  const _HoldingDetailCard({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider).valueOrNull;
    final matches = portfolio?.holdings
            .where((h) => h.assetId == assetId)
            .toList() ??
        const <Holding>[];
    if (matches.isEmpty) return const SizedBox.shrink();
    final holding = matches.first;

    final ccy = portfolio?.currency ?? 'PLN';
    final unitValue = holding.amount == 0
        ? holding.valueCcy
        : holding.valueCcy / holding.amount;
    final unitLabel = holding.category == 'currency'
        ? holding.assetId
        : (holding.isManual ? 'szt.' : assetId);
    // Wartość edytujemy w walucie NATYWNEJ aktywa — tylko gdy backend ją zwraca
    // (unit_currency). Inaczej nie wiemy w czym edytować (groziło zapisaniem PLN
    // jako USD), więc edycja wartości jest wyłączona. Ilość edytujemy zawsze.
    final canEditValue = holding.isManual && holding.unitCurrency != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // „Twoje BTC w portfelu" — nazwa aktywa wyróżniona.
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                children: [
                  const TextSpan(text: 'Twoje '),
                  TextSpan(
                    text: holding.displayName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' w portfelu'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 18, height: 1.3),
                      children: [
                        TextSpan(
                          text: '${_fmtAmount(holding.amount)} $unitLabel ',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(
                          text: 'o wartości ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextSpan(
                          text: moneyCcy(holding.valueCcy, ccy),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _openEditor(
                      context,
                      holding,
                      holding.unitValueNative ?? unitValue,
                      holding.unitCurrency ?? ccy,
                      canEditValue),
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.accent),
                  tooltip: canEditValue ? 'Edytuj ilość i wartość' : 'Edytuj ilość',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            // Aktywo przeniesione do innej kategorii — pokazujemy jego typ
            // natywny i gdzie się wyświetla, żeby było jasne „co tu robi".
            if (holding.displayCategory != null &&
                holding.displayCategory != holding.category) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.swap_horiz,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Typ: ${categoryLabel(holding.category)} · '
                      'pokazywane w: ${categoryLabel(holding.groupCategory)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, Holding holding, double unitValue,
      String ccy, bool canEditValue) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HoldingEditor(
        holding: holding,
        unitValue: unitValue,
        currency: ccy,
        canEditValue: canEditValue,
      ),
    );
  }
}


/// Bottom sheet edycji holdingu. Market → tylko ilość (cena jest rynkowa).
/// Manual → ilość i wartość jednostki (user podaje wycenę sam).
class _HoldingEditor extends ConsumerStatefulWidget {
  final Holding holding;
  final double unitValue;
  final String currency;

  /// Czy wolno edytować wartość jednostki (manual + podgląd w walucie
  /// preferowanej). W obcej walucie tylko ilość.
  final bool canEditValue;
  const _HoldingEditor({
    required this.holding,
    required this.unitValue,
    required this.currency,
    required this.canEditValue,
  });

  @override
  ConsumerState<_HoldingEditor> createState() => _HoldingEditorState();
}

class _HoldingEditorState extends ConsumerState<_HoldingEditor> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _valueCtrl;
  bool _busy = false;
  String? _error;

  bool get _editValue => widget.canEditValue;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: _trim(widget.holding.amount));
    // Wartość jednostki bywa zaszumiona przez przeliczenia fx (500 → 499,99999),
    // więc prefill zaokrąglamy do 2 miejsc i obcinamy końcowe zera.
    _valueCtrl = TextEditingController(text: _money(widget.unitValue));
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  String _money(double v) {
    var s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = widget.holding.id;
    if (id == null) return setState(() => _error = 'Brak id pozycji.');
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      return setState(() => _error = 'Podaj poprawną ilość.');
    }
    final body = <String, dynamic>{'amount': amount};
    if (_editValue) {
      final value = parseAmount(_valueCtrl.text);
      if (value == null || value <= 0) {
        return setState(() => _error = 'Podaj poprawną wartość.');
      }
      // value jest już w walucie natywnej aktywa (pole edytowane tylko gdy
      // backend zwraca unit_currency) — wysyłamy bez konwersji.
      body['unit_value'] = value;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await updateHolding(id, body);
      refreshPortfolio(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _busy = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final id = widget.holding.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Usunąć aktywo?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text('„${widget.holding.displayName}" zniknie z portfela.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń',
                style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await deleteHolding(id);
      refreshPortfolio(ref);
      if (!mounted) return;
      // Zamykamy edytor i ekran aktywa (już nie istnieje).
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final title = _editValue
        ? 'Aktualizuj „${widget.holding.displayName}"'
        : 'Zmień ilość — ${widget.holding.displayName}';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          const Text('Ilość',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          _sheetField(_amountCtrl),
          if (_editValue) ...[
            const SizedBox(height: 16),
            const Text('Wartość jednostki',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            _sheetField(_valueCtrl, suffixText: widget.currency),
          ] else if (widget.holding.isManual) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Zmiana wartości będzie dostępna po aktualizacji serwera. '
                    'Na razie, by poprawić wycenę, usuń aktywo i dodaj ponownie.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.negative, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor:
                    AppColors.accent.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Zapisz',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.negative),
              label: const Text('Usuń aktywo',
                  style: TextStyle(color: AppColors.negative)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController controller, {String? suffixText}) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          suffixText: suffixText,
          suffixStyle: const TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

