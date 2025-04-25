import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/document_storage_service.dart';
import '../../../../core/data/models/flashcard.dart';

/// Serviço para gerenciar a geração de flashcards
class FlashcardsService {
  final IAServiceInterface iaService;
  final DocumentStorageService storageService;

  FlashcardsService({
    required this.iaService,
    required this.storageService,
  });

  /// Gera flashcards a partir de um texto
  Future<List<Flashcard>> gerarFlashcards({
    required String userId,
    required String texto,
    required String materia,
    String? editalId,
  }) async {
    // Salvar o documento enviado
    await storageService.addUploadedDocument(
      userId,
      'Texto para flashcards - $materia',
      'txt',
      DocumentStorageService.FLASHCARDS,
      texto.codeUnits,
    );

    // Gerar flashcards usando o serviço de IA
    final flashcards = await iaService.gerarFlashcards(
      userId: userId,
      editalId: editalId,
      materia: materia,
      texto: texto,
    );

    // Formatar o resultado como texto
    String resultado = 'Foram gerados ${flashcards.length} flashcards:\n\n';
    for (int i = 0; i < flashcards.length; i++) {
      final flashcard = flashcards[i];
      resultado += 'Flashcard ${i + 1}:\n';
      resultado += 'Pergunta: ${flashcard.pergunta}\n';
      resultado += 'Resposta: ${flashcard.resposta}\n\n';
    }

    // Salvar o resultado gerado
    await storageService.addGeneratedFile(
      userId,
      'Flashcards - $materia',
      'txt',
      DocumentStorageService.FLASHCARDS,
      resultado,
    );

    return flashcards;
  }

  /// Formata uma lista de flashcards como texto
  String formatarFlashcardsComoTexto(List<Flashcard> flashcards) {
    String resultado = 'Foram gerados ${flashcards.length} flashcards:\n\n';
    for (int i = 0; i < flashcards.length; i++) {
      final flashcard = flashcards[i];
      resultado += 'Flashcard ${i + 1}:\n';
      resultado += 'Pergunta: ${flashcard.pergunta}\n';
      resultado += 'Resposta: ${flashcard.resposta}\n\n';
    }
    return resultado;
  }
}
