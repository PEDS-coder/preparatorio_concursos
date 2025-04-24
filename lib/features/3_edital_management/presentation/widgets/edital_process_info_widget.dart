import 'package:flutter/material.dart';

/// Widget que representa as informações sobre o processo de análise de edital
class EditalProcessInfoWidget extends StatelessWidget {
  const EditalProcessInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como funciona:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildProcessStep(
          '1. Upload do Edital',
          'Envie os arquivos PDF do edital do concurso',
        ),
        SizedBox(height: 16),
        _buildProcessStep(
          '2. Análise com IA',
          'A API LLM (Gemini ou OpenAI) analisa o edital e extrai as informações importantes',
        ),
        SizedBox(height: 16),
        _buildProcessStep(
          '3. Seleção de Cargo',
          'Escolha o cargo para o qual deseja se preparar',
        ),
        SizedBox(height: 16),
        _buildProcessStep(
          '4. Plano Personalizado',
          'Receba um plano de estudos personalizado para o cargo escolhido',
        ),
      ],
    );
  }

  Widget _buildProcessStep(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
