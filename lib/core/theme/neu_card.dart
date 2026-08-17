import 'package:flutter/material.dart';

class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light mode shadows from growhalal-theme.css
    final lightShadows = [
      BoxShadow(
        color: const Color(0x7ACEBBA9), // rgba(206, 187, 169, 0.48)
        offset: const Offset(8, 8),
        blurRadius: 18,
      ),
      BoxShadow(
        color: const Color(0xF2FFFFFF), // rgba(255, 255, 255, 0.95)
        offset: const Offset(-8, -8),
        blurRadius: 18,
      ),
    ];

    // Dark mode shadows from growhalal-theme.css
    final darkShadows = [
      BoxShadow(
        color: const Color(0x8C000000), // rgba(0, 0, 0, 0.55)
        offset: const Offset(8, 8),
        blurRadius: 20,
      ),
      BoxShadow(
        color: const Color(0xA614343E), // rgba(20, 52, 62, 0.65)
        offset: const Offset(-6, -6),
        blurRadius: 16,
      ),
    ];

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? const Color(0x2622D3EE) : const Color(0xA6FFFFFF),
          width: 1,
        ),
        boxShadow: isDark ? darkShadows : lightShadows,
      ),
      child: child,
    );
  }
}
