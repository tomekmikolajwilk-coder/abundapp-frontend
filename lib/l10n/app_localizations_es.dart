// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Abundapp';

  @override
  String get addAsset => 'Añadir activo';

  @override
  String get add => 'Añadir';

  @override
  String get valueOverTime => 'Valor en el tiempo';

  @override
  String get changeBreakdown => 'Desglose del cambio';

  @override
  String get breakdownTransactions => 'Transacciones';

  @override
  String get breakdownPriceMovement => 'Movimiento de precio';

  @override
  String get breakdownInterest => 'Intereses';

  @override
  String get noData => 'Sin datos';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get myPortfolio => 'Mi cartera';

  @override
  String get portfolioCenter => 'Cartera';

  @override
  String get portfolioValue => 'Valor de la cartera';

  @override
  String valueOf(String name) {
    return 'Valor de $name';
  }

  @override
  String yourAsset(String asset) {
    return 'Tu $asset';
  }

  @override
  String get periodLastVisit => 'Desde la última visita';

  @override
  String get periodYesterday => 'Desde ayer';

  @override
  String get periodWeekStart => 'Desde el inicio de la semana';

  @override
  String get periodMonthStart => 'Desde el inicio del mes';

  @override
  String get periodYearStart => 'Desde el inicio del año';

  @override
  String get periodAllTime => 'Desde el inicio';

  @override
  String get categoryCrypto => 'Cripto';

  @override
  String get categoryStock => 'Acciones';

  @override
  String get categoryEtf => 'ETF';

  @override
  String get categoryMetal => 'Metales';

  @override
  String get categoryCurrency => 'Efectivo';

  @override
  String get categoryRealEstate => 'Inmuebles';

  @override
  String get categoryValuables => 'Objetos de valor';

  @override
  String get categoryBonds => 'Bonos';

  @override
  String get categoryDeposits => 'Depósitos';

  @override
  String get categoryOther => 'Otros';

  @override
  String get addSectionMarket => 'Activos de mercado';

  @override
  String get addSectionMarketHint =>
      'La app conoce el precio — solo indicas la cantidad.';

  @override
  String get addSectionManual => 'Tú indicas el valor';

  @override
  String get addSectionManualHint =>
      'Inmuebles, objetos de valor y más — tú proporcionas la valoración.';

  @override
  String get fieldAsset => 'Activo';

  @override
  String get fieldAmountOwned => 'Cuánto posees';

  @override
  String get showInCategory => 'Mostrar en categoría (opcional)';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldQuantity => 'Cantidad';

  @override
  String get fieldUnitValue => 'Valor unitario';

  @override
  String get bondGrowthHint =>
      'El valor crece esto al año — se acumula a diario.';

  @override
  String get bondRateLabel => 'Tipo de interés anual (%)';

  @override
  String get bondInfoTitle => 'Cómo funciona el cálculo';

  @override
  String get bondInfoText =>
      'El valor de un bono crece a diario según el tipo de interés dividido entre 365 días. Con un 5% anual y un valor de 100, tras un año tienes unos 105. La app lo recalcula una vez al día en el servidor.';

  @override
  String get ok => 'OK';

  @override
  String get errEnterName => 'Introduce el nombre del activo.';

  @override
  String get errEnterAmount => 'Introduce una cantidad válida.';

  @override
  String get errEnterUnitValue => 'Introduce el valor unitario.';

  @override
  String get errInvalidRate => 'Tipo de interés no válido.';

  @override
  String get errSelectAsset => 'Selecciona un activo.';

  @override
  String get errPriceUnavailable =>
      'No podemos valorar este activo ahora mismo. Elige otro o añádelo en «Otros» con un valor establecido manualmente.';

  @override
  String get errPriceTransient =>
      'No se pudo obtener el precio ahora mismo. Inténtalo de nuevo en un momento.';

  @override
  String get search => 'Buscar…';

  @override
  String get searchByNameOrTicker => 'Buscar por nombre o símbolo…';

  @override
  String get minTwoChars => 'Escribe al menos 2 caracteres para buscar.';

  @override
  String get noResults => 'Sin resultados.';

  @override
  String get errLoadAssets => 'No se pudieron cargar los activos';

  @override
  String get assetNotListedQuestion => '¿No encuentras tu activo? ';

  @override
  String get addInOtherCategory => 'Añádelo en Otros';

  @override
  String get andSetValueManually => ' y establece el valor manualmente.';

  @override
  String get pickFromList => 'Elegir de la lista';

  @override
  String get chooseAsset => 'Elegir activo';

  @override
  String get authTagline => 'Tu patrimonio en un solo lugar.';

  @override
  String get authSignInTitle => 'Iniciar sesión';

  @override
  String get authSignUpTitle => 'Crear cuenta';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authSignUp => 'Registrarse';

  @override
  String get authToggleToSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authToggleToSignUp => '¿No tienes cuenta? Regístrate';

  @override
  String get authEmail => 'Correo';

  @override
  String get authEnterEmail => 'Introduce tu correo';

  @override
  String get authInvalidEmail => 'Correo no válido';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authEnterPassword => 'Introduce tu contraseña';

  @override
  String get authPasswordMin =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get authAccountCreated =>
      'Cuenta creada. Revisa tu correo para confirmarla y luego inicia sesión.';

  @override
  String get authGenericError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get txTitle => 'Transacciones';

  @override
  String get txLoadError => 'No se pudieron cargar las transacciones';

  @override
  String txAtPrice(String price) {
    return 'a $price';
  }

  @override
  String get txEmpty => 'Sin transacciones';

  @override
  String get txEmptyHint =>
      'Añade un activo y aquí aparecerá una entrada de compra.';

  @override
  String get egHalf => 'p. ej. 0,5';

  @override
  String get egOne => 'p. ej. 1';

  @override
  String get egFive => 'p. ej. 5';

  @override
  String get etfDisplayHint =>
      'P. ej. un ETF de bonos puede mostrarse en «Bonos» en lugar de «ETF».';

  @override
  String get otherDisplayHint =>
      'Un activo que no está en las listas (p. ej. una acción no admitida) puede mostrarse en una categoría correspondiente.';
}
