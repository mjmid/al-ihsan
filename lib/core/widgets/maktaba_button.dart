import 'package:flutter/material.dart';

enum _MaktabaButtonType { primary, secondary, danger }

class MaktabaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final _MaktabaButtonType _type;

  const MaktabaButton.primary({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  })  : _type = _MaktabaButtonType.primary,
        super(key: key);

  const MaktabaButton.secondary({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  })  : _type = _MaktabaButtonType.secondary,
        super(key: key);

  const MaktabaButton.danger({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  })  : _type = _MaktabaButtonType.danger,
        super(key: key);

  @override
  State<MaktabaButton> createState() => _MaktabaButtonState();
}

class _MaktabaButtonState extends State<MaktabaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = widget._type == _MaktabaButtonType.danger;

    Widget buttonContent = widget.isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget._type == _MaktabaButtonType.primary || isDanger
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(0, 52)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Widget button;
    switch (widget._type) {
      case _MaktabaButtonType.primary:
        button = FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style,
          child: buttonContent,
        );
        break;
      case _MaktabaButtonType.secondary:
        button = OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style,
          child: buttonContent,
        );
        break;
      case _MaktabaButtonType.danger:
        button = FilledButton.tonal(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.errorContainer.withOpacity(0.5);
              }
              return theme.colorScheme.error;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onErrorContainer.withOpacity(0.5);
              }
              return theme.colorScheme.onError;
            }),
          ),
          child: buttonContent,
        );
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: button,
          ),
        ),
      ),
    );
  }
}
