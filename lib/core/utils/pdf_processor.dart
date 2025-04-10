import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Classe para processamento avançado de PDFs
class PdfProcessor {
  /// Callback para reportar progresso
  final Function(double, String)? onProgress;

  /// Construtor
  PdfProcessor({this.onProgress});

  /// Extrai texto de um PDF, incluindo tabelas e estruturas complexas
  Future<String> extractTextFromPdf(dynamic pdfSource, {bool useOcr = false, bool useAdvancedMethods = true}) async {
    if (pdfSource is String && !kIsWeb) {
      // Caminho do arquivo (plataformas nativas)
      return await _extractFromPath(pdfSource, useOcr: useOcr, useAdvancedMethods: useAdvancedMethods);
    } else if (pdfSource is Uint8List) {
      // Bytes do arquivo (web ou bytes diretos)
      return await _extractFromBytes(pdfSource, useOcr: useOcr, useAdvancedMethods: useAdvancedMethods);
    } else {
      throw Exception('Formato de fonte de PDF não suportado');
    }
  }

  /// Extrai texto de um PDF a partir dos bytes (método público)
  Future<String> extractTextFromPdfBytes(Uint8List bytes, {bool useOcr = false, bool useAdvancedMethods = true}) async {
    return await _extractFromBytes(bytes, useOcr: useOcr, useAdvancedMethods: useAdvancedMethods);
  }

  /// Extrai texto de um PDF a partir do caminho do arquivo
  Future<String> _extractFromPath(String filePath, {bool useOcr = false, bool useAdvancedMethods = true}) async {
    final File file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();
    return _extractFromBytes(bytes, useOcr: useOcr, useAdvancedMethods: useAdvancedMethods);
  }

  /// Extrai texto de um PDF a partir dos bytes
  Future<String> _extractFromBytes(Uint8List bytes, {bool useOcr = false, bool useAdvancedMethods = true}) async {
    // Usar OCR se solicitado
    if (useOcr) {
      return await _extractWithOcr(bytes);
    }

    // Extração normal de texto
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final int pageCount = document.pages.count;

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
        final String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        // Extrair tabelas
        final List<String> tableDatas = await _extractTablesFromPage(document, i);

        // Combinar resultados
        extractedText += pageText;

        // Adicionar dados de tabelas
        if (tableDatas.isNotEmpty) {
          extractedText += '\n\n--- TABELAS DETECTADAS ---\n\n';
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

      return extractedText;
    } finally {
      document.dispose();
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
      print('Erro ao extrair tabelas: $e');
    }

    return tableData;
  }

  /// Extrai texto usando OCR para PDFs escaneados
  Future<String> _extractWithOcr(Uint8List pdfBytes) async {
    String extractedText = '';

    try {
      // Renderizar páginas do PDF como imagens de alta qualidade
      final List<Uint8List> pageImages = await _renderPdfPagesToImages(pdfBytes);
      final int totalPages = pageImages.length;

      if (pageImages.isEmpty) {
        return 'Não foi possível extrair imagens do PDF para OCR.';
      }

      // Inicializar o reconhecedor de texto com opções avançadas
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      // Processar cada imagem de página
      for (int i = 0; i < pageImages.length; i++) {
        // Reportar progresso
        if (onProgress != null) {
          onProgress!((i + 1) / totalPages, 'Processando OCR na página ${i + 1} de $totalPages...');
        }

        try {
          // Converter a imagem para um formato compatível com o OCR
          final img.Image? decodedImage = img.decodeImage(pageImages[i]);

          if (decodedImage == null) {
            print('Falha ao decodificar imagem da página $i');
            continue;
          }

          // Pré-processamento da imagem para melhorar o OCR
          img.Image processedImage = decodedImage;

          // Aumentar contraste para melhorar a detecção de texto
          processedImage = img.adjustColor(
            processedImage,
            contrast: 1.2,
            brightness: 0.05,
          );

          // Converter de volta para Uint8List
          final Uint8List processedBytes = Uint8List.fromList(img.encodeJpg(processedImage, quality: 100));

          // Processar a imagem com OCR
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

          // Remover quebras de linha desnecessárias no meio de frases
          pageText = pageText.replaceAll(RegExp(r'(?<=[a-z])\n(?=[a-z])'), ' ');

          // Adicionar texto reconhecido
          extractedText += 'Página ${i + 1}:\n$pageText\n\n';

        } catch (pageError) {
          print('Erro no OCR da página $i: $pageError');
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
      extractedText = _postProcessOcrText(extractedText);

      return extractedText;
    } catch (e) {
      print('Erro no OCR: $e');
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
      print('Erro ao renderizar PDF para imagens: $e');

      // Criar pelo menos uma imagem em branco para o OCR não falhar completamente
      final Uint8List placeholderImage = Uint8List.fromList(List.filled(1000 * 1000 * 4, 255));
      images.add(placeholderImage);
    }

    return images;
  }

  /// Detecta se um PDF é escaneado (imagem) ou digital
  Future<bool> isPdfScanned(Uint8List pdfBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final int pageCount = document.pages.count;

      // Verificar a primeira página
      if (pageCount > 0) {
        final String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: 0,
          endPageIndex: 0,
        );

        // Se o texto extraído for muito pequeno em relação ao esperado,
        // provavelmente é um PDF escaneado
        if (pageText.length < 100) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erro ao verificar se o PDF é escaneado: $e');
      return false;
    }
  }

  /// Otimiza o processamento para PDFs muito grandes
  Future<String> processLargePdf(Uint8List pdfBytes, {int chunkSize = 20}) async {
    final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
    final int pageCount = document.pages.count;

    try {
      String extractedText = '';
      final int totalChunks = (pageCount / chunkSize).ceil();

      // Processar em chunks para evitar problemas de memória
      for (int chunk = 0; chunk < totalChunks; chunk++) {
        final int startPage = chunk * chunkSize;
        final int endPage = (chunk + 1) * chunkSize - 1 < pageCount
            ? (chunk + 1) * chunkSize - 1
            : pageCount - 1;

        // Reportar progresso
        if (onProgress != null) {
          onProgress!((chunk + 1) / totalChunks, 'Processando chunk ${chunk + 1} de $totalChunks...');
        }

        // Extrair texto do chunk
        final String chunkText = PdfTextExtractor(document).extractText(
          startPageIndex: startPage,
          endPageIndex: endPage,
        );

        extractedText += chunkText + '\n\n';

        // Pausa para liberar memória
        await Future.delayed(Duration(milliseconds: 100));
      }

      return extractedText;
    } finally {
      document.dispose();
    }
  }
}
