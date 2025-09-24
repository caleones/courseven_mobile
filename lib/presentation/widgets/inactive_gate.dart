import 'package:flutter/material.dart';

/// InactiveGate
/// Reusable wrapper that dims and blocks interaction when [inactive] is true.
/// Optionally you can override [dimOpacity]. Defaults to 0.55.
class InactiveGate extends StatelessWidget {
  final bool inactive;
  final Widget child;
  final double dimOpacity;
  final Duration fadeDuration;

  const InactiveGate({
    super.key,
    required this.inactive,
    required this.child,
    this.dimOpacity = 0.55,
    this.fadeDuration = const Duration(milliseconds: 180),
  });

  @override
  Widget build(BuildContext context) {
    final content = IgnorePointer(
      ignoring: inactive,
      child: AnimatedOpacity(
        opacity: inactive ? dimOpacity : 1,
        duration: fadeDuration,
        curve: Curves.easeInOut,
        child: child,
      ),
    );
    return content;
  }
}
