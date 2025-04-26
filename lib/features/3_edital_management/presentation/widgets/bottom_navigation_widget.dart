import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../screens/cargo_select_screen.dart';

/// Widget que representa a barra de navegação inferior
class BottomNavigationWidget extends StatelessWidget {
  final String editalId;
  final VoidCallback onBack;

  const BottomNavigationWidget({
    Key? key,
    required this.editalId,
    required this.onBack,
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
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar para a tela de seleção de cargo usando a rota nomeada
                Navigator.pushNamed(
                  context,
                  '/cargo/select',
                  arguments: editalId,
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Selecionar Cargo'),
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
