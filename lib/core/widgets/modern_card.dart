import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool useShadow;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.useShadow = false,
    this.onTap,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = backgroundColor ?? (isDarkMode ? AppTheme.darkCardColor : Colors.white);
    final isLightCard = !isDarkMode || (backgroundColor != null && backgroundColor!.computeLuminance() > 0.5);

    // Aplicar DefaultTextStyle apenas se o card tiver fundo claro
    Widget content = isLightCard
        ? DefaultTextStyle(
            style: TextStyle(color: Colors.black87),
            child: child,
          )
        : child;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient != null ? null : cardColor,
          gradient: gradient,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          boxShadow: useShadow ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ] : null,
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: isDarkMode ? 1 : 0,
          ),
        ),
        child: content,
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final LinearGradient? gradient;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.gradient,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.primaryGradient,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient?.colors.first ?? AppTheme.primaryColor).withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
