import 'package:flutter/material.dart';

/// Widget que exibe uma mensagem quando nenhum cargo é encontrado
class NoCargosMessageWidget extends StatelessWidget {
  final VoidCallback onUseGenericCargo;
  final VoidCallback onBack;

  const NoCargosMessageWidget({
    Key? key,
    required this.onUseGenericCargo,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Nenhum cargo identificado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Não foi possível identificar cargos no edital. Isso pode ocorrer quando a API não consegue extrair corretamente os cargos do PDF. Você pode continuar com um cargo genérico ou voltar e tentar analisar o edital novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.amber.shade800),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.add_circle_outline),
                label: Text('Usar Cargo Genérico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: onUseGenericCargo,
              ),
              SizedBox(width: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.arrow_back),
                label: Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade800,
                  side: BorderSide(color: Colors.amber.shade600),
                ),
                onPressed: onBack,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Dica: Você pode tentar selecionar apenas as páginas do PDF que contêm informações sobre os cargos para melhorar a análise.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
