import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/portfolio_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

class AbundApp extends StatelessWidget {
  const AbundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abundapp',
      theme: buildAppTheme(),
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
        ref.invalidate(snapshotDatesProvider);
        ref.invalidate(currenciesProvider);
        ref.invalidate(visitBaselineProvider);
        ref.invalidate(selectedCurrencyProvider);
        ref.invalidate(selectedPeriodProvider);
      }
    });

    final session = ref.watch(sessionProvider);
    return session == null ? const AuthScreen() : const DashboardScreen();
  }
}
