import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Переход между экранами в стиле Material «fade-through»:
/// уходящий экран растворяется и слегка отдаляется, входящий —
/// проявляется и подтягивается к нормальному масштабу.
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  FadeThroughPageRoute({required this.page, super.settings})
      : super(
          transitionDuration: Motion.emphasized,
          reverseTransitionDuration: Motion.base,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Motion.emphasizedCurve,
              reverseCurve: Motion.standard,
            );
            final outgoing = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Motion.standard,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: curved, curve: const Interval(0.2, 1)),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(
                    CurvedAnimation(
                      parent: outgoing,
                      curve: const Interval(0, 0.6),
                    ),
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1, end: 1.04).animate(outgoing),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );

  final Widget page;
}
