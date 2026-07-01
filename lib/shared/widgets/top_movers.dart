import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/top_mover.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/providers/top_movers_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../features/dashboard/dashboard_context.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../l10n/app_localizations.dart';
import 'asset_avatar.dart';
import 'chart_reveal.dart';

/// Wybiera karty do sekcji „Top movers" z listy posortowanej po sile ruchu.
///
/// Reguły:
/// - <2 aktywa → pusta lista (nie ma czego rankować, sekcja się chowa);
/// - ≥4 aktywa → po 2 z każdej strony (cel 4 karty), inaczej po 1 (cel 2);
/// - najpierw `perSide` gainerów i loserów, potem dopełnienie brakujących
///   slotów mocniejszą stroną (po |%|), żeby utrzymać stałą liczbę kart;
/// - finalna kolejność: gainery malejąco, potem losery (najmocniejszy spadek).
List<TopMover> selectTopMovers(List<TopMover> movers) {
  // <2 aktywa → nie ma czego rankować.
  if (movers.length < 2) return const [];

  // ≥4 aktywa → 4 karty (cel 2+2); mniej → 2 karty (cel 1+1).
  final perSide = movers.length >= 4 ? 2 : 1;
  final target = perSide * 2;

  final gainers = movers
      .where((m) => m.pricePct != null && m.pricePct! > 0)
      .toList()
    ..sort((a, b) => b.pricePct!.compareTo(a.pricePct!));
  final losers = movers
      .where((m) => m.pricePct != null && m.pricePct! < 0)
      .toList()
    ..sort((a, b) => a.pricePct!.compareTo(b.pricePct!));

  // Najpierw po `perSide` z każdej strony, potem dopełniamy brakujące sloty
  // mocniejszą stroną (po |%|), żeby utrzymać stałą liczbę kart.
  final selected = <TopMover>[
    ...gainers.take(perSide),
    ...losers.take(perSide),
  ];
  if (selected.length < target) {
    final leftovers = [
      ...gainers.skip(perSide),
      ...losers.skip(perSide),
    ]..sort((a, b) => b.pricePct!.abs().compareTo(a.pricePct!.abs()));
    selected.addAll(leftovers.take(target - selected.length));
  }

  // Kolejność: gainery (malejąco) przed loserami (najmocniejszy spadek).
  selected.sort((a, b) {
    final aUp = a.pricePct! > 0, bUp = b.pricePct! > 0;
    if (aUp != bUp) return aUp ? -1 : 1;
    return aUp
        ? b.pricePct!.compareTo(a.pricePct!)
        : a.pricePct!.compareTo(b.pricePct!);
  });

  return selected;
}

class TopMovers extends ConsumerWidget {
  final DashboardContext dashContext;

  const TopMovers({super.key, required this.dashContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Na poziomie pojedynczego aktywa nie ma „moverów".
    if (dashContext.level == DashboardLevel.asset) {
      return const SizedBox.shrink();
    }

    final movers = ref.watch(topMoversProvider(dashContext));
    final selected = selectTopMovers(movers);

    // Brak kart (za mało aktywów lub żadnego ruchu) → chowamy sekcję.
    if (selected.isEmpty) return const SizedBox.shrink();

    final currency = ref.watch(portfolioProvider).valueOrNull?.currency ?? '';

    return ChartReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).topMovers,
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),
          // Siatka 2 w rzędzie: górny rząd gainery, dolny losery; karty
          // rozciągnięte na całą szerokość (Expanded).
          for (var i = 0; i < selected.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MoverCard(mover: selected[i], currency: currency),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < selected.length
                        ? _MoverCard(
                            mover: selected[i + 1], currency: currency)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoverCard extends ConsumerWidget {
  final TopMover mover;
  final String currency;

  const _MoverCard({required this.mover, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = mover.isPositive ? AppColors.positive : AppColors.negative;
    final spark = ref.watch(moverSparklineProvider(mover.assetId));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            context: DashboardContext.asset(mover.category, mover.assetId),
          ),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symbol + strzałka
          Row(
            children: [
              AssetAvatar.asset(
                assetId: mover.assetId,
                category: mover.category,
                size: 26,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  mover.assetId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                mover.isPositive ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Wartość bieżąca
          Text(
            moneyCcy(mover.valueNow, currency),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          // Sparkline
          Expanded(
            child: spark.maybeWhen(
              data: (points) => points.length < 2
                  ? const SizedBox.shrink()
                  : _Sparkline(points: points, color: color),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          // % zmiany w okresie
          Row(
            children: [
              Text(
                '${mover.isPositive ? '+' : '−'}${mover.pricePct!.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// Lekki sparkline rysowany CustomPainterem — linia + miękkie wypełnienie pod.
class _Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;

  const _Sparkline({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _SparklinePainter(points: points, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final dx = size.width / (points.length - 1);

    Offset at(int i) {
      final x = dx * i;
      final norm = (points[i] - minV) / range; // 0..1
      final y = size.height - norm * size.height;
      return Offset(x, y);
    }

    final line = Path()..moveTo(0, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }

    // Wypełnienie pod linią
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // Linia
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.color != color;
}
