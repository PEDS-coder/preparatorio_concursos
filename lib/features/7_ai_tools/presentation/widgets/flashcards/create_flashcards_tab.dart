import 'package:flutter/material.dart';
import 'mode_selector.dart';
import 'text_input_mode.dart';
import 'document_upload_mode.dart';
import 'result_display.dart';

/// Widget para a aba de criação de flashcards
class CreateFlashcardsTab extends StatelessWidget {
  final String modoEntrada;
  final Function(String) onModeChanged;
  final TextEditingController textController;
  final TextEditingController materiaController;
  final bool isLoading;
  final String? errorMessage;
  final String? resultado;
  final String? textoUpload;
  final VoidCallback onGeneratePressed;
  final Function(String, String?, String?) onDocumentProcessed;

  const CreateFlashcardsTab({
    Key? key,
    required this.modoEntrada,
    required this.onModeChanged,
    required this.textController,
    required this.materiaController,
    required this.isLoading,
    this.errorMessage,
    this.resultado,
    this.textoUpload,
    required this.onGeneratePressed,
    required this.onDocumentProcessed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Criar Flashcards com IA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Faça upload de um documento ou insira um texto para gerar flashcards automaticamente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Seleção de modo
          ModeSelector(
            currentMode: modoEntrada,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 24),

          // Mensagem de erro, se houver
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
            ),

          // Conteúdo baseado no modo selecionado
          modoEntrada == 'texto'
              ? TextInputMode(
                  textController: textController,
                  materiaController: materiaController,
                  isLoading: isLoading,
                  onGeneratePressed: onGeneratePressed,
                )
              : DocumentUploadMode(
                  isLoading: isLoading,
                  onDocumentProcessed: onDocumentProcessed,
                ),

          // Resultado
          if (resultado != null)
            ResultDisplay(resultado: resultado!),
        ],
      ),
    );
  }
}
