import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'logger_adapter.dart';
import 'custom_pdf_bitmap.dart';
import 'pdf_bitmap_adapter.dart';

/// Classe para detecção de PDFs escaneados
class PdfScannerDetector {
  static const String _tag = 'PdfScannerDetector';

  /// Limiar de texto por página para considerar como escaneado
  static const int minTextLengthPerPage = 100;

  /// Limiar de caracteres por pixel para considerar como escaneado
  static const double minCharsPerPixelThreshold = 0.0001;

  /// Limiar de confiança para considerar como escaneado
  static const double scannedConfidenceThreshold = 0.7;

  /// Verifica se um PDF é escaneado
  static Future<bool> isPdfScanned(Uint8List pdfBytes, {int maxPagesToCheck = 5}) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final int pageCount = document.pages.count;

      // Limitar o número de páginas a verificar para economizar tempo
      final int pagesToCheck = pageCount < maxPagesToCheck ? pageCount : maxPagesToCheck;

      // Pontuação de confiança (0-1) de que o PDF é escaneado
      double scannedConfidence = 0.0;

      for (int i = 0; i < pagesToCheck; i++) {
        final double pageConfidence = await _isPageScanned(document, i);
        scannedConfidence += pageConfidence / pagesToCheck;
      }

      document.dispose();

      final bool isScanned = scannedConfidence >= scannedConfidenceThreshold;
      AppLogger.d(_tag, 'PDF escaneado? $isScanned (confiança: ${(scannedConfidence * 100).toStringAsFixed(1)}%)');

      return isScanned;
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao verificar se o PDF é escaneado', e);
      // Em caso de erro, assumir que não é escaneado
      return false;
    }
  }

  /// Verifica se uma página específica é escaneada
  static Future<double> _isPageScanned(PdfDocument document, int pageIndex) async {
    try {
      // Extrair texto da página
      final String pageText = PdfTextExtractor(document).extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );

      // Se a página tem muito pouco texto, provavelmente é escaneada
      if (pageText.length < minTextLengthPerPage) {
        return 0.9; // Alta confiança de que é escaneada
      }

      // Renderizar a página como imagem para análise
      final PdfPage page = document.pages[pageIndex];
      final CustomPdfBitmap bitmap = await PdfBitmapAdapter.convertPageToBitmap(page);

      // Calcular a densidade de texto (caracteres por pixel)
      final double charsPerPixel = pageText.length / (bitmap.width * bitmap.height);

      // Se a densidade de texto for muito baixa, provavelmente é escaneada
      if (charsPerPixel < minCharsPerPixelThreshold) {
        return 0.8;
      }

      // Analisar a imagem para características de documentos escaneados
      final double imageAnalysisConfidence = await _analyzeImageForScanFeatures(bitmap);

      // Combinar os resultados
      return imageAnalysisConfidence;
    } catch (e) {
      AppLogger.w(_tag, 'Erro ao analisar página $pageIndex', e);
      return 0.0; // Em caso de erro, assumir que não é escaneada
    }
  }

  // O método _renderPageAsBitmap foi movido para o PdfBitmapAdapter

  /// Analisa a imagem para características de documentos escaneados
  static Future<double> _analyzeImageForScanFeatures(CustomPdfBitmap bitmap) async {
    // Esta é uma implementação simplificada
    // Em uma implementação real, usaria algoritmos mais avançados de processamento de imagem

    // Converter para formato compatível com a biblioteca image
    final img.Image? image = _convertPdfBitmapToImage(bitmap);

    if (image == null) {
      return 0.0;
    }

    // Características que indicam um documento escaneado:
    // 1. Ruído de fundo
    // 2. Bordas irregulares no texto
    // 3. Padrões de compressão JPEG

    // Calcular histograma para detectar ruído
    final double noiseScore = _calculateNoiseScore(image);

    // Detectar bordas irregulares
    final double edgeScore = _calculateEdgeScore(image);

    // Detectar padrões de compressão JPEG
    final double compressionScore = _calculateCompressionScore(image);

    // Combinar pontuações
    final double combinedScore = (noiseScore * 0.4) + (edgeScore * 0.4) + (compressionScore * 0.2);

    return combinedScore;
  }

  /// Converte um CustomPdfBitmap para o formato da biblioteca image
  static img.Image? _convertPdfBitmapToImage(CustomPdfBitmap bitmap) {
    try {
      return img.Image.fromBytes(
        width: bitmap.width,
        height: bitmap.height,
        bytes: bitmap.data.buffer,
        order: img.ChannelOrder.rgba,
      );
    } catch (e) {
      AppLogger.w(_tag, 'Erro ao converter bitmap', e);
      return null;
    }
  }

  /// Calcula pontuação de ruído na imagem
  static double _calculateNoiseScore(img.Image image) {
    // Implementação simplificada
    // Em uma implementação real, usaria algoritmos mais avançados

    // Converter para escala de cinza
    final img.Image grayscale = img.grayscale(image);

    // Calcular variação local em pequenas regiões
    double totalVariation = 0;
    int samples = 0;

    // Amostragem de regiões
    for (int y = 10; y < grayscale.height - 10; y += 20) {
      for (int x = 10; x < grayscale.width - 10; x += 20) {
        final List<int> values = [];

        // Coletar valores em uma pequena região
        for (int dy = -5; dy <= 5; dy++) {
          for (int dx = -5; dx <= 5; dx++) {
            final img.Pixel pixel = grayscale.getPixel(x + dx, y + dy);
            values.add(pixel.r.toInt()); // Em escala de cinza, r = g = b
          }
        }

        // Calcular variação
        if (values.isNotEmpty) {
          final double mean = values.reduce((a, b) => a + b) / values.length;
          double variance = 0;
          for (final int value in values) {
            variance += (value - mean) * (value - mean);
          }
          variance /= values.length;

          totalVariation += variance;
          samples++;
        }
      }
    }

    // Normalizar
    final double averageVariation = samples > 0 ? totalVariation / samples : 0;

    // Converter para pontuação (0-1)
    // Valores típicos para documentos escaneados: 100-500
    // Valores típicos para documentos digitais: 0-50
    double score = averageVariation / 300;
    if (score > 1) score = 1;

    return score;
  }

  /// Calcula pontuação de bordas irregulares
  static double _calculateEdgeScore(img.Image image) {
    // Implementação simplificada
    // Em uma implementação real, usaria algoritmos de detecção de bordas como Sobel ou Canny

    // Aplicar detecção de bordas simples
    final img.Image edges = img.sobel(image);

    // Contar pixels de borda
    int edgePixels = 0;
    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        final img.Pixel pixel = edges.getPixel(x, y);
        final int value = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        if (value > 30) { // Limiar para considerar como borda
          edgePixels++;
        }
      }
    }

    // Calcular densidade de bordas
    final double edgeDensity = edgePixels / (edges.width * edges.height);

    // Converter para pontuação (0-1)
    // Documentos escaneados tendem a ter mais bordas irregulares
    double score = edgeDensity * 100;
    if (score > 1) score = 1;

    return score;
  }

  /// Calcula pontuação de padrões de compressão
  static double _calculateCompressionScore(img.Image image) {
    // Implementação simplificada
    // Em uma implementação real, usaria transformada DCT para detectar artefatos JPEG

    // Detectar blocos de 8x8 (típicos da compressão JPEG)
    int blockPatterns = 0;
    int samples = 0;

    for (int y = 0; y < image.height - 8; y += 8) {
      for (int x = 0; x < image.width - 8; x += 8) {
        // Verificar bordas de blocos
        bool hasBlockEdge = false;

        // Verificar bordas horizontais
        for (int dx = 0; dx < 8; dx++) {
          final img.Pixel topPixel = image.getPixel(x + dx, y);
          final img.Pixel bottomPixel = image.getPixel(x + dx, y + 7);
          final img.Pixel topNextPixel = image.getPixel(x + dx, y - 1 < 0 ? 0 : y - 1);
          final img.Pixel bottomNextPixel = image.getPixel(x + dx, y + 8 >= image.height ? image.height - 1 : y + 8);

          final int top = (0.299 * topPixel.r + 0.587 * topPixel.g + 0.114 * topPixel.b).round();
          final int bottom = (0.299 * bottomPixel.r + 0.587 * bottomPixel.g + 0.114 * bottomPixel.b).round();
          final int topNext = (0.299 * topNextPixel.r + 0.587 * topNextPixel.g + 0.114 * topNextPixel.b).round();
          final int bottomNext = (0.299 * bottomNextPixel.r + 0.587 * bottomNextPixel.g + 0.114 * bottomNextPixel.b).round();

          if ((top - topNext).abs() > 10 || (bottom - bottomNext).abs() > 10) {
            hasBlockEdge = true;
            break;
          }
        }

        // Verificar bordas verticais
        if (!hasBlockEdge) {
          for (int dy = 0; dy < 8; dy++) {
            final img.Pixel leftPixel = image.getPixel(x, y + dy);
            final img.Pixel rightPixel = image.getPixel(x + 7, y + dy);
            final img.Pixel leftNextPixel = image.getPixel(x - 1 < 0 ? 0 : x - 1, y + dy);
            final img.Pixel rightNextPixel = image.getPixel(x + 8 >= image.width ? image.width - 1 : x + 8, y + dy);

            final int left = (0.299 * leftPixel.r + 0.587 * leftPixel.g + 0.114 * leftPixel.b).round();
            final int right = (0.299 * rightPixel.r + 0.587 * rightPixel.g + 0.114 * rightPixel.b).round();
            final int leftNext = (0.299 * leftNextPixel.r + 0.587 * leftNextPixel.g + 0.114 * leftNextPixel.b).round();
            final int rightNext = (0.299 * rightNextPixel.r + 0.587 * rightNextPixel.g + 0.114 * rightNextPixel.b).round();

            if ((left - leftNext).abs() > 10 || (right - rightNext).abs() > 10) {
              hasBlockEdge = true;
              break;
            }
          }
        }

        if (hasBlockEdge) {
          blockPatterns++;
        }

        samples++;
      }
    }

    // Calcular densidade de padrões de blocos
    final double blockDensity = samples > 0 ? blockPatterns / samples : 0;

    // Converter para pontuação (0-1)
    double score = blockDensity * 2;
    if (score > 1) score = 1;

    return score;
  }
}
