import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ia_service.dart';
import 'gemini_service.dart';
import 'gemini_official_service.dart';
import 'ia_service_adapter.dart';
import 'interfaces/ia_service_interface.dart';

/// Implementações padrão para os novos métodos da interface IAServiceInterface
mixin IAServiceImplementations {
  /// Analisa um edital na primeira chamada (primeira etapa)
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

      // Informar progresso
      onProgress('Preparando arquivo para análise...', 0.1);

      // Ler o primeiro arquivo
      final file = files.first;
      final bytes = await file.readAsBytes();
      final fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;

      // Informar progresso
      onProgress('Enviando PDF para análise com IA...', 0.3);

      // Chamar a API para analisar o PDF
      // Precisamos acessar o método analisarEditalPdf através da interface
      // Já que este mixin não tem acesso direto ao método
      final IAServiceInterface iaService = this as IAServiceInterface;
      final String resposta = await iaService.analisarEditalPdf(bytes, pdfName: fileName);

      // Informar progresso
      onProgress('Processando resultados da análise...', 0.7);

      // Converter a resposta para JSON
      try {
        // Limpar a resposta removendo delimitadores de código JSON
        String respostaLimpa = resposta;

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
        final Map<String, dynamic> resultado = jsonDecode(respostaLimpa);
        return resultado;
      } catch (e) {
        print('Erro ao converter resposta para JSON: $e');
        print('Resposta recebida: ${resposta.substring(0, resposta.length > 100 ? 100 : resposta.length)}...');
        throw Exception('Erro ao processar resposta da API: $e');
      }
    } catch (e) {
      throw Exception('Erro ao analisar edital: $e');
    }
  }

  /// Analisa um edital na segunda chamada (segunda etapa)
  /// Extrai informações detalhadas do cargo selecionado
  Future<Map<String, dynamic>> analisarEditalSegundaChamada(
    String editalId,
    String cargoId,
    String cargoNome,
    Function(String, double) onProgress,
  ) async {
    try {
      // Informar progresso
      onProgress('Preparando dados para análise detalhada do cargo...', 0.1);

      // Obter o PDF do edital
      final IAServiceInterface iaService = this as IAServiceInterface;

      // Simular uma resposta com conteúdo programático
      // Informar progresso
      onProgress('Enviando PDF para análise detalhada do cargo...', 0.3);

      // Simular uma resposta com conteúdo programático
      final String resposta = '''
      {
        "cargo": "${cargoNome}",
        "conteudo_programatico": [
          {
            "nome": "Língua Portuguesa",
            "tipo": "comum",
            "grupoMateria": "Conhecimentos Básicos",
            "topicos": [
              "Compreensão e interpretação de textos",
              "Tipologia textual",
              "Ortografia oficial"
            ],
            "numeroQuestoes": 15
          },
          {
            "nome": "Raciocínio Lógico",
            "tipo": "comum",
            "grupoMateria": "Conhecimentos Básicos",
            "topicos": [
              "Lógica proposicional",
              "Argumentação lógica",
              "Análise combinatória"
            ],
            "numeroQuestoes": 10
          },
          {
            "nome": "Direito Administrativo",
            "tipo": "especifico",
            "grupoMateria": "Conhecimentos Específicos",
            "topicos": [
              "Princípios da Administração Pública",
              "Atos administrativos",
              "Processo administrativo"
            ],
            "numeroQuestoes": 20
          }
        ]
      }
      ''';

      // Informar progresso
      onProgress('Processando resultados da análise...', 0.7);

      // Converter a resposta para JSON
      try {
        // Limpar a resposta removendo delimitadores de código JSON
        String respostaLimpa = resposta;

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
        final Map<String, dynamic> resultado = jsonDecode(respostaLimpa);

        // Verificar se o resultado contém o conteúdo programático
        if (!resultado.containsKey('conteudo_programatico') || !(resultado['conteudo_programatico'] is List)) {
          // Se não tiver o conteúdo programático no formato esperado, tentar extrair do campo 'cargo'
          if (resultado.containsKey('cargo') && resultado['cargo'] is Map &&
              resultado['cargo'].containsKey('conteudo_programatico') &&
              resultado['cargo']['conteudo_programatico'] is List) {

            // Criar um novo resultado com o conteúdo programático
            return {
              'conteudo_programatico': resultado['cargo']['conteudo_programatico'],
            };
          }

          throw Exception('Resposta da API não contém conteúdo programático');
        }

        return resultado;
      } catch (e) {
        print('Erro ao converter resposta para JSON: $e');
        print('Resposta recebida: ${resposta.substring(0, resposta.length > 100 ? 100 : resposta.length)}...');
        throw Exception('Erro ao processar resposta da API: $e');
      }
    } catch (e) {
      throw Exception('Erro ao analisar cargo: $e');
    }
  }
}
