import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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

/// Serviço para upload de arquivos PDF
class PdfUploadService {
  /// Seleciona arquivos PDF e retorna seus nomes, caminhos e bytes
  Future<PdfUploadResult?> pickPdfFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true, // Permitir seleção de múltiplos arquivos
    );

    if (result == null || result.files.isEmpty) {
      return null; // Usuário cancelou a seleção
    }

    List<String> fileNames = [];
    List<String?> filePaths = [];
    List<Uint8List> bytesList = [];

    // Processar cada arquivo selecionado
    for (var file in result.files) {
      fileNames.add(file.name);

      // Obter os bytes do arquivo
      if (kIsWeb) {
        // Web
        if (file.bytes != null) {
          bytesList.add(file.bytes!);
          filePaths.add(null);
        }
      } else {
        // Desktop/Mobile
        if (file.path != null) {
          final fileObj = File(file.path!);
          final bytes = await fileObj.readAsBytes();
          bytesList.add(bytes);
          filePaths.add(file.path);
        }
      }
    }

    if (bytesList.isEmpty) {
      throw Exception('Não foi possível ler os arquivos PDF');
    }

    return PdfUploadResult(
      fileNames: fileNames,
      filePaths: filePaths,
      bytesList: bytesList,
    );
  }
}
