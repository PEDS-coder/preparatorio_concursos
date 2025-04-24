import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import '../data/models/dados_extraidos.dart';
import '../data/services/ia_service.dart';
import '../utils/json_processor.dart';
import '../utils/yaml_processor.dart';

/// Exceção lançada quando ocorre um erro na análise do edital
class EditalAnalysisException implements Exception {
  final String message;
  EditalAnalysisException(this.message);
  @override
  String toString() => 'EditalAnalysisException: $message';
}

/// Classe responsável por analisar editais de concurso
class EditalAnalyzer {
  final IAService iaService;
  final Function(double, String)? onProgress;

  EditalAnalyzer({
    required this.iaService,
    this.onProgress,
  });

  /// Função para reportar progresso
  void _reportProgress(double progress, String message) {
    if (onProgress != null) {
      onProgress!(progress, message);
    }
  }

  /// Função para log (apenas em modo debug)
  void _log(String message) {
    if (kDebugMode) {
      print('[EditalAnalyzer] $message');
    }
  }

  /// Analisa um edital e extrai apenas os cargos disponíveis (primeira etapa do novo fluxo)
  /// Retorna um objeto DadosExtraidos com apenas os cargos preenchidos
  /// Envia o PDF diretamente para a LLM sem extração prévia de texto
  Future<DadosExtraidos> analisarEdital([String? textoEdital, Uint8List? pdfBytes]) async {
    _reportProgress(0.05, 'Iniciando análise...');
    Map<String, dynamic>? dadosExtraidosMap;

    try {
      // Verificar se temos o PDF
      if (pdfBytes == null || pdfBytes.isEmpty) {
        throw EditalAnalysisException('PDF do edital não fornecido. A análise direta de edital requer o arquivo PDF.');
      }
      
      _reportProgress(0.1, 'Preparando PDF para envio direto à LLM...');

      // Enviar o PDF diretamente para a LLM sem extração prévia
      _reportProgress(0.2, 'Enviando PDF diretamente para a LLM...');
      
      // Enviar o PDF diretamente para a API
      final String? resultado = await iaService.analisarEditalPdf(pdfBytes);
      
      if (resultado == null || resultado.isEmpty) {
        _log('Resultado da análise do PDF vazio');
        throw EditalAnalysisException('A análise do PDF falhou. Verifique se a API está configurada corretamente.');
      }
      
      _reportProgress(0.7, 'Processando resultado da análise...');
      _log('Resultado da análise recebido. Processando resposta...');
      
      // Processar o resultado (preferencialmente JSON)
      dadosExtraidosMap = _processarRespostaLLM(resultado);
      
      if (dadosExtraidosMap != null) {
        _log('Processamento da resposta bem-sucedido!');

        // Adicionar o texto completo ao resultado se disponível
        if (textoEdital != null && textoEdital.isNotEmpty) {
          dadosExtraidosMap['textoCompleto'] = textoEdital;
        }

        _reportProgress(0.9, 'Convertendo dados para formato final...');

        // Retornar os dados extraídos pela LLM
        return _converterParaDadosExtraidos(dadosExtraidosMap);
      } else {
        // Se a análise com LLM falhou, lançar uma exceção
        throw EditalAnalysisException('A extração de cargos falhou. Verifique se a API está configurada corretamente.');
      }
    } catch (e, stackTrace) {
      _log('Erro na análise principal: $e\nStackTrace: $stackTrace');
      _reportProgress(1.0, 'Falha na análise.');
      throw EditalAnalysisException('Falha ao analisar o edital: $e');
    }
  }

  /// Processa a resposta da API LLM (preferencialmente JSON, com fallback para YAML)
  Map<String, dynamic>? _processarRespostaLLM(String resposta) {
    try {
      // Processar como JSON (abordagem principal)
      _log('Processando resposta como JSON...');
      _log('Primeiros 200 caracteres da resposta: ${resposta.substring(0, min(200, resposta.length))}...');

      // Verificar se a resposta contém a estrutura esperada para cargos
      if (resposta.contains('"cargos"') || resposta.contains('"total_cargos"') || resposta.contains('"cargos_disponiveis"')) {
        _log('Resposta contém estrutura de cargos esperada');
      } else {
        _log('AVISO: Resposta não contém estrutura de cargos esperada');
      }

      // Usar o processador JSON para lidar com respostas
      final jsonResult = JsonProcessor.processJson(resposta);

      if (jsonResult != null) {
        _log('Processamento JSON bem-sucedido!');
        _log('Chaves no resultado JSON: ${jsonResult.keys.join(', ')}');

        // Verificar se há cargos no resultado
        if (jsonResult.containsKey('cargos')) {
          var cargos = jsonResult['cargos'];
          if (cargos is List) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida');
          }
        } else if (jsonResult.containsKey('cargos_disponiveis')) {
          var cargos = jsonResult['cargos_disponiveis'];
          if (cargos is List) {
            _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
            // Copiar para o campo 'cargos' para padronização
            jsonResult['cargos'] = cargos;
          } else {
            _log('Campo "cargos_disponiveis" não é uma lista válida');
          }
        } else {
          _log('Nenhum campo de cargos encontrado no resultado JSON');
        }

        return jsonResult;
      }

      // Se falhar com JSON, tentar com YAML como fallback
      _log('Processamento JSON falhou, tentando YAML como fallback...');

      // Usar o processador YAML para lidar com respostas complexas
      final result = YamlProcessor.processYaml(resposta);

      if (result != null) {
        _log('Processamento YAML bem-sucedido!');
        _log('Chaves no resultado YAML: ${result.keys.join(', ')}');

        // Verificar se há cargos no resultado
        if (result.containsKey('cargos')) {
          var cargos = result['cargos'];
          if (cargos is List) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida');
          }
        } else if (result.containsKey('cargos_disponiveis')) {
          var cargos = result['cargos_disponiveis'];
          if (cargos is List) {
            _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
            // Copiar para o campo 'cargos' para padronização
            result['cargos'] = cargos;
          } else {
            _log('Campo "cargos_disponiveis" não é uma lista válida');
          }
        } else {
          _log('Nenhum campo de cargos encontrado no resultado YAML');
        }

        return result;
      }

      _log('Todas as tentativas de processamento falharam');
      return null;
    } catch (e, stackTrace) {
      _log('Erro ao processar resposta: $e\nStackTrace: $stackTrace');
      return null;
    }
  }

  /// Converte um Map<String, dynamic> para um objeto DadosExtraidos
  DadosExtraidos _converterParaDadosExtraidos(Map<String, dynamic> dados) {
    try {
      return DadosExtraidos.fromJson(dados);
    } catch (e, stackTrace) {
      _log('Erro ao converter para DadosExtraidos: $e\nStackTrace: $stackTrace');
      throw EditalAnalysisException('Erro ao converter dados extraídos: $e');
    }
  }
}
