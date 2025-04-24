import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/utils/plano_data_logger.dart';
import 'calendario_service.dart';
import 'extrator_dados_service.dart';

/// Serviço para gerenciamento do resumo do plano
class PlanoResumoService {
  final PlanoEstudoService _planoService;
  final EditalService _editalService;
  final CalendarioService _calendarioService;
  final ExtratorDadosService _extratoService;
  final PlanoDataLogger _logger = PlanoDataLogger();

  PlanoResumoService(
    this._planoService, 
    this._editalService,
    this._calendarioService,
    this._extratoService,
  );

  /// Carrega o plano de estudos e o edital associado
  Future<Map<String, dynamic>> carregarPlano(String planoId) async {
    try {
      _logger.logRecuperacao(planoId, 'inicio_carregamento', 'Iniciando carregamento do plano');
      var plano = _planoService.getPlanoById(planoId);

      if (plano == null) {
        _logger.logRecuperacao(planoId, 'plano_nao_encontrado', 'Plano não encontrado com ID: $planoId');
        debugPrint('ERRO: Plano não encontrado com ID: $planoId');
        return {'plano': null, 'edital': null, 'sessoesPorDia': {}, 'erro': 'Plano não encontrado'};
      }

      _logger.logRecuperacao(plano.id, 'plano_recuperado', {
        'id': plano.id,
        'editalId': plano.editalId,
        'cargoIds': plano.cargoIds,
        'dataInicio': plano.dataInicio.toIso8601String(),
        'dataFim': plano.dataFim.toIso8601String(),
        'horasSemanais': plano.horasSemanais,
        'ferramentas': plano.ferramentas,
        'materiasProficiencia': plano.materiasProficiencia.map((m) => {'materia': m.nomeMateria, 'nivel': m.nivelProficiencia}).toList(),
        'recompensas': plano.recompensas.map((r) => {'tipo': r.tipoRecompensa, 'descricao': r.descricaoRecompensa}).toList(),
        'sessoesEstudo': plano.sessoesEstudo.length,
        'metadados_keys': plano.metadados.keys.toList(),
      });

      // Verificar se o plano tem sessões de estudo
      if (plano.sessoesEstudo.isEmpty) {
        _logger.logRecuperacao(plano.id, 'sessoes_vazias', 'Plano não possui sessões de estudo. Gerando sessões...');
        // Gerar sessões de estudo para o plano
        await _planoService.gerarSessoesParaPlano(plano.id);
        // Recarregar o plano com as novas sessões
        final planoAtualizado = _planoService.getPlanoById(planoId);
        if (planoAtualizado != null) {
          plano = planoAtualizado;
          _logger.logRecuperacao(plano.id, 'plano_atualizado', {
            'sessoesEstudo': plano.sessoesEstudo.length,
          });
        }
      }

      // Agrupar sessões por dia para o calendário
      final Map<DateTime, List<SessaoEstudo>> sessoesPorDia = _calendarioService.agruparSessoesPorDia(plano.sessoesEstudo);

      _logger.logRecuperacao(plano.id, 'processando_sessoes', 'Processando ${plano.sessoesEstudo.length} sessões de estudo');
      
      Map<String, int> sessoesContagem = {};
      sessoesPorDia.forEach((data, sessoes) {
        final dataStr = '${data.day}/${data.month}/${data.year}';
        sessoesContagem[dataStr] = sessoes.length;
      });
      _logger.logRecuperacao(plano.id, 'contagem_sessoes_por_dia', sessoesContagem);

      // Verificar se há dados do ciclo de estudos nos metadados
      if (plano.metadados.containsKey('planoEstudos')) {
        _logger.logRecuperacao(plano.id, 'planoEstudos_metadados', {
          'cicloEstudos': plano.metadados['planoEstudos']['cicloEstudos'] != null ? 'presente' : 'ausente',
          'materiasPrioritarias': plano.metadados['planoEstudos']['materiasPrioritarias'] != null ? 'presente' : 'ausente',
          'grupos': plano.metadados['planoEstudos']['grupos'] != null ? 'presente' : 'ausente',
          'calendario': plano.metadados['planoEstudos']['calendario'] != null ? 'presente' : 'ausente',
        });
      } else {
        _logger.logRecuperacao(plano.id, 'planoEstudos_metadados', 'ausente');
      }

      // Carregar o edital associado ao plano
      Edital? edital;
      if (plano.editalId.isNotEmpty) {
        edital = _editalService.getEditalById(plano.editalId);
        if (edital != null) {
          _logger.logRecuperacao(plano.id, 'edital_recuperado', {
            'id': edital.id,
            'titulo': edital.dadosExtraidos.titulo,
            'orgao': edital.dadosExtraidos.orgao,
            'banca': edital.dadosExtraidos.banca,
            'cargos': edital.dadosExtraidos.cargos.length,
            'dadosOriginais': edital.dadosOriginais != null ? 'presente' : 'ausente',
          });
        } else {
          _logger.logRecuperacao(plano.id, 'edital_nao_encontrado', 'Edital não encontrado com ID: ${plano.editalId}');
        }
      }

      _logger.logRecuperacao(plano.id, 'carregamento_concluido', 'Plano carregado com sucesso');
      
      return {
        'plano': plano,
        'edital': edital,
        'sessoesPorDia': sessoesPorDia,
        'focusedDay': plano.dataInicio,
        'selectedDay': plano.dataInicio,
      };
    } catch (e) {
      _logger.logRecuperacao(planoId, 'erro_carregamento', 'Erro ao carregar plano: $e');
      debugPrint('ERRO ao carregar plano: $e');
      return {'plano': null, 'edital': null, 'sessoesPorDia': {}, 'erro': e.toString()};
    }
  }

  /// Obtém o cargo selecionado do plano
  Cargo? obterCargoSelecionado(PlanoEstudo plano, Edital? edital) {
    if (edital == null || plano.cargoIds.isEmpty) {
      return null;
    }

    // Encontrar o cargo selecionado
    final cargoId = plano.cargoIds.first;
    final cargos = edital.dadosExtraidos.cargos;
    
    try {
      return cargos.firstWhere(
        (cargo) => cargo.id == cargoId || cargo.nome == cargoId,
        orElse: () => Cargo(nome: cargoId, conteudoProgramatico: []),
      );
    } catch (e) {
      debugPrint('Erro ao obter cargo selecionado: $e');
      return Cargo(nome: cargoId, conteudoProgramatico: []);
    }
  }

  /// Agrupa matérias por grupo/módulo
  Map<String, List<ConteudoProgramatico>> agruparMateriasPorGrupo(Cargo cargo) {
    Map<String, List<ConteudoProgramatico>> materiasPorGrupo = {};

    // Verificar se há matérias com grupo definido
    bool temGruposDefinidos = cargo.conteudoProgramatico.any((c) => c.grupoMateria != null && c.grupoMateria!.isNotEmpty);

    // Agrupar matérias por grupo
    for (var conteudo in cargo.conteudoProgramatico) {
      String grupoChave;

      if (temGruposDefinidos && conteudo.grupoMateria != null && conteudo.grupoMateria!.isNotEmpty) {
        // Usar o grupo definido pela LLM
        grupoChave = conteudo.grupoMateria!;
      } else {
        // Fallback para a classificação tradicional se não houver grupos definidos
        if (conteudo.tipo.toLowerCase() == 'comum' ||
            conteudo.tipo.toLowerCase() == 'básico' ||
            conteudo.tipo.toLowerCase() == 'basico' ||
            conteudo.tipo.toLowerCase() == 'conhecimentos básicos' ||
            conteudo.tipo.toLowerCase() == 'conhecimentos basicos') {
          grupoChave = 'Conhecimentos Básicos';
        } else if (conteudo.tipo.toLowerCase() == 'específico' ||
                  conteudo.tipo.toLowerCase() == 'especifico' ||
                  conteudo.tipo.toLowerCase() == 'conhecimentos específicos' ||
                  conteudo.tipo.toLowerCase() == 'conhecimentos especificos') {
          grupoChave = 'Conhecimentos Específicos';
        } else {
          // Se não for básico nem específico, usar o tipo como grupo
          grupoChave = conteudo.tipo.isEmpty ? 'Outros' : conteudo.tipo;
        }
      }

      // Adicionar ao grupo correspondente
      if (!materiasPorGrupo.containsKey(grupoChave)) {
        materiasPorGrupo[grupoChave] = [];
      }

      materiasPorGrupo[grupoChave]!.add(conteudo);
    }

    return materiasPorGrupo;
  }

  /// Obtém informações detalhadas sobre vagas
  Map<String, dynamic> obterInformacoesVagas(Edital? edital, Cargo? cargo) {
    if (edital == null) {
      return {'texto': 'Não informado', 'detalhes': null};
    }

    // Verificar se temos informações detalhadas sobre vagas
    if (edital.dadosExtraidos.dadosVaga != null) {
      final dadosVaga = edital.dadosExtraidos.dadosVaga!;
      String vagasInfo = '';

      if (dadosVaga.imediatas != null) {
        vagasInfo += 'Imediatas: ${dadosVaga.imediatas}';
      }

      if (dadosVaga.cadastroReserva == true) {
        if (vagasInfo.isNotEmpty) vagasInfo += ' + ';
        vagasInfo += 'Cadastro Reserva';
      }

      if (vagasInfo.isEmpty) {
        if (dadosVaga.totalConsolidado != null) {
          vagasInfo = 'Total: ${dadosVaga.totalConsolidado}';
        } else {
          vagasInfo = 'Não informado';
        }
      }

      return {
        'texto': vagasInfo,
        'detalhes': dadosVaga,
      };
    }

    // Verificar se temos informações nos dados originais
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('vagas')) {
      final vagasOriginais = edital.dadosOriginais!['vagas'];
      if (vagasOriginais is Map) {
        // Tentar extrair informações de vagas do JSON original
        String vagasInfo = '';

        if (vagasOriginais.containsKey('imediatas') && vagasOriginais['imediatas'] != null) {
          vagasInfo += 'Imediatas: ${vagasOriginais['imediatas']}';
        }

        if (vagasOriginais.containsKey('cadastro_reserva') && vagasOriginais['cadastro_reserva'] == true) {
          if (vagasInfo.isNotEmpty) vagasInfo += ' + ';
          vagasInfo += 'Cadastro Reserva';
        }

        if (vagasInfo.isEmpty) {
          if (vagasOriginais.containsKey('total_consolidado') && vagasOriginais['total_consolidado'] != null) {
            vagasInfo = 'Total: ${vagasOriginais['total_consolidado']}';
          } else {
            vagasInfo = 'Não informado';
          }
        }

        return {
          'texto': vagasInfo,
          'detalhes': vagasOriginais,
        };
      }
    }

    // Se não encontrou informações detalhadas, buscar no cargo
    if (cargo != null && cargo.vagas != null && cargo.vagas! > 0) {
      return {
        'texto': 'Total: ${cargo.vagas}',
        'detalhes': {'total': cargo.vagas},
      };
    }

    // Verificar se temos informações nos dados originais do cargo
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cargos') && cargo != null) {
      final cargosOriginais = edital.dadosOriginais!['cargos'];
      if (cargosOriginais is List) {
        for (final cargoOriginal in cargosOriginais) {
          if (cargoOriginal is Map && cargoOriginal.containsKey('nome')) {
            String nomeCargo = cargoOriginal['nome'].toString();
            if (nomeCargo.toLowerCase().contains(cargo.nome.toLowerCase())) {
              // Encontrou o cargo, extrair informações
              if (cargoOriginal.containsKey('vagas') && cargoOriginal['vagas'] != null) {
                return {
                  'texto': 'Total: ${cargoOriginal['vagas']}',
                  'detalhes': {'total': cargoOriginal['vagas']},
                };
              }
              break;
            }
          }
        }
      }
    }

    return {'texto': 'Não informado', 'detalhes': null};
  }

  /// Obtém informações sobre o cargo (salário, escolaridade, nível)
  Map<String, String> obterInformacoesDetalhadas(Edital? edital, Cargo? cargo) {
    if (edital == null || cargo == null) {
      return {
        'salario': 'Não informado',
        'escolaridade': 'Não informado',
        'nivel': 'Não informado',
      };
    }

    String salario = 'Não informado';
    String escolaridade = 'Não informado';
    String nivel = 'Não informado';

    // Verificar se temos informações nos dados originais
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cargos')) {
      final cargosOriginais = edital.dadosOriginais!['cargos'];
      if (cargosOriginais is List) {
        for (final cargoOriginal in cargosOriginais) {
          if (cargoOriginal is Map && cargoOriginal.containsKey('nome')) {
            String nomeCargo = cargoOriginal['nome'].toString();
            if (nomeCargo.toLowerCase().contains(cargo.nome.toLowerCase())) {
              // Encontrou o cargo, extrair informações
              if (cargoOriginal.containsKey('salario') && cargoOriginal['salario'] != null) {
                salario = cargoOriginal['salario'].toString();
              }
              if (cargoOriginal.containsKey('escolaridade') && cargoOriginal['escolaridade'] != null) {
                escolaridade = cargoOriginal['escolaridade'].toString();
              }
              if (cargoOriginal.containsKey('nivel') && cargoOriginal['nivel'] != null) {
                nivel = cargoOriginal['nivel'].toString();
              }
              break;
            }
          }
        }
      }
    }

    return {
      'salario': salario,
      'escolaridade': escolaridade,
      'nivel': nivel,
    };
  }
}
