import 'dart:convert';
import '../../../../core/utils/plano_data_logger.dart';

/// Serviço para processar e validar respostas da LLM
class LLMResponseProcessor {
  final PlanoDataLogger logger;

  LLMResponseProcessor({required this.logger});

  /// Processa a resposta da LLM e extrai o JSON
  Map<String, dynamic> processarResposta(String resposta, String planoId) {
    logger.logProcessamentoLLM(planoId, 'resposta_recebida', {
      'tamanho_resposta': resposta.length,
      'inicio_resposta': resposta.substring(0, resposta.length > 100 ? 100 : resposta.length),
    });

    // Salvar a resposta completa da LLM para referência
    logger.logProcessamentoLLM(planoId, 'resposta_completa_referencia', 'RESPOSTA_LLM_COMPLETA_$planoId');

    try {
      // Verificar se a resposta está em formato markdown
      String jsonString = resposta;

      // Extrair JSON de blocos de código markdown
      if (resposta.trim().startsWith('```json') && resposta.trim().endsWith('```')) {
        jsonString = resposta.trim().substring(7, resposta.trim().length - 3).trim();
        logger.logProcessamentoLLM(planoId, 'json_extraido_markdown', 'JSON extraído do formato markdown');
      } else if (resposta.contains('```json') && resposta.contains('```')) {
        // Extrair o conteúdo entre ```json e ```
        final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
        final match = jsonBlockRegex.firstMatch(resposta);
        if (match != null) {
          jsonString = match.group(1)!.trim();
          logger.logProcessamentoLLM(planoId, 'json_extraido_markdown_interno', 'JSON extraído de bloco markdown interno');
        }
      } else if (resposta.trim().startsWith('```') && resposta.trim().endsWith('```')) {
        jsonString = resposta.trim().substring(3, resposta.trim().length - 3).trim();
        logger.logProcessamentoLLM(planoId, 'conteudo_extraido_markdown', 'Conteúdo extraído do formato markdown genérico');
      }

      // Tentar decodificar o JSON
      Map<String, dynamic> resultadoJSON = json.decode(jsonString);

      // Verificar a estrutura do JSON
      _verificarEstruturaJSON(resultadoJSON, planoId);

      // Normalizar chaves similares
      resultadoJSON = _normalizarChavesSimilares(resultadoJSON, planoId);

      // Extrair dados do concurso e cargo se presentes
      resultadoJSON = _extrairDadosConcursoCargo(resultadoJSON, planoId);

      return resultadoJSON;
    } catch (e) {
      logger.logProcessamentoLLM(planoId, 'erro_decodificar_json', 'Erro: $e');

      try {
        // Tentar extrair o JSON da resposta usando expressão regular
        final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.firstMatch(resposta);

        if (match != null) {
          final jsonStr = match.group(0);
          logger.logProcessamentoLLM(planoId, 'json_extraido_regex', {
            'tamanho_json': jsonStr!.length,
            'inicio_json': jsonStr.substring(0, jsonStr.length > 100 ? 100 : jsonStr.length),
          });

          Map<String, dynamic> resultadoJSON = json.decode(jsonStr);

          // Verificar a estrutura do JSON
          _verificarEstruturaJSON(resultadoJSON, planoId);

          // Normalizar chaves similares
          resultadoJSON = _normalizarChavesSimilares(resultadoJSON, planoId);

          // Extrair dados do concurso e cargo se presentes
          resultadoJSON = _extrairDadosConcursoCargo(resultadoJSON, planoId);

          return resultadoJSON;
        } else {
          // Tentar extrair múltiplos objetos JSON da resposta
          final RegExp multipleJsonRegex = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}');
          final matches = multipleJsonRegex.allMatches(resposta);

          if (matches.isNotEmpty) {
            // Pegar o maior objeto JSON encontrado (provavelmente o mais completo)
            String maiorJsonStr = '';
            for (var m in matches) {
              String jsonStr = m.group(0)!;
              if (jsonStr.length > maiorJsonStr.length) {
                maiorJsonStr = jsonStr;
              }
            }

            logger.logProcessamentoLLM(planoId, 'json_extraido_regex_multiplo', {
              'tamanho_json': maiorJsonStr.length,
              'inicio_json': maiorJsonStr.substring(0, maiorJsonStr.length > 100 ? 100 : maiorJsonStr.length),
            });

            Map<String, dynamic> resultadoJSON = json.decode(maiorJsonStr);

            // Verificar a estrutura do JSON
            _verificarEstruturaJSON(resultadoJSON, planoId);

            // Normalizar chaves similares
            resultadoJSON = _normalizarChavesSimilares(resultadoJSON, planoId);

            // Extrair dados do concurso e cargo se presentes
            resultadoJSON = _extrairDadosConcursoCargo(resultadoJSON, planoId);

            return resultadoJSON;
          } else {
            throw Exception('Não foi possível extrair JSON válido da resposta');
          }
        }
      } catch (regexError) {
        logger.logProcessamentoLLM(planoId, 'erro_corrigir_json', 'Erro: $regexError');

        // Retornar dados simulados em caso de erro
        logger.logProcessamentoLLM(planoId, 'usando_dados_simulados', 'Usando dados simulados devido a erro na resposta da LLM');
        return _gerarDadosSimulados();
      }
    }
  }

  /// Extrai dados do concurso e cargo se presentes no JSON
  Map<String, dynamic> _extrairDadosConcursoCargo(Map<String, dynamic> json, String planoId) {
    Map<String, dynamic> resultado = Map.from(json);

    // Log para depuração
    logger.logProcessamentoLLM(planoId, 'json_recebido_para_extracao', {
      'chaves_json': json.keys.toList(),
      'tamanho_json': json.toString().length,
    });

    // Verificar se há dados de concurso
    if (json.containsKey('concurso')) {
      logger.logProcessamentoLLM(planoId, 'dados_concurso_encontrados', 'Dados do concurso encontrados no JSON');

      // Adicionar dados do concurso ao resultado
      resultado['concurso'] = json['concurso'];

      // Extrair dados específicos do concurso para o nível superior
      Map<String, dynamic> concurso = json['concurso'];
      // Extrair dados básicos
      if (concurso.containsKey('titulo')) resultado['titulo'] = concurso['titulo'];
      if (concurso.containsKey('orgao')) resultado['orgao'] = concurso['orgao'];
      if (concurso.containsKey('banca')) resultado['banca'] = concurso['banca'];

      // Extrair dados de inscrição
      if (concurso.containsKey('inscricoes') && concurso['inscricoes'] is Map) {
        Map<String, dynamic> inscricoes = concurso['inscricoes'];
        if (inscricoes.containsKey('inicio')) resultado['inicioInscricao'] = inscricoes['inicio'];
        if (inscricoes.containsKey('fim')) resultado['fimInscricao'] = inscricoes['fim'];
        if (inscricoes.containsKey('taxa')) resultado['valorInscricao'] = inscricoes['taxa'];
      }

      // Extrair dados da prova
      if (concurso.containsKey('prova') && concurso['prova'] is Map) {
        Map<String, dynamic> prova = concurso['prova'];
        if (prova.containsKey('data')) resultado['dataProva'] = prova['data'];
        if (prova.containsKey('local')) resultado['localProva'] = prova['local'];
        if (prova.containsKey('total_questoes')) resultado['totalQuestoes'] = prova['total_questoes'];
        if (prova.containsKey('formato')) resultado['formatoProva'] = prova['formato'];
        if (prova.containsKey('duracao')) resultado['duracaoProva'] = prova['duracao'];
        if (prova.containsKey('tema_discursiva')) resultado['temaProvaSubjetiva'] = prova['tema_discursiva'];
        if (prova.containsKey('criterios_aprovacao')) resultado['criteriosAprovacao'] = prova['criterios_aprovacao'];
        if (prova.containsKey('criterios_reprovacao')) resultado['criteriosReprovacao'] = prova['criterios_reprovacao'];
        if (prova.containsKey('criterios_desempate')) resultado['criteriosDesempate'] = prova['criterios_desempate'];
      }

      // Extrair dados de cotas
      if (concurso.containsKey('cotas')) resultado['cotas'] = concurso['cotas'];
    }

    // Extrair dados básicos do nível superior (formato do prompt concurso_conteudo_prompt.txt)
    // Estes campos podem estar no nível superior do JSON, sem a chave 'concurso'
    if (json.containsKey('titulo')) resultado['titulo'] = json['titulo'];
    if (json.containsKey('orgao')) resultado['orgao'] = json['orgao'];
    if (json.containsKey('banca')) resultado['banca'] = json['banca'];

    // Extrair dados de inscrição do nível superior
    if (json.containsKey('inscricoes') && json['inscricoes'] is Map) {
      Map<String, dynamic> inscricoes = json['inscricoes'];
      if (inscricoes.containsKey('inicio')) resultado['inicioInscricao'] = inscricoes['inicio'];
      if (inscricoes.containsKey('fim')) resultado['fimInscricao'] = inscricoes['fim'];
      if (inscricoes.containsKey('taxa')) resultado['valorInscricao'] = inscricoes['taxa'];
    }

    // Extrair informações de período de inscrição
    if (json.containsKey('periodo_inscricao')) {
      if (json['periodo_inscricao'] is Map) {
        Map<String, dynamic> periodoInscricao = json['periodo_inscricao'];
        if (periodoInscricao.containsKey('inicio')) resultado['inicioInscricao'] = periodoInscricao['inicio'];
        if (periodoInscricao.containsKey('fim')) resultado['fimInscricao'] = periodoInscricao['fim'];
      } else if (json['periodo_inscricao'] is String) {
        // Se for uma string, assumir que é o período completo
        resultado['periodoInscricao'] = json['periodo_inscricao'];
      }
    }

    // Extrair taxa de inscrição
    if (json.containsKey('taxa_inscricao')) {
      resultado['valorInscricao'] = json['taxa_inscricao'];
    }

    // Extrair data da prova
    if (json.containsKey('data_prova')) {
      resultado['dataProva'] = json['data_prova'];
    }

    // Extrair local da prova
    if (json.containsKey('local_prova')) {
      resultado['localProva'] = json['local_prova'];
    }

    // Extrair duração da prova
    if (json.containsKey('duracao_prova')) {
      resultado['duracaoProva'] = json['duracao_prova'];
    }

    // Extrair total de questões
    if (json.containsKey('total_questoes')) {
      resultado['totalQuestoes'] = json['total_questoes'];
    }

    // Extrair formato da prova
    if (json.containsKey('formato_prova')) {
      if (json['formato_prova'] is List) {
        resultado['formatoProva'] = (json['formato_prova'] as List).join(', ');
      } else {
        resultado['formatoProva'] = json['formato_prova'].toString();
      }
    }

    // Extrair tema da prova subjetiva
    if (json.containsKey('tema_prova_subjetiva')) {
      resultado['temaProvaSubjetiva'] = json['tema_prova_subjetiva'];
    }

    // Extrair critérios de aprovação
    if (json.containsKey('criterios_aprovacao')) {
      resultado['criteriosAprovacao'] = json['criterios_aprovacao'];
    }

    // Extrair critérios de reprovação
    if (json.containsKey('criterios_reprovacao')) {
      resultado['criteriosReprovacao'] = json['criterios_reprovacao'];
    }

    // Extrair critérios de desempate
    if (json.containsKey('criterios_desempate')) {
      if (json['criterios_desempate'] is List) {
        resultado['criteriosDesempate'] = json['criterios_desempate'];
      } else {
        resultado['criteriosDesempate'] = json['criterios_desempate'].toString();
      }
    }

    // Verificar se há dados de cargo
    if (json.containsKey('cargo')) {
      logger.logProcessamentoLLM(planoId, 'dados_cargo_encontrados', 'Dados do cargo encontrados no JSON');

      // Adicionar dados do cargo ao resultado
      resultado['cargo'] = json['cargo'];

      // Extrair dados específicos do cargo para o nível superior
      Map<String, dynamic> cargo = json['cargo'];
      if (cargo.containsKey('nome')) resultado['nomeCargo'] = cargo['nome'];
      if (cargo.containsKey('vagas')) resultado['vagas'] = cargo['vagas'];
      if (cargo.containsKey('escolaridade')) resultado['escolaridade'] = cargo['escolaridade'];
      if (cargo.containsKey('salario')) resultado['salario'] = cargo['salario'];
      if (cargo.containsKey('nivel')) resultado['nivel'] = cargo['nivel'];

      // Extrair conteúdo programático
      if (cargo.containsKey('conteudo_programatico') && cargo['conteudo_programatico'] is Map) {
        Map<String, dynamic> conteudo = cargo['conteudo_programatico'];
        if (conteudo.containsKey('materias')) {
          resultado['grupos'] = [
            {
              'nome': 'Conteúdo Programático',
              'materias': conteudo['materias']
            }
          ];
        }
      }
        }

    // Verificar se há dados de prova diretamente no JSON
    if (json.containsKey('prova') && json['prova'] is Map) {
      logger.logProcessamentoLLM(planoId, 'dados_prova_encontrados', 'Dados da prova encontrados diretamente no JSON');

      Map<String, dynamic> prova = json['prova'];
      resultado['prova'] = prova; // Armazenar o objeto prova completo

      // Extrair dados da prova para o nível superior
      if (prova.containsKey('data')) resultado['dataProva'] = prova['data'];
      if (prova.containsKey('local')) resultado['localProva'] = prova['local'];
      if (prova.containsKey('total_questoes')) resultado['totalQuestoes'] = prova['total_questoes'];
      if (prova.containsKey('formato')) {
        if (prova['formato'] is List) {
          resultado['formatoProva'] = (prova['formato'] as List).join(', ');
        } else {
          resultado['formatoProva'] = prova['formato'].toString();
        }
      }
      if (prova.containsKey('duracao')) resultado['duracaoProva'] = prova['duracao'];
      if (prova.containsKey('tema_discursiva')) resultado['temaProvaSubjetiva'] = prova['tema_discursiva'];
      if (prova.containsKey('criterios_aprovacao')) resultado['criteriosAprovacao'] = prova['criterios_aprovacao'];
      if (prova.containsKey('criterios_reprovacao')) resultado['criteriosReprovacao'] = prova['criterios_reprovacao'];
      if (prova.containsKey('criterios_desempate')) {
        if (prova['criterios_desempate'] is List) {
          resultado['criteriosDesempate'] = prova['criterios_desempate'];
        } else {
          resultado['criteriosDesempate'] = prova['criterios_desempate'].toString();
        }
      }
    }

    // Verificar se há dados de cotas diretamente no JSON
    if (json.containsKey('cotas')) {
      logger.logProcessamentoLLM(planoId, 'dados_cotas_encontrados', 'Dados de cotas encontrados diretamente no JSON');
      resultado['cotas'] = json['cotas'];
    }

    // Verificar se há dados de vagas diretamente no JSON
    if (json.containsKey('vagas') && json['vagas'] is Map) {
      logger.logProcessamentoLLM(planoId, 'dados_vagas_encontrados', 'Dados de vagas encontrados diretamente no JSON');
      resultado['vagas'] = json['vagas'];
    }

    // Verificar se há conteúdo programático diretamente no JSON
    if (json.containsKey('conteudo_programatico') && json['conteudo_programatico'] is List) {
      logger.logProcessamentoLLM(planoId, 'conteudo_programatico_encontrado', 'Conteúdo programático encontrado diretamente no JSON');

      // Armazenar o conteúdo programático completo
      resultado['conteudo_programatico_completo'] = json['conteudo_programatico'];

      // Agrupar o conteúdo programático por grupo
      Map<String, List<dynamic>> gruposMaterias = {};

      for (var materia in json['conteudo_programatico']) {
        if (materia is Map) {
          String grupo = 'Sem Grupo';

          // Verificar se há grupo_materia definido
          if (materia.containsKey('grupo_materia') && materia['grupo_materia'] != null && materia['grupo_materia'].toString().isNotEmpty) {
            grupo = materia['grupo_materia'].toString();
          }

          if (!gruposMaterias.containsKey(grupo)) {
            gruposMaterias[grupo] = [];
          }

          gruposMaterias[grupo]!.add(materia);
        }
      }

      // Criar a estrutura de grupos
      List<Map<String, dynamic>> grupos = [];

      gruposMaterias.forEach((nomeGrupo, materias) {
        grupos.add({
          'nome': nomeGrupo,
          'materias': materias,
        });
      });

      resultado['grupos'] = grupos;

      // Extrair lista de matérias para uso no plano
      List<String> materias = [];
      for (var materia in json['conteudo_programatico']) {
        if (materia is Map && materia.containsKey('nome')) {
          materias.add(materia['nome'].toString());
        }
      }

      if (materias.isNotEmpty) {
        resultado['materias'] = materias;
        logger.logProcessamentoLLM(planoId, 'materias_extraidas', {
          'total_materias': materias.length,
          'materias': materias,
        });
      }
    }

    // Registrar os dados extraídos
    logger.logProcessamentoLLM(planoId, 'dados_extraidos', {
      'chaves_extraidas': resultado.keys.toList(),
      'total_chaves': resultado.keys.length,
    });

    return resultado;
  }

  /// Verifica a estrutura do JSON recebido
  void _verificarEstruturaJSON(Map<String, dynamic> json, String planoId) {
    final estruturaJSON = {
      'ciclo_estudos_presente': json.containsKey('ciclo_estudos'),
      'materias_prioritarias_presente': json.containsKey('materias_prioritarias'),
      'recomendacoes_gerais_presente': json.containsKey('recomendacoes_gerais'),
      'metadados_presente': json.containsKey('metadados'),
      'grupos_presente': json.containsKey('grupos'),
      'calendario_presente': json.containsKey('calendario'),
      'duracao_total_ciclo_presente': json.containsKey('duracao_total_ciclo'),
      'total_blocos_ciclo_presente': json.containsKey('total_blocos_ciclo'),
      'chaves_presentes': json.keys.toList(),
    };

    logger.logProcessamentoLLM(planoId, 'json_decodificado', estruturaJSON);
  }

  /// Normaliza chaves similares no JSON
  Map<String, dynamic> _normalizarChavesSimilares(Map<String, dynamic> json, String planoId) {
    // Identificar chaves similares
    final Map<String, String> chavesSimilares = {};
    for (final chave in json.keys) {
      if (chave.contains('ciclo') || chave.contains('estudo')) {
        chavesSimilares['ciclo_estudos_similar'] = chave;
      }
      if (chave.contains('materia') || chave.contains('prioridade')) {
        chavesSimilares['materias_prioritarias_similar'] = chave;
      }
      if (chave.contains('meta') || chave.contains('dados')) {
        chavesSimilares['metadados_similar'] = chave;
      }
      if (chave.contains('recomend') || chave.contains('dica')) {
        chavesSimilares['recomendacoes_similar'] = chave;
      }
    }

    // Criar uma cópia do JSON para modificar
    Map<String, dynamic> jsonNormalizado = Map.from(json);

    // Identificar chaves similares para duração total do ciclo
    for (final chave in json.keys) {
      if (chave.contains('duracao') && (chave.contains('total') || chave.contains('ciclo'))) {
        chavesSimilares['duracao_total_ciclo_similar'] = chave;
      }
      if ((chave.contains('total') || chave.contains('quantidade')) && chave.contains('blocos')) {
        chavesSimilares['total_blocos_ciclo_similar'] = chave;
      }
    }

    // Substituir chaves similares pelas chaves padrão
    if (!jsonNormalizado.containsKey('ciclo_estudos') && chavesSimilares.containsKey('ciclo_estudos_similar')) {
      final chaveSimilar = chavesSimilares['ciclo_estudos_similar']!;
      logger.logProcessamentoLLM(planoId, 'usando_chave_similar', {'original': 'ciclo_estudos', 'similar': chaveSimilar});
      jsonNormalizado['ciclo_estudos'] = jsonNormalizado[chaveSimilar];
    }

    if (!jsonNormalizado.containsKey('materias_prioritarias') && chavesSimilares.containsKey('materias_prioritarias_similar')) {
      final chaveSimilar = chavesSimilares['materias_prioritarias_similar']!;
      logger.logProcessamentoLLM(planoId, 'usando_chave_similar', {'original': 'materias_prioritarias', 'similar': chaveSimilar});
      jsonNormalizado['materias_prioritarias'] = jsonNormalizado[chaveSimilar];
    }

    if (!jsonNormalizado.containsKey('metadados') && chavesSimilares.containsKey('metadados_similar')) {
      final chaveSimilar = chavesSimilares['metadados_similar']!;
      logger.logProcessamentoLLM(planoId, 'usando_chave_similar', {'original': 'metadados', 'similar': chaveSimilar});
      jsonNormalizado['metadados'] = jsonNormalizado[chaveSimilar];
    }

    // Verificar e corrigir o formato do ciclo de estudos
    if (jsonNormalizado.containsKey('ciclo_estudos')) {
      jsonNormalizado['ciclo_estudos'] = _validarCicloEstudos(jsonNormalizado['ciclo_estudos'], planoId);
    } else {
      logger.logProcessamentoLLM(planoId, 'ciclo_estudos_ausente', 'Ciclo de estudos não encontrado na resposta da LLM');
      jsonNormalizado['ciclo_estudos'] = _gerarCicloEstudosPadrao();
    }

    // Verificar e corrigir o formato das matérias prioritárias
    if (jsonNormalizado.containsKey('materias_prioritarias')) {
      jsonNormalizado['materias_prioritarias'] = _validarMateriasPrioritarias(jsonNormalizado['materias_prioritarias'], planoId);
    } else {
      logger.logProcessamentoLLM(planoId, 'materias_prioritarias_ausentes', 'Matérias prioritárias não encontradas na resposta da LLM');
      jsonNormalizado['materias_prioritarias'] = _gerarMateriasPrioritariasPadrao();
    }

    // Processar duração total do ciclo
    if (!jsonNormalizado.containsKey('duracao_total_ciclo') && chavesSimilares.containsKey('duracao_total_ciclo_similar')) {
      final chaveSimilar = chavesSimilares['duracao_total_ciclo_similar']!;
      logger.logProcessamentoLLM(planoId, 'usando_chave_similar', {'original': 'duracao_total_ciclo', 'similar': chaveSimilar});
      jsonNormalizado['duracao_total_ciclo'] = jsonNormalizado[chaveSimilar];
    }

    // Garantir que a duração total do ciclo seja um número inteiro
    if (jsonNormalizado.containsKey('duracao_total_ciclo')) {
      final duracaoTotalCiclo = jsonNormalizado['duracao_total_ciclo'];
      if (duracaoTotalCiclo is int) {
        // Já está no formato correto
      } else if (duracaoTotalCiclo is double) {
        jsonNormalizado['duracao_total_ciclo'] = duracaoTotalCiclo.round();
      } else if (duracaoTotalCiclo is String) {
        try {
          jsonNormalizado['duracao_total_ciclo'] = int.parse(duracaoTotalCiclo);
        } catch (e) {
          logger.logProcessamentoLLM(planoId, 'erro_converter_duracao_total_ciclo', {'erro': e.toString()});
          jsonNormalizado['duracao_total_ciclo'] = _calcularDuracaoTotalCiclo(jsonNormalizado['ciclo_estudos']);
        }
      } else {
        logger.logProcessamentoLLM(planoId, 'duracao_total_ciclo_formato_incorreto', {'tipo': duracaoTotalCiclo.runtimeType.toString()});
        jsonNormalizado['duracao_total_ciclo'] = _calcularDuracaoTotalCiclo(jsonNormalizado['ciclo_estudos']);
      }
    } else {
      // Se não houver duração total do ciclo, calcular com base no ciclo de estudos
      jsonNormalizado['duracao_total_ciclo'] = _calcularDuracaoTotalCiclo(jsonNormalizado['ciclo_estudos']);
    }

    // Processar total de blocos do ciclo
    if (!jsonNormalizado.containsKey('total_blocos_ciclo') && chavesSimilares.containsKey('total_blocos_ciclo_similar')) {
      final chaveSimilar = chavesSimilares['total_blocos_ciclo_similar']!;
      logger.logProcessamentoLLM(planoId, 'usando_chave_similar', {'original': 'total_blocos_ciclo', 'similar': chaveSimilar});
      jsonNormalizado['total_blocos_ciclo'] = jsonNormalizado[chaveSimilar];
    }

    // Garantir que o total de blocos do ciclo seja um número inteiro
    if (jsonNormalizado.containsKey('total_blocos_ciclo')) {
      final totalBlocosCiclo = jsonNormalizado['total_blocos_ciclo'];
      if (totalBlocosCiclo is int) {
        // Já está no formato correto
      } else if (totalBlocosCiclo is double) {
        jsonNormalizado['total_blocos_ciclo'] = totalBlocosCiclo.round();
      } else if (totalBlocosCiclo is String) {
        try {
          jsonNormalizado['total_blocos_ciclo'] = int.parse(totalBlocosCiclo);
        } catch (e) {
          logger.logProcessamentoLLM(planoId, 'erro_converter_total_blocos_ciclo', {'erro': e.toString()});
          jsonNormalizado['total_blocos_ciclo'] = _calcularTotalBlocosCiclo(jsonNormalizado['ciclo_estudos']);
        }
      } else {
        logger.logProcessamentoLLM(planoId, 'total_blocos_ciclo_formato_incorreto', {'tipo': totalBlocosCiclo.runtimeType.toString()});
        jsonNormalizado['total_blocos_ciclo'] = _calcularTotalBlocosCiclo(jsonNormalizado['ciclo_estudos']);
      }
    } else {
      // Se não houver total de blocos do ciclo, calcular com base no ciclo de estudos
      jsonNormalizado['total_blocos_ciclo'] = _calcularTotalBlocosCiclo(jsonNormalizado['ciclo_estudos']);
    }

    return jsonNormalizado;
  }

  /// Valida e corrige o formato do ciclo de estudos
  List<dynamic> _validarCicloEstudos(dynamic cicloEstudos, String planoId) {
    if (cicloEstudos is! List) {
      logger.logProcessamentoLLM(planoId, 'ciclo_estudos_nao_e_lista', 'O ciclo de estudos não é uma lista');
      return _gerarCicloEstudosPadrao();
    }

    if (cicloEstudos.isEmpty) {
      logger.logProcessamentoLLM(planoId, 'ciclo_estudos_vazio', 'O ciclo de estudos está vazio');
      return _gerarCicloEstudosPadrao();
    }

    // Verificar o formato do ciclo de estudos
    bool formatoCorreto = true;

    // Verificar o primeiro dia do ciclo
    dynamic primeiroDia = cicloEstudos[0];
    if (primeiroDia is Map) {
      // Verificar se tem a chave 'dia' ou 'dia_ciclo'
      if (!primeiroDia.containsKey('dia') && !primeiroDia.containsKey('dia_ciclo')) {
        formatoCorreto = false;
        logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'Falta a chave "dia" ou "dia_ciclo"');
      }

      // Verificar se tem a chave 'blocos'
      if (!primeiroDia.containsKey('blocos')) {
        formatoCorreto = false;
        logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'Falta a chave "blocos"');
      } else if (primeiroDia['blocos'] is! List) {
        formatoCorreto = false;
        logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'A chave "blocos" não é uma lista');
      } else {
        // Verificar o formato dos blocos
        List<dynamic> blocos = primeiroDia['blocos'];
        if (blocos.isNotEmpty) {
          dynamic primeiroBloco = blocos[0];
          if (primeiroBloco is Map) {
            // Verificar se tem as chaves necessárias
            if (!primeiroBloco.containsKey('materia')) {
              formatoCorreto = false;
              logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'Falta a chave "materia" no bloco');
            }
            if (!primeiroBloco.containsKey('duracao_minutos') && !primeiroBloco.containsKey('duracao')) {
              formatoCorreto = false;
              logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'Falta a chave "duracao_minutos" ou "duracao" no bloco');
            }
            if (!primeiroBloco.containsKey('ferramenta')) {
              formatoCorreto = false;
              logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'Falta a chave "ferramenta" no bloco');
            }
          } else {
            formatoCorreto = false;
            logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'O bloco não é um objeto');
          }
        }
      }
    } else {
      formatoCorreto = false;
      logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto', 'O dia do ciclo não é um objeto');
    }

    // Se o formato estiver incorreto, retornar um ciclo de estudos padrão
    if (!formatoCorreto) {
      logger.logProcessamentoLLM(planoId, 'ciclo_estudos_formato_incorreto_substituindo', 'Substituindo ciclo de estudos com formato incorreto');
      return _gerarCicloEstudosPadrao();
    }

    return cicloEstudos;
  }

  /// Valida e corrige o formato das matérias prioritárias
  List<dynamic> _validarMateriasPrioritarias(dynamic materiasPrioritarias, String planoId) {
    if (materiasPrioritarias is! List) {
      logger.logProcessamentoLLM(planoId, 'materias_prioritarias_nao_e_lista', 'As matérias prioritárias não são uma lista');
      return _gerarMateriasPrioritariasPadrao();
    }

    if (materiasPrioritarias.isEmpty) {
      logger.logProcessamentoLLM(planoId, 'materias_prioritarias_vazia', 'A lista de matérias prioritárias está vazia');
      return _gerarMateriasPrioritariasPadrao();
    }

    // Verificar o formato das matérias prioritárias
    bool formatoCorreto = true;

    // Verificar a primeira matéria prioritária
    dynamic primeiraMateria = materiasPrioritarias[0];
    if (primeiraMateria is Map) {
      // Verificar se tem a chave 'nome' ou 'materia'
      if (!primeiraMateria.containsKey('nome') && !primeiraMateria.containsKey('materia')) {
        formatoCorreto = false;
        logger.logProcessamentoLLM(planoId, 'materias_prioritarias_formato_incorreto', 'Falta a chave "nome" ou "materia"');
      }

      // Verificar se tem a chave 'pontuacao_prioridade' ou 'pontuacao' ou 'prioridade'
      if (!primeiraMateria.containsKey('pontuacao_prioridade') &&
          !primeiraMateria.containsKey('pontuacao') &&
          !primeiraMateria.containsKey('prioridade')) {
        formatoCorreto = false;
        logger.logProcessamentoLLM(planoId, 'materias_prioritarias_formato_incorreto', 'Falta a chave "pontuacao_prioridade" ou "pontuacao" ou "prioridade"');
      }
    } else {
      formatoCorreto = false;
      logger.logProcessamentoLLM(planoId, 'materias_prioritarias_formato_incorreto', 'A matéria prioritária não é um objeto');
    }

    // Se o formato estiver incorreto, retornar matérias prioritárias padrão
    if (!formatoCorreto) {
      logger.logProcessamentoLLM(planoId, 'materias_prioritarias_formato_incorreto_substituindo', 'Substituindo matérias prioritárias com formato incorreto');
      return _gerarMateriasPrioritariasPadrao();
    }

    // Normalizar o formato das matérias prioritárias
    List<Map<String, dynamic>> materiasPrioritariasNormalizadas = [];
    for (var materia in materiasPrioritarias) {
      if (materia is Map) {
        String nome = materia['nome'] ?? materia['materia'] ?? 'Desconhecida';
        int pontuacao = materia['pontuacao_prioridade'] ?? materia['pontuacao'] ?? materia['prioridade'] ?? 0;
        materiasPrioritariasNormalizadas.add({
          'nome': nome,
          'pontuacao_prioridade': pontuacao,
        });
      }
    }

    return materiasPrioritariasNormalizadas;
  }

  /// Gera dados simulados para uso em caso de erro
  Map<String, dynamic> _gerarDadosSimulados() {
    return {
      'ciclo_estudos': _gerarCicloEstudosPadrao(),
      'materias_prioritarias': _gerarMateriasPrioritariasPadrao(),
    };
  }

  /// Gera um ciclo de estudos padrão
  List<Map<String, dynamic>> _gerarCicloEstudosPadrao() {
    return [
      {
        'dia': 1,
        'blocos': [
          {'ordem': 1, 'materia': 'Português', 'duracao_minutos': 90, 'ferramenta': 'Videoaulas'},
          {'ordem': 2, 'materia': 'Matemática', 'duracao_minutos': 60, 'ferramenta': 'Questões'},
        ]
      },
      {
        'dia': 2,
        'blocos': [
          {'ordem': 1, 'materia': 'Direito Constitucional', 'duracao_minutos': 90, 'ferramenta': 'Resumos'},
          {'ordem': 2, 'materia': 'Português', 'duracao_minutos': 60, 'ferramenta': 'Questões'},
        ]
      },
    ];
  }

  /// Gera matérias prioritárias padrão
  List<Map<String, dynamic>> _gerarMateriasPrioritariasPadrao() {
    return [
      {'nome': 'Português', 'pontuacao_prioridade': 31},
      {'nome': 'Matemática', 'pontuacao_prioridade': 25},
      {'nome': 'Direito Constitucional', 'pontuacao_prioridade': 20},
    ];
  }

  /// Calcula a duração total do ciclo com base no ciclo de estudos
  int _calcularDuracaoTotalCiclo(List<dynamic> cicloEstudos) {
    if (cicloEstudos.isEmpty) {
      return 7; // Valor padrão de uma semana
    }

    try {
      // Encontrar o maior valor de 'dia' no ciclo
      int maiorDia = 0;
      for (final dia in cicloEstudos) {
        if (dia is Map && dia.containsKey('dia')) {
          final valorDia = dia['dia'];
          if (valorDia is int && valorDia > maiorDia) {
            maiorDia = valorDia;
          }
        }
      }

      return maiorDia > 0 ? maiorDia : 7; // Retornar o maior dia ou 7 como padrão
    } catch (e) {
      return 7; // Em caso de erro, retornar 7 como padrão
    }
  }

  /// Calcula o total de blocos do ciclo com base no ciclo de estudos
  int _calcularTotalBlocosCiclo(List<dynamic> cicloEstudos) {
    if (cicloEstudos.isEmpty) {
      return 14; // Valor padrão de 2 blocos por dia durante uma semana
    }

    try {
      // Contar o total de blocos em todos os dias do ciclo
      int totalBlocos = 0;
      for (final dia in cicloEstudos) {
        if (dia is Map && dia.containsKey('blocos')) {
          final blocos = dia['blocos'];
          if (blocos is List) {
            totalBlocos += blocos.length;
          }
        }
      }

      return totalBlocos > 0 ? totalBlocos : 14; // Retornar o total de blocos ou 14 como padrão
    } catch (e) {
      return 14; // Em caso de erro, retornar 14 como padrão
    }
  }
}
