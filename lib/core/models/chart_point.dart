class ChartPoint {
  final DateTime date;
  final double value;

  const ChartPoint({required this.date, required this.value});
}

/// Rolling zakres widoczny na wykresie. Steruje tylko oknem startowym —
/// pełna historia pozostaje załadowana, więc można przesuwać w lewo.
enum ChartRange { month, quarter, year, all }

extension ChartRangeX on ChartRange {
  String get label => switch (this) {
        ChartRange.month => '1M',
        ChartRange.quarter => '3M',
        ChartRange.year => '1R',
        ChartRange.all => 'MAX',
      };

  /// Liczba dni okna; null = cała historia.
  int? get days => switch (this) {
        ChartRange.month => 30,
        ChartRange.quarter => 90,
        ChartRange.year => 365,
        ChartRange.all => null,
      };
}

