import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';

/// Interface para o serviço de compartilhamento
abstract class IShareService {
  /// Compartilha um plano de estudo
  Future<bool> sharePlanoEstudo(PlanoEstudo plano);

  /// Compartilha uma imagem
  Future<bool> shareImage(Uint8List imageBytes, {String? text, String? subject});

  /// Compartilha um widget como imagem
  Future<bool> shareWidgetAsImage(GlobalKey<State<StatefulWidget>> key, {String? text, String? subject});

  /// Compartilha um texto
  Future<bool> shareText(String text, {String? subject});

  /// Compartilha um arquivo
  Future<bool> shareFile(String filePath, {String? text, String? subject});
}
