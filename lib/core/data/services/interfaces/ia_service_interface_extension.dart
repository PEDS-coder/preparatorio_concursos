import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ia_service_interface.dart';

/// Extensão para a interface IAServiceInterface
/// Adiciona métodos para análise de editais em duas etapas
extension IAServiceInterfaceExtension on IAServiceInterface {
  /// Analisa um edital na primeira chamada
  /// Extrai informações básicas e cargos
  Future<Map<String, dynamic>> analisarEditalPrimeiraChamada(
    List<File> files,
    Function(String, double) onProgress,
  ) async {
    // Implementação padrão que usa os métodos existentes
    try {
      // Verificar se há arquivos
      if (files.isEmpty) {
        throw Exception('Nenhum arquivo fornecido');
      }

      // Ler o primeiro arquivo
      final file = files.first;
      final bytes = await file.readAsBytes();

      // Informar progresso
      onProgress('Analisando edital...', 0.3);

      // Chamar o método existente para analisar o edital
      final resultado = await analisarEditalPdf(bytes, pdfName: file.path.split('/').last);

      // Informar progresso
      onProgress('Processando resultados...', 0.7);

      // Converter o resultado para Map
      try {
        // Limpar a resposta removendo delimitadores de código JSON
        String respostaLimpa = resultado;

        // Remover delimitadores de código JSON no início (```json)
        if (respostaLimpa.trim().startsWith('```json')) {
          respostaLimpa = respostaLimpa.replaceFirst(RegExp(r'^\s*```json\s*'), '');
        } else if (respostaLimpa.trim().startsWith('```')) {
          respostaLimpa = respostaLimpa.replaceFirst(RegExp(r'^\s*```\s*'), '');
        }

        // Remover delimitadores de código no final (```)
        if (respostaLimpa.trim().endsWith('```')) {
          respostaLimpa = respostaLimpa.replaceFirst(RegExp(r'\s*```\s*$'), '');
        }

        print('Resposta limpa: ${respostaLimpa.substring(0, respostaLimpa.length > 100 ? 100 : respostaLimpa.length)}...');

        // Tentar converter para JSON
        final Map<String, dynamic> resultadoJson = jsonDecode(respostaLimpa);
        return resultadoJson;
      } catch (e) {
        throw Exception('Erro ao processar resposta da API: $e');
      }
    } catch (e) {
      throw Exception('Erro ao analisar edital: $e');
    }
  }

  /// Analisa um edital na segunda chamada
  /// Extrai informações detalhadas do cargo selecionado
  Future<Map<String, dynamic>> analisarEditalSegundaChamada(
    String editalId,
    String cargoId,
    String cargoNome,
    Function(String, double) onProgress,
  ) async {
    // Esta implementação foi removida para evitar conflitos com a implementação em IAServiceImplementations
    // Cada serviço de IA deve implementar seu próprio método analisarEditalSegundaChamada
    throw UnimplementedError('Este método deve ser implementado por cada serviço de IA específico');
  }
}
