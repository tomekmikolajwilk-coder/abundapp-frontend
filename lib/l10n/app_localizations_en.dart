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

  @override
  String get addSectionMarket => 'Market assets';

  @override
  String get addSectionMarketHint =>
      'The app knows the price — you only enter the amount.';

  @override
  String get addSectionManual => 'You set the value';

  @override
  String get addSectionManualHint =>
      'Real estate, valuables and more — you provide the valuation.';

  @override
  String get fieldAsset => 'Asset';

  @override
  String get fieldAmountOwned => 'How much you own';

  @override
  String get showInCategory => 'Show in category (optional)';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get fieldUnitValue => 'Unit value';

  @override
  String get bondGrowthHint =>
      'The value grows by this much per year — accrued daily.';

  @override
  String get bondRateLabel => 'Annual interest rate (%)';

  @override
  String get bondInfoTitle => 'How accrual works';

  @override
  String get bondInfoText =>
      'A bond\'s value grows daily by the interest rate divided by 365 days. At 5% per year and a value of 100, after a year you have about 105. The app recalculates this once a day on the server.';

  @override
  String get ok => 'OK';

  @override
  String get errEnterName => 'Enter the asset name.';

  @override
  String get errEnterAmount => 'Enter a valid amount.';

  @override
  String get errEnterUnitValue => 'Enter the unit value.';

  @override
  String get errInvalidRate => 'Invalid interest rate.';

  @override
  String get errSelectAsset => 'Select an asset.';

  @override
  String get errPriceUnavailable =>
      'We can\'t price this asset right now. Pick another, or add it under \"Other\" with a manually set value.';

  @override
  String get errPriceTransient =>
      'Couldn\'t fetch the price right now. Please try again in a moment.';

  @override
  String get search => 'Search…';

  @override
  String get searchByNameOrTicker => 'Search by name or ticker…';

  @override
  String get minTwoChars => 'Type at least 2 characters to search.';

  @override
  String get noResults => 'No results.';

  @override
  String get errLoadAssets => 'Couldn\'t load assets';

  @override
  String get assetNotListedQuestion => 'Can\'t find your asset? ';

  @override
  String get addInOtherCategory => 'Add it under Other';

  @override
  String get andSetValueManually => ' and set the value manually.';

  @override
  String get pickFromList => 'Pick from list';

  @override
  String get chooseAsset => 'Choose asset';

  @override
  String get authTagline => 'Your wealth in one place.';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authToggleToSignIn => 'Already have an account? Sign in';

  @override
  String get authToggleToSignUp => 'No account? Sign up';

  @override
  String get authEmail => 'Email';

  @override
  String get authEnterEmail => 'Enter your email';

  @override
  String get authInvalidEmail => 'Invalid email';

  @override
  String get authPassword => 'Password';

  @override
  String get authEnterPassword => 'Enter your password';

  @override
  String get authPasswordMin => 'Password must be at least 6 characters';

  @override
  String get authAccountCreated =>
      'Account created. Check your email to confirm it, then sign in.';

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get txTitle => 'Transactions';

  @override
  String get txLoadError => 'Couldn\'t load transactions';

  @override
  String txAtPrice(String price) {
    return 'at $price';
  }

  @override
  String get txEmpty => 'No transactions';

  @override
  String get txEmptyHint =>
      'Add an asset and a purchase entry will appear here.';

  @override
  String get egHalf => 'e.g. 0.5';

  @override
  String get egOne => 'e.g. 1';

  @override
  String get egFive => 'e.g. 5';

  @override
  String get etfDisplayHint =>
      'E.g. a bond ETF can be shown under \"Bonds\" instead of \"ETFs\".';

  @override
  String get otherDisplayHint =>
      'An asset that\'s not in the lists (e.g. an unsupported stock) can be shown in a matching category.';

  @override
  String get topMovers => 'Top movers';

  @override
  String get emptyPortfolioTitle => 'Your portfolio is empty';

  @override
  String get emptyPortfolioBody =>
      'Add your first asset — cash, stocks, gold or crypto — and you\'ll see your whole net worth here.';

  @override
  String get addAssets => 'Add assets';

  @override
  String get currencyPickerTitle => 'Show value in currency';

  @override
  String get currencyPickerNote =>
      'Converted at today\'s rate. The chart history is a projection of the current rate, not a past value.';

  @override
  String get currencyLoadError => 'Couldn\'t load currencies';

  @override
  String get worth => 'worth ';

  @override
  String get editAmountAndValue => 'Edit amount and value';

  @override
  String get editAmountTooltip => 'Edit amount';

  @override
  String get errEnterValidValue => 'Enter a valid value.';

  @override
  String get deleteAssetTitle => 'Delete asset?';

  @override
  String deleteAssetConfirm(String name) {
    return '\"$name\" will disappear from your portfolio.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String updateAssetTitle(String name) {
    return 'Update \"$name\"';
  }

  @override
  String editAmountTitle(String name) {
    return 'Change amount — $name';
  }

  @override
  String get valueEditServerHint =>
      'Changing the value will be available after a server update. For now, to fix the valuation, delete the asset and add it again.';

  @override
  String get save => 'Save';

  @override
  String get deleteAssetButton => 'Delete asset';

  @override
  String get loggedInAs => 'Signed in as';

  @override
  String get open => 'Open';

  @override
  String get errorLabel => 'Error';
}
