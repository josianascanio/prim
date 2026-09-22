import 'package:flutter/material.dart';

class AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double borderRadius;
  final bool isSpinning;

  const AnimatedActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.borderRadius = 12.0,
    this.isSpinning = false,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _spinController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _spinAnimation = Tween<double>(begin: 0, end: -1).animate(_spinController);
    if (widget.isSpinning) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _spinController.repeat();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _spinController.dispose();
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
    final isDisabled = widget.onPressed == null && !widget.isSpinning;

    Widget buttonContent = Container(
      width: widget.size,
      height: widget.size ?? double.infinity,
      decoration: BoxDecoration(
        color: isDisabled ? bgColor.withOpacity(0.5) : bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: RotationTransition(
        turns: _spinAnimation,
        child: Icon(widget.icon, color: isDisabled ? fgColor.withOpacity(0.5) : fgColor),
      ),
    );

    if (widget.size == null) {
      buttonContent = AspectRatio(aspectRatio: 1.0, child: buttonContent);
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(message: widget.tooltip, child: buttonContent),
      ),
    );
  }
}
