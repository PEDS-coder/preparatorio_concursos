import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:preparatorio_concursos/core/utils/custom_pdf_bitmap.dart';

/// Adaptador para converter entre PdfBitmap e CustomPdfBitmap
class PdfBitmapAdapter {
  /// Converte um PdfPage para CustomPdfBitmap
  static Future<CustomPdfBitmap> convertPageToBitmap(PdfPage page) async {
    // Tamanho reduzido para análise mais rápida
    const int targetWidth = 600;
    final double aspectRatio = page.size.width / page.size.height;
    final int targetHeight = (targetWidth / aspectRatio).round();

    // Criar bitmap personalizado
    final data = Uint8List(targetWidth * targetHeight * 4);
    final CustomPdfBitmap bitmap = CustomPdfBitmap(data, width: targetWidth, height: targetHeight);

    return bitmap;
  }

  /// Converte um CustomPdfBitmap para PdfBitmap
  static PdfBitmap convertToPdfBitmap(CustomPdfBitmap customBitmap) {
    return PdfBitmap(customBitmap.data);
  }
}
