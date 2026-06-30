// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Abundapp';

  @override
  String get addAsset => 'Anlage hinzufügen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get valueOverTime => 'Wert im Zeitverlauf';

  @override
  String get changeBreakdown => 'Veränderung – Aufschlüsselung';

  @override
  String get breakdownTransactions => 'Transaktionen';

  @override
  String get breakdownPriceMovement => 'Kursbewegung';

  @override
  String get breakdownInterest => 'Zinsen';

  @override
  String get noData => 'Keine Daten';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get logout => 'Abmelden';

  @override
  String get myPortfolio => 'Mein Portfolio';

  @override
  String get portfolioCenter => 'Portfolio';

  @override
  String get portfolioValue => 'Portfoliowert';

  @override
  String valueOf(String name) {
    return 'Wert von $name';
  }

  @override
  String yourAsset(String asset) {
    return 'Dein $asset';
  }

  @override
  String get periodLastVisit => 'Seit letztem Besuch';

  @override
  String get periodYesterday => 'Seit gestern';

  @override
  String get periodWeekStart => 'Seit Wochenbeginn';

  @override
  String get periodMonthStart => 'Seit Monatsbeginn';

  @override
  String get periodYearStart => 'Seit Jahresbeginn';

  @override
  String get periodAllTime => 'Gesamt';

  @override
  String get categoryCrypto => 'Krypto';

  @override
  String get categoryStock => 'Aktien';

  @override
  String get categoryEtf => 'ETFs';

  @override
  String get categoryMetal => 'Metalle';

  @override
  String get categoryCurrency => 'Bargeld';

  @override
  String get categoryRealEstate => 'Immobilien';

  @override
  String get categoryValuables => 'Wertgegenstände';

  @override
  String get categoryBonds => 'Anleihen';

  @override
  String get categoryDeposits => 'Einlagen';

  @override
  String get categoryOther => 'Sonstiges';
}
