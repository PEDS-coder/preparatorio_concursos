import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'logger_adapter.dart';

/// Classe para otimização de processamento de PDFs grandes
class PdfOptimizer {
  static const String _tag = 'PdfOptimizer';
  
  /// Tamanho máximo recomendado para processamento em memória (em bytes)
  static const int maxInMemorySize = 20 * 1024 * 1024; // 20MB
  
  /// Número máximo de páginas para processar por vez
  static const int defaultChunkSize = 20;
  
  /// Callback para reportar progresso
  final Function(double, String)? onProgress;
  
  /// Construtor
  PdfOptimizer({this.onProgress});
  
  /// Verifica se um PDF é grande e precisa de otimização
  static bool needsOptimization(Uint8List pdfBytes) {
    return pdfBytes.length > maxInMemorySize;
  }
  
  /// Processa um PDF grande em chunks para evitar problemas de memória
  Future<String> processLargePdf(
    Uint8List pdfBytes, {
    int chunkSize = defaultChunkSize,
    bool extractTables = true,
  }) async {
    AppLogger.i(_tag, 'Iniciando processamento otimizado de PDF grande (${(pdfBytes.length / 1024 / 1024).toStringAsFixed(2)}MB)');
    
    try {
      // Obter informações básicas do PDF
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final int pageCount = document.pages.count;
      document.dispose();
      
      AppLogger.i(_tag, 'PDF tem $pageCount páginas, processando em chunks');
      
      // Calcular número de chunks
      final int totalChunks = (pageCount / chunkSize).ceil();
      String extractedText = '';
      
      // Processar em chunks
      for (int chunk = 0; chunk < totalChunks; chunk++) {
        final int startPage = chunk * chunkSize;
        final int endPage = (chunk + 1) * chunkSize - 1 < pageCount 
            ? (chunk + 1) * chunkSize - 1 
            : pageCount - 1;
        
        if (onProgress != null) {
          onProgress!(chunk / totalChunks, 'Processando páginas ${startPage + 1} a ${endPage + 1} de $pageCount...');
        }
        
        AppLogger.d(_tag, 'Processando chunk ${chunk + 1}/$totalChunks (páginas ${startPage + 1}-${endPage + 1})');
        
        // Usar isolate para processamento paralelo se não estiver na web
        if (!kIsWeb) {
          final String chunkText = await _processChunkInIsolate(
            pdfBytes, 
            startPage, 
            endPage,
            extractTables,
          );
          extractedText += chunkText;
        } else {
          // Fallback para web (sem isolates)
          final String chunkText = await _processChunk(
            pdfBytes, 
            startPage, 
            endPage,
            extractTables,
          );
          extractedText += chunkText;
        }
        
        // Pausa para não bloquear a UI
        await Future.delayed(Duration(milliseconds: 50));
      }
      
      AppLogger.i(_tag, 'Processamento otimizado concluído com sucesso');
      return extractedText;
    } catch (e) {
      AppLogger.e(_tag, 'Erro no processamento otimizado', e);
      return 'Erro no processamento otimizado: $e';
    }
  }
  
  /// Processa um chunk de páginas em um isolate separado
  Future<String> _processChunkInIsolate(
    Uint8List pdfBytes,
    int startPage,
    int endPage,
    bool extractTables,
  ) async {
    final ReceivePort receivePort = ReceivePort();
    
    await Isolate.spawn(
      _isolateProcessChunk,
      _IsolateParams(
        pdfBytes: pdfBytes,
        startPage: startPage,
        endPage: endPage,
        extractTables: extractTables,
        sendPort: receivePort.sendPort,
      ),
    );
    
    // Aguardar resultado do isolate
    final String result = await receivePort.first as String;
    return result;
  }
  
  /// Função executada no isolate para processar um chunk
  static void _isolateProcessChunk(_IsolateParams params) {
    // Não podemos usar o logger aqui porque estamos em um isolate
    try {
      final PdfDocument document = PdfDocument(inputBytes: params.pdfBytes);
      String extractedText = '';
      
      for (int i = params.startPage; i <= params.endPage; i++) {
        try {
          // Extrair texto normal
          final String pageText = PdfTextExtractor(document).extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          
          extractedText += 'Página ${i + 1}:\n$pageText\n\n';
          
          // Extrair tabelas se solicitado
          if (params.extractTables) {
            // Implementação simplificada para tabelas
            // Em uma implementação real, usaria uma biblioteca específica
            final List<String> tableDatas = _extractTablesFromPageInIsolate(document, i);
            
            if (tableDatas.isNotEmpty) {
              extractedText += '\n--- TABELAS DETECTADAS NA PÁGINA ${i + 1} ---\n\n';
              for (int t = 0; t < tableDatas.length; t++) {
                extractedText += 'TABELA ${t + 1}:\n${tableDatas[t]}\n\n';
              }
            }
          }
        } catch (e) {
          extractedText += 'Página ${i + 1}: [Erro ao extrair texto: $e]\n\n';
        }
      }
      
      document.dispose();
      params.sendPort.send(extractedText);
    } catch (e) {
      params.sendPort.send('Erro no processamento: $e');
    }
  }
  
  /// Extrai tabelas de uma página no isolate
  static List<String> _extractTablesFromPageInIsolate(PdfDocument document, int pageIndex) {
    final List<String> tableData = [];
    
    try {
      // Obter a página
      final PdfPage page = document.pages[pageIndex];
      
      // Tentativa simples de detectar tabelas baseada em padrões de texto
      final String pageText = PdfTextExtractor(document).extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
      
      // Procurar por linhas que possam ser tabelas (contendo vários espaços ou caracteres de tabulação)
      final List<String> lines = pageText.split('\n');
      String currentTable = '';
      bool inTable = false;
      
      for (final String line in lines) {
        // Heurística simples: linhas com vários espaços consecutivos ou caracteres de tabulação
        // podem ser parte de uma tabela
        if (line.contains(RegExp(r'\s{3,}')) || line.contains('\t')) {
          if (!inTable) {
            inTable = true;
            currentTable = '';
          }
          currentTable += line + '\n';
        } else if (inTable) {
          // Fim da tabela
          inTable = false;
          if (currentTable.isNotEmpty) {
            tableData.add(currentTable);
          }
        }
      }
      
      // Adicionar a última tabela se estiver no final do texto
      if (inTable && currentTable.isNotEmpty) {
        tableData.add(currentTable);
      }
    } catch (e) {
      // Não podemos usar o logger aqui porque estamos em um isolate
    }
    
    return tableData;
  }
  
  /// Processa um chunk de páginas diretamente (sem isolate)
  Future<String> _processChunk(
    Uint8List pdfBytes,
    int startPage,
    int endPage,
    bool extractTables,
  ) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      String extractedText = '';
      
      for (int i = startPage; i <= endPage; i++) {
        try {
          // Extrair texto normal
          final String pageText = PdfTextExtractor(document).extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          
          extractedText += 'Página ${i + 1}:\n$pageText\n\n';
          
          // Extrair tabelas se solicitado
          if (extractTables) {
            // Implementação simplificada para tabelas
            final List<String> tableDatas = _extractTablesFromPage(document, i);
            
            if (tableDatas.isNotEmpty) {
              extractedText += '\n--- TABELAS DETECTADAS NA PÁGINA ${i + 1} ---\n\n';
              for (int t = 0; t < tableDatas.length; t++) {
                extractedText += 'TABELA ${t + 1}:\n${tableDatas[t]}\n\n';
              }
            }
          }
        } catch (e) {
          AppLogger.w(_tag, 'Erro ao extrair texto da página ${i + 1}: $e');
          extractedText += 'Página ${i + 1}: [Erro ao extrair texto]\n\n';
        }
        
        // Pausa para não bloquear a UI
        if ((i - startPage) % 5 == 0) {
          await Future.delayed(Duration(milliseconds: 10));
        }
      }
      
      document.dispose();
      return extractedText;
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao processar chunk', e);
      return 'Erro ao processar chunk: $e';
    }
  }
  
  /// Extrai tabelas de uma página
  List<String> _extractTablesFromPage(PdfDocument document, int pageIndex) {
    final List<String> tableData = [];
    
    try {
      // Obter a página
      final PdfPage page = document.pages[pageIndex];
      
      // Tentativa simples de detectar tabelas baseada em padrões de texto
      final String pageText = PdfTextExtractor(document).extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
      
      // Procurar por linhas que possam ser tabelas (contendo vários espaços ou caracteres de tabulação)
      final List<String> lines = pageText.split('\n');
      String currentTable = '';
      bool inTable = false;
      
      for (final String line in lines) {
        // Heurística simples: linhas com vários espaços consecutivos ou caracteres de tabulação
        // podem ser parte de uma tabela
        if (line.contains(RegExp(r'\s{3,}')) || line.contains('\t')) {
          if (!inTable) {
            inTable = true;
            currentTable = '';
          }
          currentTable += line + '\n';
        } else if (inTable) {
          // Fim da tabela
          inTable = false;
          if (currentTable.isNotEmpty) {
            tableData.add(currentTable);
          }
        }
      }
      
      // Adicionar a última tabela se estiver no final do texto
      if (inTable && currentTable.isNotEmpty) {
        tableData.add(currentTable);
      }
    } catch (e) {
      AppLogger.w(_tag, 'Erro ao extrair tabelas', e);
    }
    
    return tableData;
  }
  
  /// Processa múltiplos PDFs em paralelo
  Future<List<String>> processPdfsInParallel(
    List<Uint8List> pdfBytesList, {
    int maxConcurrent = 2,
  }) async {
    AppLogger.i(_tag, 'Iniciando processamento em lote de ${pdfBytesList.length} PDFs');
    
    final List<String> results = List.filled(pdfBytesList.length, '');
    final List<Future<void>> futures = [];
    
    // Limitar o número de processamentos concorrentes
    final pool = Pool(maxConcurrent);
    
    for (int i = 0; i < pdfBytesList.length; i++) {
      final pdfBytes = pdfBytesList[i];
      
      futures.add(pool.withResource(() async {
        try {
          if (needsOptimization(pdfBytes)) {
            AppLogger.i(_tag, 'PDF ${i + 1} é grande (${(pdfBytes.length / 1024 / 1024).toStringAsFixed(2)}MB), usando processamento otimizado');
            results[i] = await processLargePdf(pdfBytes);
          } else {
            AppLogger.i(_tag, 'Processando PDF ${i + 1} com método padrão');
            final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
            results[i] = PdfTextExtractor(document).extractText();
            document.dispose();
          }
        } catch (e) {
          AppLogger.e(_tag, 'Erro ao processar PDF ${i + 1}', e);
          results[i] = 'Erro ao processar PDF ${i + 1}: $e';
        }
      }));
    }
    
    // Aguardar todos os processamentos
    await Future.wait(futures);
    
    return results;
  }
}

/// Classe para limitar o número de operações concorrentes
class Pool {
  final int _maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _waitQueue = [];
  
  Pool(this._maxConcurrent);
  
  Future<T> withResource<T>(Future<T> Function() task) async {
    // Aguardar se já atingiu o limite
    if (_current >= _maxConcurrent) {
      final completer = Completer<void>();
      _waitQueue.add(completer);
      await completer.future;
    }
    
    _current++;
    
    try {
      return await task();
    } finally {
      _current--;
      
      // Liberar próximo da fila
      if (_waitQueue.isNotEmpty) {
        final completer = _waitQueue.removeAt(0);
        completer.complete();
      }
    }
  }
}

/// Classe para passar parâmetros para o isolate
class _IsolateParams {
  final Uint8List pdfBytes;
  final int startPage;
  final int endPage;
  final bool extractTables;
  final SendPort sendPort;
  
  _IsolateParams({
    required this.pdfBytes,
    required this.startPage,
    required this.endPage,
    required this.extractTables,
    required this.sendPort,
  });
}
