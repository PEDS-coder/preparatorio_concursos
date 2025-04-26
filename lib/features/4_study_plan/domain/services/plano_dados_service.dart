import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/plano_data_logger.dart';

/// Serviço para extrair e armazenar dados do plano de estudos
class PlanoDadosService {
  final PlanoDataLogger _logger = PlanoDataLogger();

  /// Extrai dados do JSON retornado pela LLM e armazena nos metadados do plano
  Future<void> extrairDadosLLMParaPlano(PlanoEstudo plano, String jsonResponse) async {
    try {
      debugPrint('Extraindo dados da resposta LLM para o plano ${plano.id}');
      _logger.logRecuperacao(plano.id, 'extraindo_dados_llm', {
        'tamanho_resposta': jsonResponse.length,
        'inicio_resposta': jsonResponse.substring(0, jsonResponse.length > 100 ? 100 : jsonResponse.length)
      });

      // Verificar se a resposta é um JSON válido
      Map<String, dynamic> dadosJson;
      try {
        dadosJson = json.decode(jsonResponse);
        _logger.logRecuperacao(plano.id, 'json_decodificado', {
          'chaves_json': dadosJson.keys.toList(),
          'tamanho_json': jsonResponse.length
        });
      } catch (e) {
        _logger.logRecuperacao(plano.id, 'erro_decodificar_json', {
          'erro': e.toString(),
          'resposta': jsonResponse.substring(0, jsonResponse.length > 200 ? 200 : jsonResponse.length)
        });
        return;
      }

      // Verificar campos presentes no JSON
      _logger.logRecuperacao(plano.id, 'chaves_extraidas', {
        'chaves_extraidas': dadosJson.keys.toList(),
        'total_chaves': dadosJson.keys.length
      });

      // Extrair dados do ciclo de estudos
      if (dadosJson.containsKey('ciclo_estudos')) {
        plano.metadados['planoEstudos'] = {
          'cicloEstudos': dadosJson['ciclo_estudos'],
        };
      }

      // Extrair dados de duração do ciclo
      List<String> camposNumericos = ['duracao_total_ciclo', 'total_blocos_ciclo'];
      Map<String, dynamic> camposPresentes = {};

      for (var campo in camposNumericos) {
        if (dadosJson.containsKey(campo)) {
          plano.metadados[campo] = dadosJson[campo];
          camposPresentes[campo] = dadosJson[campo];
        }
      }

      _logger.logRecuperacao(plano.id, 'campos_presentes', {
        'campos_presentes': camposPresentes.keys.toList(),
        'total_campos': camposPresentes.keys.length
      });

      // Extrair matérias prioritárias
      if (dadosJson.containsKey('materias_prioritarias')) {
        plano.metadados['planoEstudos']['materiasPrioritarias'] = dadosJson['materias_prioritarias'];
      }

      // Extrair recomendações gerais
      if (dadosJson.containsKey('recomendacoes_gerais')) {
        plano.metadados['planoEstudos']['recomendacoesGerais'] = dadosJson['recomendacoes_gerais'];
      }

      // Extrair conteúdo programático do LLM
      if (dadosJson.containsKey('conteudo_programatico')) {
        plano.metadados['conteudo_programatico'] = dadosJson['conteudo_programatico'];
      }

      // Extrair dados da prova
      if (dadosJson.containsKey('prova')) {
        plano.metadados['prova'] = dadosJson['prova'];

        // Extrair campos específicos da prova para facilitar o acesso
        Map<String, dynamic> prova = dadosJson['prova'];
        if (prova.containsKey('data')) plano.metadados['dataProva'] = prova['data'];
        if (prova.containsKey('local')) plano.metadados['localProva'] = prova['local'];
        if (prova.containsKey('formato')) plano.metadados['formatoProva'] = prova['formato'];
        if (prova.containsKey('total_questoes')) plano.metadados['totalQuestoes'] = prova['total_questoes'];
        if (prova.containsKey('duracao')) plano.metadados['duracaoProva'] = prova['duracao'];
        if (prova.containsKey('tema_discursiva')) plano.metadados['temaProvaSubjetiva'] = prova['tema_discursiva'];
        if (prova.containsKey('criterios_aprovacao')) plano.metadados['criteriosAprovacao'] = prova['criterios_aprovacao'];
        if (prova.containsKey('criterios_reprovacao')) plano.metadados['criteriosReprovacao'] = prova['criterios_reprovacao'];
        if (prova.containsKey('criterios_desempate')) plano.metadados['criteriosDesempate'] = prova['criterios_desempate'];
      }

      // Extrair dados do concurso
      if (dadosJson.containsKey('concurso')) {
        plano.metadados['concurso'] = dadosJson['concurso'];

        // Extrair campos específicos do concurso para facilitar o acesso
        Map<String, dynamic> concurso = dadosJson['concurso'];
        if (concurso.containsKey('titulo')) plano.metadados['titulo'] = concurso['titulo'];
        if (concurso.containsKey('orgao')) plano.metadados['orgao'] = concurso['orgao'];
        if (concurso.containsKey('banca')) plano.metadados['banca'] = concurso['banca'];

        // Extrair dados de inscrição
        if (concurso.containsKey('inscricoes')) {
          Map<String, dynamic> inscricoes = concurso['inscricoes'];
          if (inscricoes.containsKey('periodo')) plano.metadados['periodoInscricao'] = inscricoes['periodo'];
          if (inscricoes.containsKey('taxa')) plano.metadados['valorInscricao'] = inscricoes['taxa'];
        }
      }

      // Registrar metadados atualizados
      _logger.logRecuperacao(plano.id, 'planoEstudos_metadados', {
        'cicloEstudos': plano.metadados.containsKey('planoEstudos') &&
                        plano.metadados['planoEstudos'] is Map &&
                        (plano.metadados['planoEstudos'] as Map).containsKey('cicloEstudos')
                        ? 'presente' : 'ausente',
        'materiasPrioritarias': plano.metadados.containsKey('planoEstudos') &&
                               plano.metadados['planoEstudos'] is Map &&
                               (plano.metadados['planoEstudos'] as Map).containsKey('materiasPrioritarias')
                               ? 'presente' : 'ausente',
        'grupos': plano.metadados.containsKey('planoEstudos') &&
                 plano.metadados['planoEstudos'] is Map &&
                 (plano.metadados['planoEstudos'] as Map).containsKey('grupos')
                 ? 'presente' : 'ausente',
        'calendario': plano.metadados.containsKey('planoEstudos') &&
                     plano.metadados['planoEstudos'] is Map &&
                     (plano.metadados['planoEstudos'] as Map).containsKey('calendario')
                     ? 'presente' : 'ausente'
      });

      debugPrint('Dados extraídos com sucesso para o plano ${plano.id}');
    } catch (e) {
      debugPrint('Erro ao extrair dados da resposta LLM: $e');
      _logger.logRecuperacao(plano.id, 'erro_extrair_dados_llm', {
        'erro': e.toString()
      });
    }
  }

  /// Extrai dados do edital para o plano
  Future<void> extrairDadosEditalParaPlano(PlanoEstudo plano, Edital edital) async {
    try {
      debugPrint('Extraindo dados do edital para o plano ${plano.id}');

      // Extrair dados básicos do edital
      if (edital.dadosExtraidos.titulo != null && edital.dadosExtraidos.titulo!.isNotEmpty) {
        plano.metadados['titulo'] = edital.dadosExtraidos.titulo;
      } else {
        plano.metadados['titulo'] = edital.nomeConcurso;
      }

      if (edital.dadosExtraidos.orgao != null && edital.dadosExtraidos.orgao!.isNotEmpty) {
        plano.metadados['orgao'] = edital.dadosExtraidos.orgao;
      }

      if (edital.dadosExtraidos.banca != null && edital.dadosExtraidos.banca!.isNotEmpty) {
        plano.metadados['banca'] = edital.dadosExtraidos.banca;
      }

      // Extrair dados dos dados extraídos do edital
      final dadosExtraidos = edital.dadosExtraidos;

      if (dadosExtraidos.dataProva != null && dadosExtraidos.dataProva!.isNotEmpty) {
        plano.metadados['dataProva'] = dadosExtraidos.dataProva;
      }

      if (dadosExtraidos.localProva != null && dadosExtraidos.localProva!.isNotEmpty) {
        plano.metadados['localProva'] = dadosExtraidos.localProva;
      }

      if (dadosExtraidos.valorTaxa != null) {
        plano.metadados['valorInscricao'] = dadosExtraidos.valorTaxa.toString();
      }

      // Extrair dados da prova
      if (dadosExtraidos.dadosProva != null) {
        final dadosProva = dadosExtraidos.dadosProva!;

        if (dadosProva.totalQuestoes != null) {
          plano.metadados['totalQuestoes'] = dadosProva.totalQuestoes.toString();
        }

        if (dadosProva.formato != null && dadosProva.formato!.isNotEmpty) {
          plano.metadados['formatoProva'] = dadosProva.formato!.join(', ');
        }

        if (dadosProva.temaDiscursiva != null && dadosProva.temaDiscursiva!.isNotEmpty) {
          plano.metadados['temaProvaSubjetiva'] = dadosProva.temaDiscursiva;
        }

        if (dadosProva.criteriosAprovacao != null && dadosProva.criteriosAprovacao!.isNotEmpty) {
          plano.metadados['criteriosAprovacao'] = dadosProva.criteriosAprovacao;
        }

        if (dadosProva.criteriosReprovacao != null && dadosProva.criteriosReprovacao!.isNotEmpty) {
          plano.metadados['criteriosReprovacao'] = dadosProva.criteriosReprovacao;
        }

        if (dadosProva.criteriosDesempate != null && dadosProva.criteriosDesempate!.isNotEmpty) {
          plano.metadados['criteriosDesempate'] = dadosProva.criteriosDesempate!.join('\n');
        }

        if (dadosProva.duracao != null && dadosProva.duracao!.isNotEmpty) {
          plano.metadados['duracaoProva'] = dadosProva.duracao;
        }
      }

      // Extrair dados dos dados originais do edital
      if (edital.dadosOriginais != null) {
        debugPrint('Verificando dados originais do edital...');

        // Verificar se há dados de prova nos dados originais
        if (edital.dadosOriginais!.containsKey('prova') && edital.dadosOriginais!['prova'] is Map) {
          final provaOriginal = edital.dadosOriginais!['prova'] as Map;
          debugPrint('  Encontrado prova nos dados originais: ${provaOriginal.keys.toList()}');

          if (!plano.metadados.containsKey('prova')) {
            plano.metadados['prova'] = Map<String, dynamic>.from(provaOriginal);
          }

          // Extrair campos específicos da prova
          if (provaOriginal.containsKey('formato') && !plano.metadados.containsKey('formatoProva')) {
            var formato = provaOriginal['formato'];
            if (formato is List) {
              plano.metadados['formatoProva'] = formato.join(', ');
            } else if (formato is String) {
              plano.metadados['formatoProva'] = formato;
            }
            debugPrint('  Extraído formatoProva: ${plano.metadados['formatoProva']}');
          }

          if (provaOriginal.containsKey('criterios_desempate') && !plano.metadados.containsKey('criteriosDesempate')) {
            var criterios = provaOriginal['criterios_desempate'];
            if (criterios is List) {
              plano.metadados['criteriosDesempate'] = criterios.join('\n');
            } else if (criterios is String) {
              plano.metadados['criteriosDesempate'] = criterios;
            }
            debugPrint('  Extraído criteriosDesempate: ${plano.metadados['criteriosDesempate']}');
          }

          if (provaOriginal.containsKey('criterios_reprovacao') && !plano.metadados.containsKey('criteriosReprovacao')) {
            plano.metadados['criteriosReprovacao'] = provaOriginal['criterios_reprovacao'].toString();
            debugPrint('  Extraído criteriosReprovacao: ${plano.metadados['criteriosReprovacao']}');
          }
        }

        // Verificar se há dados de prova na estrutura aninhada
        if (edital.dadosOriginais!.containsKey('concurso') &&
            edital.dadosOriginais!['concurso'] is Map &&
            (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {

          final provaOriginal = edital.dadosOriginais!['concurso']['prova'] as Map;
          debugPrint('  Encontrado concurso.prova nos dados originais: ${provaOriginal.keys.toList()}');

          if (!plano.metadados.containsKey('prova')) {
            plano.metadados['prova'] = Map<String, dynamic>.from(provaOriginal);
          }

          // Extrair campos específicos da prova
          if (provaOriginal.containsKey('criterios_reprovacao') && !plano.metadados.containsKey('criteriosReprovacao')) {
            plano.metadados['criteriosReprovacao'] = provaOriginal['criterios_reprovacao'].toString();
            debugPrint('  Extraído criteriosReprovacao de concurso.prova: ${plano.metadados['criteriosReprovacao']}');
          }
        }

        // Verificar se há dados de inscrição nos dados originais
        if (edital.dadosOriginais!.containsKey('inscricoes') && edital.dadosOriginais!['inscricoes'] is Map) {
          final inscricoesOriginal = edital.dadosOriginais!['inscricoes'] as Map;
          debugPrint('  Encontrado inscricoes nos dados originais: ${inscricoesOriginal.keys.toList()}');

          if (inscricoesOriginal.containsKey('taxa') && !plano.metadados.containsKey('valorInscricao')) {
            plano.metadados['valorInscricao'] = inscricoesOriginal['taxa'].toString();
            debugPrint('  Extraído valorInscricao: ${plano.metadados['valorInscricao']}');
          }

          if (inscricoesOriginal.containsKey('periodo') && !plano.metadados.containsKey('periodoInscricao')) {
            plano.metadados['periodoInscricao'] = inscricoesOriginal['periodo'].toString();
            debugPrint('  Extraído periodoInscricao: ${plano.metadados['periodoInscricao']}');
          }
        }

        // Verificar se há dados de inscrição na estrutura aninhada
        if (edital.dadosOriginais!.containsKey('concurso') &&
            edital.dadosOriginais!['concurso'] is Map &&
            (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

          final inscricoesOriginal = edital.dadosOriginais!['concurso']['inscricoes'] as Map;
          debugPrint('  Encontrado concurso.inscricoes nos dados originais: ${inscricoesOriginal.keys.toList()}');

          if (inscricoesOriginal.containsKey('taxa') && !plano.metadados.containsKey('valorInscricao')) {
            plano.metadados['valorInscricao'] = inscricoesOriginal['taxa'].toString();
            debugPrint('  Extraído valorInscricao de concurso.inscricoes: ${plano.metadados['valorInscricao']}');
          }

          if (inscricoesOriginal.containsKey('periodo') && !plano.metadados.containsKey('periodoInscricao')) {
            plano.metadados['periodoInscricao'] = inscricoesOriginal['periodo'].toString();
            debugPrint('  Extraído periodoInscricao de concurso.inscricoes: ${plano.metadados['periodoInscricao']}');
          }
        }
      }

      debugPrint('Dados do edital extraídos com sucesso para o plano ${plano.id}');
    } catch (e) {
      debugPrint('Erro ao extrair dados do edital: $e');
    }
  }
}
