import '../../l10n/app_localizations.dart';
import '../api/portfolio_api.dart';

/// Mapuje błąd z API na ZLOKALIZOWANY komunikat dla usera. Rozpoznaje maszynowy
/// `code` (opcja A) — dzięki temu nigdy nie pokazujemy surowego (polskiego)
/// `message` z backendu. Nieznany błąd → generyczny „coś poszło nie tak".
String localizedApiError(AppLocalizations l, Object e) {
  if (e is ApiException) {
    switch (e.code) {
      case 'price_unavailable':
        return l.errPriceUnavailable;
      case 'price_transient':
        return l.errPriceTransient;
    }
    // 503 bez code też traktujemy jako przejściowe (starszy deploy backendu).
    if (e.statusCode == 503) return l.errPriceTransient;
  }
  return l.errGeneric;
}
