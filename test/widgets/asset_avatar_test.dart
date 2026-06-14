import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abundapp/shared/widgets/asset_avatar.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

// Kolor obwódki avatara = pierwszy (jedyny) Container z BoxDecoration.
Color _ringColor(WidgetTester tester) {
  final container = tester.widget<Container>(find.byType(Container).first);
  final deco = container.decoration as BoxDecoration;
  return (deco.border as Border).top.color;
}

void main() {
  group('AssetAvatar.category — ikona kategorii', () {
    final cases = {
      'crypto': Icons.currency_bitcoin,
      'stock': Icons.show_chart,
      'etf': Icons.pie_chart,
      'metal': Icons.workspace_premium,
      'currency': Icons.payments,
      'nieznana': Icons.category, // fallback
    };

    cases.forEach((category, expectedIcon) {
      testWidgets('$category → $expectedIcon', (tester) async {
        await tester.pumpWidget(_wrap(AssetAvatar.category(category)));
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, expectedIcon);
      });
    });
  });

  group('AssetAvatar.asset — fallback inicjałów', () {
    testWidgets('akcje → inicjały tickera (uppercase)', (tester) async {
      await tester
          .pumpWidget(_wrap(const AssetAvatar.asset(assetId: 'aapl', category: 'stock')));
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('metale → inicjały', (tester) async {
      await tester
          .pumpWidget(_wrap(const AssetAvatar.asset(assetId: 'XAU', category: 'metal')));
      expect(find.text('XAU'), findsOneWidget);
    });
  });

  group('AssetAvatar.asset — obrazek dla crypto/currency', () {
    testWidgets('crypto → próbuje załadować obrazek (Image)', (tester) async {
      await tester
          .pumpWidget(_wrap(const AssetAvatar.asset(assetId: 'btc', category: 'crypto')));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('currency → próbuje załadować flagę (Image)', (tester) async {
      await tester
          .pumpWidget(_wrap(const AssetAvatar.asset(assetId: 'pln', category: 'currency')));
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('AssetAvatar — kolor obwódki', () {
    testWidgets('metal XAU → złoty kolor', (tester) async {
      await tester
          .pumpWidget(_wrap(const AssetAvatar.asset(assetId: 'XAU', category: 'metal')));
      expect(_ringColor(tester),
          const Color(0xFFFFC83D).withValues(alpha: 0.45));
    });

    testWidgets('ringColor nadpisuje kolor kategorii', (tester) async {
      await tester.pumpWidget(_wrap(const AssetAvatar.asset(
        assetId: 'AAPL',
        category: 'stock',
        ringColor: Color(0xFF123456),
      )));
      expect(
          _ringColor(tester), const Color(0xFF123456).withValues(alpha: 0.45));
    });
  });
}
