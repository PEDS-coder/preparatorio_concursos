import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para exibir mensagem de recurso premium
class PremiumRequiredView extends StatelessWidget {
  final VoidCallback onUpgradePressed;

  const PremiumRequiredView({
    Key? key,
    required this.onUpgradePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.amber,
            ),
            SizedBox(height: 24),
            Text(
              'Recurso Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Os flashcards com IA estão disponíveis apenas para usuários premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('FAZER UPGRADE'),
            ),
          ],
        ),
      ),
    );
  }
}
