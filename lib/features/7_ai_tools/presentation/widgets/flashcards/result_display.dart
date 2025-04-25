import 'package:flutter/material.dart';
import '../../../../../core/widgets/modern_card.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para exibir o resultado da geração de flashcards
class ResultDisplay extends StatelessWidget {
  final String resultado;
  final VoidCallback? onDownload;

  const ResultDisplay({
    Key? key,
    required this.resultado,
    this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: ModernCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Flashcards Gerados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              resultado,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('BAIXAR'),
                  onPressed: onDownload ?? () {
                    // Implementação padrão se não for fornecida
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download iniciado'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
