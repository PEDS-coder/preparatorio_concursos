import 'package:flutter/material.dart';
import '../../../../../core/widgets/styled_text_field.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/analysis_animation_widget.dart';

/// Widget para entrada de texto para geração de flashcards
class TextInputMode extends StatelessWidget {
  final TextEditingController textController;
  final TextEditingController materiaController;
  final bool isLoading;
  final VoidCallback onGeneratePressed;

  const TextInputMode({
    Key? key,
    required this.textController,
    required this.materiaController,
    required this.isLoading,
    required this.onGeneratePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de matéria
        Text(
          'Matéria',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        StyledTextField(
          controller: materiaController,
          hintText: 'Ex: Direito Constitucional',
          prefixIcon: Icons.subject,
        ),
        SizedBox(height: 16),

        // Campo de texto
        Text(
          'Texto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        StyledTextField(
          controller: textController,
          hintText: 'Cole aqui o texto para gerar flashcards...',
          prefixIcon: Icons.text_fields,
          maxLines: 10,
        ),
        SizedBox(height: 24),

        // Botão de gerar
        _buildGenerateButton(),
      ],
    );
  }

  Widget _buildGenerateButton() {
    if (isLoading) {
      return Container(
        height: 300,
        child: Center(
          child: Card(
            elevation: 8,
            color: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: AnalysisAnimationWidget(
                width: 350,
                height: 300,
                message: 'Criando Flashcards',
                statusMessages: [
                  'Analisando texto original...',
                  'Identificando conceitos chave...',
                  'Formulando perguntas...',
                  'Elaborando respostas...',
                  'Criando cartões de estudo...',
                  'Finalizando flashcards...',
                ],
                animationType: AnimationType.flashcard,
              ),
            ),
          ),
        ),
      );
    }

    return GradientButton(
      onPressed: onGeneratePressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome),
          SizedBox(width: 8),
          Text('GERAR FLASHCARDS'),
        ],
      ),
      fullWidth: true,
    );
  }
}
