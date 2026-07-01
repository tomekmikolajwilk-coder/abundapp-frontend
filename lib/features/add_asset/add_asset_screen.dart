import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/portfolio_api.dart';
import '../../core/models/available_asset.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error.dart';
import '../../l10n/app_localizations.dart';
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

  // Waluta, w której user wpisuje wartość manualnego aktywa (null = preferowana).
  String? _valueCurrency;

  bool _submitting = false;
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
      _valueCurrency = null;
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
          cat == null
              ? AppLocalizations.of(context).addAsset
              : categoryLabel(AppLocalizations.of(context), cat.id),
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
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionLabel(l.addSectionMarket),
        const SizedBox(height: 4),
        Text(l.addSectionMarketHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        ..._marketCategories.map(_categoryTile),
        const SizedBox(height: 28),
        _SectionLabel(l.addSectionManual),
        const SizedBox(height: 4),
        Text(l.addSectionManualHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
              Text(categoryLabel(AppLocalizations.of(context), c.id),
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
        _SubmitBar(
          loading: _submitting,
          onPressed: _submitting ? null : () => _submit(cat),
        ),
      ],
    );
  }

  List<Widget> _marketFields(_CategoryOption cat) {
    final l = AppLocalizations.of(context);
    return [
      _FieldLabel(l.fieldAsset),
      const SizedBox(height: 8),
      _AssetPickerField(
        category: cat.id,
        selected: _asset,
        onTap: () => _openAssetPicker(cat.id),
      ),
      const SizedBox(height: 20),
      _FieldLabel(l.fieldAmountOwned),
      const SizedBox(height: 8),
      _NumberField(controller: _amountCtrl, hint: l.egHalf),
      if (cat.id == 'etf') ...[
        const SizedBox(height: 20),
        _FieldLabel(l.showInCategory),
        const SizedBox(height: 4),
        Text(
          l.etfDisplayHint,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _DisplayCategoryPicker(
          value: _displayCategory,
          onChanged: (v) => setState(() => _displayCategory = v),
          targets: _etfDisplayTargets,
          noneLabel: AppLocalizations.of(context).categoryEtf,
        ),
      ],
    ];
  }

  List<Widget> _manualFields(_CategoryOption cat) {
    final l = AppLocalizations.of(context);
    return [
      _FieldLabel(l.fieldName),
      const SizedBox(height: 8),
      _TextField(controller: _nameCtrl, hint: '', maxLength: 24),
      const SizedBox(height: 20),
      _FieldLabel(l.fieldQuantity),
      const SizedBox(height: 8),
      _NumberField(controller: _amountCtrl, hint: l.egOne),
      const SizedBox(height: 20),
      Row(
        children: [
          _FieldLabel(l.fieldUnitValue),
          const Spacer(),
          _CurrencySelector(
            options: currencyValueOptions(_preferred),
            selected: _valueCurrency ?? _preferred,
            onChanged: (c) => setState(() => _valueCurrency = c),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _NumberField(
          controller: _valueCtrl,
          hint: '',
          suffixText: _valueCurrency ?? _preferred),
      if (cat.id == 'bonds') ...[
        const SizedBox(height: 20),
        const _RateLabelWithInfo(),
        const SizedBox(height: 4),
        Text(
          l.bondGrowthHint,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _NumberField(controller: _rateCtrl, hint: l.egFive),
      ],
      if (cat.id == 'other') ...[
        const SizedBox(height: 20),
        _FieldLabel(l.showInCategory),
        const SizedBox(height: 4),
        Text(
          l.otherDisplayHint,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _DisplayCategoryPicker(
          value: _displayCategory,
          onChanged: (v) => setState(() => _displayCategory = v),
          targets: _otherDisplayTargets,
          noneLabel: AppLocalizations.of(context).categoryOther,
        ),
      ],
    ];
  }

  // --- Picker aktywa (bottom sheet z wyszukiwarką) ---

  void _openAssetPicker(String category) {
    void onSelected(AvailableAsset a) => setState(() {
          _asset = a;
          _error = null;
        });
    void onAddOther() =>
        _pickCategory(const _CategoryOption('other', manual: true));

    // Duże katalogi (stock/ETF) → search-as-you-type po /assets/search.
    // Małe, w cache z ceną (crypto/currency/metal) → bulk z /assets jak dotąd.
    final useSearch = category == 'stock' || category == 'etf';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => useSearch
          ? _AssetSearchSheet(
              category: category,
              onSelected: onSelected,
              onAddOther: onAddOther,
            )
          : _AssetPickerSheet(
              category: category,
              onSelected: onSelected,
              onAddOther: onAddOther,
            ),
    );
  }

  // --- Zatwierdzenie ---

  Future<void> _submit(_CategoryOption cat) async {
    final l = AppLocalizations.of(context);
    // Składamy body wg kontraktu; wartość manualną wysyłamy SUROWĄ + walutę,
    // przeliczenie robi backend (trzyma unit_value natywnie w currency).
    final Map<String, dynamic> body;
    if (cat.manual) {
      final name = _nameCtrl.text.trim();
      final amount = parseAmount(_amountCtrl.text);
      final value = parseAmount(_valueCtrl.text);
      if (name.isEmpty) return _fail(l.errEnterName);
      if (amount == null || amount <= 0) return _fail(l.errEnterAmount);
      if (value == null || value <= 0) return _fail(l.errEnterUnitValue);
      double? rate;
      if (cat.id == 'bonds' && _rateCtrl.text.trim().isNotEmpty) {
        rate = parseAmount(_rateCtrl.text);
        if (rate == null || rate < 0) return _fail(l.errInvalidRate);
      }
      body = {
        'category': cat.id,
        'amount': amount,
        'custom': {
          'name': name,
          'unit_value': value,
          'currency': _valueCurrency ?? _preferred,
          if (cat.id == 'other' && _displayCategory != null)
            'display_category': _displayCategory,
          'interest_rate': ?rate,
        },
      };
    } else {
      final asset = _asset;
      final amount = parseAmount(_amountCtrl.text);
      if (asset == null) return _fail(l.errSelectAsset);
      if (amount == null || amount <= 0) return _fail(l.errEnterAmount);
      body = {
        'category': cat.id,
        'asset_id': asset.assetId,
        'amount': amount,
        // display_category dla market podajemy poza obiektem custom.
        if (cat.id == 'etf' && _displayCategory != null)
          'display_category': _displayCategory,
      };
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await addHolding(body);
      refreshPortfolio(ref);
      if (!mounted) return;
      // Lądujemy na ekranie nowo dodanego aktywa. Klucz: asset_id (market) lub
      // id wiersza (manual). Kategoria = ta, pod którą aktywo jest grupowane.
      final assetKey =
          (created['asset_id'] ?? created['id'])?.toString() ?? '';
      final groupCat =
          (created['display_category'] ?? created['category'])?.toString() ??
              cat.id;
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.push(MaterialPageRoute(
        builder: (_) => DashboardScreen(
          context: DashboardContext.asset(groupCat, assetKey),
        ),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _cleanError(Object e) =>
      localizedApiError(AppLocalizations.of(context), e);

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
        _FieldLabel(AppLocalizations.of(context).bondRateLabel),
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(AppLocalizations.of(dialogCtx).bondInfoTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text(
          AppLocalizations.of(dialogCtx).bondInfoText,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppLocalizations.of(dialogCtx).ok,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

/// Kompaktowy dropdown waluty wartości (lista wspieranych walut).
class _CurrencySelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _CurrencySelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.length <= 1) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      color: AppColors.surfaceElevated,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => options
          .map((c) => PopupMenuItem(
                value: c,
                child: Text(c,
                    style: TextStyle(
                        color: c == selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight:
                            c == selected ? FontWeight.w700 : FontWeight.normal)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
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
  final String? suffixText;
  const _NumberField({required this.controller, required this.hint, this.suffixText});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration(hint).copyWith(
          suffixText: suffixText,
          suffixStyle: const TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
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
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selected!.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    if (selected!.displayName != null)
                      Text(selected!.assetId,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ] else
              Text(AppLocalizations.of(context).pickFromList,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
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
          (c) => _chip(categoryLabel(AppLocalizations.of(context), c), value == c,
              () => onChanged(c)),
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
  final VoidCallback? onPressed;
  final bool loading;
  const _SubmitBar({required this.onPressed, this.loading = false});

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
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(AppLocalizations.of(context).add,
                  style: const TextStyle(
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
                decoration: _inputDecoration(AppLocalizations.of(context).search).copyWith(
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
                error: (_, _) => Center(
                    child: Text(AppLocalizations.of(context).errLoadAssets,
                        style: const TextStyle(color: AppColors.textSecondary))),
                data: (byCategory) {
                  final all = byCategory[widget.category] ?? const [];
                  final list = _query.isEmpty
                      ? all
                      : all
                          .where((a) =>
                              a.assetId.toUpperCase().contains(_query) ||
                              a.label.toUpperCase().contains(_query))
                          .toList();
                  if (list.isEmpty) {
                    return Center(
                        child: Text(AppLocalizations.of(context).noResults,
                            style: const TextStyle(
                                color: AppColors.textSecondary)));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return ListTile(
                        leading: AssetAvatar.asset(
                            assetId: a.assetId, category: widget.category, size: 32),
                        title: Text(a.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500)),
                        subtitle: a.displayName != null
                            ? Text(a.assetId,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12))
                            : null,
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

/// Picker dla dużych katalogów (stock/ETF): search-as-you-type po
/// `/assets/search` z debounce, paginacją (infinite scroll) i metadanymi
/// (nazwa · ticker · giełda). Katalog ma tysiące pozycji i `/assets` nie zwraca
/// go w całości, więc filtrujemy po stronie serwera.
class _AssetSearchSheet extends StatefulWidget {
  final String category;
  final ValueChanged<AvailableAsset> onSelected;
  final VoidCallback onAddOther;
  const _AssetSearchSheet({
    required this.category,
    required this.onSelected,
    required this.onAddOther,
  });

  @override
  State<_AssetSearchSheet> createState() => _AssetSearchSheetState();
}

class _AssetSearchSheetState extends State<_AssetSearchSheet> {
  static const _minChars = 2;
  static const _limit = 20;
  static const _debounce = Duration(milliseconds: 300);

  final _ctrl = TextEditingController();
  Timer? _timer;
  String _query = '';
  final List<AvailableAsset> _results = [];
  bool _loading = false;
  bool _hasMore = false;
  int _offset = 0;
  Object? _error;
  // Rośnie przy każdym nowym wyszukiwaniu — odpowiedzi z nieaktualnego zapytania
  // (wolniejszy network niż kolejne wpisanie) odrzucamy po niezgodności id.
  int _reqId = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final q = v.trim();
    _timer?.cancel();
    setState(() => _query = q);
    if (q.length < _minChars) {
      setState(() {
        _results.clear();
        _hasMore = false;
        _loading = false;
        _error = null;
        _reqId++; // unieważnij odpowiedzi w locie
      });
      return;
    }
    _timer = Timer(_debounce, () => _search(reset: true));
  }

  Future<void> _search({required bool reset}) async {
    if (_query.length < _minChars) return;
    if (!reset && (_loading || !_hasMore)) return;
    final reqId = ++_reqId;
    final offset = reset ? 0 : _offset;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _results.clear();
        _offset = 0;
      }
    });
    try {
      final page = await searchAssets(
        q: _query,
        category: widget.category,
        limit: _limit,
        offset: offset,
      );
      if (reqId != _reqId || !mounted) return; // wynik nieaktualnego zapytania
      setState(() {
        _results.addAll(page.results);
        _offset = offset + page.results.length;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (reqId != _reqId || !mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 &&
        _hasMore &&
        !_loading) {
      _search(reset: false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(AppLocalizations.of(context).searchByNameOrTicker)
                    .copyWith(
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 20),
                  fillColor: AppColors.surfaceElevated,
                ),
              ),
            ),
            Expanded(child: _body(scrollController)),
            _PickerFooterHint(onTap: () {
              Navigator.pop(context);
              widget.onAddOther();
            }),
          ],
        );
      },
    );
  }

  Widget _body(ScrollController scrollController) {
    final l = AppLocalizations.of(context);
    if (_query.length < _minChars) {
      return _CenteredHint(l.minTwoChars);
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _results.isEmpty) {
      return _CenteredHint(l.errLoadAssets);
    }
    if (_results.isEmpty) {
      return _CenteredHint(l.noResults);
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView.builder(
        controller: scrollController,
        // +1 na wskaźnik doczytywania kolejnej strony.
        itemCount: _results.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _results.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final a = _results[i];
          return ListTile(
            leading: AssetAvatar.asset(
                assetId: a.assetId, category: widget.category, size: 32),
            title: Text(a.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text(_subtitle(a),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            onTap: () {
              widget.onSelected(a);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  // „AAPL · NASDAQ" lub „AAPL · US" — giełda gdy jest, inaczej kraj.
  String _subtitle(AvailableAsset a) {
    final loc = a.exchange ?? a.country;
    return loc == null ? a.assetId : '${a.assetId} · $loc';
  }
}

/// Wyśrodkowana podpowiedź/empty-state w pickerze.
class _CenteredHint extends StatelessWidget {
  final String text;
  const _CenteredHint(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
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
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, height: 1.3),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context).assetNotListedQuestion,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context).addInOtherCategory,
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context).andSetValueManually,
                        style: const TextStyle(color: AppColors.textSecondary),
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
