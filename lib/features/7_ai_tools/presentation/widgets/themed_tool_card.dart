import 'package:flutter/material.dart';
import '../../../../core/widgets/modern_card.dart';
import '../theme/tool_themes.dart';

/// Widget de card temático para as ferramentas de IA
/// 
/// Este widget aplica o tema específico da ferramenta aos cards
/// usados nas telas de ferramentas.
class ThemedToolCard extends StatelessWidget {
  final String toolType;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool useShadow;
  final bool useGradient;
  final bool useBorder;
  final BorderRadius? borderRadius;

  const ThemedToolCard({
    Key? key,
    required this.toolType,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.useShadow = true,
    this.useGradient = false,
    this.useBorder = true,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolTheme = ToolThemes.getThemeForTool(toolType);
    
    return ModernCard(
      onTap: onTap,
      useShadow: useShadow,
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      gradient: useGradient ? toolTheme.gradient : null,
      backgroundColor: !useGradient ? Colors.black.withOpacity(0.3) : null,
      child: Stack(
        children: [
          if (useBorder && !useGradient)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: toolTheme.color,
                  borderRadius: BorderRadius.only(
                    topLeft: (borderRadius ?? BorderRadius.circular(16)).topLeft,
                    topRight: (borderRadius ?? BorderRadius.circular(16)).topRight,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Widget de botão temático para as ferramentas de IA
class ThemedToolButton extends StatelessWidget {
  final String toolType;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isSmall;

  const ThemedToolButton({
    Key? key,
    required this.toolType,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolTheme = ToolThemes.getThemeForTool(toolType);
    
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: toolTheme.color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: isSmall ? 8 : 12,
          ),
        ),
        child: _buildButtonContent(toolTheme),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: toolTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: isSmall ? 8 : 12,
          ),
        ),
        child: _buildButtonContent(toolTheme),
      );
    }
  }

  Widget _buildButtonContent(ToolTheme toolTheme) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmall ? 16 : 20,
            color: isOutlined ? toolTheme.color : Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: isOutlined ? toolTheme.color : Colors.white,
            ),
          ),
        ],
      );
    } else {
      return Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 12 : 14,
          fontWeight: FontWeight.bold,
          color: isOutlined ? toolTheme.color : Colors.white,
        ),
      );
    }
  }
}
