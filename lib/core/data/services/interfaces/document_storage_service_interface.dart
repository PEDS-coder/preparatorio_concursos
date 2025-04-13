import 'dart:typed_data';

/// Interface para o serviço de armazenamento de documentos
abstract class IDocumentStorageService {
  /// Salva um documento
  Future<String> saveDocument(
    Uint8List bytes,
    String fileName,
    String type,
    Map<String, dynamic> metadata,
  );

  /// Obtém um documento pelo ID
  Future<Uint8List?> getDocument(String documentId);

  /// Remove um documento
  Future<bool> removeDocument(String documentId);

  /// Obtém os metadados de um documento
  Future<Map<String, dynamic>?> getDocumentMetadata(String documentId);

  /// Atualiza os metadados de um documento
  Future<bool> updateDocumentMetadata(
    String documentId,
    Map<String, dynamic> metadata,
  );

  /// Lista todos os documentos
  Future<List<Map<String, dynamic>>> listDocuments();

  /// Lista documentos por tipo
  Future<List<Map<String, dynamic>>> listDocumentsByType(String type);

  /// Verifica se um documento existe
  Future<bool> documentExists(String documentId);
}
