import 'package:flutter/material.dart';

/// Widget para implementar um card com animação
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? shadowColor;
  final double elevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Duration duration;
  final bool enableTapAnimation;
  final bool enableHoverAnimation;
  final double hoverElevation;
  final double tapScale;
  
  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.color,
    this.shadowColor,
    this.elevation = 2.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.duration = const Duration(milliseconds: 200),
    this.enableTapAnimation = true,
    this.enableHoverAnimation = true,
    this.hoverElevation = 4.0,
    this.tapScale = 0.98,
  }) : super(key: key);
  
  @override
  _AnimatedCardState createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
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
      end: widget.tapScale,
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
    final color = widget.color ?? theme.cardColor;
    final shadowColor = widget.shadowColor ?? theme.shadowColor;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8.0);
    final padding = widget.padding ?? const EdgeInsets.all(16.0);
    final margin = widget.margin ?? const EdgeInsets.all(0.0);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableTapAnimation && _isPressed
              ? _scaleAnimation.value
              : 1.0,
          child: MouseRegion(
            onEnter: (_) {
              if (widget.enableHoverAnimation) {
                setState(() => _isHovered = true);
              }
            },
            onExit: (_) {
              if (widget.enableHoverAnimation) {
                setState(() => _isHovered = false);
              }
            },
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: (_) {
                if (widget.enableTapAnimation && widget.onTap != null) {
                  setState(() => _isPressed = true);
                  _controller.forward();
                }
              },
              onTapUp: (_) {
                if (widget.enableTapAnimation && widget.onTap != null) {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                }
              },
              onTapCancel: () {
                if (widget.enableTapAnimation && widget.onTap != null) {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                }
              },
              child: AnimatedContainer(
                duration: widget.duration,
                margin: margin,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(_isHovered ? 0.3 : 0.2),
                      blurRadius: _isHovered && widget.enableHoverAnimation
                          ? widget.hoverElevation
                          : widget.elevation,
                      offset: Offset(0, _isHovered && widget.enableHoverAnimation ? 4 : 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Padding(
                    padding: padding,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
