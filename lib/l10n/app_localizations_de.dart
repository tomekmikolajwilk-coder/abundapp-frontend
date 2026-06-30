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

  @override
  String get addSectionMarket => 'Markt-Anlagen';

  @override
  String get addSectionMarketHint =>
      'Den Preis kennt die App — du gibst nur die Menge an.';

  @override
  String get addSectionManual => 'Wert selbst eingeben';

  @override
  String get addSectionManualHint =>
      'Immobilien, Wertgegenstände und mehr — du gibst die Bewertung an.';

  @override
  String get fieldAsset => 'Anlage';

  @override
  String get fieldAmountOwned => 'Wie viel du besitzt';

  @override
  String get showInCategory => 'In Kategorie anzeigen (optional)';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldQuantity => 'Menge';

  @override
  String get fieldUnitValue => 'Stückwert';

  @override
  String get bondGrowthHint =>
      'Der Wert wächst jährlich um diesen Betrag — täglich verzinst.';

  @override
  String get bondRateLabel => 'Jährlicher Zinssatz (%)';

  @override
  String get bondInfoTitle => 'So funktioniert die Verzinsung';

  @override
  String get bondInfoText =>
      'Der Wert einer Anleihe wächst täglich um den Zinssatz geteilt durch 365 Tage. Bei 5% pro Jahr und einem Wert von 100 hast du nach einem Jahr etwa 105. Die App berechnet dies einmal täglich auf dem Server.';

  @override
  String get ok => 'OK';

  @override
  String get errEnterName => 'Gib den Namen der Anlage ein.';

  @override
  String get errEnterAmount => 'Gib eine gültige Menge ein.';

  @override
  String get errEnterUnitValue => 'Gib den Stückwert ein.';

  @override
  String get errInvalidRate => 'Ungültiger Zinssatz.';

  @override
  String get errSelectAsset => 'Wähle eine Anlage.';

  @override
  String get errPriceUnavailable =>
      'Wir können diese Anlage gerade nicht bewerten. Wähle eine andere oder füge sie unter „Sonstiges“ mit manuell gesetztem Wert hinzu.';

  @override
  String get errPriceTransient =>
      'Kurs konnte gerade nicht abgerufen werden. Bitte versuche es gleich noch einmal.';

  @override
  String get search => 'Suchen…';

  @override
  String get searchByNameOrTicker => 'Nach Name oder Ticker suchen…';

  @override
  String get minTwoChars => 'Gib mindestens 2 Zeichen ein, um zu suchen.';

  @override
  String get noResults => 'Keine Ergebnisse.';

  @override
  String get errLoadAssets => 'Anlagen konnten nicht geladen werden';

  @override
  String get assetNotListedQuestion => 'Anlage nicht gefunden? ';

  @override
  String get addInOtherCategory => 'Unter Sonstiges hinzufügen';

  @override
  String get andSetValueManually => ' und den Wert manuell setzen.';

  @override
  String get pickFromList => 'Aus Liste wählen';

  @override
  String get chooseAsset => 'Anlage wählen';

  @override
  String get authTagline => 'Dein Vermögen an einem Ort.';

  @override
  String get authSignInTitle => 'Anmelden';

  @override
  String get authSignUpTitle => 'Konto erstellen';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authSignUp => 'Registrieren';

  @override
  String get authToggleToSignIn => 'Bereits ein Konto? Anmelden';

  @override
  String get authToggleToSignUp => 'Kein Konto? Registrieren';

  @override
  String get authEmail => 'E-Mail';

  @override
  String get authEnterEmail => 'Gib deine E-Mail ein';

  @override
  String get authInvalidEmail => 'Ungültige E-Mail';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authEnterPassword => 'Gib dein Passwort ein';

  @override
  String get authPasswordMin => 'Passwort mindestens 6 Zeichen';

  @override
  String get authAccountCreated =>
      'Konto erstellt. Bestätige deine E-Mail und melde dich dann an.';

  @override
  String get authGenericError =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get txTitle => 'Transaktionen';

  @override
  String get txLoadError => 'Transaktionen konnten nicht geladen werden';

  @override
  String txAtPrice(String price) {
    return 'zu $price';
  }

  @override
  String get txEmpty => 'Keine Transaktionen';

  @override
  String get txEmptyHint =>
      'Füge eine Anlage hinzu, dann erscheint hier ein Kaufeintrag.';

  @override
  String get egHalf => 'z. B. 0,5';

  @override
  String get egOne => 'z. B. 1';

  @override
  String get egFive => 'z. B. 5';

  @override
  String get etfDisplayHint =>
      'Z. B. einen Anleihen-ETF kannst du unter „Anleihen“ statt „ETFs“ anzeigen.';

  @override
  String get otherDisplayHint =>
      'Eine Anlage, die nicht in den Listen steht (z. B. eine nicht unterstützte Aktie), kannst du in einer passenden Kategorie anzeigen.';
}
