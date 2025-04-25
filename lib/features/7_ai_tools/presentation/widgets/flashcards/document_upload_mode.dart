import 'package:flutter/material.dart';
import '../../../../../core/widgets/document_upload_widget.dart';
import '../../../../../core/widgets/analysis_animation_widget.dart';

/// Widget para upload de documentos para geração de flashcards
class DocumentUploadMode extends StatelessWidget {
  final bool isLoading;
  final Function(String, String?, String?) onDocumentProcessed;

  const DocumentUploadMode({
    Key? key,
    required this.isLoading,
    required this.onDocumentProcessed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Card(
            elevation: 8,
            color: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: AnalysisAnimationWidget(
                width: 350,
                height: 300,
                message: 'Criando Flashcards',
                statusMessages: [
                  'Processando documento...',
                  'Extraindo texto...',
                  'Identificando conceitos chave...',
                  'Formulando perguntas...',
                  'Elaborando respostas...',
                  'Criando cartões de estudo...',
                ],
                animationType: AnimationType.flashcard,
              ),
            ),
          ),
        ),
      );
    }

    return DocumentUploadWidget(
      title: 'Upload de Documento',
      description: 'Faça upload de um documento para gerar flashcards automaticamente',
      onDocumentProcessed: onDocumentProcessed,
    );
  }
}
