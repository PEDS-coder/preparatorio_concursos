import 'dart:typed_data';

/// Interface para o serviço de classificação de documentos
abstract class IDocumentClassifierService {
  /// Classifica um documento
  Future<Map<String, dynamic>> classifyDocument(
    Uint8List documentBytes,
    String fileName,
  );

  /// Extrai informações de um documento
  Future<Map<String, dynamic>> extractDocumentInfo(
    Uint8List documentBytes,
    String fileName,
  );

  /// Detecta o tipo de documento
  Future<String> detectDocumentType(
    Uint8List documentBytes,
    String fileName,
  );

  /// Verifica se um documento é um edital
  Future<bool> isEdital(
    Uint8List documentBytes,
    String fileName,
  );
}
