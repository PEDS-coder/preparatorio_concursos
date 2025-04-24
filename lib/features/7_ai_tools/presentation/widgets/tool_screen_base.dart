import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../theme/tool_themes.dart';

/// Widget base para as telas de ferramentas de IA
/// 
/// Este widget aplica o tema específico da ferramenta e fornece uma estrutura
/// consistente para todas as telas de ferramentas.
class ToolScreenBase extends StatelessWidget {
  final String title;
  final String toolType;
  final Widget body;
  final List<Widget>? actions;
  final List<Widget>? tabs;
  final TabController? tabController;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget premiumRequiredWidget;

  const ToolScreenBase({
    Key? key,
    required this.title,
    required this.toolType,
    required this.body,
    this.actions,
    this.tabs,
    this.tabController,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    required this.premiumRequiredWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPremium = authService.isPremium;
    final toolTheme = ToolThemes.getThemeForTool(toolType);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              toolTheme.icon,
              color: toolTheme.color,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: actions,
        bottom: tabs != null && tabController != null
            ? TabBar(
                controller: tabController,
                indicatorColor: toolTheme.color,
                labelColor: toolTheme.color,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: tabs!,
              )
            : null,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkBackground,
                toolTheme.color.withOpacity(0.1),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkBackground,
              toolTheme.color.withOpacity(0.05),
              AppTheme.darkBackground,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: !isPremium ? premiumRequiredWidget : body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
    );
  }
}

/// Widget para exibir a mensagem de recurso premium
class PremiumRequiredWidget extends StatelessWidget {
  final String toolType;
  final VoidCallback? onUpgrade;

  const PremiumRequiredWidget({
    Key? key,
    required this.toolType,
    this.onUpgrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolTheme = ToolThemes.getThemeForTool(toolType);
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 800 || screenSize.height > 600;
    final isFullScreen = screenSize.height > 700;

    return Container(
      padding: EdgeInsets.all(isFullScreen ? 12 : (isLargeScreen ? 20 : 16)),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isFullScreen ? 16 : (isLargeScreen ? 24 : 20)),
            width: isLargeScreen ? 450 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(isFullScreen ? 16 : (isLargeScreen ? 24 : 20)),
              border: Border.all(
                color: toolTheme.color.withOpacity(0.3),
                width: isLargeScreen ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: toolTheme.color.withOpacity(0.1),
                  blurRadius: isFullScreen ? 20 : (isLargeScreen ? 30 : 20),
                  spreadRadius: isFullScreen ? 4 : (isLargeScreen ? 8 : 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock,
                  size: isFullScreen ? 40 : (isLargeScreen ? 56 : 48),
                  color: toolTheme.color,
                ),
                SizedBox(height: isFullScreen ? 12 : (isLargeScreen ? 20 : 16)),
                Text(
                  'Recursos Premium',
                  style: TextStyle(
                    fontSize: isFullScreen ? 20 : (isLargeScreen ? 26 : 22),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isFullScreen ? 8 : (isLargeScreen ? 14 : 12)),
                Text(
                  'Esta ferramenta está disponível apenas para usuários premium.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isFullScreen ? 13 : (isLargeScreen ? 16 : 14),
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: isFullScreen ? 16 : (isLargeScreen ? 24 : 20)),
                ElevatedButton(
                  onPressed: onUpgrade ?? () async {
                    // Simulação de upgrade
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.upgradeToPremium();

                    // Mostrar confirmação
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Parabéns! Você agora é um usuário Premium.'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: toolTheme.color,
                    padding: EdgeInsets.symmetric(
                      vertical: isFullScreen ? 10 : (isLargeScreen ? 14 : 12),
                      horizontal: isFullScreen ? 20 : (isLargeScreen ? 28 : 24)
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isFullScreen ? 10 : (isLargeScreen ? 14 : 12)),
                    ),
                  ),
                  child: Text(
                    'FAZER UPGRADE',
                    style: TextStyle(
                      fontSize: isFullScreen ? 13 : (isLargeScreen ? 15 : 14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
