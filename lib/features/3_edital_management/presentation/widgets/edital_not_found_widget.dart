import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que exibe quando o edital não é encontrado
class EditalNotFoundWidget extends StatelessWidget {
  final VoidCallback onBack;

  const EditalNotFoundWidget({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text(
              'Edital não encontrado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('O edital solicitado não foi encontrado ou foi removido.'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
