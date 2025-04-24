import 'package:flutter/material.dart';

/// Widget que exibe instruções para o usuário
class InstructionsWidget extends StatelessWidget {
  const InstructionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'Instruções',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. Faça o upload do arquivo PDF do edital do concurso',
            style: TextStyle(color: Colors.blue.shade900),
          ),
          SizedBox(height: 4),
          Text(
            '2. Clique em "Analisar com IA" para extrair informações do edital',
            style: TextStyle(color: Colors.blue.shade900),
          ),
          SizedBox(height: 4),
          Text(
            '3. Aguarde a análise ser concluída para visualizar os resultados',
            style: TextStyle(color: Colors.blue.shade900),
          ),
          SizedBox(height: 8),
          Text(
            'Dica: Você pode selecionar múltiplos arquivos PDF se o edital estiver dividido em vários documentos.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
