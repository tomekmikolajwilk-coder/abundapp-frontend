import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/features/auth/auth_screen.dart';
import 'package:abundapp/l10n/app_localizations.dart';

Widget _wrap() => ProviderScope(
      child: MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AuthScreen(),
      ),
    );

void main() {
  group('AuthScreen', () {
    testWidgets('startuje w trybie logowania', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.text('Nie masz konta? Zarejestruj się'), findsOneWidget);
    });

    testWidgets('przełącza na rejestrację', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Nie masz konta? Zarejestruj się'));
      await tester.pump();
      expect(find.text('Załóż konto'), findsOneWidget);
      expect(find.text('Masz już konto? Zaloguj się'), findsOneWidget);
    });

    testWidgets('puste pola → komunikaty walidacji (bez wywołania sieci)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj'));
      await tester.pump();
      expect(find.text('Podaj email'), findsOneWidget);
      expect(find.text('Podaj hasło'), findsOneWidget);
    });

    testWidgets('za krótkie hasło → komunikat', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Hasło'), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj'));
      await tester.pump();
      expect(find.text('Hasło min. 6 znaków'), findsOneWidget);
    });
  });
}
