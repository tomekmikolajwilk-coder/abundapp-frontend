// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Abundapp';

  @override
  String get addAsset => 'Dodaj aktywo';

  @override
  String get add => 'Dodaj';

  @override
  String get valueOverTime => 'Wartość w czasie';

  @override
  String get changeBreakdown => 'Skład zmiany';

  @override
  String get breakdownTransactions => 'Transakcje';

  @override
  String get breakdownPriceMovement => 'Ruch ceny';

  @override
  String get breakdownInterest => 'Odsetki';

  @override
  String get noData => 'Brak danych';

  @override
  String get settings => 'Ustawienia';

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'Systemowy';

  @override
  String get logout => 'Wyloguj się';

  @override
  String get myPortfolio => 'Mój portfel';

  @override
  String get portfolioCenter => 'Portfel';

  @override
  String get portfolioValue => 'Wartość portfela';

  @override
  String valueOf(String name) {
    return 'Wartość $name';
  }

  @override
  String yourAsset(String asset) {
    return 'Twoje $asset w portfelu';
  }

  @override
  String get periodLastVisit => 'Od ostatniej wizyty';

  @override
  String get periodYesterday => 'Od wczoraj';

  @override
  String get periodWeekStart => 'Od początku tygodnia';

  @override
  String get periodMonthStart => 'Od początku miesiąca';

  @override
  String get periodYearStart => 'Od początku roku';

  @override
  String get periodAllTime => 'Od początku';

  @override
  String get categoryCrypto => 'Krypto';

  @override
  String get categoryStock => 'Akcje';

  @override
  String get categoryEtf => 'ETF-y';

  @override
  String get categoryMetal => 'Metale';

  @override
  String get categoryCurrency => 'Gotówka';

  @override
  String get categoryRealEstate => 'Nieruchomości';

  @override
  String get categoryValuables => 'Kosztowności';

  @override
  String get categoryBonds => 'Obligacje';

  @override
  String get categoryDeposits => 'Lokaty';

  @override
  String get categoryOther => 'Inne';

  @override
  String get addSectionMarket => 'Aktywa rynkowe';

  @override
  String get addSectionMarketHint =>
      'Cenę zna aplikacja — podajesz tylko ilość.';

  @override
  String get addSectionManual => 'Wartość wpisujesz sam';

  @override
  String get addSectionManualHint =>
      'Nieruchomości, kosztowności i inne — podajesz wycenę.';

  @override
  String get fieldAsset => 'Aktywo';

  @override
  String get fieldAmountOwned => 'Ile posiadasz';

  @override
  String get showInCategory => 'Pokaż w kategorii (opcjonalnie)';

  @override
  String get fieldName => 'Nazwa';

  @override
  String get fieldQuantity => 'Ilość';

  @override
  String get fieldUnitValue => 'Wartość jednostki';

  @override
  String get bondGrowthHint =>
      'Wartość rośnie o tyle rocznie — naliczane codziennie.';

  @override
  String get bondRateLabel => 'Oprocentowanie roczne (%)';

  @override
  String get bondInfoTitle => 'Jak działa naliczanie';

  @override
  String get bondInfoText =>
      'Wartość obligacji rośnie codziennie o oprocentowanie podzielone na 365 dni. Przy 5% rocznie i wartości 100 — po roku masz ok. 105. Aplikacja przelicza to raz dziennie po stronie serwera.';

  @override
  String get ok => 'OK';

  @override
  String get errEnterName => 'Podaj nazwę aktywa.';

  @override
  String get errEnterAmount => 'Podaj poprawną ilość.';

  @override
  String get errEnterUnitValue => 'Podaj wartość jednostki.';

  @override
  String get errInvalidRate => 'Niepoprawne oprocentowanie.';

  @override
  String get errSelectAsset => 'Wybierz aktywo.';

  @override
  String get errPriceUnavailable =>
      'Nie umiemy teraz wycenić tego aktywa. Wybierz inne albo dodaj je w kategorii „Inne\" z ręcznie ustawioną wartością.';

  @override
  String get errPriceTransient =>
      'Chwilowy problem z pobraniem kursu. Spróbuj ponownie za chwilę.';

  @override
  String get search => 'Szukaj…';

  @override
  String get searchByNameOrTicker => 'Szukaj po nazwie lub tickerze…';

  @override
  String get minTwoChars => 'Wpisz co najmniej 2 znaki, aby wyszukać.';

  @override
  String get noResults => 'Brak wyników.';

  @override
  String get errLoadAssets => 'Nie udało się pobrać aktywów';

  @override
  String get assetNotListedQuestion => 'Nie ma Twojego aktywa? ';

  @override
  String get addInOtherCategory => 'Dodaj je w kategorii Inne';

  @override
  String get andSetValueManually => ' i ustaw wartość ręcznie.';

  @override
  String get pickFromList => 'Wybierz z listy';

  @override
  String get chooseAsset => 'Wybierz aktywo';
}
