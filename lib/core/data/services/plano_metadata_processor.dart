import '../../utils/plano_data_logger.dart';
import '../../utils/dynamic_map_converter.dart';
import '../models/edital.dart';
import 'edital_service.dart';

/// Classe responsável por processar metadados para planos de estudo
class PlanoMetadataProcessor {
  final PlanoDataLogger _logger;
  final EditalService _editalService;

  /// Construtor
  PlanoMetadataProcessor({
    required PlanoDataLogger logger,
    required EditalService editalService,
  }) : _logger = logger, _editalService = editalService;

  /// Processa metadados para um plano de estudo
  Map<String, dynamic> processarMetadados({
    required String planoId,
    required String? editalId,
    required Map<String, dynamic> dadosAdicionaisConvertidos,
  }) {
    final Map<String, dynamic> metadados = {};

    // 1. Processar dados do Edital (se editalId fornecido)
    _processarDadosEdital(planoId, editalId, metadados);

    // 2. Processar dadosAdicionaisConvertidos (resposta LLM, etc.)
    _processarDadosLLM(planoId, dadosAdicionaisConvertidos, metadados);

    // 3. Adicionar o restante dos dadosAdicionaisConvertidos
    _adicionarDadosRestantes(dadosAdicionaisConvertidos, metadados);

    // Remover chaves com valores nulos ou vazios para limpeza
    metadados.removeWhere((key, value) =>
      value == null ||
      (value is String && value.isEmpty) ||
      (value is List && value.isEmpty)
    );

    _logger.logArmazenamento(planoId, 'metadados_finais', metadados);
    return metadados;
  }

  // Processa dados do edital
  void _processarDadosEdital(String planoId, String? editalId, Map<String, dynamic> metadados) {
    if (editalId == null || editalId.isEmpty) return;

    final edital = _editalService.getEditalById(editalId);
    if (edital == null) {
      _logger.logArmazenamento(planoId, 'warn_edital_nao_encontrado', {'editalId': editalId});
      return;
    }

    // Prioridade: Dados Extraídos
    final de = edital.dadosExtraidos;
    metadados['titulo'] = de.titulo ?? metadados['titulo'];
    metadados['orgao'] = de.orgao ?? metadados['orgao'];
    metadados['banca'] = de.banca ?? metadados['banca'];

    // Dados de inscrição
    metadados['inicioInscricao'] = de.inicioInscricao?.toIso8601String() ?? metadados['inicioInscricao'];
    metadados['fimInscricao'] = de.fimInscricao?.toIso8601String() ?? metadados['fimInscricao'];
    metadados['valorInscricao'] = de.valorTaxa ?? de.taxaInscricao ?? metadados['valorInscricao'];

    // Dados da prova
    metadados['dataProva'] = de.dataProva ?? metadados['dataProva'];
    metadados['localProva'] = de.localProva ?? metadados['localProva'];
    metadados['totalQuestoes'] = de.totalQuestoes ?? metadados['totalQuestoes'];
    metadados['formatoProva'] = de.formatoProva ?? metadados['formatoProva'];
    metadados['duracaoProva'] = de.duracaoProva ?? metadados['duracaoProva'];
    metadados['temaProvaSubjetiva'] = de.temaDiscursiva ?? metadados['temaProvaSubjetiva'];
    metadados['criteriosAprovacao'] = de.criteriosAprovacao ?? metadados['criteriosAprovacao'];
    metadados['criteriosReprovacao'] = de.criteriosReprovacao ?? metadados['criteriosReprovacao'];
    metadados['criteriosDesempate'] = de.criteriosDesempate ?? metadados['criteriosDesempate'];

    _processarDadosProva(planoId, de, metadados);
    _processarCotas(de, metadados);
    _processarDadosOriginais(planoId, edital, metadados);

    _logger.logArmazenamento(planoId, 'dados_edital_transferidos', metadados);
  }

  // Processa dados da prova
  void _processarDadosProva(String planoId, DadosExtraidos de, Map<String, dynamic> metadados) {
    if (de.dadosProva == null) return;

    final dp = de.dadosProva!;
    metadados['totalQuestoes'] = dp.totalQuestoes ?? metadados['totalQuestoes'];
    if (dp.formato != null && dp.formato!.isNotEmpty) {
      metadados['formatoProva'] = dp.formato!.join(', ');
    }
    metadados['temaProvaSubjetiva'] = dp.temaDiscursiva ?? metadados['temaProvaSubjetiva'];
    metadados['criteriosAprovacao'] = dp.criteriosAprovacao ?? metadados['criteriosAprovacao'];
    metadados['criteriosReprovacao'] = dp.criteriosReprovacao ?? metadados['criteriosReprovacao'];
    metadados['duracaoProva'] = dp.duracao ?? metadados['duracaoProva'];
    metadados['criteriosDesempate'] = dp.criteriosDesempate ?? metadados['criteriosDesempate'];
  }

  // Processa dados de cotas
  void _processarCotas(DadosExtraidos de, Map<String, dynamic> metadados) {
    if (de.cotas == null || de.cotas!.isEmpty) return;

    metadados['cotas'] = de.cotas!.map((cota) => {
      'nome': cota.nome,
      'percentual': cota.percentual,
      'numero_vagas': cota.numeroVagas,
      'criterios': cota.criterios
    }).toList();
  }

  // Processa dados originais do edital
  void _processarDadosOriginais(String planoId, Edital edital, Map<String, dynamic> metadados) {
    if (edital.dadosOriginais == null) return;

    _logger.logArmazenamento(planoId, 'processando_dados_originais', {'chaves': edital.dadosOriginais!.keys.toList()});
    try {
      final orig = DynamicMapConverter.toStringDynamicMap(edital.dadosOriginais!);

      // Extrair dados básicos
      if (!metadados.containsKey('titulo') || metadados['titulo'] == null) {
        metadados['titulo'] = orig['titulo'] ?? orig['titulo_concurso'];
      }

      if (!metadados.containsKey('orgao') || metadados['orgao'] == null) {
        metadados['orgao'] = orig['orgao'] ?? orig['orgao_responsavel'];
      }

      if (!metadados.containsKey('banca') || metadados['banca'] == null) {
        metadados['banca'] = orig['banca'] ?? orig['banca_organizadora'];
      }

      // Extrair dados de inscrição
      if (orig.containsKey('inscricoes') && orig['inscricoes'] is Map) {
        final inscricoesOriginal = orig['inscricoes'] as Map;

        if (inscricoesOriginal.containsKey('inicio') && (!metadados.containsKey('inicioInscricao') || metadados['inicioInscricao'] == null)) {
          metadados['inicioInscricao'] = inscricoesOriginal['inicio'];
        }

        if (inscricoesOriginal.containsKey('fim') && (!metadados.containsKey('fimInscricao') || metadados['fimInscricao'] == null)) {
          metadados['fimInscricao'] = inscricoesOriginal['fim'];
        }

        if (inscricoesOriginal.containsKey('taxa') && (!metadados.containsKey('valorInscricao') || metadados['valorInscricao'] == null)) {
          metadados['valorInscricao'] = inscricoesOriginal['taxa'];
        }
      }

      // Extrair dados da prova
      if (orig.containsKey('prova') && orig['prova'] is Map) {
        final provaOriginal = orig['prova'] as Map;

        if (provaOriginal.containsKey('data') && (!metadados.containsKey('dataProva') || metadados['dataProva'] == null)) {
          metadados['dataProva'] = provaOriginal['data'];
        }

        if (provaOriginal.containsKey('local') && (!metadados.containsKey('localProva') || metadados['localProva'] == null)) {
          metadados['localProva'] = provaOriginal['local'];
        }

        if (provaOriginal.containsKey('total_questoes') && (!metadados.containsKey('totalQuestoes') || metadados['totalQuestoes'] == null)) {
          metadados['totalQuestoes'] = provaOriginal['total_questoes'];
        }

        if (provaOriginal.containsKey('formato') && (!metadados.containsKey('formatoProva') || metadados['formatoProva'] == null)) {
          if (provaOriginal['formato'] is List) {
            metadados['formatoProva'] = (provaOriginal['formato'] as List).join(', ');
          } else {
            metadados['formatoProva'] = provaOriginal['formato'].toString();
          }
        }

        if (provaOriginal.containsKey('duracao') && (!metadados.containsKey('duracaoProva') || metadados['duracaoProva'] == null)) {
          metadados['duracaoProva'] = provaOriginal['duracao'];
        }

        if (provaOriginal.containsKey('tema_discursiva') && (!metadados.containsKey('temaProvaSubjetiva') || metadados['temaProvaSubjetiva'] == null)) {
          metadados['temaProvaSubjetiva'] = provaOriginal['tema_discursiva'];
        }

        if (provaOriginal.containsKey('criterios_aprovacao') && (!metadados.containsKey('criteriosAprovacao') || metadados['criteriosAprovacao'] == null)) {
          metadados['criteriosAprovacao'] = provaOriginal['criterios_aprovacao'];
        }

        if (provaOriginal.containsKey('criterios_reprovacao') && (!metadados.containsKey('criteriosReprovacao') || metadados['criteriosReprovacao'] == null)) {
          metadados['criteriosReprovacao'] = provaOriginal['criterios_reprovacao'];
        }

        if (provaOriginal.containsKey('criterios_desempate') && (!metadados.containsKey('criteriosDesempate') || metadados['criteriosDesempate'] == null)) {
          if (provaOriginal['criterios_desempate'] is List) {
            metadados['criteriosDesempate'] = provaOriginal['criterios_desempate'];
          } else {
            metadados['criteriosDesempate'] = provaOriginal['criterios_desempate'].toString();
          }
        }
      }

      _processarDadosOriginaisProva(planoId, orig, metadados);
      _processarDadosOriginaisConcurso(planoId, orig, metadados);
      _processarDadosOriginaisCotas(planoId, orig, metadados);

      _logger.logArmazenamento(planoId, 'dados_originais_transferidos', {
        'chaves_transferidas': metadados.keys.toList(),
      });
    } catch (e, s) {
      _logger.logArmazenamento(planoId, 'erro_converter_dados_originais', {'erro': e.toString(), 'stack': s.toString()});
    }
  }

  // Processa dados originais da prova
  void _processarDadosOriginaisProva(String planoId, Map<String, dynamic> orig, Map<String, dynamic> metadados) {
    final provaData = orig['prova'];
    if (provaData is! Map) {
      if (provaData != null) {
        _logger.logArmazenamento(planoId, 'warn_dados_originais_prova_nao_mapa', {'tipo': provaData.runtimeType});
      }
      return;
    }

    try {
      final provaOrig = DynamicMapConverter.toStringDynamicMap(provaData);
      metadados['totalQuestoes'] ??= provaOrig['total_questoes'];
      metadados['formatoProva'] ??= (provaOrig['formato'] is List
        ? (provaOrig['formato'] as List).join(', ')
        : provaOrig['formato']?.toString());
      metadados['temaProvaSubjetiva'] ??= provaOrig['tema_discursiva'];
      metadados['criteriosAprovacao'] ??= provaOrig['criterios_aprovacao'];
      metadados['criteriosReprovacao'] ??= provaOrig['criterios_reprovacao'];
      metadados['duracaoProva'] ??= provaOrig['duracao'];
      metadados['criteriosDesempate'] ??= provaOrig['criterios_desempate'];
    } catch (e) {
      _logger.logArmazenamento(planoId, 'erro_processar_dados_originais_prova', {'erro': e.toString()});
    }
  }

  // Processa dados originais do concurso
  void _processarDadosOriginaisConcurso(String planoId, Map<String, dynamic> orig, Map<String, dynamic> metadados) {
    final concursoData = orig['concurso'];
    if (concursoData is! Map) {
      if (concursoData != null) {
        _logger.logArmazenamento(planoId, 'warn_dados_originais_concurso_nao_mapa', {'tipo': concursoData.runtimeType});
      }
      return;
    }

    try {
      final concOrig = DynamicMapConverter.toStringDynamicMap(concursoData);
      _processarDadosOriginaisInscricoes(planoId, concOrig, metadados);
      metadados['dataProva'] ??= concOrig['data_prova'];
      metadados['localProva'] ??= concOrig['local_prova'];
      metadados['valorInscricao'] ??= concOrig['taxa_inscricao'];
    } catch (e) {
      _logger.logArmazenamento(planoId, 'erro_processar_dados_originais_concurso', {'erro': e.toString()});
    }
  }

  // Processa dados originais de inscrições
  void _processarDadosOriginaisInscricoes(String planoId, Map<String, dynamic> concOrig, Map<String, dynamic> metadados) {
    final inscricoesData = concOrig['inscricoes'];
    if (inscricoesData is! Map) {
      if (inscricoesData != null) {
        _logger.logArmazenamento(planoId, 'warn_dados_originais_inscricoes_nao_mapa', {'tipo': inscricoesData.runtimeType});
      }
      return;
    }

    try {
      final inscOrig = DynamicMapConverter.toStringDynamicMap(inscricoesData);

      // Extrair início e fim da inscrição
      if (inscOrig.containsKey('inicio')) {
        metadados['inicioInscricao'] ??= inscOrig['inicio'];
      }

      if (inscOrig.containsKey('fim')) {
        metadados['fimInscricao'] ??= inscOrig['fim'];
      }

      // Extrair taxa de inscrição
      if (inscOrig.containsKey('taxa')) {
        metadados['valorInscricao'] ??= inscOrig['taxa'];
      }

      // Criar período de inscrições formatado
      if (inscOrig.containsKey('inicio') && inscOrig.containsKey('fim')) {
        metadados['periodoInscricoes'] ??= '${inscOrig['inicio']} a ${inscOrig['fim']}';
      }

      _logger.logArmazenamento(planoId, 'dados_inscricoes_processados', {
        'inicio': inscOrig['inicio'],
        'fim': inscOrig['fim'],
        'taxa': inscOrig['taxa'],
      });
    } catch (e) {
      _logger.logArmazenamento(planoId, 'erro_processar_dados_originais_inscricoes', {'erro': e.toString()});
    }
  }

  // Processa dados originais de cotas
  void _processarDadosOriginaisCotas(String planoId, Map<String, dynamic> orig, Map<String, dynamic> metadados) {
    if (!orig.containsKey('cotas') || metadados['cotas'] != null) return;

    final cotasOriginal = orig['cotas'];
    if (cotasOriginal is List) {
      metadados['cotas'] = cotasOriginal.map((cota) {
        if (cota is Map) {
          try {
            return DynamicMapConverter.toStringDynamicMap(cota)['nome'] ?? cota.toString();
          } catch (_) { return cota.toString(); }
        }
        return cota.toString();
      }).join(', ');
    } else if (cotasOriginal is Map) {
      try {
        metadados['cotas'] = DynamicMapConverter.toStringDynamicMap(cotasOriginal).keys.join(', ');
      } catch (_) { metadados['cotas'] = cotasOriginal.toString(); }
    } else {
      metadados['cotas'] = cotasOriginal?.toString();
    }
  }

  // Processa dados da LLM
  void _processarDadosLLM(String planoId, Map<String, dynamic> dadosAdicionaisConvertidos, Map<String, dynamic> metadados) {
    if (!dadosAdicionaisConvertidos.containsKey('planoEstudos')) return;

    final planoEstudosData = dadosAdicionaisConvertidos['planoEstudos'];
    if (planoEstudosData is! Map) {
      if (planoEstudosData != null) {
        _logger.logArmazenamento(planoId, 'warn_planoEstudosData_nao_mapa_geral', {'tipo': planoEstudosData.runtimeType});
      }
      return;
    }

    try {
      final planoEstudosMap = DynamicMapConverter.toStringDynamicMap(planoEstudosData);
      _processarMetadadosPlano(planoId, planoEstudosMap, metadados);
      _processarProvaLLM(planoId, planoEstudosMap, metadados);
      _processarConcursoLLM(planoId, planoEstudosMap, metadados);
      _processarCotasLLM(planoId, planoEstudosMap, metadados);
      _processarDuracaoTotalCiclo(planoId, planoEstudosMap, metadados);
      _processarTotalBlocosCiclo(planoId, planoEstudosMap, metadados);
    } catch (e, s) {
      _logger.logArmazenamento(planoId, 'erro_converter_planoEstudosData_geral', {'erro': e.toString(), 'stack': s.toString()});
    }
  }

  // Processa metadados do plano
  void _processarMetadadosPlano(String planoId, Map<String, dynamic> planoEstudosMap, Map<String, dynamic> metadados) {
    final metadadosPlanoData = planoEstudosMap['metadados'];
    if (metadadosPlanoData is! Map) {
      if (metadadosPlanoData != null) {
        _logger.logArmazenamento(planoId, 'warn_metadados_plano_nao_mapa', {'tipo': metadadosPlanoData.runtimeType});
      }
      return;
    }

    try {
      final metaPlano = DynamicMapConverter.toStringDynamicMap(metadadosPlanoData);
      metadados.addAll(metaPlano); // Adiciona ou sobrescreve
      _logger.logArmazenamento(planoId, 'metadados_plano_estudos_adicionados', {'keys': metaPlano.keys.toList()});
    } catch (e, s) {
      _logger.logArmazenamento(planoId, 'erro_converter_metadados_plano', {'erro': e.toString(), 'stack': s.toString()});
    }
  }

  // Processa dados da prova da LLM
  void _processarProvaLLM(String planoId, Map<String, dynamic> planoEstudosMap, Map<String, dynamic> metadados) {
    final provaLLMData = planoEstudosMap['prova'];
    if (provaLLMData is! Map) {
      if (provaLLMData != null) {
        _logger.logArmazenamento(planoId, 'warn_prova_llm_nao_mapa', {'tipo': provaLLMData.runtimeType});
      }
      return;
    }

    try {
      final provaLLM = DynamicMapConverter.toStringDynamicMap(provaLLMData);
      metadados['totalQuestoes'] = provaLLM['total_questoes'] ?? metadados['totalQuestoes'];
      metadados['formatoProva'] = (provaLLM['formato'] is List
        ? (provaLLM['formato'] as List).join(', ')
        : provaLLM['formato']?.toString()) ?? metadados['formatoProva'];
      metadados['temaProvaSubjetiva'] = provaLLM['tema_discursiva'] ?? metadados['temaProvaSubjetiva'];
      metadados['criteriosAprovacao'] = provaLLM['criterios_aprovacao'] ?? metadados['criteriosAprovacao'];
      metadados['criteriosReprovacao'] = provaLLM['criterios_reprovacao'] ?? metadados['criteriosReprovacao'];
      metadados['duracaoProva'] = provaLLM['duracao'] ?? metadados['duracaoProva'];
      metadados['criteriosDesempate'] = provaLLM['criterios_desempate'] ?? metadados['criteriosDesempate'];
      _logger.logArmazenamento(planoId, 'dados_prova_llm_processados', {'keys': provaLLM.keys.toList()});
    } catch (e, s) {
      _logger.logArmazenamento(planoId, 'erro_converter_prova_llm', {'erro': e.toString(), 'stack': s.toString()});
    }
  }

  // Processa dados do concurso da LLM
  void _processarConcursoLLM(String planoId, Map<String, dynamic> planoEstudosMap, Map<String, dynamic> metadados) {
    final concursoLLMData = planoEstudosMap['concurso'];
    if (concursoLLMData is! Map) {
      if (concursoLLMData != null) {
        _logger.logArmazenamento(planoId, 'warn_concurso_llm_nao_mapa', {'tipo': concursoLLMData.runtimeType});
      }
      return;
    }

    try {
      final concLLM = DynamicMapConverter.toStringDynamicMap(concursoLLMData);
      _processarInscricoesLLM(planoId, concLLM, metadados);
      metadados['dataProva'] = concLLM['data_prova'] ?? metadados['dataProva'];
      metadados['localProva'] = concLLM['local_prova'] ?? metadados['localProva'];
      metadados['valorInscricao'] = concLLM['taxa_inscricao'] ?? metadados['valorInscricao'];
      _logger.logArmazenamento(planoId, 'dados_concurso_llm_processados', {'keys': concLLM.keys.toList()});
    } catch (e, s) {
      _logger.logArmazenamento(planoId, 'erro_converter_concurso_llm', {'erro': e.toString(), 'stack': s.toString()});
    }
  }

  // Processa dados de inscrições da LLM
  void _processarInscricoesLLM(String planoId, Map<String, dynamic> concLLM, Map<String, dynamic> metadados) {
    final inscricoesLLMData = concLLM['inscricoes'];
    if (inscricoesLLMData is! Map) {
      if (inscricoesLLMData != null) {
        _logger.logArmazenamento(planoId, 'warn_inscricoes_llm_nao_mapa', {'tipo': inscricoesLLMData.runtimeType});
      }
      return;
    }

    try {
      final inscLLM = DynamicMapConverter.toStringDynamicMap(inscricoesLLMData);

      // Extrair início e fim da inscrição
      if (inscLLM.containsKey('inicio')) {
        metadados['inicioInscricao'] = inscLLM['inicio']; // Sobrescreve sempre se presente
      }

      if (inscLLM.containsKey('fim')) {
        metadados['fimInscricao'] = inscLLM['fim']; // Sobrescreve sempre se presente
      }

      // Extrair taxa de inscrição
      if (inscLLM.containsKey('taxa')) {
        metadados['valorInscricao'] = inscLLM['taxa']; // Sobrescreve sempre se presente
      }

      // Criar período de inscrições formatado
      if (inscLLM.containsKey('inicio') && inscLLM.containsKey('fim')) {
        metadados['periodoInscricoes'] = '${inscLLM['inicio']} a ${inscLLM['fim']}'; // Sobrescreve sempre se presente
      }

      _logger.logArmazenamento(planoId, 'dados_inscricoes_llm_processados', {
        'inicio': inscLLM['inicio'],
        'fim': inscLLM['fim'],
        'taxa': inscLLM['taxa'],
      });
    } catch (e, s) {
      _logger.logArmazenamento(planoId, 'erro_converter_inscricoes_llm', {'erro': e.toString(), 'stack': s.toString()});
    }
  }

  // Processa dados de cotas da LLM
  void _processarCotasLLM(String planoId, Map<String, dynamic> planoEstudosMap, Map<String, dynamic> metadados) {
    if (!planoEstudosMap.containsKey('cotas')) return;

    final cotasLLM = planoEstudosMap['cotas'];
    if (cotasLLM is List) {
      metadados['cotas'] = cotasLLM.map((cota) {
        if (cota is Map) {
          try {
            return DynamicMapConverter.toStringDynamicMap(cota)['nome'] ?? cota.toString();
          } catch (_) { return cota.toString(); }
        }
        return cota.toString();
      }).join(', ');
    } else if (cotasLLM is Map) {
      try {
        metadados['cotas'] = DynamicMapConverter.toStringDynamicMap(cotasLLM).keys.join(', ');
      } catch (_) { metadados['cotas'] = cotasLLM.toString(); }
    } else if (cotasLLM != null) {
      metadados['cotas'] = cotasLLM.toString(); // Sobrescreve sempre se presente
    } else {
      metadados.remove('cotas'); // Remove se for explicitamente nulo
    }
    _logger.logArmazenamento(planoId, 'dados_cotas_llm_processados', {'tipo': cotasLLM.runtimeType});
  }

  // Processa duração total do ciclo
  void _processarDuracaoTotalCiclo(String planoId, Map<String, dynamic> planoEstudosMap, Map<String, dynamic> metadados) {
    // Verificar se há duração total do ciclo no planoEstudosMap
    if (planoEstudosMap.containsKey('duracao_total_ciclo')) {
      final duracaoTotalCiclo = planoEstudosMap['duracao_total_ciclo'];
      if (duracaoTotalCiclo != null) {
        try {
          if (duracaoTotalCiclo is int) {
            metadados['duracaoTotalCiclo'] = duracaoTotalCiclo;
          } else if (duracaoTotalCiclo is double) {
            metadados['duracaoTotalCiclo'] = duracaoTotalCiclo.round();
          } else if (duracaoTotalCiclo is String) {
            metadados['duracaoTotalCiclo'] = int.tryParse(duracaoTotalCiclo) ?? 7;
          } else {
            metadados['duracaoTotalCiclo'] = 7; // Valor padrão
          }
        } catch (e) {
          _logger.logArmazenamento(planoId, 'erro_processar_duracao_total_ciclo', {'erro': e.toString()});
          metadados['duracaoTotalCiclo'] = 7; // Valor padrão em caso de erro
        }
      }
    } else {
      // Se não houver duração total do ciclo, calcular com base no ciclo de estudos
      metadados['duracaoTotalCiclo'] = _calcularDuracaoTotalCiclo(planoId, planoEstudosMap);
    }

    _logger.logArmazenamento(planoId, 'duracao_total_ciclo_processada', {'duracaoTotalCiclo': metadados['duracaoTotalCiclo']});
  }

  // Calcula a duração total do ciclo com base no ciclo de estudos
  int _calcularDuracaoTotalCiclo(String planoId, Map<String, dynamic> planoEstudosMap) {
    if (!planoEstudosMap.containsKey('ciclo_estudos')) {
      return 7; // Valor padrão de uma semana
    }

    final cicloEstudos = planoEstudosMap['ciclo_estudos'];
    if (cicloEstudos is! List || cicloEstudos.isEmpty) {
      return 7; // Valor padrão de uma semana
    }

    try {
      // Encontrar o maior valor de 'dia' no ciclo
      int maiorDia = 0;
      for (final dia in cicloEstudos) {
        if (dia is Map) {
          final valorDia = dia['dia'];
          if (valorDia is int && valorDia > maiorDia) {
            maiorDia = valorDia;
          }
        }
      }

      return maiorDia > 0 ? maiorDia : 7; // Retornar o maior dia ou 7 como padrão
    } catch (e) {
      _logger.logArmazenamento(planoId, 'erro_calcular_duracao_total_ciclo', {'erro': e.toString()});
      return 7; // Em caso de erro, retornar 7 como padrão
    }
  }

  // Processa total de blocos do ciclo
  void _processarTotalBlocosCiclo(String planoId, Map<String, dynamic> planoEstudosMap, Map<String, dynamic> metadados) {
    // Verificar se há total de blocos do ciclo no planoEstudosMap
    if (planoEstudosMap.containsKey('total_blocos_ciclo')) {
      final totalBlocosCiclo = planoEstudosMap['total_blocos_ciclo'];
      if (totalBlocosCiclo != null) {
        try {
          if (totalBlocosCiclo is int) {
            metadados['totalBlocosCiclo'] = totalBlocosCiclo;
          } else if (totalBlocosCiclo is double) {
            metadados['totalBlocosCiclo'] = totalBlocosCiclo.round();
          } else if (totalBlocosCiclo is String) {
            metadados['totalBlocosCiclo'] = int.tryParse(totalBlocosCiclo) ?? 14;
          } else {
            metadados['totalBlocosCiclo'] = 14; // Valor padrão
          }
        } catch (e) {
          _logger.logArmazenamento(planoId, 'erro_processar_total_blocos_ciclo', {'erro': e.toString()});
          metadados['totalBlocosCiclo'] = 14; // Valor padrão em caso de erro
        }
      }
    } else {
      // Se não houver total de blocos do ciclo, calcular com base no ciclo de estudos
      metadados['totalBlocosCiclo'] = _calcularTotalBlocosCiclo(planoId, planoEstudosMap);
    }

    _logger.logArmazenamento(planoId, 'total_blocos_ciclo_processado', {'totalBlocosCiclo': metadados['totalBlocosCiclo']});
  }

  // Calcula o total de blocos do ciclo com base no ciclo de estudos
  int _calcularTotalBlocosCiclo(String planoId, Map<String, dynamic> planoEstudosMap) {
    if (!planoEstudosMap.containsKey('ciclo_estudos')) {
      return 14; // Valor padrão de 2 blocos por dia durante uma semana
    }

    final cicloEstudos = planoEstudosMap['ciclo_estudos'];
    if (cicloEstudos is! List || cicloEstudos.isEmpty) {
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
      _logger.logArmazenamento(planoId, 'erro_calcular_total_blocos_ciclo', {'erro': e.toString()});
      return 14; // Em caso de erro, retornar 14 como padrão
    }
  }

  // Adiciona dados restantes
  void _adicionarDadosRestantes(Map<String, dynamic> dadosAdicionaisConvertidos, Map<String, dynamic> metadados) {
    dadosAdicionaisConvertidos.forEach((key, value) {
      if (key != 'planoEstudos' && value != null) {
        metadados[key] = value;
      }
    });
  }
}
