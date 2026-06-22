import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Okrągła ikonka aktywa lub kategorii ze spójnym stylem (obwódka w kolorze
/// kategorii). Łańcuch fallbacków zapewnia, że zawsze coś się wyświetli:
///
///   logo krypto (assets/crypto/) → flaga waluty (assets/flags/)
///   → ikonka kategorii → inicjały tickera
///
/// Logo i flagi są bundlowane offline; brak pliku => fallback bez błędu.
class AssetAvatar extends StatelessWidget {
  /// assetId (tryb aktywa) albo categoryId (tryb kategorii).
  final String id;
  final String category;
  final bool isCategory;
  final double size;

  /// Opcjonalny kolor obwódki — np. kolor wycinka wykresu, żeby zachować
  /// korelację legenda↔slice. Gdy null, używany jest kolor kategorii/metalu.
  final Color? ringColor;

  const AssetAvatar.asset({
    super.key,
    required String assetId,
    required this.category,
    this.size = 32,
    this.ringColor,
  })  : id = assetId,
        isCategory = false;

  const AssetAvatar.category(
    String categoryId, {
    super.key,
    this.size = 32,
    this.ringColor,
  })  : id = categoryId,
        category = categoryId,
        isCategory = true;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceElevated,
        border: Border.all(
          color: (ringColor ?? color).withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _content(color),
    );
  }

  Widget _content(Color color) {
    if (isCategory) return _categoryIcon(color);

    final file = id.toLowerCase();
    switch (category) {
      case 'crypto':
        return Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: Image.asset(
            'assets/crypto/$file.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _initials(color),
          ),
        );
      case 'currency':
        return Image.asset(
          'assets/flags/$file.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(color),
        );
      case 'real_estate':
      case 'valuables':
      case 'bonds':
      case 'deposits':
      case 'other':
        // Aktywa manualne mają nazwy (nie tickery) — inicjały długiej nazwy
        // wyglądałyby źle, więc pokazujemy ikonę kategorii.
        return _categoryIcon(color);
      default:
        // akcje + metale → inicjały tickera
        return _initials(color);
    }
  }

  Widget _categoryIcon(Color color) {
    final icon = switch (category) {
      'crypto' => Icons.currency_bitcoin,
      'stock' => Icons.show_chart,
      'etf' => Icons.pie_chart,
      'metal' => Icons.workspace_premium,
      'currency' => Icons.payments,
      'real_estate' => Icons.home_work,
      'valuables' => Icons.diamond,
      'bonds' => Icons.receipt_long,
      'deposits' => Icons.savings,
      'other' => Icons.widgets,
      _ => Icons.category,
    };
    return Center(child: Icon(icon, color: color, size: size * 0.52));
  }

  Widget _initials(Color color) {
    // Długie nazwy (np. custom assety) jako pełny tekst są nieczytelne na małej
    // ikonce — pokazujemy wtedy tylko pierwszą literę.
    final text = id.length > 5 ? id.substring(0, 1).toUpperCase() : id.toUpperCase();
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.5,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Kolor obwódki/ikonki. Metale dostają charakterystyczne barwy, reszta
  /// dziedziczy kolor kategorii.
  Color _avatarColor() {
    switch (id.toUpperCase()) {
      case 'XAU':
        return const Color(0xFFFFC83D); // złoto
      case 'XAG':
        return const Color(0xFFB8C0C8); // srebro
      case 'XPT':
        return const Color(0xFFE5E4E2); // platyna
      case 'XPD':
        return const Color(0xFFCED0DD); // pallad
    }
    return _categoryColor(category);
  }
}

Color _categoryColor(String c) => switch (c) {
      'crypto' => const Color(0xFF6C5CE7),
      'stock' => const Color(0xFF00CEC9),
      'etf' => const Color(0xFFFD79A8),
      'metal' => const Color(0xFFFDAA5E),
      'currency' => const Color(0xFF74B9FF),
      'real_estate' => const Color(0xFF55A3B2),
      'valuables' => const Color(0xFFE56B94),
      'bonds' => const Color(0xFF6FCF97),
      'deposits' => const Color(0xFF7C9CF0),
      'other' => const Color(0xFFA29BFE),
      _ => const Color(0xFFA29BFE),
    };
