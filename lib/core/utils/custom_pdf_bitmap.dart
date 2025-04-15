import 'dart:typed_data';

/// Classe personalizada para representar um bitmap de PDF
///
/// Esta classe foi criada para substituir o PdfBitmap da biblioteca syncfusion_flutter_pdf
/// e evitar problemas de compatibilidade e conflitos de importação. Ela fornece uma
/// implementação simplificada que contém apenas os campos necessários para o nosso uso.
///
/// A classe armazena os dados brutos da imagem como um Uint8List, junto com informações
/// de dimensão (largura e altura). Isso permite que o PdfScannerDetector processe
/// imagens de PDF sem depender diretamente da biblioteca syncfusion_flutter_pdf.
class CustomPdfBitmap {
  /// Largura do bitmap
  int width;

  /// Altura do bitmap
  int height;

  /// Dados do bitmap
  Uint8List data;

  /// Construtor
  ///
  /// @param data Os dados brutos da imagem como um Uint8List
  /// @param width A largura da imagem em pixels (opcional, padrão: 0)
  /// @param height A altura da imagem em pixels (opcional, padrão: 0)
  CustomPdfBitmap(this.data, {this.width = 0, this.height = 0});
}
