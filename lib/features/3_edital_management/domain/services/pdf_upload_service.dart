import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/logger_adapter.dart';

/// Resultado do upload de PDFs
class PdfUploadResult {
  final List<String> fileNames;
  final List<String?> filePaths;
  final List<Uint8List> bytesList;

  PdfUploadResult({
    required this.fileNames,
    required this.filePaths,
    required this.bytesList,
  });
}

/// Exceção específica para erros de upload de PDF
class PdfUploadException implements Exception {
  final String message;
  final String? detailedMessage;
  final StackTrace? stackTrace;

  PdfUploadException(this.message, {this.detailedMessage, this.stackTrace});

  @override
  String toString() => 'PdfUploadException: $message${detailedMessage != null ? '\nDetalhes: $detailedMessage' : ''}';
}

/// Serviço para upload de arquivos PDF
class PdfUploadService {
  static const String _tag = 'PdfUploadService';

  /// Tamanho máximo recomendado para arquivos PDF (20MB)
  static const int maxPdfSizeBytes = 20 * 1024 * 1024;



  /// Seleciona arquivos PDF e retorna seus nomes, caminhos e bytes
  Future<PdfUploadResult?> pickPdfFiles({
    bool allowMultiple = true,
    Function(String)? onError,
    VoidCallback? onCancel,
  }) async {
    try {
      // Selecionar arquivos PDF
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: allowMultiple,
        withData: kIsWeb, // Carregar dados diretamente no web
      );

      if (result == null || result.files.isEmpty) {
        AppLogger.i(_tag, 'Seleção de arquivo cancelada pelo usuário');
        if (onCancel != null) {
          onCancel();
        }
        return null; // Usuário cancelou a seleção
      }

      AppLogger.i(_tag, '${result.files.length} arquivo(s) selecionado(s)');

      List<String> fileNames = [];
      List<String?> filePaths = [];
      List<Uint8List> bytesList = [];

      // Verificar tamanho total dos arquivos
      int totalSize = 0;
      for (var file in result.files) {
        if (kIsWeb) {
          if (file.bytes != null) {
            totalSize += file.bytes!.length;
          }
        } else {
          if (file.size != null) {
            totalSize += file.size!;
          }
        }
      }

      // Verificar se o tamanho total excede o limite
      if (totalSize > maxPdfSizeBytes) {
        final sizeInMB = (totalSize / (1024 * 1024)).toStringAsFixed(2);
        final maxSizeInMB = (maxPdfSizeBytes / (1024 * 1024)).toStringAsFixed(2);

        AppLogger.w(_tag, 'Tamanho total dos arquivos ($sizeInMB MB) excede o limite de $maxSizeInMB MB');

        if (onError != null) {
          onError('O tamanho total dos arquivos ($sizeInMB MB) excede o limite recomendado de $maxSizeInMB MB. Selecione arquivos menores ou use a compressão de PDF.');
        }

        return null;
      }

      // Processar cada arquivo selecionado
      for (var file in result.files) {
        AppLogger.d(_tag, 'Processando arquivo: ${file.name} (${(file.size ?? 0) / 1024} KB)');

        fileNames.add(file.name);

        try {
          // Obter os bytes do arquivo
          if (kIsWeb) {
            // Web
            if (file.bytes != null) {
              bytesList.add(file.bytes!);
              filePaths.add(null);
              AppLogger.d(_tag, 'Arquivo web processado com sucesso: ${file.name}');
            } else {
              AppLogger.w(_tag, 'Arquivo web sem bytes: ${file.name}');
              throw PdfUploadException('Não foi possível ler o arquivo ${file.name}');
            }
          } else {
            // Desktop/Mobile
            if (file.path != null) {
              final fileObj = File(file.path!);

              // Verificar se o arquivo existe
              if (!await fileObj.exists()) {
                AppLogger.e(_tag, 'Arquivo não encontrado: ${file.path}');
                throw PdfUploadException('Arquivo não encontrado: ${file.name}');
              }

              // Ler os bytes do arquivo
              final bytes = await fileObj.readAsBytes();

              bytesList.add(bytes);
              filePaths.add(file.path);
              AppLogger.d(_tag, 'Arquivo local processado com sucesso: ${file.name}');
            } else {
              AppLogger.w(_tag, 'Arquivo local sem caminho: ${file.name}');
              throw PdfUploadException('Não foi possível acessar o arquivo ${file.name}');
            }
          }
        } catch (e, stackTrace) {
          AppLogger.e(_tag, 'Erro ao processar arquivo ${file.name}', e, stackTrace);

          if (e is PdfUploadException) {
            if (onError != null) {
              onError(e.message);
            }
          } else {
            if (onError != null) {
              onError('Erro ao processar o arquivo ${file.name}: ${e.toString()}');
            }
          }

          // Continuar processando os outros arquivos
          continue;
        }
      }

      if (bytesList.isEmpty) {
        AppLogger.e(_tag, 'Nenhum arquivo PDF foi processado com sucesso');
        throw PdfUploadException('Não foi possível ler nenhum dos arquivos PDF selecionados');
      }

      AppLogger.i(_tag, '${bytesList.length} arquivo(s) processado(s) com sucesso');

      return PdfUploadResult(
        fileNames: fileNames,
        filePaths: filePaths,
        bytesList: bytesList,
      );
    } catch (e, stackTrace) {
      if (e is PdfUploadException) {
        AppLogger.e(_tag, e.message, e.detailedMessage, e.stackTrace ?? stackTrace);
        if (onError != null) {
          onError(e.message);
        }
      } else {
        AppLogger.e(_tag, 'Erro ao selecionar arquivos PDF', e, stackTrace);
        if (onError != null) {
          onError('Erro ao selecionar arquivos PDF: ${e.toString()}');
        }
      }
      return null;
    }
  }

  /// Verifica se um arquivo PDF está dentro do tamanho limite
  bool isPdfSizeValid(int sizeInBytes) {
    return sizeInBytes <= maxPdfSizeBytes;
  }

  /// Formata o tamanho do arquivo para exibição
  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
