enum PnlPeriod {
  lastVisit,
  yesterday,
  weekStart,
  monthStart,
  yearStart,
  allTime,
}

extension PnlPeriodLabel on PnlPeriod {
  String get label => switch (this) {
        PnlPeriod.lastVisit => 'Od ostatniej wizyty',
        PnlPeriod.yesterday => 'Od wczoraj',
        PnlPeriod.weekStart => 'Od początku tygodnia',
        PnlPeriod.monthStart => 'Od początku miesiąca',
        PnlPeriod.yearStart => 'Od początku roku',
        PnlPeriod.allTime => 'Od początku',
      };

  /// Zwraca datę snapshotu odpowiadającą danemu okresowi.
  /// null = nie wymaga snapshotu (lastVisit obsługiwany osobno).
  String? snapshotDate(DateTime now) => switch (this) {
        PnlPeriod.lastVisit => null,
        PnlPeriod.yesterday => _formatDate(now.subtract(const Duration(days: 1))),
        PnlPeriod.weekStart => _formatDate(_startOfWeek(now)),
        PnlPeriod.monthStart => _formatDate(DateTime(now.year, now.month, 1)),
        PnlPeriod.yearStart => _formatDate(DateTime(now.year, 1, 1)),
        PnlPeriod.allTime => null, // użyjemy najstarszej dostępnej daty
      };
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _startOfWeek(DateTime d) {
  // poniedziałek jako pierwszy dzień tygodnia
  final daysFromMonday = (d.weekday - 1) % 7;
  return DateTime(d.year, d.month, d.day - daysFromMonday);
}
