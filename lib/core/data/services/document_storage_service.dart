import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../config/directory_config.dart';

/// Serviço para gerenciar o armazenamento de documentos e arquivos gerados pela IA
class DocumentStorageService extends ChangeNotifier {
  // Diretórios de armazenamento
  static const String _uploadedDocsDir = 'uploaded_documents';
  static const String _generatedFilesDir = 'generated_files';

  // Tipos de ferramentas
  static const String FLASHCARDS = 'flashcards';
  static const String RESUMOS = 'resumos';
  static const String QUESTOES = 'questoes';
  static const String MAPAS = 'mapas';

  // Listas de documentos e arquivos
  List<StoredDocument> _uploadedDocuments = [];
  List<GeneratedFile> _generatedFiles = [];

  // Getters
  List<StoredDocument> get uploadedDocuments => _uploadedDocuments;
  List<GeneratedFile> get generatedFiles => _generatedFiles;

  // Construtor
  DocumentStorageService() {
    _initDirectories();
    _loadDocuments();
    _loadGeneratedFiles();
  }

  // Inicializar diretórios
  Future<void> _initDirectories() async {
    if (kIsWeb) return; // No web, não precisamos criar diretórios físicos

    try {
      // Usar os diretórios definidos em DirectoryConfig
      final uploadDir = Directory(DirectoryConfig.uploadedDocumentsDir);
      final generatedDir = Directory(DirectoryConfig.generateFilesDir);

      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      if (!await generatedDir.exists()) {
        await generatedDir.create(recursive: true);
      }

      debugPrint('Diretórios de armazenamento inicializados');
    } catch (e) {
      debugPrint('Erro ao inicializar diretórios: $e');
    }
  }

  // Carregar documentos do armazenamento
  Future<void> _loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = prefs.getStringList('uploaded_documents') ?? [];

      _uploadedDocuments = docsJson
          .map((json) => StoredDocument.fromMap(jsonDecode(json)))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar documentos: $e');
    }
  }

  // Carregar arquivos gerados do armazenamento
  Future<void> _loadGeneratedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getStringList('generated_files') ?? [];

      _generatedFiles = filesJson
          .map((json) => GeneratedFile.fromMap(jsonDecode(json)))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar arquivos gerados: $e');
    }
  }

  // Salvar documentos no armazenamento
  Future<void> _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = _uploadedDocuments
          .map((doc) => jsonEncode(doc.toMap()))
          .toList();

      await prefs.setStringList('uploaded_documents', docsJson);
    } catch (e) {
      debugPrint('Erro ao salvar documentos: $e');
    }
  }

  // Salvar arquivos gerados no armazenamento
  Future<void> _saveGeneratedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = _generatedFiles
          .map((file) => jsonEncode(file.toMap()))
          .toList();

      await prefs.setStringList('generated_files', filesJson);
    } catch (e) {
      debugPrint('Erro ao salvar arquivos gerados: $e');
    }
  }

  // Adicionar um documento enviado
  Future<StoredDocument> addUploadedDocument(
    String userId,
    String fileName,
    String fileType,
    String toolType,
    List<int> fileBytes
  ) async {
    final id = const Uuid().v4();
    final timestamp = DateTime.now();

    // Salvar o arquivo no sistema de arquivos (exceto na web)
    String? filePath;
    if (!kIsWeb) {
      final file = File('${DirectoryConfig.uploadedDocumentsDir}/$id.$fileType');
      await file.writeAsBytes(fileBytes);
      filePath = file.path;
    }

    // Criar o objeto de documento
    final document = StoredDocument(
      id: id,
      userId: userId,
      fileName: fileName,
      fileType: fileType,
      toolType: toolType,
      uploadDate: timestamp,
      filePath: filePath,
      fileBytes: kIsWeb ? fileBytes : null,
    );

    // Adicionar à lista e salvar
    _uploadedDocuments.add(document);
    await _saveDocuments();
    notifyListeners();

    return document;
  }

  // Adicionar um arquivo gerado pela IA
  Future<GeneratedFile> addGeneratedFile(
    String userId,
    String fileName,
    String fileType,
    String toolType,
    String content,
    {String? sourceDocumentId}
  ) async {
    final id = const Uuid().v4();
    final timestamp = DateTime.now();

    // Salvar o conteúdo no sistema de arquivos (exceto na web)
    String? filePath;
    if (!kIsWeb) {
      final file = File('${DirectoryConfig.generateFilesDir}/$id.$fileType');
      await file.writeAsString(content);
      filePath = file.path;
    }

    // Criar o objeto de arquivo gerado
    final generatedFile = GeneratedFile(
      id: id,
      userId: userId,
      fileName: fileName,
      fileType: fileType,
      toolType: toolType,
      generationDate: timestamp,
      filePath: filePath,
      content: content,
      sourceDocumentId: sourceDocumentId,
    );

    // Adicionar à lista e salvar
    _generatedFiles.add(generatedFile);
    await _saveGeneratedFiles();
    notifyListeners();

    return generatedFile;
  }

  // Obter documentos enviados por tipo de ferramenta
  List<StoredDocument> getUploadedDocumentsByTool(String userId, String toolType) {
    return _uploadedDocuments
        .where((doc) => doc.userId == userId && doc.toolType == toolType)
        .toList();
  }

  // Obter arquivos gerados por tipo de ferramenta
  List<GeneratedFile> getGeneratedFilesByTool(String userId, String toolType) {
    return _generatedFiles
        .where((file) => file.userId == userId && file.toolType == toolType)
        .toList();
  }

  // Excluir um documento enviado
  Future<bool> deleteUploadedDocument(String documentId) async {
    try {
      final index = _uploadedDocuments.indexWhere((doc) => doc.id == documentId);
      if (index == -1) return false;

      final document = _uploadedDocuments[index];

      // Excluir o arquivo do sistema de arquivos (exceto na web)
      if (!kIsWeb && document.filePath != null) {
        final file = File(document.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remover da lista e salvar
      _uploadedDocuments.removeAt(index);
      await _saveDocuments();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erro ao excluir documento: $e');
      return false;
    }
  }

  // Excluir um arquivo gerado
  Future<bool> deleteGeneratedFile(String fileId) async {
    try {
      final index = _generatedFiles.indexWhere((file) => file.id == fileId);
      if (index == -1) return false;

      final generatedFile = _generatedFiles[index];

      // Excluir o arquivo do sistema de arquivos (exceto na web)
      if (!kIsWeb && generatedFile.filePath != null) {
        final file = File(generatedFile.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remover da lista e salvar
      _generatedFiles.removeAt(index);
      await _saveGeneratedFiles();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erro ao excluir arquivo gerado: $e');
      return false;
    }
  }

  // Obter o conteúdo de um documento enviado
  Future<String?> getUploadedDocumentContent(String documentId) async {
    try {
      final document = _uploadedDocuments.firstWhere((doc) => doc.id == documentId);

      if (kIsWeb && document.fileBytes != null) {
        // No web, retornar o conteúdo dos bytes
        return utf8.decode(document.fileBytes!);
      } else if (document.filePath != null) {
        // Em plataformas nativas, ler o arquivo
        final file = File(document.filePath!);
        if (await file.exists()) {
          return await file.readAsString();
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao obter conteúdo do documento: $e');
      return null;
    }
  }

  // Obter os bytes de um documento enviado (para download)
  Future<Uint8List?> getUploadedDocumentBytes(String documentId) async {
    try {
      final document = _uploadedDocuments.firstWhere((doc) => doc.id == documentId);

      if (kIsWeb && document.fileBytes != null) {
        // No web, retornar os bytes diretamente
        return Uint8List.fromList(document.fileBytes!);
      } else if (document.filePath != null) {
        // Em plataformas nativas, ler o arquivo
        final file = File(document.filePath!);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao obter bytes do documento: $e');
      return null;
    }
  }

  // Obter os bytes de um arquivo gerado (para download)
  Future<Uint8List?> getGeneratedFileBytes(String fileId) async {
    try {
      final generatedFile = _generatedFiles.firstWhere((file) => file.id == fileId);

      if (generatedFile.filePath != null) {
        // Em plataformas nativas, ler o arquivo
        final file = File(generatedFile.filePath!);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }

      // Se não tiver arquivo físico, converter o conteúdo em bytes
      return Uint8List.fromList(utf8.encode(generatedFile.content));
    } catch (e) {
      debugPrint('Erro ao obter bytes do arquivo gerado: $e');
      return null;
    }
  }

  // Gerar nome de arquivo para download
  String generateFileName(String toolType, String fileType) {
    final dateFormat = DateFormat('yyyyMMdd_HHmmss');
    final timestamp = dateFormat.format(DateTime.now());

    String prefix;
    switch (toolType) {
      case FLASHCARDS:
        prefix = 'flashcards';
        break;
      case RESUMOS:
        prefix = 'resumo';
        break;
      case QUESTOES:
        prefix = 'questoes';
        break;
      case MAPAS:
        prefix = 'mapa_mental';
        break;
      default:
        prefix = 'arquivo';
    }

    return '${prefix}_$timestamp.$fileType';
  }
}

/// Classe para representar um documento enviado
class StoredDocument {
  final String id;
  final String userId;
  final String fileName;
  final String fileType;
  final String toolType;
  final DateTime uploadDate;
  final String? filePath;
  final List<int>? fileBytes;

  StoredDocument({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileType,
    required this.toolType,
    required this.uploadDate,
    this.filePath,
    this.fileBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileType': fileType,
      'toolType': toolType,
      'uploadDate': uploadDate.toIso8601String(),
      'filePath': filePath,
      // Não salvamos os bytes no mapa para evitar problemas de tamanho
    };
  }

  factory StoredDocument.fromMap(Map<String, dynamic> map) {
    return StoredDocument(
      id: map['id'],
      userId: map['userId'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      toolType: map['toolType'],
      uploadDate: DateTime.parse(map['uploadDate']),
      filePath: map['filePath'],
      fileBytes: null, // Os bytes não são carregados do mapa
    );
  }
}

/// Classe para representar um arquivo gerado pela IA
class GeneratedFile {
  final String id;
  final String userId;
  final String fileName;
  final String fileType;
  final String toolType;
  final DateTime generationDate;
  final String? filePath;
  final String content;
  final String? sourceDocumentId;

  GeneratedFile({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileType,
    required this.toolType,
    required this.generationDate,
    this.filePath,
    required this.content,
    this.sourceDocumentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileType': fileType,
      'toolType': toolType,
      'generationDate': generationDate.toIso8601String(),
      'filePath': filePath,
      'content': content,
      'sourceDocumentId': sourceDocumentId,
    };
  }

  factory GeneratedFile.fromMap(Map<String, dynamic> map) {
    return GeneratedFile(
      id: map['id'],
      userId: map['userId'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      toolType: map['toolType'],
      generationDate: DateTime.parse(map['generationDate']),
      filePath: map['filePath'],
      content: map['content'],
      sourceDocumentId: map['sourceDocumentId'],
    );
  }
}
