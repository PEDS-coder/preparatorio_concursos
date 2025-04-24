import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget que aplica um gradiente a um container com efeitos de sombra
/// 
/// Pode ser usado para criar elementos de UI com transições de cores
/// em vez de cores sólidas, seguindo o design elegante solicitado.
class GradientContainer extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final bool addShadow;
  final double? width;
  final double? height;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Border? border;

  const GradientContainer({
    Key? key,
    required this.child,
    this.gradient,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0),
    this.elevation = 2.0,
    this.addShadow = true,
    this.width,
    this.height,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LinearGradient effectiveGradient = gradient ?? AppTheme.primaryGradient;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: addShadow ? [
          BoxShadow(
            color: effectiveGradient.colors.first.withOpacity(0.3),
            blurRadius: elevation * 4,
            spreadRadius: elevation,
            offset: const Offset(0, 2),
          ),
        ] : null,
        border: border,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  /// Cria um GradientContainer com o gradiente primário
  factory GradientContainer.primary({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.primaryGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }

  /// Cria um GradientContainer com o gradiente secundário
  factory GradientContainer.secondary({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.secondaryGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }

  /// Cria um GradientContainer com o gradiente azul
  factory GradientContainer.blue({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.blueGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }

  /// Cria um GradientContainer com o gradiente vermelho
  factory GradientContainer.red({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.redGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }

  /// Cria um GradientContainer com o gradiente verde
  factory GradientContainer.green({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.greenGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }

  /// Cria um GradientContainer com o gradiente âmbar
  factory GradientContainer.amber({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.amberGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }

  /// Cria um GradientContainer com o gradiente roxo
  factory GradientContainer.purple({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(0),
    double elevation = 2.0,
    bool addShadow = true,
    double? width,
    double? height,
  }) {
    return GradientContainer(
      child: child,
      gradient: AppTheme.purpleGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      addShadow: addShadow,
      width: width,
      height: height,
    );
  }
}
