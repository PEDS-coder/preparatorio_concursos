import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuração de diretórios para a aplicação
class DirectoryConfig {
  /// Diretório raiz para armazenar as respostas da API
  static final String apiResponsesDir = '${Directory.current.path}/api_responses';

  /// Diretório para armazenar as respostas da primeira chamada
  static final String primeiraChamadaDir = '$apiResponsesDir/primeira_chamada';

  /// Diretório para armazenar as respostas da segunda chamada
  static final String segundaChamadaDir = '$apiResponsesDir/segunda_chamada';

  /// Diretório para armazenar as respostas do plano de estudos
  static final String planoEstudosDir = '$apiResponsesDir/plano_estudos';

  /// Diretório para armazenar outras respostas
  static final String outrasRespostasDir = '$apiResponsesDir/outras_respostas';

  /// Diretório para armazenar logs
  static final String logsDir = '${Directory.current.path}/logs';

  /// Diretório para armazenar cache de análises
  static final String analysisCacheDir = '${Directory.current.path}/analysis_cache';

  /// Diretório para armazenar editais
  static final String editaisDir = '${Directory.current.path}/editais';

  /// Diretório para armazenar arquivos gerados
  static final String generateFilesDir = '${Directory.current.path}/generate_files';

  /// Diretório para armazenar arquivos do projeto de PDF para flashcards
  static final String projetoPdfFlashcardsDir = '${Directory.current.path}/projeto_pdf_para_flashcards';

  /// Diretório para armazenar documentos enviados
  static final String uploadedDocumentsDir = '${Directory.current.path}/uploaded_documents';

  /// Inicializa todos os diretórios
  static Future<void> initializeAllDirectories() async {
    final directories = [
      apiResponsesDir,
      primeiraChamadaDir,
      segundaChamadaDir,
      planoEstudosDir,
      outrasRespostasDir,
      logsDir,
      analysisCacheDir,
      editaisDir,
      generateFilesDir,
      projetoPdfFlashcardsDir,
      uploadedDocumentsDir,
    ];

    for (final dir in directories) {
      try {
        final directory = Directory(dir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          debugPrint('Diretório criado: $dir');
        } else {
          debugPrint('Diretório já existe: $dir');
        }
      } catch (e) {
        debugPrint('Erro ao criar diretório $dir: $e');
      }
    }
  }
}
