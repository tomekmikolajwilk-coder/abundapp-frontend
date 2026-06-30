import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Abundapp'**
  String get appTitle;

  /// No description provided for @addAsset.
  ///
  /// In en, this message translates to:
  /// **'Add asset'**
  String get addAsset;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @valueOverTime.
  ///
  /// In en, this message translates to:
  /// **'Value over time'**
  String get valueOverTime;

  /// No description provided for @changeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Change breakdown'**
  String get changeBreakdown;

  /// No description provided for @breakdownTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get breakdownTransactions;

  /// No description provided for @breakdownPriceMovement.
  ///
  /// In en, this message translates to:
  /// **'Price movement'**
  String get breakdownPriceMovement;

  /// No description provided for @breakdownInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get breakdownInterest;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @myPortfolio.
  ///
  /// In en, this message translates to:
  /// **'My portfolio'**
  String get myPortfolio;

  /// No description provided for @portfolioCenter.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioCenter;

  /// No description provided for @portfolioValue.
  ///
  /// In en, this message translates to:
  /// **'Portfolio value'**
  String get portfolioValue;

  /// No description provided for @valueOf.
  ///
  /// In en, this message translates to:
  /// **'{name} value'**
  String valueOf(String name);

  /// No description provided for @yourAsset.
  ///
  /// In en, this message translates to:
  /// **'Your {asset}'**
  String yourAsset(String asset);

  /// No description provided for @periodLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Since last visit'**
  String get periodLastVisit;

  /// No description provided for @periodYesterday.
  ///
  /// In en, this message translates to:
  /// **'Since yesterday'**
  String get periodYesterday;

  /// No description provided for @periodWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Week to date'**
  String get periodWeekStart;

  /// No description provided for @periodMonthStart.
  ///
  /// In en, this message translates to:
  /// **'Month to date'**
  String get periodMonthStart;

  /// No description provided for @periodYearStart.
  ///
  /// In en, this message translates to:
  /// **'Year to date'**
  String get periodYearStart;

  /// No description provided for @periodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAllTime;

  /// No description provided for @categoryCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get categoryCrypto;

  /// No description provided for @categoryStock.
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get categoryStock;

  /// No description provided for @categoryEtf.
  ///
  /// In en, this message translates to:
  /// **'ETFs'**
  String get categoryEtf;

  /// No description provided for @categoryMetal.
  ///
  /// In en, this message translates to:
  /// **'Metals'**
  String get categoryMetal;

  /// No description provided for @categoryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get categoryCurrency;

  /// No description provided for @categoryRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real estate'**
  String get categoryRealEstate;

  /// No description provided for @categoryValuables.
  ///
  /// In en, this message translates to:
  /// **'Valuables'**
  String get categoryValuables;

  /// No description provided for @categoryBonds.
  ///
  /// In en, this message translates to:
  /// **'Bonds'**
  String get categoryBonds;

  /// No description provided for @categoryDeposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get categoryDeposits;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @addSectionMarket.
  ///
  /// In en, this message translates to:
  /// **'Market assets'**
  String get addSectionMarket;

  /// No description provided for @addSectionMarketHint.
  ///
  /// In en, this message translates to:
  /// **'The app knows the price — you only enter the amount.'**
  String get addSectionMarketHint;

  /// No description provided for @addSectionManual.
  ///
  /// In en, this message translates to:
  /// **'You set the value'**
  String get addSectionManual;

  /// No description provided for @addSectionManualHint.
  ///
  /// In en, this message translates to:
  /// **'Real estate, valuables and more — you provide the valuation.'**
  String get addSectionManualHint;

  /// No description provided for @fieldAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get fieldAsset;

  /// No description provided for @fieldAmountOwned.
  ///
  /// In en, this message translates to:
  /// **'How much you own'**
  String get fieldAmountOwned;

  /// No description provided for @showInCategory.
  ///
  /// In en, this message translates to:
  /// **'Show in category (optional)'**
  String get showInCategory;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @fieldUnitValue.
  ///
  /// In en, this message translates to:
  /// **'Unit value'**
  String get fieldUnitValue;

  /// No description provided for @bondGrowthHint.
  ///
  /// In en, this message translates to:
  /// **'The value grows by this much per year — accrued daily.'**
  String get bondGrowthHint;

  /// No description provided for @bondRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual interest rate (%)'**
  String get bondRateLabel;

  /// No description provided for @bondInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'How accrual works'**
  String get bondInfoTitle;

  /// No description provided for @bondInfoText.
  ///
  /// In en, this message translates to:
  /// **'A bond\'s value grows daily by the interest rate divided by 365 days. At 5% per year and a value of 100, after a year you have about 105. The app recalculates this once a day on the server.'**
  String get bondInfoText;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter the asset name.'**
  String get errEnterName;

  /// No description provided for @errEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get errEnterAmount;

  /// No description provided for @errEnterUnitValue.
  ///
  /// In en, this message translates to:
  /// **'Enter the unit value.'**
  String get errEnterUnitValue;

  /// No description provided for @errInvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Invalid interest rate.'**
  String get errInvalidRate;

  /// No description provided for @errSelectAsset.
  ///
  /// In en, this message translates to:
  /// **'Select an asset.'**
  String get errSelectAsset;

  /// No description provided for @errPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We can\'t price this asset right now. Pick another, or add it under \"Other\" with a manually set value.'**
  String get errPriceUnavailable;

  /// No description provided for @errPriceTransient.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch the price right now. Please try again in a moment.'**
  String get errPriceTransient;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get search;

  /// No description provided for @searchByNameOrTicker.
  ///
  /// In en, this message translates to:
  /// **'Search by name or ticker…'**
  String get searchByNameOrTicker;

  /// No description provided for @minTwoChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search.'**
  String get minTwoChars;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get noResults;

  /// No description provided for @errLoadAssets.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load assets'**
  String get errLoadAssets;

  /// No description provided for @assetNotListedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your asset? '**
  String get assetNotListedQuestion;

  /// No description provided for @addInOtherCategory.
  ///
  /// In en, this message translates to:
  /// **'Add it under Other'**
  String get addInOtherCategory;

  /// No description provided for @andSetValueManually.
  ///
  /// In en, this message translates to:
  /// **' and set the value manually.'**
  String get andSetValueManually;

  /// No description provided for @pickFromList.
  ///
  /// In en, this message translates to:
  /// **'Pick from list'**
  String get pickFromList;

  /// No description provided for @chooseAsset.
  ///
  /// In en, this message translates to:
  /// **'Choose asset'**
  String get chooseAsset;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Your wealth in one place.'**
  String get authTagline;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authToggleToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authToggleToSignIn;

  /// No description provided for @authToggleToSignUp.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get authToggleToSignUp;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authInvalidEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authEnterPassword;

  /// No description provided for @authPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordMin;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to confirm it, then sign in.'**
  String get authAccountCreated;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @txTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get txTitle;

  /// No description provided for @txLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get txLoadError;

  /// No description provided for @txAtPrice.
  ///
  /// In en, this message translates to:
  /// **'at {price}'**
  String txAtPrice(String price);

  /// No description provided for @txEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get txEmpty;

  /// No description provided for @txEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add an asset and a purchase entry will appear here.'**
  String get txEmptyHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
