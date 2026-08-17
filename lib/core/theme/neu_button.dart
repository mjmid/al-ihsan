import 'package:flutter/material.dart';

class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final EdgeInsetsGeometry padding;

  const NeuButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isPrimary = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Light Mode Button Shadows
    final lightRaised = [
      BoxShadow(
        color: const Color(0x73CEBBA9), // rgba(206, 187, 169, 0.45)
        offset: const Offset(5, 5),
        blurRadius: 12,
      ),
      BoxShadow(
        color: const Color(0xF2FFFFFF), // rgba(255, 255, 255, 0.95)
        offset: const Offset(-5, -5),
        blurRadius: 12,
      ),
    ];

    // Light Inset (Pressed)
    final lightInset = [
      BoxShadow(
        color: const Color(0x6BCEBBA9),
        offset: const Offset(3, 3),
        blurRadius: 6,
        blurStyle: BlurStyle.inner,
      ),
      BoxShadow(
        color: const Color(0xF2FFFFFF),
        offset: const Offset(-3, -3),
        blurRadius: 6,
        blurStyle: BlurStyle.inner,
      ),
    ];

    // Dark Mode Button Shadows
    final darkRaised = [
      BoxShadow(
        color: const Color(0x80000000), // rgba(0, 0, 0, 0.50)
        offset: const Offset(5, 5),
        blurRadius: 12,
      ),
      BoxShadow(
        color: const Color(0x9914343E), // rgba(20, 52, 62, 0.60)
        offset: const Offset(-4, -4),
        blurRadius: 10,
      ),
    ];

    // Dark Inset (Pressed)
    final darkInset = [
      BoxShadow(
        color: const Color(0x99000000),
        offset: const Offset(3, 3),
        blurRadius: 6,
        blurStyle: BlurStyle.inner,
      ),
      BoxShadow(
        color: const Color(0x8014343E),
        offset: const Offset(-3, -3),
        blurRadius: 6,
        blurStyle: BlurStyle.inner,
      ),
    ];

    // Primary Button (Highlighted)
    final primaryDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [theme.colorScheme.primary, const Color(0xFF166534)] // Dark Green
            : [
                theme.colorScheme.primary,
                const Color(0xFF1B5E2A)
              ], // Light Green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: _isPressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(0, 2),
                blurRadius: 4,
                blurStyle: BlurStyle.inner,
              )
            ]
          : [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.35),
                offset: const Offset(0, 4),
                blurRadius: 14,
              )
            ],
    );

    // Standard Secondary Button
    final secondaryDecoration = BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark ? const Color(0x2622D3EE) : const Color(0xA6FFFFFF),
        width: 1,
      ),
      boxShadow: _isPressed
          ? (isDark ? darkInset : lightInset)
          : (isDark ? darkRaised : lightRaised),
    );

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed == null) return;
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onPressed == null) return;
        setState(() => _isPressed = false);
        widget.onPressed!();
      },
      onTapCancel: () {
        if (widget.onPressed == null) return;
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: widget.padding,
        decoration: widget.isPrimary ? primaryDecoration : secondaryDecoration,
        transform: Matrix4.translationValues(0, _isPressed ? 1.0 : 0.0, 0),
        child: DefaultTextStyle(
          style: theme.textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w600,
            color:
                widget.isPrimary ? Colors.white : theme.colorScheme.onSurface,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
