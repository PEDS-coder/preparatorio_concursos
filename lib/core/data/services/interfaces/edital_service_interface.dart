import 'dart:typed_data';

import 'package:preparatorio_concursos/core/data/models/edital.dart';

/// Interface para o serviço de editais
abstract class IEditalService {
  /// Carrega os editais salvos
  Future<void> loadEditais();

  /// Adiciona um novo edital
  Future<void> addEdital(Edital edital);

  /// Atualiza um edital existente
  Future<void> updateEdital(Edital edital);

  /// Remove um edital
  Future<void> removeEdital(String editalId);

  /// Obtém um edital pelo ID
  Edital? getEditalById(String editalId);

  /// Define o edital atual
  Future<void> setCurrentEdital(String editalId);

  /// Obtém o edital atual
  Edital? getCurrentEdital();

  /// Analisa um edital a partir de um arquivo PDF
  Future<Edital> analisarEdital(Uint8List pdfBytes, {String? fileName});

  /// Extrai o conteúdo programático de um edital
  Future<Map<String, dynamic>> extrairConteudoProgramatico(
    String editalId,
    List<String> cargoIds,
  );

  /// Obtém a lista de editais
  List<Edital> get editais;

  /// Obtém o edital atual
  Edital? get currentEdital;

  /// Verifica se há editais salvos
  bool get hasEditais;
}
