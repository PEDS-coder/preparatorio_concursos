import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool fullWidth;
  final Widget? icon;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final bool isEnabled;
  final Widget child;

  const GradientButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.elevation = 0,
    this.fullWidth = false,
    this.icon,
    this.width,
    this.height,
    this.textStyle,
    this.isEnabled = true,
  }) : super(key: key);

  // Construtor alternativo para compatibilidade com código existente
  // Esta implementação será substituída pelo adaptador global
  static GradientButton withText({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    LinearGradient? gradient,
    double borderRadius = 16.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    double elevation = 0,
    bool fullWidth = false,
    Widget? icon,
    double? width,
    double? height,
    TextStyle? textStyle,
    bool isEnabled = true,
  }) {
    return GradientButton(
      key: key,
      onPressed: onPressed,
      child: Text(text, style: textStyle ?? TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      gradient: gradient,
      borderRadius: borderRadius,
      padding: padding,
      elevation: elevation,
      fullWidth: fullWidth,
      icon: icon,
      width: width,
      height: height,
      textStyle: textStyle,
      isEnabled: isEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonGradient = !isEnabled
        ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
        : gradient ?? AppTheme.primaryGradient;

    return Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: padding,
            child: Center(
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 12),
                  ],
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OutlineGradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final bool fullWidth;
  final Widget? icon;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const OutlineGradientButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.gradient,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.borderWidth = 2.0,
    this.fullWidth = false,
    this.icon,
    this.width,
    this.height,
    this.textStyle,
  }) : super(key: key);

  // Construtor alternativo para compatibilidade com código existente
  static OutlineGradientButton withText({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    LinearGradient? gradient,
    double borderRadius = 16.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    double borderWidth = 2.0,
    bool fullWidth = false,
    Widget? icon,
    double? width,
    double? height,
    TextStyle? textStyle,
  }) {
    return OutlineGradientButton(
      key: key,
      onPressed: onPressed,
      child: Text(text, style: textStyle ?? TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      gradient: gradient,
      borderRadius: borderRadius,
      padding: padding,
      borderWidth: borderWidth,
      fullWidth: fullWidth,
      icon: icon,
      width: width,
      height: height,
      textStyle: textStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonGradient = gradient ?? AppTheme.primaryGradient;
    final buttonTextStyle = textStyle ??
        TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        );

    return Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            splashColor: AppTheme.primaryColor.withOpacity(0.2),
            highlightColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: padding,
              child: Center(
                child: Row(
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      SizedBox(width: 12),
                    ],
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IconGradientButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final double size;
  final double borderRadius;
  final double elevation;

  const IconGradientButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.size = 56.0,
    this.borderRadius = 16.0,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonGradient = gradient ?? AppTheme.primaryGradient;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
