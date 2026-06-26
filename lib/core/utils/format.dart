/// Formatowanie kwot z odstępami na tysiącach: 127513.93 → "127 514".
/// Separator tysięcy to wąska spacja (U+202F) — nie łamie się na końcu linii
/// i wygląda czyściej niż zwykła spacja. Grupowanie robimy ręcznie, żeby nie
/// zależeć od separatorów konkretnego locale.
const _thinSpace = ' ';

/// Odstęp przed kodem waluty — twarda spacja (U+00A0), szersza niż wąska spacja
/// grupowania, żeby kwota nie zlewała się z walutą („1 000 USD", nie „1 000USD").
const _ccySpace = ' ';

/// Wstawia separatory tysięcy do całkowitej części liczby.
String _group(int absWhole) {
  final digits = absWhole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(_thinSpace);
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// "127 514" — zaokrąglone, bez groszy. Do dużych wartości portfela.
String money(num value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  return '$sign${_group(rounded.abs())}';
}

/// "127 514 PLN".
String moneyCcy(num value, String currency) => '${money(value)}$_ccySpace$currency';

/// "+1 234 PLN" / "-1 234 PLN" — zawsze ze znakiem, do PnL.
String moneySigned(num value, String currency) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${_group(value.abs().round())}$_ccySpace$currency';
}

/// "127 513,93 PLN" — z groszami (przecinek dziesiętny), gdy trzeba precyzji.
String moneyPreciseCcy(num value, String currency) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  final whole = abs.floor();
  final cents = ((abs - whole) * 100).round().toString().padLeft(2, '0');
  return '$sign${_group(whole)},$cents$_ccySpace$currency';
}

/// Skrót dużych liczb na osi wykresu: 100552 → "100.6k", 1.2e6 → "1.2M".
String compactNumber(double v) {
  if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}
