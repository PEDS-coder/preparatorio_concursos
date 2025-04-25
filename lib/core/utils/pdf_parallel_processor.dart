import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'logger_adapter.dart';
import 'pdf_optimizer.dart';
import 'pdf_scanner_detector.dart';

/// Classe para processamento paralelo de PDFs
class PdfParallelProcessor {
  static const String _tag = 'PdfParallelProcessor';
  
  /// Callback para reportar progresso
  final Function(double, String)? onProgress;
  
  /// Construtor
  PdfParallelProcessor({this.onProgress});
  
  /// Processa múltiplos PDFs em paralelo
  Future<List<String>> processPdfsInParallel(
    List<Uint8List> pdfBytesList, {
    int maxConcurrent = 2,
    bool detectScanned = true,
    bool useOcrForScanned = true,
  }) async {
    AppLogger.i(_tag, 'Iniciando processamento em lote de ${pdfBytesList.length} PDFs');
    
    final List<String> results = List.filled(pdfBytesList.length, '');
    final List<Future<void>> futures = [];
    
    // Limitar o número de processamentos concorrentes
    final pool = Pool(maxConcurrent);
    
    for (int i = 0; i < pdfBytesList.length; i++) {
      final pdfBytes = pdfBytesList[i];
      final int pdfIndex = i;
      
      futures.add(pool.withResource(() async {
        try {
          // Reportar progresso
          if (onProgress != null) {
            onProgress!(i / pdfBytesList.length, 'Processando PDF ${i + 1} de ${pdfBytesList.length}...');
          }
          
          // Verificar se o PDF é grande
          final bool isLarge = PdfOptimizer.needsOptimization(pdfBytes);
          
          // Verificar se o PDF é escaneado
          bool isScanned = false;
          if (detectScanned) {
            isScanned = await PdfScannerDetector.isPdfScanned(pdfBytes);
          }
          
          // Escolher a estratégia de processamento
          if (isLarge) {
            AppLogger.i(_tag, 'PDF ${i + 1} é grande (${(pdfBytes.length / 1024 / 1024).toStringAsFixed(2)}MB), usando processamento otimizado');
            final optimizer = PdfOptimizer(
              onProgress: (progress, message) {
                if (onProgress != null) {
                  final overallProgress = (i + progress) / pdfBytesList.length;
                  onProgress!(overallProgress, message);
                }
              }
            );
            results[pdfIndex] = await optimizer.processLargePdf(pdfBytes);
          } else if (isScanned && useOcrForScanned) {
            AppLogger.i(_tag, 'PDF ${i + 1} é escaneado ou OCR foi solicitado, usando OCR');
            // Aqui seria implementado o processamento com OCR
            // Como é uma implementação simplificada, usamos o método padrão
            results[pdfIndex] = await _processStandardPdf(pdfBytes);
          } else {
            AppLogger.i(_tag, 'Processando PDF ${i + 1} com método padrão');
            results[pdfIndex] = await _processStandardPdf(pdfBytes);
          }
        } catch (e) {
          AppLogger.e(_tag, 'Erro ao processar PDF ${i + 1}', e);
          results[pdfIndex] = 'Erro ao processar PDF ${i + 1}: $e';
        }
      }));
    }
    
    // Aguardar todos os processamentos
    await Future.wait(futures);
    
    return results;
  }
  
  /// Processa um PDF usando o método padrão
  Future<String> _processStandardPdf(Uint8List pdfBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao processar PDF padrão', e);
      return 'Erro ao processar PDF: $e';
    }
  }
  
  /// Processa um PDF em um isolate separado
  Future<String> _processInIsolate(Uint8List pdfBytes) async {
    if (kIsWeb) {
      // Isolates não são suportados na web
      return _processStandardPdf(pdfBytes);
    }
    
    final ReceivePort receivePort = ReceivePort();
    
    await Isolate.spawn(
      _isolateProcess,
      _IsolateParams(
        pdfBytes: pdfBytes,
        sendPort: receivePort.sendPort,
      ),
    );
    
    // Aguardar resultado do isolate
    final String result = await receivePort.first as String;
    return result;
  }
  
  /// Função executada no isolate
  static void _isolateProcess(_IsolateParams params) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: params.pdfBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      params.sendPort.send(text);
    } catch (e) {
      params.sendPort.send('Erro no processamento: $e');
    }
  }
}

/// Classe para passar parâmetros para o isolate
class _IsolateParams {
  final Uint8List pdfBytes;
  final SendPort sendPort;
  
  _IsolateParams({
    required this.pdfBytes,
    required this.sendPort,
  });
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
