import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que exibe a barra de navegação inferior com botões de ação
class BottomNavigationWidget extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onCreatePlanPressed;

  const BottomNavigationWidget({
    Key? key,
    required this.onBackPressed,
    required this.onCreatePlanPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: onBackPressed,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCreatePlanPressed,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Criar Plano'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
