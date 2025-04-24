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
    metadados['dataProva'] = de.dataProva ?? metadados['dataProva'];
    metadados['valorInscricao'] = de.valorTaxa ?? metadados['valorInscricao'];
    metadados['localProva'] = de.localProva ?? metadados['localProva'];

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
      _processarDadosOriginaisProva(planoId, orig, metadados);
      _processarDadosOriginaisConcurso(planoId, orig, metadados);
      _processarDadosOriginaisCotas(planoId, orig, metadados);
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
      if (inscOrig.containsKey('inicio') && inscOrig.containsKey('fim')) {
        metadados['periodoInscricoes'] ??= '${inscOrig['inicio']} a ${inscOrig['fim']}';
      }
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
      if (inscLLM.containsKey('inicio') && inscLLM.containsKey('fim')) {
        metadados['periodoInscricoes'] = '${inscLLM['inicio']} a ${inscLLM['fim']}'; // Sobrescreve sempre se presente
      }
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

  // Adiciona dados restantes
  void _adicionarDadosRestantes(Map<String, dynamic> dadosAdicionaisConvertidos, Map<String, dynamic> metadados) {
    dadosAdicionaisConvertidos.forEach((key, value) {
      if (key != 'planoEstudos' && value != null) {
        metadados[key] = value;
      }
    });
  }
}
