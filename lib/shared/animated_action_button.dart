import 'package:flutter/material.dart';

class AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double borderRadius;

  const AnimatedActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.borderRadius = 12.0,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = widget.iconColor ?? theme.colorScheme.onPrimaryContainer;
    final isDisabled = widget.onPressed == null;

    Widget buttonContent = Container(
      width: widget.size,
      height: widget.size ?? double.infinity,
      decoration: BoxDecoration(
        color: isDisabled ? bgColor.withOpacity(0.5) : bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Icon(
        widget.icon,
        color: isDisabled ? fgColor.withOpacity(0.5) : fgColor,
      ),
    );

    if (widget.size == null) {
      buttonContent = AspectRatio(
        aspectRatio: 1.0,
        child: buttonContent,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: widget.tooltip,
          child: buttonContent,
        ),
      ),
    );
  }
}
