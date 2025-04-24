import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Classe utilitária para padronizar a navegação do BottomNavigationBar em todas as telas
class BottomNavigationHelper {
  /// Cria um BottomNavigationBar padronizado para todas as telas
  static Widget buildBottomNavigationBar(
    BuildContext context, {
    required int currentIndex,
    bool useDarkTheme = false,
  }) {
    final Color backgroundColor = useDarkTheme ? AppTheme.darkSurface : Colors.white;
    final Color unselectedColor = useDarkTheme ? Colors.white.withOpacity(0.7) : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            _navigateToTab(context, index);
          }
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: unselectedColor,
        backgroundColor: backgroundColor,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          color: unselectedColor,
          fontSize: 12,
        ),
        items: [
          // Abas principais
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            activeIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            activeIcon: Icon(Icons.article, color: AppTheme.primaryColor),
            label: 'Meu Edital',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            activeIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            label: 'Plano',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            activeIcon: Icon(Icons.insights, color: AppTheme.primaryColor),
            label: 'Progresso',
          ),
          // Ferramentas de IA (agrupadas)
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            activeIcon: Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
            label: 'Ferramentas',
          ),
          // Mercado Aprovação
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            activeIcon: Icon(Icons.shopping_bag, color: AppTheme.primaryColor),
            label: 'Mercado',
          ),
        ],
      ),
    );
  }

  /// Navega para a aba correspondente ao índice
  static void _navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1: // Meu Edital
        Navigator.pushReplacementNamed(context, '/editais');
        break;
      case 2: // Plano
        Navigator.pushReplacementNamed(context, '/plano');
        break;
      case 3: // Progresso
        Navigator.pushReplacementNamed(context, '/gamificacao');
        break;
      case 4: // Ferramentas
        Navigator.pushReplacementNamed(context, '/ferramentas');
        break;
      case 5: // Mercado
        Navigator.pushReplacementNamed(context, '/mercado');
        break;
    }
  }
}
