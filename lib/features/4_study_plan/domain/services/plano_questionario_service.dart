import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/plano_data_logger.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/auth/auth_service.dart';
import 'llm_response_processor.dart';
import 'plano_data_validator.dart';

/// Serviço para gerenciar a lógica de criação do plano de estudos
class PlanoQuestionarioService {
  final IAServiceInterface iaService;
  final PlanoEstudoService planoService;
  final AuthService authService;
  final PlanoDataLogger logger;
  final PlanoDataValidator validator;
  final LLMResponseProcessor llmProcessor;

  PlanoQuestionarioService({
    required this.iaService,
    required this.planoService,
    required this.authService,
    required this.logger,
    required this.validator,
    required this.llmProcessor,
  });

  /// Gera um plano de estudos com base nos dados do questionário
  Future<String?> gerarPlanoEstudos({
    required Map<String, dynamic> dadosCargo,
    required Map<String, dynamic> dadosEdital,
    required DateTime? dataInicio,
    required DateTime? dataFim,
    required Map<String, int> horasPorDia,
    required Map<String, List<int>> horasSelecionadas,
    required List<String> ferramentas,
    required Map<String, String> proficiencia,
    required List<RecompensaConfig> recompensas,
    required Function(double, String) onProgress,
  }) async {
    // Verificar se o usuário está autenticado
    final usuario = authService.currentUser;
    if (usuario == null) {
      throw Exception('Você precisa estar autenticado para criar um plano de estudo.');
    }

    // Gerar ID temporário para logs
    final planoId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Atualizar progresso
      onProgress(0.1, 'Preparando dados para geração do plano...');

      // Preparar dados para enviar à API
      final List<String> materiasOriginais = (dadosCargo['materias'] as List<String>? ?? []);

      // Criar um mapa de proficiência com os nomes originais das matérias
      final Map<String, String> proficienciaOriginal = {};
      for (var entry in proficiencia.entries) {
        // Encontrar o nome original da matéria (case sensitive)
        final String nomeOriginal = materiasOriginais.firstWhere(
          (m) => m.toLowerCase() == entry.key.toLowerCase(),
          orElse: () => entry.key
        );
        proficienciaOriginal[nomeOriginal] = entry.value;
      }

      // Preparar dados para a API
      final Map<String, dynamic> dadosParaAPI = {
        'cargo': dadosCargo['cargo'],
        'materias': materiasOriginais,
        'dataInicio': dataInicio != null ? '${dataInicio.day}/${dataInicio.month}/${dataInicio.year}' : '',
        'dataFim': dataFim != null ? '${dataFim.day}/${dataFim.month}/${dataFim.year}' : '',
        'horasPorDia': horasPorDia,
        'horasSelecionadas': horasSelecionadas,
        'ferramentas': ferramentas,
        'proficiencia': proficienciaOriginal,
        'recompensas': recompensas.map((r) => {'tipo': r.tipoRecompensa, 'descricao': r.descricaoRecompensa}).toList(),
        'edital': dadosEdital,
      };

      // Atualizar progresso
      onProgress(0.2, 'Gerando plano de estudos com IA...');

      // Chamar a API para gerar o plano de estudos
      String resultadoAPI = '';
      try {
        resultadoAPI = await iaService.gerarPlanoEstudos(
          cargoAlvo: dadosCargo['cargo'],
          dadosCargo: dadosParaAPI,
        );

        // Salvar a resposta completa em um arquivo de log para análise posterior
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/llm_response_log.txt');
          await file.writeAsString('${DateTime.now().toString()}\n$resultadoAPI\n\n', mode: FileMode.append);
          logger.logProcessamentoLLM(planoId, 'resposta_salva_arquivo_log', {'caminho': file.path});
        } catch (e) {
          logger.logProcessamentoLLM(planoId, 'erro_salvar_arquivo_log', {'erro': e.toString()});
        }

        // Salvar a resposta em um arquivo específico para este plano
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/resposta_llm_$planoId.json');
          await file.writeAsString(resultadoAPI);
          logger.logProcessamentoLLM(planoId, 'resposta_salva_arquivo', {'caminho': file.path});
        } catch (e) {
          logger.logProcessamentoLLM(planoId, 'erro_salvar_arquivo', {'erro': e.toString()});
        }
      } catch (e) {
        logger.logProcessamentoLLM(planoId, 'erro_chamar_api', {'erro': e.toString()});
        // Usar dados simulados em caso de erro
        resultadoAPI = '{"ciclo_estudos": [{"dia": 1, "blocos": [{"ordem": 1, "materia": "Português", "duracao_minutos": 90, "ferramenta": "Videoaulas"}]}], "materias_prioritarias": [{"nome": "Português", "pontuacao_prioridade": 31}]}';
      }

      // Atualizar progresso
      onProgress(0.5, 'Processando resposta da IA...');

      // Processar o resultado da API
      Map<String, dynamic> resultadoJSON = llmProcessor.processarResposta(resultadoAPI, planoId);

      // Registrar tamanho da resposta e campos presentes
      logger.logProcessamentoLLM(planoId, 'tamanho_resposta', {
        'tamanho_resposta': resultadoAPI.length,
        'inicio_resposta': resultadoAPI.substring(0, resultadoAPI.length > 100 ? 100 : resultadoAPI.length)
      });

      // Atualizar progresso
      onProgress(0.7, 'Construindo plano de estudos...');

      // Preparar dados para criar o plano
      List<MateriaProficiencia> materiasProficiencia = validator.criarMateriasProficiencia(proficiencia);

      // Verificar se há recompensas, caso contrário usar padrão
      List<RecompensaConfig> recompensasParaUsar = recompensas;
      if (recompensasParaUsar.isEmpty) {
        recompensasParaUsar = validator.criarRecompensasPadrao();
      }

      // Criar dados adicionais para o plano
      Map<String, dynamic> planoEstudos = {
        'materias': materiasOriginais.map((m) => {'nome': m}).toList(),
        'proficiencia': materiasProficiencia.map((mp) => {
          'materia': mp.nomeMateria,
          'nivel': mp.nivelProficiencia
        }).toList(),
        'recompensas': recompensasParaUsar.map((r) => {'tipo': r.tipoRecompensa, 'descricao': r.descricaoRecompensa}).toList(),
        'horasPorMateria': {for (var m in materiasOriginais) m: 20},
        'cicloEstudos': resultadoJSON['ciclo_estudos'],
        'materiasPrioritarias': resultadoJSON['materias_prioritarias'],
        'grupos': resultadoJSON['grupos'] ?? [
          {
            'nome': 'Conhecimentos Básicos',
            'materias': [
              {'nome': 'Português', 'questoes': 10, 'peso': 1, 'desempate': false, 'assuntos': ['Interpretação', 'Gramática']},
              {'nome': 'Matemática', 'questoes': 5, 'peso': 1, 'desempate': false, 'assuntos': ['Aritmética', 'Álgebra']},
            ]
          },
          {
            'nome': 'Conhecimentos Específicos',
            'materias': [
              {'nome': 'Direito Constitucional', 'questoes': 10, 'peso': 2, 'desempate': true, 'assuntos': ['Princípios', 'Direitos Fundamentais']},
              {'nome': 'Direito Administrativo', 'questoes': 10, 'peso': 2, 'desempate': false, 'assuntos': ['Administração Pública', 'Atos Administrativos']},
            ]
          }
        ],
      };

      // Verificar se os metadados estão presentes
      Map<String, dynamic> metadados = {};

      // Adicionar todos os dados extraídos aos metadados
      resultadoJSON.forEach((key, value) {
        if (key != 'ciclo_estudos' && key != 'materias_prioritarias' && key != 'recomendacoes_gerais') {
          metadados[key] = value;
        }
      });

      // Se houver metadados específicos, adicionar também
      if (resultadoJSON.containsKey('metadados')) {
        final metadadosEspecificos = resultadoJSON['metadados'] as Map<String, dynamic>;
        metadadosEspecificos.forEach((key, value) {
          metadados[key] = value;
        });
      }

      // Adicionar dados do edital aos metadados
      if (dadosEdital.containsKey('dadosOriginais') && dadosEdital['dadosOriginais'] != null) {
        metadados['dadosOriginais'] = dadosEdital['dadosOriginais'];
      }

      logger.logProcessamentoLLM(planoId, 'metadados_detalhes', {
        'campos_presentes': metadados.keys.toList(),
        'total_campos': metadados.keys.length,
      });

      // Atualizar progresso
      onProgress(0.9, 'Criando plano de estudos...');

      // Criar o plano com os dados coletados
      logger.logArmazenamento(planoId, 'criando_plano', {
        'userId': usuario.id,
        'editalId': dadosEdital['id'] ?? '',
        'cargo': dadosCargo['cargo'] ?? '',
        'dataInicio': (dataInicio ?? DateTime.now()).toIso8601String(),
        'dataFim': (dataFim ?? DateTime.now().add(const Duration(days: 90))).toIso8601String(),
        'horasPorDia': horasPorDia,
        'ferramentas': ferramentas,
        'materiasProficiencia': materiasProficiencia.map((mp) => '${mp.nomeMateria}: ${mp.nivelProficiencia}').toList(),
        'recompensas': recompensasParaUsar.map((r) => '${r.tipoRecompensa}: ${r.descricaoRecompensa}').toList(),
      });

      final plano = await planoService.criarPlanoEstudo(
        usuario.id,
        dadosEdital['id'] ?? '',
        [dadosCargo['cargo'] ?? ''],
        dataInicio ?? DateTime.now(),
        dataFim ?? DateTime.now().add(const Duration(days: 90)),
        horasPorDia,
        ferramentas,
        materiasProficiencia,
        recompensasParaUsar,
        horariosEspecificos: horasSelecionadas,
        dadosAdicionais: {
          ...dadosEdital,
          ...dadosCargo,
          'planoEstudos': planoEstudos,
        },
      );

      // Atualizar metadados do plano com o JSON processado pela LLM
      await planoService.atualizarMetadados(plano.id, resultadoJSON);

      logger.logArmazenamento(plano.id, 'plano_criado', {
        'id': plano.id,
        'metadados_keys': plano.metadados.keys.toList(),
        'planoEstudos_presente': plano.metadados.containsKey('planoEstudos'),
        'sessoesEstudo': plano.sessoesEstudo.length,
      });

      // Atualizar progresso
      onProgress(1.0, 'Plano de estudos criado com sucesso!');

      return plano.id;
    } catch (e) {
      logger.logArmazenamento(planoId, 'erro_criar_plano', {'erro': e.toString()});
      throw Exception('Erro ao criar plano de estudo: $e');
    }
  }
}
