import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'api_quota_indicator.dart';

/// AppBar personalizado que inclui um indicador de uso de cotas da API
class AppBarWithQuota extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showQuotaIndicator;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  
  const AppBarWithQuota({
    Key? key,
    required this.title,
    this.actions,
    this.showQuotaIndicator = true,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Criar uma lista de ações que inclui o indicador de cotas
    final List<Widget> allActions = [];
    
    // Adicionar o indicador de cotas se necessário
    if (showQuotaIndicator) {
      allActions.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: ApiQuotaIndicator(),
        ),
      );
    }
    
    // Adicionar as ações personalizadas
    if (actions != null) {
      allActions.addAll(actions!);
    }
    
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      leading: leading,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.gradientStart,
              AppTheme.gradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: allActions,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
