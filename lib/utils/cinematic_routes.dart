import 'package:flutter/material.dart';

/// Cinematic route: cross-fade + gentle slide up + subtle scale settle.
Route<T> cinematicRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          final value = curved.value;
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 26),
              child: Transform.scale(
                scale: 0.985 + 0.015 * value,
                child: child,
              ),
            ),
          );
        },
        child: child,
      );
    },
  );
}

/// Glowing dialog route (used by the random picker).
Route<T> cinematicDialogRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    barrierDismissible: false,
    opaque: false,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

extension CinematicNavigation on BuildContext {
  Future<T?> pushCinematic<T>(Widget page) {
    return Navigator.of(this).push(cinematicRoute<T>(page));
  }

  Future<T?> pushCinematicDialog<T>(Widget page) {
    return Navigator.of(this).push(cinematicDialogRoute<T>(page));
  }
}