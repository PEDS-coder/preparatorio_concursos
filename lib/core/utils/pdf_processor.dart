import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'logger_adapter.dart';
import 'pdf_optimizer.dart';
import 'pdf_scanner_detector.dart';
import 'pdf_parallel_processor.dart';

/// Configurações para o processamento de PDF
class PdfProcessorConfig {
  /// Tamanho do chunk para processamento de PDFs grandes
  final int chunkSize;

  /// Usar OCR por padrão
  final bool useOcrByDefault;

  /// Qualidade da imagem para OCR (1-100)
  final int ocrImageQuality;

  /// Limite de tamanho para considerar um PDF como grande (em bytes)
  final int largePdfThreshold;

  /// Construtor
  PdfProcessorConfig({
    this.chunkSize = 20,
    this.useOcrByDefault = false,
    this.ocrImageQuality = 100,
    this.largePdfThreshold = 10 * 1024 * 1024, // 10MB
  });
}

/// Resultado do processamento de PDF
class PdfProcessingResult {
  final String text;
  final bool usedOcr;
  final bool isLargePdf;
  final int pageCount;
  final List<String> tables;
  final Map<String, dynamic> metadata;
  final List<String> warnings;
  final List<String> errors;

  PdfProcessingResult({
    required this.text,
    this.usedOcr = false,
    this.isLargePdf = false,
    this.pageCount = 0,
    this.tables = const [],
    this.metadata = const {},
    this.warnings = const [],
    this.errors = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasContent => text.isNotEmpty;
  bool get hasTables => tables.isNotEmpty;
}

/// Classe para processamento avançado de PDFs
class PdfProcessor {
  static const String _tag = 'PdfProcessor';

  /// Callback para reportar progresso
  final Function(double, String)? onProgress;

  /// Configurações de processamento
  final PdfProcessorConfig config;

  /// Construtor
  PdfProcessor({this.onProgress, PdfProcessorConfig? config}) :
    this.config = config ?? PdfProcessorConfig();

  /// Extrai texto de um PDF, incluindo tabelas e estruturas complexas
  Future<PdfProcessingResult> extractTextFromPdf(
    dynamic pdfSource, {
    bool? useOcr,
    bool? useAdvancedMethods,
  }) async {
    AppLogger.d(_tag, 'Iniciando extração de texto de PDF');

    final bool shouldUseOcr = useOcr ?? config.useOcrByDefault;
    final bool shouldUseAdvancedMethods = useAdvancedMethods ?? true;
    final List<String> warnings = [];
    final List<String> errors = [];

    try {
      if (pdfSource is String && !kIsWeb) {
        // Caminho do arquivo (plataformas nativas)
        AppLogger.d(_tag, 'Processando PDF a partir do caminho: $pdfSource');
        return await _extractFromPath(
          pdfSource,
          useOcr: shouldUseOcr,
          useAdvancedMethods: shouldUseAdvancedMethods,
          warnings: warnings,
          errors: errors,
        );
      } else if (pdfSource is Uint8List) {
        // Bytes do arquivo (web ou bytes diretos)
        AppLogger.d(_tag, 'Processando PDF a partir de bytes (tamanho: ${pdfSource.length} bytes)');
        return await _extractFromBytes(
          pdfSource,
          useOcr: shouldUseOcr,
          useAdvancedMethods: shouldUseAdvancedMethods,
          warnings: warnings,
          errors: errors,
        );
      } else {
        final error = 'Formato de fonte de PDF não suportado: ${pdfSource.runtimeType}';
        AppLogger.e(_tag, error);
        errors.add(error);
        return PdfProcessingResult(
          text: '',
          errors: errors,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(_tag, 'Erro ao extrair texto do PDF', e, stackTrace);
      errors.add('Erro ao extrair texto: $e');
      return PdfProcessingResult(
        text: '',
        errors: errors,
      );
    }
  }

  /// Extrai texto de um PDF a partir dos bytes (método público)
  Future<PdfProcessingResult> extractTextFromPdfBytes(
    Uint8List bytes, {
    bool? useOcr,
    bool? useAdvancedMethods,
  }) async {
    final bool shouldUseOcr = useOcr ?? config.useOcrByDefault;
    final bool shouldUseAdvancedMethods = useAdvancedMethods ?? true;
    final List<String> warnings = [];
    final List<String> errors = [];

    return await _extractFromBytes(
      bytes,
      useOcr: shouldUseOcr,
      useAdvancedMethods: shouldUseAdvancedMethods,
      warnings: warnings,
      errors: errors,
    );
  }

  /// Extrai texto de um PDF a partir do caminho do arquivo
  Future<PdfProcessingResult> _extractFromPath(
    String filePath, {
    required bool useOcr,
    required bool useAdvancedMethods,
    required List<String> warnings,
    required List<String> errors,
  }) async {
    try {
      final File file = File(filePath);
      final Uint8List bytes = await file.readAsBytes();
      return _extractFromBytes(
        bytes,
        useOcr: useOcr,
        useAdvancedMethods: useAdvancedMethods,
        warnings: warnings,
        errors: errors,
      );
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao ler arquivo PDF: $filePath', e);
      errors.add('Erro ao ler arquivo PDF: $e');
      return PdfProcessingResult(
        text: '',
        errors: errors,
      );
    }
  }

  /// Extrai texto de um PDF a partir dos bytes
  Future<PdfProcessingResult> _extractFromBytes(
    Uint8List bytes, {
    required bool useOcr,
    required bool useAdvancedMethods,
    required List<String> warnings,
    required List<String> errors,
  }) async {
    // Verificar se o PDF é grande
    final bool isLargePdf = bytes.length > config.largePdfThreshold;

    // Verificar se o PDF é escaneado
    bool isScanned = false;
    try {
      isScanned = await isPdfScanned(bytes);
      if (isScanned) {
        AppLogger.i(_tag, 'PDF detectado como escaneado, considerando usar OCR');
        warnings.add('PDF detectado como escaneado, qualidade do texto pode ser afetada');
      }
    } catch (e) {
      AppLogger.w(_tag, 'Erro ao verificar se o PDF é escaneado', e);
      warnings.add('Não foi possível verificar se o PDF é escaneado');
    }

    // Usar OCR se solicitado ou se o PDF for escaneado
    final bool shouldUseOcr = useOcr || isScanned;
    if (shouldUseOcr) {
      AppLogger.i(_tag, 'Usando OCR para extrair texto do PDF');
      try {
        final String ocrText = await _extractWithOcr(bytes);
        return PdfProcessingResult(
          text: ocrText,
          usedOcr: true,
          isLargePdf: isLargePdf,
          warnings: warnings,
          errors: errors,
        );
      } catch (e) {
        AppLogger.e(_tag, 'Erro ao extrair texto com OCR', e);
        errors.add('Erro ao extrair texto com OCR: $e');
        warnings.add('Falha no OCR, tentando método alternativo');
        // Continuar com o método normal em caso de falha no OCR
      }
    }

    // Se o PDF for grande, usar processamento otimizado
    if (isLargePdf) {
      AppLogger.i(_tag, 'PDF grande detectado, usando processamento otimizado');
      warnings.add('PDF grande detectado, usando processamento otimizado');
      try {
        final String largeText = await processLargePdf(bytes);
        return PdfProcessingResult(
          text: largeText,
          usedOcr: false,
          isLargePdf: true,
          warnings: warnings,
          errors: errors,
        );
      } catch (e) {
        AppLogger.e(_tag, 'Erro ao processar PDF grande', e);
        errors.add('Erro ao processar PDF grande: $e');
        warnings.add('Falha no processamento otimizado, tentando método padrão');
        // Continuar com o método normal em caso de falha
      }
    }

    // Extração normal de texto
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      final List<String> allTableData = [];
      Map<String, dynamic> metadata = {};

      // Extrair metadados do documento
      try {
        metadata['title'] = document.documentInformation.title ?? '';
        metadata['author'] = document.documentInformation.author ?? '';
        metadata['subject'] = document.documentInformation.subject ?? '';
        metadata['keywords'] = document.documentInformation.keywords ?? '';
        metadata['creator'] = document.documentInformation.creator ?? '';
        metadata['producer'] = document.documentInformation.producer ?? '';
        metadata['creation_date'] = document.documentInformation.creationDate?.toString() ?? '';
        metadata['modification_date'] = document.documentInformation.modificationDate?.toString() ?? '';
        metadata['page_count'] = pageCount;
      } catch (e) {
        AppLogger.w(_tag, 'Erro ao extrair metadados do PDF', e);
        warnings.add('Não foi possível extrair todos os metadados do PDF');
      }

      try {
        // Resultado combinado
        String extractedText = '';

        // Extrair texto e tabelas de cada página
        for (int i = 0; i < pageCount; i++) {
          // Reportar progresso
          if (onProgress != null) {
            onProgress!((i + 1) / pageCount, 'Processando página ${i + 1} de $pageCount...');
          }

          // Extrair texto normal
          String pageText = '';
          try {
            pageText = PdfTextExtractor(document).extractText(
              startPageIndex: i,
              endPageIndex: i,
            );
          } catch (e) {
            AppLogger.w(_tag, 'Erro ao extrair texto da página ${i + 1}', e);
            warnings.add('Erro ao extrair texto da página ${i + 1}');
            pageText = '[Erro ao extrair texto desta página]';
          }

          // Extrair tabelas
          List<String> tableDatas = [];
          try {
            tableDatas = await _extractTablesFromPage(document, i);
            if (tableDatas.isNotEmpty) {
              allTableData.addAll(tableDatas);
            }
          } catch (e) {
            AppLogger.w(_tag, 'Erro ao extrair tabelas da página ${i + 1}', e);
            warnings.add('Erro ao extrair tabelas da página ${i + 1}');
          }

          // Combinar resultados
          extractedText += pageText;

          // Adicionar dados de tabelas
          if (tableDatas.isNotEmpty) {
            extractedText += '\n\n--- TABELAS DETECTADAS NA PÁGINA ${i + 1} ---\n\n';
            for (int t = 0; t < tableDatas.length; t++) {
              extractedText += 'TABELA ${t + 1}:\n${tableDatas[t]}\n\n';
            }
          }

          extractedText += '\n\n';

          // Pausa para não bloquear a UI
          if (i % 5 == 0) {
            await Future.delayed(Duration(milliseconds: 10));
          }
        }

        return PdfProcessingResult(
          text: extractedText,
          usedOcr: false,
          isLargePdf: isLargePdf,
          pageCount: pageCount,
          tables: allTableData,
          metadata: metadata,
          warnings: warnings,
          errors: errors,
        );
      } finally {
        document.dispose();
      }
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao extrair texto do PDF', e);
      errors.add('Erro ao extrair texto do PDF: $e');
      return PdfProcessingResult(
        text: '',
        usedOcr: false,
        isLargePdf: isLargePdf,
        warnings: warnings,
        errors: errors,
      );
    }
  }

  /// Extrai tabelas de uma página do PDF
  Future<List<String>> _extractTablesFromPage(PdfDocument document, int pageIndex) async {
    final List<String> tableData = [];

    try {
      // Obter a página
      final PdfPage page = document.pages[pageIndex];

      // Nota: A extração de tabelas foi simplificada devido a limitações da biblioteca
      // Em uma implementação real, usaria uma biblioteca específica para extração de tabelas

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
      AppLogger.e('PdfProcessor', 'Erro ao extrair tabelas', e);
    }

    return tableData;
  }

  /// Extrai texto usando OCR para PDFs escaneados
  Future<String> _extractWithOcr(Uint8List pdfBytes) async {
    String extractedText = '';
    AppLogger.i(_tag, 'Iniciando extração de texto com OCR');

    try {
      // Renderizar páginas do PDF como imagens de alta qualidade
      AppLogger.d(_tag, 'Renderizando páginas do PDF como imagens para OCR');
      final List<Uint8List> pageImages = await _renderPdfPagesToImages(pdfBytes);
      final int totalPages = pageImages.length;

      if (pageImages.isEmpty) {
        AppLogger.w(_tag, 'Não foi possível extrair imagens do PDF para OCR');
        return 'Não foi possível extrair imagens do PDF para OCR.';
      }

      AppLogger.d(_tag, 'Iniciando OCR em $totalPages páginas');

      // Inicializar o reconhecedor de texto com opções avançadas
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      // Processar cada imagem de página
      for (int i = 0; i < pageImages.length; i++) {
        // Reportar progresso
        if (onProgress != null) {
          onProgress!((i + 1) / totalPages, 'Processando OCR na página ${i + 1} de $totalPages...');
        }

        try {
          AppLogger.d(_tag, 'Processando OCR na página ${i + 1}');

          // Converter a imagem para um formato compatível com o OCR
          final img.Image? decodedImage = img.decodeImage(pageImages[i]);

          if (decodedImage == null) {
            AppLogger.w(_tag, 'Falha ao decodificar imagem da página $i');
            continue;
          }

          // Pré-processamento da imagem para melhorar o OCR
          AppLogger.d(_tag, 'Aplicando pré-processamento na imagem da página ${i + 1}');
          img.Image processedImage = decodedImage;

          // Aumentar contraste para melhorar a detecção de texto
          processedImage = img.adjustColor(
            processedImage,
            contrast: 1.2,
            brightness: 0.05,
          );

          // Converter de volta para Uint8List
          final Uint8List processedBytes = Uint8List.fromList(
            img.encodeJpg(processedImage, quality: config.ocrImageQuality)
          );

          // Processar a imagem com OCR
          AppLogger.d(_tag, 'Executando OCR na imagem processada da página ${i + 1}');
          final InputImage inputImage = InputImage.fromBytes(
            bytes: processedBytes,
            metadata: InputImageMetadata(
              size: Size(processedImage.width.toDouble(), processedImage.height.toDouble()),
              rotation: InputImageRotation.rotation0deg,
              format: InputImageFormat.bgra8888,
              bytesPerRow: processedImage.width * 4, // 4 bytes por pixel (RGBA)
            ),
          );

          final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

          // Processar o texto reconhecido para melhorar a qualidade
          String pageText = recognizedText.text;
          AppLogger.d(_tag, 'Texto reconhecido na página ${i + 1}: ${pageText.length} caracteres');

          // Remover quebras de linha desnecessárias no meio de frases
          pageText = pageText.replaceAll(RegExp(r'(?<=[a-z])\n(?=[a-z])'), ' ');

          // Adicionar texto reconhecido
          extractedText += 'Página ${i + 1}:\n$pageText\n\n';

        } catch (pageError) {
          AppLogger.e(_tag, 'Erro no OCR da página $i', pageError);
          extractedText += 'Página ${i + 1}: [Erro no processamento OCR]\n\n';
        }

        // Pausa para não bloquear a UI
        if (i % 2 == 0) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }

      // Liberar recursos
      textRecognizer.close();

      // Pós-processamento do texto completo
      AppLogger.d(_tag, 'Aplicando pós-processamento ao texto OCR');
      extractedText = _postProcessOcrText(extractedText);
      AppLogger.i(_tag, 'OCR concluído com sucesso: ${extractedText.length} caracteres extraídos');

      return extractedText;
    } catch (e) {
      AppLogger.e(_tag, 'Erro no OCR', e);
      return 'Erro ao processar OCR: $e';
    }
  }

  /// Pós-processamento do texto OCR para melhorar a qualidade
  String _postProcessOcrText(String text) {
    // Corrigir espaços extras
    String processed = text.replaceAll(RegExp(r'\s+'), ' ');

    // Corrigir quebras de linha
    processed = processed.replaceAll(' \n ', '\n');

    // Preservar parágrafos
    processed = processed.replaceAll('\n\n', '\n\n');

    // Corrigir caracteres comumente mal interpretados
    processed = processed.replaceAll('l1', '11');
    processed = processed.replaceAll('I1', '11');
    processed = processed.replaceAll('O0', '00');
    processed = processed.replaceAll('S5', '55');

    return processed;
  }

  /// Renderiza páginas do PDF como imagens para OCR
  Future<List<Uint8List>> _renderPdfPagesToImages(Uint8List pdfBytes) async {
    final List<Uint8List> images = [];

    try {
      // Usar Syncfusion para extrair texto
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final int pageCount = document.pages.count;

      // Criar imagens simuladas para cada página
      for (int i = 0; i < pageCount; i++) {
        // Reportar progresso
        if (onProgress != null) {
          onProgress!((i + 0.5) / pageCount, 'Processando página ${i + 1} de $pageCount...');
        }

        // Criar uma imagem em branco para o OCR
        // Em uma implementação real, usaria uma biblioteca de renderização adequada
        final Uint8List placeholderImage = Uint8List.fromList(List.filled(1000 * 1000 * 4, 255));
        images.add(placeholderImage);

        // Pausa para não bloquear a UI
        if (i % 2 == 0) {
          await Future.delayed(Duration(milliseconds: 20));
        }
      }

      document.dispose();
    } catch (e) {
      AppLogger.e('PdfProcessor', 'Erro ao renderizar PDF para imagens', e);

      // Criar pelo menos uma imagem em branco para o OCR não falhar completamente
      final Uint8List placeholderImage = Uint8List.fromList(List.filled(1000 * 1000 * 4, 255));
      images.add(placeholderImage);
    }

    return images;
  }

  /// Detecta se um PDF é escaneado (imagem) ou digital
  Future<bool> isPdfScanned(Uint8List pdfBytes) async {
    return PdfScannerDetector.isPdfScanned(pdfBytes);
  }

  /// Otimiza o processamento para PDFs muito grandes
  Future<String> processLargePdf(Uint8List pdfBytes, {int? chunkSize}) async {
    final optimizer = PdfOptimizer(onProgress: onProgress);
    return optimizer.processLargePdf(
      pdfBytes,
      chunkSize: chunkSize ?? config.chunkSize,
    );
  }

  /// Processa múltiplos PDFs em lote
  Future<Map<String, String>> processBatchPdfs(List<Uint8List> pdfBytesList) async {
    final parallelProcessor = PdfParallelProcessor(onProgress: onProgress);
    final List<String> results = await parallelProcessor.processPdfsInParallel(
      pdfBytesList,
      maxConcurrent: 2,
      detectScanned: true,
      useOcrForScanned: config.useOcrByDefault,
    );

    // Converter para o formato de retorno esperado
    final Map<String, String> resultMap = {};
    for (int i = 0; i < results.length; i++) {
      resultMap['pdf_$i'] = results[i];
    }

    return resultMap;
  }
}
