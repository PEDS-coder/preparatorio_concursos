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
          
          return resultadoJSON;
        } else {
          throw Exception('Não foi possível extrair JSON válido da resposta');
        }
      } catch (regexError) {
        logger.logProcessamentoLLM(planoId, 'erro_corrigir_json', 'Erro: $regexError');
        
        // Retornar dados simulados em caso de erro
        logger.logProcessamentoLLM(planoId, 'usando_dados_simulados', 'Usando dados simulados devido a erro na resposta da LLM');
        return _gerarDadosSimulados();
      }
    }
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
}
