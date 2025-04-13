import 'package:flutter/material.dart';

/// Widget para implementar um botão com animação
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Duration duration;
  final bool isLoading;
  final bool isEnabled;
  final double elevation;
  final double? width;
  final double? height;
  final String? tooltip;
  
  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 200),
    this.isLoading = false,
    this.isEnabled = true,
    this.elevation = 2.0,
    this.width,
    this.height,
    this.tooltip,
  }) : super(key: key);
  
  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar a animação
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;
    final textColor = widget.textColor ?? theme.colorScheme.onPrimary;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8.0);
    final padding = widget.padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    
    final button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.isEnabled ? buttonColor : buttonColor.withOpacity(0.5),
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(0.3),
                  blurRadius: widget.elevation,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
                onTapDown: (_) {
                  if (widget.isEnabled && !widget.isLoading) {
                    setState(() => _isPressed = true);
                    _controller.forward();
                  }
                },
                onTapUp: (_) {
                  if (widget.isEnabled && !widget.isLoading) {
                    setState(() => _isPressed = false);
                    _controller.reverse();
                  }
                },
                onTapCancel: () {
                  if (widget.isEnabled && !widget.isLoading) {
                    setState(() => _isPressed = false);
                    _controller.reverse();
                  }
                },
                borderRadius: borderRadius,
                child: Padding(
                  padding: padding,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 24.0,
                            height: 24.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              strokeWidth: 2.0,
                            ),
                          )
                        : DefaultTextStyle(
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            child: widget.child,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}
