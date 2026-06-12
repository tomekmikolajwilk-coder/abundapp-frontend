import 'package:flutter/material.dart';

/// Subtelne wejście wykresu: fade + delikatny ruch w górę, odtwarzane RAZ
/// przy zamontowaniu (gdy dane dotrą). Dzięki Tween(begin→end) animacja gra
/// tylko na starcie — kolejne przebudowy (np. zaznaczenie segmentu) jej nie
/// wznawiają, bo TweenAnimationBuilder reaguje wyłącznie na zmianę `end`.
class ChartReveal extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ChartReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 550),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
    );
  }
}
