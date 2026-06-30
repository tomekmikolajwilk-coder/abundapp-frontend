// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Abundapp';

  @override
  String get addAsset => 'Add asset';

  @override
  String get add => 'Add';

  @override
  String get valueOverTime => 'Value over time';

  @override
  String get changeBreakdown => 'Change breakdown';

  @override
  String get breakdownTransactions => 'Transactions';

  @override
  String get breakdownPriceMovement => 'Price movement';

  @override
  String get breakdownInterest => 'Interest';

  @override
  String get noData => 'No data';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get logout => 'Log out';

  @override
  String get myPortfolio => 'My portfolio';

  @override
  String get portfolioCenter => 'Portfolio';

  @override
  String get portfolioValue => 'Portfolio value';

  @override
  String valueOf(String name) {
    return '$name value';
  }

  @override
  String yourAsset(String asset) {
    return 'Your $asset';
  }

  @override
  String get periodLastVisit => 'Since last visit';

  @override
  String get periodYesterday => 'Since yesterday';

  @override
  String get periodWeekStart => 'Week to date';

  @override
  String get periodMonthStart => 'Month to date';

  @override
  String get periodYearStart => 'Year to date';

  @override
  String get periodAllTime => 'All time';

  @override
  String get categoryCrypto => 'Crypto';

  @override
  String get categoryStock => 'Stocks';

  @override
  String get categoryEtf => 'ETFs';

  @override
  String get categoryMetal => 'Metals';

  @override
  String get categoryCurrency => 'Cash';

  @override
  String get categoryRealEstate => 'Real estate';

  @override
  String get categoryValuables => 'Valuables';

  @override
  String get categoryBonds => 'Bonds';

  @override
  String get categoryDeposits => 'Deposits';

  @override
  String get categoryOther => 'Other';
}
