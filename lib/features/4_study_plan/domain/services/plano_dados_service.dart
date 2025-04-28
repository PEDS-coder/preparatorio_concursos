import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';

/// Serviço para extrair e armazenar dados do plano de estudos
class PlanoDadosService {
  /// Extrai dados do JSON retornado pela LLM e armazena nos metadados do plano
  Future<void> extrairDadosLLMParaPlano(PlanoEstudo plano, String jsonResponse) async {
    try {
      debugPrint('Extraindo dados da resposta LLM para o plano ${plano.id}');

      // Verificar se a resposta é um JSON válido
      Map<String, dynamic> dadosJson;
      try {
        dadosJson = json.decode(jsonResponse);
      } catch (e) {
        debugPrint('Erro ao decodificar JSON: $e');
        return;
      }

      // Verificar campos presentes no JSON
      debugPrint('Campos extraídos: ${dadosJson.keys.toList()}');

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

      debugPrint('Campos presentes: ${camposPresentes.keys.toList()}');

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

      debugPrint('Dados extraídos com sucesso para o plano ${plano.id}');
    } catch (e) {
      debugPrint('Erro ao extrair dados da resposta LLM: $e');
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

      // Extrair informações sobre cotas
      if (dadosExtraidos.cotas != null && dadosExtraidos.cotas!.isNotEmpty) {
        plano.metadados['cotas'] = dadosExtraidos.cotas!.map((cota) => cota.toMap()).toList();
      }
    } catch (e) {
      debugPrint('Erro ao extrair dados do edital: $e');
    }
  }

  /// Extrai o conteúdo programático dos metadados do plano
  List<ConteudoProgramatico> extrairConteudoProgramatico(PlanoEstudo plano) {
    List<ConteudoProgramatico> resultado = [];

    // Verificar primeiro em metadados.conteudo_programatico
    if (plano.metadados.containsKey('conteudo_programatico') &&
        plano.metadados['conteudo_programatico'] is List) {

      try {
        final List conteudoList = plano.metadados['conteudo_programatico'] as List;
        resultado = conteudoList
            .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        debugPrint('Conteúdo programático extraído de metadados.conteudo_programatico: ${resultado.length} matérias');
        return resultado;
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.conteudo_programatico: $e');
      }
    }

    // Verificar em metadados.concurso.conteudo_programatico
    if (plano.metadados.containsKey('concurso') &&
        plano.metadados['concurso'] is Map &&
        (plano.metadados['concurso'] as Map).containsKey('conteudo_programatico') &&
        (plano.metadados['concurso'] as Map)['conteudo_programatico'] is List) {

      try {
        final List conteudoList = (plano.metadados['concurso'] as Map)['conteudo_programatico'] as List;
        resultado = conteudoList
            .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        debugPrint('Conteúdo programático extraído de metadados.concurso.conteudo_programatico: ${resultado.length} matérias');
        return resultado;
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.concurso.conteudo_programatico: $e');
      }
    }

    // Verificar em metadados.conteudo_programatico_completo
    if (plano.metadados.containsKey('conteudo_programatico_completo') &&
        plano.metadados['conteudo_programatico_completo'] is List) {

      try {
        final List conteudoList = plano.metadados['conteudo_programatico_completo'] as List;
        resultado = conteudoList
            .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        debugPrint('Conteúdo programático extraído de metadados.conteudo_programatico_completo: ${resultado.length} matérias');
        return resultado;
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de metadados.conteudo_programatico_completo: $e');
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
          return resultado;
        }
      } catch (e) {
        debugPrint('Erro ao converter conteúdo programático de materiasProficiencia: $e');
      }
    }

    debugPrint('Nenhum conteúdo programático encontrado nos metadados do plano');
    return resultado;
  }
}
