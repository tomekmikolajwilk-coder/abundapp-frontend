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
}
