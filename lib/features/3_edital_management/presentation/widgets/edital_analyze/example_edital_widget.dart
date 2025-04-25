import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que exibe a opção de usar um edital de exemplo
class ExampleEditalWidget extends StatelessWidget {
  final VoidCallback onUseExamplePressed;

  const ExampleEditalWidget({
    Key? key,
    required this.onUseExamplePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Não tem um edital?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use nosso edital de exemplo para testar a funcionalidade',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: onUseExamplePressed,
                icon: const Icon(Icons.description),
                label: const Text('Usar Edital de Exemplo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
