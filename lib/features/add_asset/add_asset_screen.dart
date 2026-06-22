import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/available_asset.dart';
import '../../core/models/holding.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/asset_avatar.dart';
import '../dashboard/dashboard_context.dart';
import '../dashboard/dashboard_screen.dart';
import 'asset_builder.dart';

/// Opis kategorii w kreatorze: id zgodne z backendem + czy wartość podaje user.
class _CategoryOption {
  final String id;
  final bool manual;
  const _CategoryOption(this.id, {required this.manual});
}

// Kolejność i podział na sekcje w kroku 1.
const _marketCategories = [
  _CategoryOption('crypto', manual: false),
  _CategoryOption('stock', manual: false),
  _CategoryOption('etf', manual: false),
  _CategoryOption('metal', manual: false),
  _CategoryOption('currency', manual: false),
];
const _manualCategories = [
  _CategoryOption('real_estate', manual: true),
  _CategoryOption('valuables', manual: true),
  _CategoryOption('bonds', manual: true),
  _CategoryOption('deposits', manual: true),
  _CategoryOption('other', manual: true),
];

// Kategorie, pod którymi aktywo-kontener (ETF / Inne) może się wyświetlać
// (display_category). „Inne" to furtka na nieobsługiwane aktywa, więc celuje
// w kategorie rynkowe.
const _etfDisplayTargets = ['stock', 'bonds', 'metal', 'crypto', 'other'];
const _otherDisplayTargets = ['stock', 'crypto', 'etf', 'metal', 'bonds', 'deposits'];

/// Kreator dodawania aktywa: krok 1 — wybór kategorii, krok 2 — formularz
/// dopasowany do kategorii (market = picker + ilość, manual = nazwa + ilość +
/// wartość). Sticky „Dodaj" na dole.
class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  _CategoryOption? _category;

  // Market
  AvailableAsset? _asset;
  String? _displayCategory; // ETF → kategoria wyświetlania

  // Wspólne / manual
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  String get _preferred =>
      ref.read(livePreferredPortfolioProvider).valueOrNull?.currency ?? 'PLN';

  void _pickCategory(_CategoryOption c) {
    setState(() {
      _category = c;
      _asset = null;
      _displayCategory = null;
      _error = null;
      _amountCtrl.clear();
      _nameCtrl.clear();
      _valueCtrl.clear();
      _rateCtrl.clear();
    });
  }

  void _back() {
    if (_category != null) {
      setState(() => _category = null);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _category;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: AppColors.textPrimary,
          onPressed: _back,
        ),
        title: Text(
          cat == null ? 'Dodaj aktywo' : categoryLabel(cat.id),
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: cat == null ? _categoryStep() : _formStep(cat),
      ),
    );
  }

  // --- Krok 1: wybór kategorii ---

  Widget _categoryStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionLabel('Aktywa rynkowe'),
        const SizedBox(height: 4),
        const Text('Cenę zna aplikacja — podajesz tylko ilość.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        ..._marketCategories.map(_categoryTile),
        const SizedBox(height: 28),
        const _SectionLabel('Wartość wpisujesz sam'),
        const SizedBox(height: 4),
        const Text('Nieruchomości, kosztowności i inne — podajesz wycenę.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        ..._manualCategories.map(_categoryTile),
      ],
    );
  }

  Widget _categoryTile(_CategoryOption c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _pickCategory(c),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AssetAvatar.category(c.id, size: 38),
              const SizedBox(width: 14),
              Text(categoryLabel(c.id),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Krok 2: formularz ---

  Widget _formStep(_CategoryOption cat) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (cat.manual) ..._manualFields(cat) else ..._marketFields(cat),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.negative, fontSize: 13)),
              ],
            ],
          ),
        ),
        _SubmitBar(onPressed: () => _submit(cat)),
      ],
    );
  }

  List<Widget> _marketFields(_CategoryOption cat) {
    return [
      const _FieldLabel('Aktywo'),
      const SizedBox(height: 8),
      _AssetPickerField(
        category: cat.id,
        selected: _asset,
        onTap: () => _openAssetPicker(cat.id),
      ),
      const SizedBox(height: 20),
      const _FieldLabel('Ile posiadasz'),
      const SizedBox(height: 8),
      _NumberField(controller: _amountCtrl, hint: 'np. 0,5'),
      if (cat.id == 'etf') ...[
        const SizedBox(height: 20),
        const _FieldLabel('Pokaż w kategorii (opcjonalnie)'),
        const SizedBox(height: 4),
        const Text(
          'Np. ETF na obligacje możesz pokazać w „Obligacje" zamiast „ETF-y".',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _DisplayCategoryPicker(
          value: _displayCategory,
          onChanged: (v) => setState(() => _displayCategory = v),
          targets: _etfDisplayTargets,
          noneLabel: 'ETF-y',
        ),
      ],
    ];
  }

  List<Widget> _manualFields(_CategoryOption cat) {
    return [
      const _FieldLabel('Nazwa'),
      const SizedBox(height: 8),
      _TextField(controller: _nameCtrl, hint: '', maxLength: 24),
      const SizedBox(height: 20),
      const _FieldLabel('Ilość'),
      const SizedBox(height: 8),
      _NumberField(controller: _amountCtrl, hint: 'np. 1'),
      const SizedBox(height: 20),
      _FieldLabel('Wartość jednostki ($_preferred)'),
      const SizedBox(height: 8),
      _NumberField(controller: _valueCtrl, hint: ''),
      if (cat.id == 'bonds') ...[
        const SizedBox(height: 20),
        const _RateLabelWithInfo(),
        const SizedBox(height: 4),
        const Text(
          'Wartość rośnie o tyle rocznie — naliczane codziennie.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _NumberField(controller: _rateCtrl, hint: 'np. 5'),
      ],
      if (cat.id == 'other') ...[
        const SizedBox(height: 20),
        const _FieldLabel('Pokaż w kategorii (opcjonalnie)'),
        const SizedBox(height: 4),
        const Text(
          'Aktywo, którego nie ma na listach (np. akcja spoza obsługiwanych) '
          'możesz pokazać w pasującej kategorii.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _DisplayCategoryPicker(
          value: _displayCategory,
          onChanged: (v) => setState(() => _displayCategory = v),
          targets: _otherDisplayTargets,
          noneLabel: 'Inne',
        ),
      ],
    ];
  }

  // --- Picker aktywa (bottom sheet z wyszukiwarką) ---

  void _openAssetPicker(String category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AssetPickerSheet(
        category: category,
        onSelected: (a) => setState(() {
          _asset = a;
          _error = null;
        }),
        onAddOther: () =>
            _pickCategory(const _CategoryOption('other', manual: true)),
      ),
    );
  }

  // --- Zatwierdzenie ---

  void _submit(_CategoryOption cat) {
    final marketAssets =
        ref.read(marketAssetsProvider).valueOrNull ?? const {};
    final preferredUsd = preferredUsdPrice(marketAssets, _preferred);

    final Holding holding;
    if (cat.manual) {
      final name = _nameCtrl.text.trim();
      final amount = parseAmount(_amountCtrl.text);
      final value = parseAmount(_valueCtrl.text);
      if (name.isEmpty) return _fail('Podaj nazwę aktywa.');
      if (amount == null || amount <= 0) return _fail('Podaj poprawną ilość.');
      if (value == null || value <= 0) return _fail('Podaj wartość jednostki.');
      double? rate;
      if (cat.id == 'bonds' && _rateCtrl.text.trim().isNotEmpty) {
        rate = parseAmount(_rateCtrl.text);
        if (rate == null || rate < 0) return _fail('Niepoprawne oprocentowanie.');
      }
      holding = buildManualHolding(
        name: name,
        category: cat.id,
        amount: amount,
        unitValueCcy: value,
        preferredUsd: preferredUsd,
        interestRate: rate,
        // „Inne" może być routowane do innej kategorii (furtka na nieobsługiwane).
        displayCategory: cat.id == 'other' ? _displayCategory : null,
      );
    } else {
      final asset = _asset;
      final amount = parseAmount(_amountCtrl.text);
      if (asset == null) return _fail('Wybierz aktywo.');
      if (amount == null || amount <= 0) return _fail('Podaj poprawną ilość.');
      final market = buildMarketHolding(
        assetId: asset.assetId,
        category: cat.id,
        amount: amount,
        priceUsd: asset.priceUsd,
        preferredUsd: preferredUsd,
      );
      // display_category dla ETF — doklejamy po zbudowaniu (builder market jej
      // nie przyjmuje, bo dotyczy tylko ETF-ów).
      holding = _displayCategory == null
          ? market
          : Holding(
              assetId: market.assetId,
              category: market.category,
              amount: market.amount,
              priceUsd: market.priceUsd,
              valueUsd: market.valueUsd,
              valueCcy: market.valueCcy,
              displayCategory: _displayCategory,
            );
    }

    ref.read(localHoldingsProvider.notifier).add(holding);

    // Lądujemy od razu na ekranie nowo dodanego aktywa (zamiast wracać na
    // poprzedni). Kategoria = ta, pod którą aktywo jest grupowane.
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(
      builder: (_) => DashboardScreen(
        context: DashboardContext.asset(holding.groupCategory, holding.assetId),
      ),
    ));
  }

  void _fail(String msg) => setState(() => _error = msg);
}

// --- Pomocnicze widgety ---

/// Etykieta pola oprocentowania z ikoną „i" — po kliknięciu pokazuje opis
/// dziennego naliczania odsetek.
class _RateLabelWithInfo extends StatelessWidget {
  const _RateLabelWithInfo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _FieldLabel('Oprocentowanie roczne (%)'),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _showInfo(context),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.info_outline,
                size: 16, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Jak działa naliczanie',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: const Text(
          'Wartość obligacji rośnie codziennie o oprocentowanie podzielone na '
          '365 dni. Przy 5% rocznie i wartości 100 — po roku masz ok. 105. '
          'Aplikacja przelicza to raz dziennie po stronie serwera.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700));
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600));
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  const _TextField({required this.controller, required this.hint, this.maxLength});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary),
        inputFormatters: maxLength == null
            ? null
            : [LengthLimitingTextInputFormatter(maxLength)],
        decoration: _inputDecoration(hint),
      );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _NumberField({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration(hint),
      );
}

class _AssetPickerField extends StatelessWidget {
  final String category;
  final AvailableAsset? selected;
  final VoidCallback onTap;
  const _AssetPickerField({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              AssetAvatar.asset(assetId: selected!.assetId, category: category, size: 28),
              const SizedBox(width: 12),
              Text(selected!.assetId,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ] else
              const Text('Wybierz z listy',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DisplayCategoryPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> targets;
  final String noneLabel;
  const _DisplayCategoryPicker({
    required this.value,
    required this.onChanged,
    required this.targets,
    required this.noneLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(noneLabel, value == null, () => onChanged(null)),
        ...targets.map(
          (c) => _chip(categoryLabel(c), value == c, () => onChanged(c)),
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final VoidCallback onPressed;
  const _SubmitBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(color: AppColors.background),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Dodaj',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Lista aktywów danej kategorii z wyszukiwarką (bottom sheet).
class _AssetPickerSheet extends ConsumerStatefulWidget {
  final String category;
  final ValueChanged<AvailableAsset> onSelected;

  /// Wywoływane gdy user nie znajduje swojego aktywa i wybiera furtkę „Inne".
  final VoidCallback onAddOther;
  const _AssetPickerSheet({
    required this.category,
    required this.onSelected,
    required this.onAddOther,
  });

  @override
  ConsumerState<_AssetPickerSheet> createState() => _AssetPickerSheetState();
}

class _AssetPickerSheetState extends ConsumerState<_AssetPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(marketAssetsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim().toUpperCase()),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Szukaj…').copyWith(
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 20),
                  fillColor: AppColors.surfaceElevated,
                ),
              ),
            ),
            Expanded(
              child: assetsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(
                    child: Text('Nie udało się pobrać aktywów',
                        style: TextStyle(color: AppColors.textSecondary))),
                data: (byCategory) {
                  final all = byCategory[widget.category] ?? const [];
                  final list = _query.isEmpty
                      ? all
                      : all
                          .where((a) => a.assetId.contains(_query))
                          .toList();
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('Brak wyników',
                            style:
                                TextStyle(color: AppColors.textSecondary)));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return ListTile(
                        leading: AssetAvatar.asset(
                            assetId: a.assetId, category: widget.category, size: 32),
                        title: Text(a.assetId,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500)),
                        onTap: () {
                          widget.onSelected(a);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _PickerFooterHint(onTap: () {
              Navigator.pop(context);
              widget.onAddOther();
            }),
          ],
        );
      },
    );
  }
}

/// Stopka pickera: gdy aktywa nie ma na liście, kieruje do kategorii „Inne".
class _PickerFooterHint extends StatelessWidget {
  final VoidCallback onTap;
  const _PickerFooterHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: AppColors.surfaceElevated, width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, height: 1.3),
                    children: [
                      TextSpan(
                        text: 'Nie ma Twojego aktywa? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: 'Dodaj je w kategorii Inne',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' i ustaw wartość ręcznie.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
