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
        debugPrint('Conteúdo programático extraído diretamente do JSON: ${(dadosJson['conteudo_programatico'] as List).length} itens');
      }

      // Extrair taxa de inscrição diretamente do JSON
      if (dadosJson.containsKey('inscricoes') && dadosJson['inscricoes'] is Map) {
        final inscricoes = dadosJson['inscricoes'] as Map;
        if (inscricoes.containsKey('taxa')) {
          plano.metadados['valorInscricao'] = inscricoes['taxa'].toString();
          debugPrint('Taxa de inscrição extraída diretamente do JSON: ${plano.metadados['valorInscricao']}');
        }
      }

      // Verificar se há dados aninhados em 'concurso'
      if (dadosJson.containsKey('concurso') && dadosJson['concurso'] is Map) {
        final concurso = dadosJson['concurso'] as Map;

        // Extrair conteúdo programático aninhado
        if (concurso.containsKey('conteudo_programatico')) {
          // Se não temos conteúdo programático direto, usar o aninhado
          if (!plano.metadados.containsKey('conteudo_programatico')) {
            plano.metadados['conteudo_programatico'] = concurso['conteudo_programatico'];
            debugPrint('Conteúdo programático extraído de concurso.conteudo_programatico: ${(concurso['conteudo_programatico'] as List).length} itens');
          }
        }

        // Extrair taxa de inscrição aninhada
        if (concurso.containsKey('inscricoes') && concurso['inscricoes'] is Map) {
          final inscricoes = concurso['inscricoes'] as Map;
          if (inscricoes.containsKey('taxa')) {
            // Se não temos taxa de inscrição direta, usar a aninhada
            if (!plano.metadados.containsKey('valorInscricao')) {
              plano.metadados['valorInscricao'] = inscricoes['taxa'].toString();
              debugPrint('Taxa de inscrição extraída de concurso.inscricoes.taxa: ${plano.metadados['valorInscricao']}');
            }
          }
        }
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

  /// Extrai o conteúdo programático dos metadados do plano
  List<ConteudoProgramatico> extrairConteudoProgramatico(PlanoEstudo plano) {
    List<ConteudoProgramatico> resultado = [];

    // Log das chaves disponíveis nos metadados para diagnóstico
    _logger.logRecuperacao(plano.id, 'chaves_metadados_plano', {
      'chaves_nivel_1': plano.metadados.keys.toList(),
      'tem_concurso': plano.metadados.containsKey('concurso'),
      'tem_conteudo_programatico': plano.metadados.containsKey('conteudo_programatico'),
      'tem_conteudo_programatico_completo': plano.metadados.containsKey('conteudo_programatico_completo'),
    });

    // Se tiver a chave 'concurso', logar suas subchaves
    if (plano.metadados.containsKey('concurso') && plano.metadados['concurso'] is Map) {
      _logger.logRecuperacao(plano.id, 'chaves_concurso', {
        'chaves_concurso': (plano.metadados['concurso'] as Map).keys.toList(),
        'tem_conteudo_programatico_em_concurso': (plano.metadados['concurso'] as Map).containsKey('conteudo_programatico'),
      });
    }

    // Verificar primeiro em metadados.conteudo_programatico
    if (plano.metadados.containsKey('conteudo_programatico') &&
        plano.metadados['conteudo_programatico'] is List) {

      try {
        final List conteudoList = plano.metadados['conteudo_programatico'] as List;
        _logger.logRecuperacao(plano.id, 'conteudo_programatico_encontrado', {
          'tamanho': conteudoList.length,
          'primeiro_item_tipo': conteudoList.isNotEmpty ? conteudoList.first.runtimeType.toString() : 'vazio',
        });

        resultado = conteudoList
            .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        debugPrint('Conteúdo programático extraído de metadados.conteudo_programatico: ${resultado.length} matérias');
        _logger.logRecuperacao(plano.id, 'conteudo_programatico_extraido', {
          'fonte': 'metadados.conteudo_programatico',
          'quantidade': resultado.length,
          'materias': resultado.map((m) => m.nome).toList(),
        });
        return resultado;
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.conteudo_programatico: $e');
        _logger.logRecuperacao(plano.id, 'erro_converter_conteudo_programatico', {
          'fonte': 'metadados.conteudo_programatico',
          'erro': e.toString(),
        });
      }
    }

    // Verificar em metadados.concurso.conteudo_programatico
    if (plano.metadados.containsKey('concurso') &&
        plano.metadados['concurso'] is Map &&
        (plano.metadados['concurso'] as Map).containsKey('conteudo_programatico') &&
        (plano.metadados['concurso'] as Map)['conteudo_programatico'] is List) {

      try {
        final List conteudoList = (plano.metadados['concurso'] as Map)['conteudo_programatico'] as List;
        _logger.logRecuperacao(plano.id, 'conteudo_programatico_concurso_encontrado', {
          'tamanho': conteudoList.length,
          'primeiro_item_tipo': conteudoList.isNotEmpty ? conteudoList.first.runtimeType.toString() : 'vazio',
        });

        resultado = conteudoList
            .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        debugPrint('Conteúdo programático extraído de metadados.concurso.conteudo_programatico: ${resultado.length} matérias');
        _logger.logRecuperacao(plano.id, 'conteudo_programatico_extraido', {
          'fonte': 'metadados.concurso.conteudo_programatico',
          'quantidade': resultado.length,
          'materias': resultado.map((m) => m.nome).toList(),
        });
        return resultado;
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.concurso.conteudo_programatico: $e');
        _logger.logRecuperacao(plano.id, 'erro_converter_conteudo_programatico', {
          'fonte': 'metadados.concurso.conteudo_programatico',
          'erro': e.toString(),
        });
      }
    }

    // Verificar em metadados.conteudo_programatico_completo
    if (plano.metadados.containsKey('conteudo_programatico_completo') &&
        plano.metadados['conteudo_programatico_completo'] is List) {

      try {
        final List conteudoList = plano.metadados['conteudo_programatico_completo'] as List;
        _logger.logRecuperacao(plano.id, 'conteudo_programatico_completo_encontrado', {
          'tamanho': conteudoList.length,
          'primeiro_item_tipo': conteudoList.isNotEmpty ? conteudoList.first.runtimeType.toString() : 'vazio',
        });

        resultado = conteudoList
            .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        debugPrint('Conteúdo programático extraído de metadados.conteudo_programatico_completo: ${resultado.length} matérias');
        _logger.logRecuperacao(plano.id, 'conteudo_programatico_extraido', {
          'fonte': 'metadados.conteudo_programatico_completo',
          'quantidade': resultado.length,
          'materias': resultado.map((m) => m.nome).toList(),
        });
        return resultado;
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.conteudo_programatico_completo: $e');
        _logger.logRecuperacao(plano.id, 'erro_converter_conteudo_programatico', {
          'fonte': 'metadados.conteudo_programatico_completo',
          'erro': e.toString(),
        });
      }
    }

    // Verificar em metadados.materias (lista de matérias de proficiência)
    if (plano.metadados.containsKey('materias') && plano.metadados['materias'] is List) {
      try {
        final List materiasList = plano.metadados['materias'] as List;
        if (materiasList.isNotEmpty) {
          debugPrint('Tentando criar conteúdo programático a partir de metadados.materias: ${materiasList.length} matérias');

          // Converter cada matéria para ConteudoProgramatico
          for (var item in materiasList) {
            if (item is Map) {
              final nome = item['nome'] ?? item['materia'] ?? '';
              if (nome.isNotEmpty) {
                resultado.add(ConteudoProgramatico(
                  nome: nome.toString(),
                  grupoMateria: 'Matérias do Concurso',
                  tipo: 'comum',
                  topicos: [],
                  numeroQuestoes: null,
                  criterioDesempate: false,
                ));
              }
            } else if (item is String) {
              resultado.add(ConteudoProgramatico(
                nome: item,
                grupoMateria: 'Matérias do Concurso',
                tipo: 'comum',
                topicos: [],
                numeroQuestoes: null,
                criterioDesempate: false,
              ));
            }
          }

          if (resultado.isNotEmpty) {
            debugPrint('Conteúdo programático criado a partir de metadados.materias: ${resultado.length} matérias');
            _logger.logRecuperacao(plano.id, 'conteudo_programatico_extraido', {
              'fonte': 'metadados.materias',
              'quantidade': resultado.length,
              'materias': resultado.map((m) => m.nome).toList(),
            });
            return resultado;
          }
        }
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.materias: $e');
      }
    }

    // Verificar em materiasProficiencia do plano
    if (plano.materiasProficiencia.isNotEmpty) {
      try {
        debugPrint('Tentando criar conteúdo programático a partir de materiasProficiencia: ${plano.materiasProficiencia.length} matérias');

        // Converter cada matéria para ConteudoProgramatico
        for (var materiaProficiencia in plano.materiasProficiencia) {
          resultado.add(ConteudoProgramatico(
            nome: materiaProficiencia.nomeMateria,
            grupoMateria: 'Matérias do Concurso',
            tipo: 'comum',
            topicos: [],
            numeroQuestoes: null,
            criterioDesempate: false,
          ));
        }

        if (resultado.isNotEmpty) {
          debugPrint('Conteúdo programático criado a partir de materiasProficiencia: ${resultado.length} matérias');
          _logger.logRecuperacao(plano.id, 'conteudo_programatico_extraido', {
            'fonte': 'materiasProficiencia',
            'quantidade': resultado.length,
            'materias': resultado.map((m) => m.nome).toList(),
          });
          return resultado;
        }
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de materiasProficiencia: $e');
      }
    }

    debugPrint('Nenhum conteúdo programático encontrado nos metadados do plano');
    _logger.logRecuperacao(plano.id, 'conteudo_programatico_nao_encontrado', {});
    return resultado;
  }
}
