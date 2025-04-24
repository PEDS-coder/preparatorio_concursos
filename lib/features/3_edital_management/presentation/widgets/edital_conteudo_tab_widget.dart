import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';

/// Widget que representa a aba de conteúdo do edital
class EditalConteudoTabWidget extends StatelessWidget {
  final Edital edital;

  const EditalConteudoTabWidget({
    Key? key,
    required this.edital,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Texto do Edital',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              edital.textoCompleto.length > 1000
                  ? '${edital.textoCompleto.substring(0, 1000)}...\n\n[Texto truncado]'
                  : edital.textoCompleto,
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // Implementar visualização completa do edital
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Funcionalidade disponível em breve!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: Icon(Icons.visibility),
            label: Text('Ver Texto Completo'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
