import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget de AppBar com gradiente para ser usado em toda a aplicação
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final LinearGradient? gradient;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appGradient = gradient ?? AppTheme.primaryGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: appGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: actions,
        leading: leading,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
