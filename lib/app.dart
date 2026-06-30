import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/portfolio_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'l10n/app_localizations.dart';

/// Klucz nawigatora — pozwala zdjąć pushnięte ekrany (asset/kategoria) przy
/// wylogowaniu, niezależnie od tego, z którego ekranu user się wylogował.
final navigatorKey = GlobalKey<NavigatorState>();

class AbundApp extends ConsumerWidget {
  const AbundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // null = język systemowy (auto); ustawiony = ręczny override z ustawień.
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Abundapp',
      navigatorKey: navigatorKey,
      theme: buildAppTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Język telefonu spoza obsługiwanych (egzotyczny) → fallback EN.
      localeListResolutionCallback: (devices, supported) {
        for (final d in devices ?? const <Locale>[]) {
          final m = supported.where((s) => s.languageCode == d.languageCode);
          if (m.isNotEmpty) return m.first;
        }
        return const Locale('en');
      },
      home: const _AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Przełącza widok zależnie od stanu sesji: brak sesji → ekran logowania,
/// aktywna sesja → dashboard. Sesja jest przywracana z dysku przez Supabase SDK
/// przy starcie, więc raz zalogowany user nie loguje się ponownie.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Przy zmianie konta (login/logout/przełączenie usera) czyścimy cache
    // providerów danych — inaczej kolejny user widziałby portfel poprzedniego
    // (globalne FutureProvidery nie są autoDispose i trzymają stary wynik).
    ref.listen(sessionProvider, (prev, next) {
      if (prev?.user.id != next?.user.id) {
        ref.invalidate(livePreferredPortfolioProvider);
        ref.invalidate(portfolioProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(snapshotDatesProvider);
        ref.invalidate(currenciesProvider);
        ref.invalidate(visitBaselineProvider);
        ref.invalidate(selectedCurrencyProvider);
        ref.invalidate(selectedPeriodProvider);

        // Po wylogowaniu zdejmij pushnięte ekrany (asset/kategoria). Bez tego wiszą
        // nad ekranem logowania i odpytują portfel bez sesji → 400 "Failed to load
        // portfolio" (bug 2). Z ekranu głównego problemu nie było (nie jest pushnięty).
        if (next == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.popUntil((r) => r.isFirst);
          });
        }
      }
    });

    final session = ref.watch(sessionProvider);
    return session == null ? const AuthScreen() : const DashboardScreen();
  }
}
