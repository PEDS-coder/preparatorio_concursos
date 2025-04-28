import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/edital_service.dart';
import 'calendario_service.dart';
import 'extrator_dados_service.dart';
import 'plano_dados_service.dart';

/// Serviço para gerenciamento do resumo do plano
class PlanoResumoService {
  final PlanoEstudoService _planoService;
  final EditalService _editalService;
  final CalendarioService _calendarioService;
  final ExtratorDadosService _extratoService;
  final PlanoDadosService _planoDadosService;

  PlanoResumoService(
    this._planoService,
    this._editalService,
    this._calendarioService,
    this._extratoService,
  ) : _planoDadosService = PlanoDadosService();

  /// Carrega o plano de estudos e o edital associado
  Future<Map<String, dynamic>> carregarPlano(String planoId) async {
    try {
      // _logger.logRecuperacao(planoId, 'inicio_carregamento', 'Iniciando carregamento do plano');
      var plano = _planoService.getPlanoById(planoId);

      if (plano == null) {
        // _logger.logRecuperacao(planoId, 'plano_nao_encontrado', 'Plano não encontrado com ID: $planoId');
        debugPrint('ERRO: Plano não encontrado com ID: $planoId');
        return {'plano': null, 'edital': null, 'sessoesPorDia': {}, 'erro': 'Plano não encontrado'};
      }

      // _logger.logRecuperacao(plano.id, 'plano_recuperado', {
      //   'id': plano.id,
      //   'editalId': plano.editalId,
      //   'cargoIds': plano.cargoIds,
      //   'dataInicio': plano.dataInicio.toIso8601String(),
      //   'dataFim': plano.dataFim.toIso8601String(),
      //   'horasSemanais': plano.horasSemanais,
      //   'ferramentas': plano.ferramentas,
      //   'materiasProficiencia': plano.materiasProficiencia.map((m) => {'materia': m.nomeMateria, 'nivel': m.nivelProficiencia}).toList(),
      //   'recompensas': plano.recompensas.map((r) => {'tipo': r.tipoRecompensa, 'descricao': r.descricaoRecompensa}).toList(),
      //   'sessoesEstudo': plano.sessoesEstudo.length,
      //   'metadados_keys': plano.metadados.keys.toList(),
      // });

      // Verificar se o plano tem sessões de estudo
      if (plano.sessoesEstudo.isEmpty) {
        // _logger.logRecuperacao(plano.id, 'sessoes_vazias', 'Plano não possui sessões de estudo. Gerando sessões...');
        // Gerar sessões de estudo para o plano
        await _planoService.gerarSessoesParaPlano(plano.id);
        // Recarregar o plano com as novas sessões
        final planoAtualizado = _planoService.getPlanoById(planoId);
        if (planoAtualizado != null) {
          plano = planoAtualizado;
          // _logger.logRecuperacao(plano.id, 'plano_atualizado', {
          //   'sessoesEstudo': plano.sessoesEstudo.length,
          // });
        }
      }

      // Agrupar sessões por dia para o calendário
      final Map<DateTime, List<SessaoEstudo>> sessoesPorDia = _calendarioService.agruparSessoesPorDia(plano.sessoesEstudo);

      // _logger.logRecuperacao(plano.id, 'processando_sessoes', 'Processando ${plano.sessoesEstudo.length} sessões de estudo');

      Map<String, int> sessoesContagem = {};
      sessoesPorDia.forEach((data, sessoes) {
        final dataStr = '${data.day}/${data.month}/${data.year}';
        sessoesContagem[dataStr] = sessoes.length;
      });
      // _logger.logRecuperacao(plano.id, 'contagem_sessoes_por_dia', sessoesContagem);

      // Verificar se há dados do ciclo de estudos nos metadados
      if (plano.metadados.containsKey('planoEstudos')) {
        // _logger.logRecuperacao(plano.id, 'planoEstudos_metadados', {
        //   'cicloEstudos': plano.metadados['planoEstudos']['cicloEstudos'] != null ? 'presente' : 'ausente',
        //   'materiasPrioritarias': plano.metadados['planoEstudos']['materiasPrioritarias'] != null ? 'presente' : 'ausente',
        //   'grupos': plano.metadados['planoEstudos']['grupos'] != null ? 'presente' : 'ausente',
        //   'calendario': plano.metadados['planoEstudos']['calendario'] != null ? 'presente' : 'ausente',
        // });
      } else {
        // _logger.logRecuperacao(plano.id, 'planoEstudos_metadados', 'ausente');
      }

      // Carregar o edital associado ao plano
      Edital? edital;
      if (plano.editalId.isNotEmpty) {
        edital = _editalService.getEditalById(plano.editalId);
        if (edital != null) {
          // _logger.logRecuperacao(plano.id, 'edital_recuperado', {
          //   'id': edital.id,
          //   'titulo': edital.dadosExtraidos.titulo,
          //   'orgao': edital.dadosExtraidos.orgao,
          //   'banca': edital.dadosExtraidos.banca,
          //   'cargos': edital.dadosExtraidos.cargos.length,
          //   'dadosOriginais': edital.dadosOriginais != null ? 'presente' : 'ausente',
          // });

          // Extrair dados do edital para o plano
          await _planoDadosService.extrairDadosEditalParaPlano(plano, edital);
        } else {
          // _logger.logRecuperacao(plano.id, 'edital_nao_encontrado', 'Edital não encontrado com ID: ${plano.editalId}');
        }
      }

      // _logger.logRecuperacao(plano.id, 'carregamento_concluido', 'Plano carregado com sucesso');

      return {
        'plano': plano,
        'edital': edital,
        'sessoesPorDia': sessoesPorDia,
        'focusedDay': plano.dataInicio,
        'selectedDay': plano.dataInicio,
      };
    } catch (e) {
      // _logger.logRecuperacao(planoId, 'erro_carregamento', 'Erro ao carregar plano: $e');
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

    debugPrint('Buscando cargo com ID: $cargoId');
    debugPrint('Cargos disponíveis: ${cargos.map((c) => "${c.id} - ${c.nome}").join(", ")}');

    try {
      // Primeiro, tentar encontrar por ID exato
      final cargoExato = cargos.firstWhere(
        (cargo) => cargo.id == cargoId,
        orElse: () => Cargo(id: '', nome: '', conteudoProgramatico: []),
      );

      if (cargoExato.id.isNotEmpty) {
        debugPrint('Cargo encontrado por ID exato: ${cargoExato.id} - ${cargoExato.nome}');
        return cargoExato;
      }

      // Se não encontrou por ID, tentar por nome exato
      final cargoNomeExato = cargos.firstWhere(
        (cargo) => cargo.nome.toLowerCase() == cargoId.toLowerCase(),
        orElse: () => Cargo(id: '', nome: '', conteudoProgramatico: []),
      );

      if (cargoNomeExato.nome.isNotEmpty) {
        debugPrint('Cargo encontrado por nome exato: ${cargoNomeExato.id} - ${cargoNomeExato.nome}');
        return cargoNomeExato;
      }

      // Se não encontrou por nome exato, tentar por nome parcial
      final cargoParcial = cargos.firstWhere(
        (cargo) => cargo.nome.toLowerCase().contains(cargoId.toLowerCase()) ||
                   cargoId.toLowerCase().contains(cargo.nome.toLowerCase()),
        orElse: () => Cargo(id: '', nome: '', conteudoProgramatico: []),
      );

      if (cargoParcial.nome.isNotEmpty) {
        debugPrint('Cargo encontrado por nome parcial: ${cargoParcial.id} - ${cargoParcial.nome}');
        return cargoParcial;
      }

      // Se não encontrou, criar um cargo com o ID fornecido
      debugPrint('Cargo não encontrado. Criando cargo com nome: $cargoId');
      return Cargo(nome: cargoId, conteudoProgramatico: []);
    } catch (e) {
      debugPrint('Erro ao obter cargo selecionado: $e');
      return Cargo(nome: cargoId, conteudoProgramatico: []);
    }
  }

  /// Agrupa matérias por grupo/módulo
  Map<String, List<ConteudoProgramatico>> agruparMateriasPorGrupo(Cargo cargo) {
    Map<String, List<ConteudoProgramatico>> materiasPorGrupo = {};

    debugPrint('Agrupando matérias para o cargo: ${cargo.nome}');
    debugPrint('Total de matérias: ${cargo.conteudoProgramatico.length}');

    // Verificar se há matérias com grupo definido
    bool temGruposDefinidos = cargo.conteudoProgramatico.any((c) => c.grupoMateria != null && c.grupoMateria!.isNotEmpty);
    debugPrint('Tem grupos definidos: $temGruposDefinidos');

    // Verificar se há matérias com grupo no campo 'grupo'
    bool temGruposCampoGrupo = cargo.conteudoProgramatico.any((c) => c.grupo != null && c.grupo!.isNotEmpty);
    debugPrint('Tem grupos no campo grupo: $temGruposCampoGrupo');

    // Verificar se há matérias com tipo definido
    bool temTiposDefinidos = cargo.conteudoProgramatico.any((c) => c.tipo.isNotEmpty);
    debugPrint('Tem tipos definidos: $temTiposDefinidos');

    // Verificar se há matérias com módulo definido
    bool temModulosDefinidos = cargo.conteudoProgramatico.any((c) =>
      (c.grupoMateria != null && c.grupoMateria!.toLowerCase().contains('módulo')) ||
      (c.grupo != null && c.grupo!.toLowerCase().contains('módulo')) ||
      (c.tipo.toLowerCase().contains('módulo')));
    debugPrint('Tem módulos definidos: $temModulosDefinidos');

    // Verificar se estamos lidando com o MPU (caso específico)
    bool isMPU = cargo.nome.toLowerCase().contains('mpu') ||
                 cargo.nome.toLowerCase().contains('ministério público');

    if (isMPU) {
      debugPrint('Detectado cargo do MPU, usando agrupamento específico');

      // Grupos específicos para o MPU
      final gruposMPU = {
        'Conhecimentos Básicos': [
          'língua portuguesa', 'português', 'raciocínio lógico', 'matemática', 'noções de informática',
          'informática', 'legislação aplicada ao mpu', 'legislação'
        ],
        'Conhecimentos Específicos': [
          'direito constitucional', 'direito administrativo', 'direito civil', 'direito processual civil',
          'direito penal', 'direito processual penal', 'direito do trabalho', 'direito processual do trabalho',
          'direito tributário', 'direito previdenciário', 'direito financeiro', 'direito ambiental'
        ]
      };

      // Agrupar matérias de acordo com os grupos do MPU
      for (var conteudo in cargo.conteudoProgramatico) {
        String grupoChave = 'Outros';
        final nomeLower = conteudo.nome.toLowerCase();

        // Verificar em qual grupo a matéria se encaixa
        for (var entry in gruposMPU.entries) {
          if (entry.value.any((materia) => nomeLower.contains(materia))) {
            grupoChave = entry.key;
            break;
          }
        }

        // Adicionar ao grupo correspondente
        if (!materiasPorGrupo.containsKey(grupoChave)) {
          materiasPorGrupo[grupoChave] = [];
        }

        // Criar uma nova instância com os campos atualizados
        final conteudoAtualizado = ConteudoProgramatico(
          nome: conteudo.nome,
          tipo: conteudo.tipo,
          topicos: conteudo.topicos,
          pesoMaior: conteudo.pesoMaior,
          criterioDesempate: conteudo.criterioDesempate,
          numeroQuestoes: conteudo.numeroQuestoes,
          questoesEstimadas: conteudo.questoesEstimadas,
          totalQuestoesGrupo: conteudo.totalQuestoesGrupo,
          grupo: grupoChave,
          grupoMateria: grupoChave
        );

        materiasPorGrupo[grupoChave]!.add(conteudoAtualizado);
      }
    } else {
      // Agrupar matérias por grupo para outros concursos
      for (var conteudo in cargo.conteudoProgramatico) {
        String grupoChave;

        // Verificar se há informações de grupo em diferentes campos
        debugPrint('Matéria: ${conteudo.nome}');
        debugPrint('  grupoMateria: ${conteudo.grupoMateria}');
        debugPrint('  grupo: ${conteudo.grupo}');
        debugPrint('  tipo: ${conteudo.tipo}');

        // Prioridade 1: Usar o campo grupoMateria se estiver definido
        if (conteudo.grupoMateria != null && conteudo.grupoMateria!.isNotEmpty) {
          grupoChave = conteudo.grupoMateria!;
          debugPrint('  Usando grupoMateria: $grupoChave');
        }
        // Prioridade 2: Usar o campo grupo se estiver definido
        else if (conteudo.grupo != null && conteudo.grupo!.isNotEmpty) {
          grupoChave = conteudo.grupo!;
          debugPrint('  Usando grupo: $grupoChave');
        }
        // Prioridade 3: Usar o tipo se estiver definido
        else if (conteudo.tipo.isNotEmpty) {
          // Normalizar tipos comuns
          final tipoLower = conteudo.tipo.toLowerCase();
          if (tipoLower == 'comum' ||
              tipoLower == 'básico' ||
              tipoLower == 'basico' ||
              tipoLower.contains('conhecimentos básicos') ||
              tipoLower.contains('conhecimentos basicos')) {
            grupoChave = 'Conhecimentos Básicos';
          } else if (tipoLower == 'específico' ||
                    tipoLower == 'especifico' ||
                    tipoLower.contains('conhecimentos específicos') ||
                    tipoLower.contains('conhecimentos especificos')) {
            grupoChave = 'Conhecimentos Específicos';
          } else {
            // Usar o tipo como está
            grupoChave = conteudo.tipo;
          }
          debugPrint('  Usando tipo normalizado: $grupoChave');
        }
        // Prioridade 4: Tentar inferir o grupo pelo nome da matéria
        else {
          final nomeLower = conteudo.nome.toLowerCase();

          // Verificar se o nome da matéria sugere um grupo
          if (nomeLower.contains('direito constitucional')) {
            grupoChave = 'Direito Constitucional';
          } else if (nomeLower.contains('direito administrativo')) {
            grupoChave = 'Direito Administrativo';
          } else if (nomeLower.contains('direito civil')) {
            grupoChave = 'Direito Civil';
          } else if (nomeLower.contains('direito processual')) {
            grupoChave = 'Direito Processual';
          } else if (nomeLower.contains('direito penal')) {
            grupoChave = 'Direito Penal';
          } else if (nomeLower.contains('português') || nomeLower.contains('lingua portuguesa')) {
            grupoChave = 'Língua Portuguesa';
          } else if (nomeLower.contains('raciocínio lógico') || nomeLower.contains('matematica')) {
            grupoChave = 'Raciocínio Lógico';
          } else if (nomeLower.contains('informática') || nomeLower.contains('informatica')) {
            grupoChave = 'Informática';
          } else {
            // Fallback para grupo genérico
            grupoChave = 'Outros';
          }
          debugPrint('  Inferindo grupo pelo nome: $grupoChave');
        }

        // Adicionar ao grupo correspondente
        if (!materiasPorGrupo.containsKey(grupoChave)) {
          materiasPorGrupo[grupoChave] = [];
        }

        // Criar uma nova instância com os campos atualizados
        final conteudoAtualizado = ConteudoProgramatico(
          nome: conteudo.nome,
          tipo: conteudo.tipo,
          topicos: conteudo.topicos,
          pesoMaior: conteudo.pesoMaior,
          criterioDesempate: conteudo.criterioDesempate,
          numeroQuestoes: conteudo.numeroQuestoes,
          questoesEstimadas: conteudo.questoesEstimadas,
          totalQuestoesGrupo: conteudo.totalQuestoesGrupo,
          grupo: grupoChave,
          grupoMateria: grupoChave
        );

        materiasPorGrupo[grupoChave]!.add(conteudoAtualizado);
      }
    }

    // Se não houver grupos definidos, criar grupos padrão
    if (materiasPorGrupo.isEmpty) {
      debugPrint('Nenhum grupo definido, criando grupos padrão');
      materiasPorGrupo = {
        'Conhecimentos Básicos': [],
        'Conhecimentos Específicos': [],
      };

      // Distribuir matérias nos grupos padrão
      for (var conteudo in cargo.conteudoProgramatico) {
        final nomeLower = conteudo.nome.toLowerCase();
        String grupoChave;

        if (nomeLower.contains('português') ||
            nomeLower.contains('lingua portuguesa') ||
            nomeLower.contains('raciocínio') ||
            nomeLower.contains('matemática') ||
            nomeLower.contains('informática')) {
          grupoChave = 'Conhecimentos Básicos';
        } else {
          grupoChave = 'Conhecimentos Específicos';
        }

        // Adicionar ao grupo correspondente
        if (!materiasPorGrupo.containsKey(grupoChave)) {
          materiasPorGrupo[grupoChave] = [];
        }

        // Criar uma nova instância com os campos atualizados
        final conteudoAtualizado = ConteudoProgramatico(
          nome: conteudo.nome,
          tipo: conteudo.tipo,
          topicos: conteudo.topicos,
          pesoMaior: conteudo.pesoMaior,
          criterioDesempate: conteudo.criterioDesempate,
          numeroQuestoes: conteudo.numeroQuestoes,
          questoesEstimadas: conteudo.questoesEstimadas,
          totalQuestoesGrupo: conteudo.totalQuestoesGrupo,
          grupo: grupoChave,
          grupoMateria: grupoChave
        );

        materiasPorGrupo[grupoChave]!.add(conteudoAtualizado);
      }
    }

    // Log dos grupos criados
    debugPrint('Grupos criados:');
    materiasPorGrupo.forEach((grupo, materias) {
      debugPrint('  $grupo: ${materias.length} matérias');
      for (var materia in materias) {
        debugPrint('    - ${materia.nome} (grupo: ${materia.grupo}, grupoMateria: ${materia.grupoMateria})');
      }
    });

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
  Map<String, dynamic> obterInformacoesDetalhadas(Edital? edital, Cargo? cargo) {
    if (edital == null || cargo == null) {
      return {
        'salario': 'Não informado',
        'escolaridade': 'Não informado',
        'nivel': 'Não informado',
        'requisitos': <String>[],
      };
    }

    String salario = 'Não informado';
    String escolaridade = 'Não informado';
    String nivel = 'Não informado';
    List<String> requisitosList = [];

    // Padronizar requisitos do cargo para lista
    if (cargo.requisitos != null && cargo.requisitos != 'Não informado') {
      if (cargo.requisitos is List) {
        requisitosList = List<String>.from(cargo.requisitos);
      } else if (cargo.requisitos is String) {
        // Tentar separar por ponto e vírgula, vírgula ou quebra de linha
        requisitosList = (cargo.requisitos as String)
          .split(RegExp(r'[;\n,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'não informado')
          .toList();
        // Se não conseguiu separar, manter como lista com único item
        if (requisitosList.isEmpty && (cargo.requisitos as String).trim().isNotEmpty) {
          requisitosList = [(cargo.requisitos as String).trim()];
        }
      }
    }

    // Se não tiver requisitos, usar escolaridade como fallback
    if (requisitosList.isEmpty && cargo.escolaridade != null && cargo.escolaridade != 'Não informado') {
      requisitosList = [cargo.escolaridade];
    }

    if (cargo.nivel != null && cargo.nivel != 'Não informado') {
      nivel = cargo.nivel;
    }
    if (cargo.salario > 0) {
      salario = cargo.salario.toString();
    }

    // Verificar se temos informações nos dados originais
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cargos')) {
      final cargosOriginais = edital.dadosOriginais!['cargos'];
      if (cargosOriginais is List) {
        for (final cargoOriginal in cargosOriginais) {
          if (cargoOriginal is Map && cargoOriginal.containsKey('nome')) {
            String nomeCargo = cargoOriginal['nome'].toString();
            if (nomeCargo.toLowerCase().contains(cargo.nome.toLowerCase())) {
              if (cargoOriginal.containsKey('salario') && cargoOriginal['salario'] != null) {
                salario = cargoOriginal['salario'].toString();
              }
              if (cargoOriginal.containsKey('requisitos') && cargoOriginal['requisitos'] != null) {
                final requisitos = cargoOriginal['requisitos'];
                if (requisitos is List) {
                  requisitosList = List<String>.from(requisitos);
                } else if (requisitos is String) {
                  requisitosList = (requisitos as String)
                    .split(RegExp(r'[;\n,]'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty && e.toLowerCase() != 'não informado')
                    .toList();
                  if (requisitosList.isEmpty && (requisitos as String).trim().isNotEmpty) {
                    requisitosList = [(requisitos as String).trim()];
                  }
                }
              } else if (cargoOriginal.containsKey('escolaridade') && cargoOriginal['escolaridade'] != null && requisitosList.isEmpty) {
                requisitosList = [cargoOriginal['escolaridade'].toString()];
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
      'requisitos': requisitosList,
    };
  }
}
