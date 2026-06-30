// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Abundapp';

  @override
  String get addAsset => 'Ajouter un actif';

  @override
  String get add => 'Ajouter';

  @override
  String get valueOverTime => 'Valeur dans le temps';

  @override
  String get changeBreakdown => 'Détail de la variation';

  @override
  String get breakdownTransactions => 'Transactions';

  @override
  String get breakdownPriceMovement => 'Mouvement de prix';

  @override
  String get breakdownInterest => 'Intérêts';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Par défaut du système';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get myPortfolio => 'Mon portefeuille';

  @override
  String get portfolioCenter => 'Portefeuille';

  @override
  String get portfolioValue => 'Valeur du portefeuille';

  @override
  String valueOf(String name) {
    return 'Valeur de $name';
  }

  @override
  String yourAsset(String asset) {
    return 'Votre $asset';
  }

  @override
  String get periodLastVisit => 'Depuis la dernière visite';

  @override
  String get periodYesterday => 'Depuis hier';

  @override
  String get periodWeekStart => 'Depuis le début de la semaine';

  @override
  String get periodMonthStart => 'Depuis le début du mois';

  @override
  String get periodYearStart => 'Depuis le début de l\'année';

  @override
  String get periodAllTime => 'Depuis le début';

  @override
  String get categoryCrypto => 'Crypto';

  @override
  String get categoryStock => 'Actions';

  @override
  String get categoryEtf => 'ETF';

  @override
  String get categoryMetal => 'Métaux';

  @override
  String get categoryCurrency => 'Liquidités';

  @override
  String get categoryRealEstate => 'Immobilier';

  @override
  String get categoryValuables => 'Objets de valeur';

  @override
  String get categoryBonds => 'Obligations';

  @override
  String get categoryDeposits => 'Dépôts';

  @override
  String get categoryOther => 'Autre';
}
