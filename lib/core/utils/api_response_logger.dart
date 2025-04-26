import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Serviço para registrar e armazenar respostas da API para referência futura
class ApiResponseLogger {
  static final ApiResponseLogger _instance = ApiResponseLogger._internal();

  factory ApiResponseLogger() => _instance;

  ApiResponseLogger._internal();

  // Diretório para armazenar as respostas da API
  static const String _apiResponsesDir = 'api_responses';
  
  // Diretório para armazenar as respostas da segunda chamada
  static const String _segundaChamadaDir = 'segunda_chamada';
  
  // Diretório para armazenar as respostas da primeira chamada
  static const String _primeiraChamadaDir = 'primeira_chamada';
  
  // Diretório para armazenar outras respostas
  static const String _outrasRespostasDir = 'outras_respostas';

  /// Salva a resposta da segunda chamada à API
  Future<String?> salvarRespostaSegundaChamada({
    required String editalId,
    required String cargoId,
    required String cargoNome,
    required Map<String, dynamic> resposta,
  }) async {
    if (kIsWeb) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final directory = await _getOrCreateDirectory(_segundaChamadaDir);
      final fileName = 'resposta_segunda_chamada_${editalId}_${cargoId}_$timestamp.json';
      final filePath = '${directory.path}/$fileName';
      
      // Adicionar metadados à resposta
      final respostaComMetadados = {
        'metadata': {
          'timestamp': timestamp,
          'data_hora': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          'edital_id': editalId,
          'cargo_id': cargoId,
          'cargo_nome': cargoNome,
          'tipo_resposta': 'segunda_chamada',
        },
        'resposta': resposta,
      };
      
      // Salvar a resposta em um arquivo JSON
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(respostaComMetadados),
        flush: true,
      );
      
      debugPrint('Resposta da segunda chamada salva em: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Erro ao salvar resposta da segunda chamada: $e');
      return null;
    }
  }

  /// Salva a resposta da primeira chamada à API
  Future<String?> salvarRespostaPrimeiraChamada({
    required String editalId,
    required Map<String, dynamic> resposta,
  }) async {
    if (kIsWeb) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final directory = await _getOrCreateDirectory(_primeiraChamadaDir);
      final fileName = 'resposta_primeira_chamada_${editalId}_$timestamp.json';
      final filePath = '${directory.path}/$fileName';
      
      // Adicionar metadados à resposta
      final respostaComMetadados = {
        'metadata': {
          'timestamp': timestamp,
          'data_hora': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          'edital_id': editalId,
          'tipo_resposta': 'primeira_chamada',
        },
        'resposta': resposta,
      };
      
      // Salvar a resposta em um arquivo JSON
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(respostaComMetadados),
        flush: true,
      );
      
      debugPrint('Resposta da primeira chamada salva em: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Erro ao salvar resposta da primeira chamada: $e');
      return null;
    }
  }

  /// Salva a resposta bruta da API
  Future<String?> salvarRespostaBruta({
    required String tipo,
    required String resposta,
    Map<String, dynamic>? metadados,
  }) async {
    if (kIsWeb) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final directory = await _getOrCreateDirectory(_outrasRespostasDir);
      final fileName = 'resposta_${tipo}_$timestamp.txt';
      final filePath = '${directory.path}/$fileName';
      
      // Criar conteúdo do arquivo
      final buffer = StringBuffer();
      
      // Adicionar metadados
      buffer.writeln('--- METADADOS ---');
      buffer.writeln('Timestamp: $timestamp');
      buffer.writeln('Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('Tipo: $tipo');
      
      if (metadados != null) {
        metadados.forEach((key, value) {
          buffer.writeln('$key: $value');
        });
      }
      
      buffer.writeln('--- RESPOSTA ---');
      buffer.writeln(resposta);
      
      // Salvar a resposta em um arquivo de texto
      final file = File(filePath);
      await file.writeAsString(buffer.toString(), flush: true);
      
      debugPrint('Resposta bruta salva em: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Erro ao salvar resposta bruta: $e');
      return null;
    }
  }

  /// Obtém ou cria o diretório para armazenar as respostas
  Future<Directory> _getOrCreateDirectory(String subdir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${appDir.path}/$_apiResponsesDir');
    
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    
    final targetDir = Directory('${baseDir.path}/$subdir');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    return targetDir;
  }

  /// Lista todas as respostas salvas
  Future<List<FileSystemEntity>> listarRespostas({String? tipo}) async {
    if (kIsWeb) return [];

    try {
      String subdir;
      switch (tipo) {
        case 'primeira_chamada':
          subdir = _primeiraChamadaDir;
          break;
        case 'segunda_chamada':
          subdir = _segundaChamadaDir;
          break;
        case 'outras':
          subdir = _outrasRespostasDir;
          break;
        default:
          // Listar todas as respostas
          final appDir = await getApplicationDocumentsDirectory();
          final baseDir = Directory('${appDir.path}/$_apiResponsesDir');
          
          if (!await baseDir.exists()) {
            return [];
          }
          
          return baseDir.listSync(recursive: true);
      }
      
      final directory = await _getOrCreateDirectory(subdir);
      return directory.listSync();
    } catch (e) {
      debugPrint('Erro ao listar respostas: $e');
      return [];
    }
  }

  /// Obtém o caminho do diretório de respostas
  Future<String?> obterCaminhoDiretorioRespostas() async {
    if (kIsWeb) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final baseDir = Directory('${appDir.path}/$_apiResponsesDir');
      
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }
      
      return baseDir.path;
    } catch (e) {
      debugPrint('Erro ao obter caminho do diretório de respostas: $e');
      return null;
    }
  }
}
