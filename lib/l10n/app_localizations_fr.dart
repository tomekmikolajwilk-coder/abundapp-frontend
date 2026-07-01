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

  @override
  String get addSectionMarket => 'Actifs de marché';

  @override
  String get addSectionMarketHint =>
      'L\'app connaît le prix — vous saisissez seulement la quantité.';

  @override
  String get addSectionManual => 'Vous saisissez la valeur';

  @override
  String get addSectionManualHint =>
      'Immobilier, objets de valeur et plus — vous fournissez l\'estimation.';

  @override
  String get fieldAsset => 'Actif';

  @override
  String get fieldAmountOwned => 'Quantité détenue';

  @override
  String get showInCategory => 'Afficher dans la catégorie (facultatif)';

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldQuantity => 'Quantité';

  @override
  String get fieldUnitValue => 'Valeur unitaire';

  @override
  String get bondGrowthHint =>
      'La valeur augmente de ce montant par an — calculé chaque jour.';

  @override
  String get bondRateLabel => 'Taux d\'intérêt annuel (%)';

  @override
  String get bondInfoTitle => 'Comment fonctionne le calcul';

  @override
  String get bondInfoText =>
      'La valeur d\'une obligation augmente chaque jour du taux d\'intérêt divisé par 365 jours. À 5% par an et une valeur de 100, après un an vous avez environ 105. L\'app recalcule cela une fois par jour côté serveur.';

  @override
  String get ok => 'OK';

  @override
  String get errEnterName => 'Saisissez le nom de l\'actif.';

  @override
  String get errEnterAmount => 'Saisissez une quantité valide.';

  @override
  String get errEnterUnitValue => 'Saisissez la valeur unitaire.';

  @override
  String get errInvalidRate => 'Taux d\'intérêt invalide.';

  @override
  String get errSelectAsset => 'Sélectionnez un actif.';

  @override
  String get errPriceUnavailable =>
      'Nous ne pouvons pas évaluer cet actif pour le moment. Choisissez-en un autre ou ajoutez-le sous « Autre » avec une valeur définie manuellement.';

  @override
  String get errPriceTransient =>
      'Impossible de récupérer le prix pour le moment. Réessayez dans un instant.';

  @override
  String get search => 'Rechercher…';

  @override
  String get searchByNameOrTicker => 'Rechercher par nom ou symbole…';

  @override
  String get minTwoChars => 'Saisissez au moins 2 caractères pour rechercher.';

  @override
  String get noResults => 'Aucun résultat.';

  @override
  String get errLoadAssets => 'Impossible de charger les actifs';

  @override
  String get assetNotListedQuestion => 'Vous ne trouvez pas votre actif ? ';

  @override
  String get addInOtherCategory => 'Ajoutez-le sous Autre';

  @override
  String get andSetValueManually => ' et définissez la valeur manuellement.';

  @override
  String get pickFromList => 'Choisir dans la liste';

  @override
  String get chooseAsset => 'Choisir un actif';

  @override
  String get authTagline => 'Votre patrimoine en un seul endroit.';

  @override
  String get authSignInTitle => 'Se connecter';

  @override
  String get authSignUpTitle => 'Créer un compte';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignUp => 'S\'inscrire';

  @override
  String get authToggleToSignIn => 'Déjà un compte ? Se connecter';

  @override
  String get authToggleToSignUp => 'Pas de compte ? S\'inscrire';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEnterEmail => 'Saisissez votre e-mail';

  @override
  String get authInvalidEmail => 'E-mail invalide';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authEnterPassword => 'Saisissez votre mot de passe';

  @override
  String get authPasswordMin =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get authAccountCreated =>
      'Compte créé. Vérifiez votre e-mail pour le confirmer, puis connectez-vous.';

  @override
  String get authGenericError =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get txTitle => 'Transactions';

  @override
  String get txLoadError => 'Impossible de charger les transactions';

  @override
  String txAtPrice(String price) {
    return 'à $price';
  }

  @override
  String get txEmpty => 'Aucune transaction';

  @override
  String get txEmptyHint =>
      'Ajoutez un actif et une entrée d\'achat apparaîtra ici.';

  @override
  String get egHalf => 'p. ex. 0,5';

  @override
  String get egOne => 'p. ex. 1';

  @override
  String get egFive => 'p. ex. 5';

  @override
  String get etfDisplayHint =>
      'P. ex. un ETF obligataire peut être affiché sous « Obligations » au lieu de « ETF ».';

  @override
  String get otherDisplayHint =>
      'Un actif qui n\'est pas dans les listes (p. ex. une action non prise en charge) peut être affiché dans une catégorie correspondante.';

  @override
  String get topMovers => 'Plus fortes variations';

  @override
  String get emptyPortfolioTitle => 'Votre portefeuille est vide';

  @override
  String get emptyPortfolioBody =>
      'Ajoutez votre premier actif — liquidités, actions, or ou crypto — et vous verrez ici l\'ensemble de votre patrimoine.';

  @override
  String get addAssets => 'Ajouter des actifs';

  @override
  String get currencyPickerTitle => 'Afficher la valeur en devise';

  @override
  String get currencyPickerNote =>
      'Converti au taux du jour. L\'historique du graphique est une projection du taux actuel, pas une valeur passée.';

  @override
  String get currencyLoadError => 'Impossible de charger les devises';

  @override
  String get worth => 'd\'une valeur de ';

  @override
  String get editAmountAndValue => 'Modifier la quantité et la valeur';

  @override
  String get editAmountTooltip => 'Modifier la quantité';

  @override
  String get errEnterValidValue => 'Saisissez une valeur valide.';

  @override
  String get deleteAssetTitle => 'Supprimer l\'actif ?';

  @override
  String deleteAssetConfirm(String name) {
    return '« $name » disparaîtra de votre portefeuille.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String updateAssetTitle(String name) {
    return 'Mettre à jour « $name »';
  }

  @override
  String editAmountTitle(String name) {
    return 'Modifier la quantité — $name';
  }

  @override
  String get valueEditServerHint =>
      'La modification de la valeur sera disponible après une mise à jour du serveur. Pour l\'instant, pour corriger l\'estimation, supprimez l\'actif et ajoutez-le à nouveau.';

  @override
  String get save => 'Enregistrer';

  @override
  String get deleteAssetButton => 'Supprimer l\'actif';

  @override
  String get loggedInAs => 'Connecté en tant que';

  @override
  String get open => 'Ouvrir';

  @override
  String get errorLabel => 'Erreur';

  @override
  String get errGeneric => 'Une erreur s\'est produite. Veuillez réessayer.';
}
