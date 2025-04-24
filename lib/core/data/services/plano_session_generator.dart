import '../../utils/plano_data_logger.dart';
import '../../utils/dynamic_map_converter.dart';
import '../models/models.dart';

/// Classe responsável por gerar sessões de estudo para planos
class PlanoSessionGenerator {
  final PlanoDataLogger _logger;

  /// Construtor
  PlanoSessionGenerator({
    required PlanoDataLogger logger,
  }) : _logger = logger;

  /// Gera sessões de estudo para um plano
  List<SessaoEstudo> gerarSessoes({
    required String userId,
    required String planoId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required Map<String, int> horasSemanais,
    required List<MateriaProficiencia> materiasProficiencia,
    required List<String> ferramentas,
    required Map<String, dynamic> dadosAdicionaisConvertidos,
    Map<String, List<int>>? horariosEspecificos,
  }) {
    // Preparar horários específicos
    Map<String, List<int>> horariosEspecificosParaUsar = _prepararHorariosEspecificos(
      planoId, 
      horariosEspecificos, 
      horasSemanais
    );

    // Verificar se há um ciclo de estudos nos dados adicionais
    bool usarCiclo = false;
    List<dynamic>? cicloEstudos;

    // Extrair ciclo de estudos dos dados adicionais
    if (dadosAdicionaisConvertidos.containsKey('planoEstudos')) {
      final planoEstudosData = dadosAdicionaisConvertidos['planoEstudos'];
      if (planoEstudosData is Map) {
        try {
          final planoEstudosMap = DynamicMapConverter.toStringDynamicMap(planoEstudosData);
          if (planoEstudosMap.containsKey('cicloEstudos') &&
              planoEstudosMap['cicloEstudos'] is List &&
              (planoEstudosMap['cicloEstudos'] as List).isNotEmpty) {
            cicloEstudos = planoEstudosMap['cicloEstudos'] as List<dynamic>;
            usarCiclo = true;
            _logger.logArmazenamento(planoId, 'usando_ciclo_estudos', 'Usando ciclo de estudos dos dados adicionais');
          }
        } catch (e) {
          _logger.logArmazenamento(planoId, 'erro_extrair_ciclo_estudos', {'erro': e.toString()});
        }
      }
    }

    // Gerar sessões usando o método apropriado
    List<SessaoEstudo> sessoesEstudo = [];
    if (usarCiclo && cicloEstudos != null) {
      sessoesEstudo = _mapearCicloParaHorariosDisponiveis(
        userId, planoId, dataInicio, dataFim, horariosEspecificosParaUsar, cicloEstudos);

      if (sessoesEstudo.isEmpty) {
        _logger.logArmazenamento(planoId, 'erro_sessoes_vazias_ciclo', 'Nenhuma sessão gerada pelo mapeamento do ciclo, usando método tradicional como fallback');
        sessoesEstudo = _gerarSessoesEstudo(
          userId, dataInicio, dataFim, horasSemanais, materiasProficiencia,
          ferramentas, horariosEspecificos: horariosEspecificosParaUsar, planoId: planoId);
      }
    } else {
      _logger.logArmazenamento(planoId, 'usando_metodo_tradicional', 'Ciclo de estudos não encontrado ou inválido, usando método tradicional');
      sessoesEstudo = _gerarSessoesEstudo(
        userId, dataInicio, dataFim, horasSemanais, materiasProficiencia,
        ferramentas, horariosEspecificos: horariosEspecificosParaUsar, planoId: planoId);
    }

    _logger.logArmazenamento(planoId, 'sessoes_estudo_geradas', {
      'total_sessoes': sessoesEstudo.length,
      'primeira_sessao': sessoesEstudo.isNotEmpty ? {
        'materia': sessoesEstudo[0].materia,
        'dataHora': sessoesEstudo[0].dataHoraInicio.toIso8601String(),
        'duracao': sessoesEstudo[0].duracaoMinutos,
      } : 'nenhuma',
    });

    return sessoesEstudo;
  }

  /// Prepara os horários específicos para uso
  Map<String, List<int>> _prepararHorariosEspecificos(
    String planoId,
    Map<String, List<int>>? horariosEspecificos,
    Map<String, int> horasSemanais,
  ) {
    Map<String, List<int>> horariosEspecificosParaUsar = horariosEspecificos ?? {};

    // Definir horários específicos se não fornecidos e necessários
    if (horariosEspecificosParaUsar.isEmpty) {
      final diasDaSemana = ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];
      bool temHorasSemanais = horasSemanais.values.any((horas) => horas > 0);

      if (temHorasSemanais) {
        for (final dia in diasDaSemana) {
          final horasDisponiveis = horasSemanais[dia] ?? 0;
          if (horasDisponiveis > 0) {
            horariosEspecificosParaUsar[dia] = _gerarHorariosParaDia(horasDisponiveis);
          }
        }
      } else {
        // Se não houver horas semanais, usar valores padrão
        _logger.logArmazenamento(planoId, 'usando_horarios_padrao', 'Nenhuma hora semanal configurada, usando valores padrão');
        horariosEspecificosParaUsar = _gerarHorariosPadrao();
      }
    }

    // Validar se existem horários específicos após a conversão/definição
    bool temHorariosEspecificos = horariosEspecificosParaUsar.values.any((list) => list.isNotEmpty);
    if (!temHorariosEspecificos) {
      _logger.logArmazenamento(planoId, 'erro_sem_horarios', 'Nenhum horário específico configurado após conversão/definição, usando padrão');
      horariosEspecificosParaUsar = _gerarHorariosPadrao(); // Fallback para padrão se algo deu errado
    }

    return horariosEspecificosParaUsar;
  }

  /// Gera horários para um dia específico
  List<int> _gerarHorariosParaDia(int horasDisponiveis) {
    List<int> horarios = [];

    // Primeiro adicionar horários da tarde/noite (18 a 24)
    for (int i = 0; i < horasDisponiveis && i < 7; i++) {
      horarios.add(18 + i > 24 ? 18 + i - 24 : 18 + i);
    }

    // Se ainda precisar de mais horários, adicionar horários da manhã (1 a 17)
    if (horasDisponiveis > 7) {
      for (int i = 0; i < horasDisponiveis - 7 && i < 17; i++) {
        horarios.add(1 + i);
      }
    }

    return horarios;
  }

  /// Gera horários padrão para todos os dias da semana
  Map<String, List<int>> _gerarHorariosPadrao() {
    return {
      'segunda': [19, 20], 'terca': [19, 20], 'quarta': [19, 20],
      'quinta': [19, 20], 'sexta': [19, 20], 'sabado': [14, 15, 16, 17],
      'domingo': [14, 15, 16, 17],
    };
  }

  /// Mapeia um ciclo de estudos para horários disponíveis
  List<SessaoEstudo> _mapearCicloParaHorariosDisponiveis(
    String userId,
    String planoId,
    DateTime dataInicio,
    DateTime dataFim,
    Map<String, List<int>> horariosEspecificos,
    List<dynamic> cicloEstudos,
  ) {
    final List<SessaoEstudo> sessoes = [];
    final List<Map<String, dynamic>> listaBlocosCiclo = [];

    // Passo 1: Achatar o ciclo para uma lista de blocos
    try {
      for (final diaCiclo in cicloEstudos) {
        if (diaCiclo is Map) {
          final diaCicloMap = DynamicMapConverter.toStringDynamicMap(diaCiclo);
          final blocosData = diaCicloMap['blocos'];
          if (blocosData is List) {
            for (final blocoOriginal in blocosData) {
              if (blocoOriginal is Map) {
                final bloco = DynamicMapConverter.toStringDynamicMap(blocoOriginal);
                // Usar valores padrão se chaves não existirem ou forem nulas
                listaBlocosCiclo.add({
                  'materia': bloco['materia']?.toString() ?? 'Matéria Padrão',
                  'ferramenta': bloco['ferramenta']?.toString() ?? 'Estudo Padrão',
                  'duracao': bloco['duracao'] is int ? bloco['duracao'] : 60,
                  'assuntos': bloco['assuntos'] is List ? bloco['assuntos'] : [],
                });
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.logArmazenamento(planoId, 'erro_achatar_ciclo', {'erro': e.toString()});
      return []; // Retornar lista vazia para usar o método tradicional como fallback
    }

    if (listaBlocosCiclo.isEmpty) {
      _logger.logArmazenamento(planoId, 'ciclo_sem_blocos', 'Ciclo não contém blocos válidos');
      return []; // Retornar lista vazia para usar o método tradicional como fallback
    }

    // Passo 2: Distribuir os blocos nos horários disponíveis
    try {
      DateTime dataAtual = dataInicio;
      int indiceBlocoAtual = 0;

      while (dataAtual.isBefore(dataFim) || dataAtual.isAtSameMomentAs(dataFim)) {
        // Obter o dia da semana em português
        String diaSemana = _obterDiaSemanaPortugues(dataAtual);
        
        // Verificar se há horários disponíveis para este dia
        if (horariosEspecificos.containsKey(diaSemana) && horariosEspecificos[diaSemana]!.isNotEmpty) {
          // Para cada hora disponível neste dia
          for (int hora in horariosEspecificos[diaSemana]!) {
            // Obter o bloco atual (com rotação cíclica)
            Map<String, dynamic> blocoAtual = listaBlocosCiclo[indiceBlocoAtual % listaBlocosCiclo.length];
            indiceBlocoAtual++;

            // Criar data/hora para a sessão
            DateTime horaInicio = DateTime(dataAtual.year, dataAtual.month, dataAtual.day, hora);
            int duracaoMinutos = blocoAtual['duracao'] is int ? blocoAtual['duracao'] : 60;
            DateTime horaFim = horaInicio.add(Duration(minutes: duracaoMinutos));

            // Criar a sessão
            SessaoEstudo sessao = SessaoEstudo(
              id: '${planoId}_${DateTime.now().millisecondsSinceEpoch}_$indiceBlocoAtual',
              planoId: planoId,
              materiaId: 'materia_${blocoAtual['materia']}', // ID temporário
              materia: blocoAtual['materia'],
              assuntoIds: [], // Sem IDs de assuntos por enquanto
              dataHoraInicio: horaInicio,
              dataHoraFim: horaFim,
              duracaoMinutos: duracaoMinutos,
              ferramentas: [blocoAtual['ferramenta']],
              observacoes: blocoAtual['assuntos'] is List && (blocoAtual['assuntos'] as List).isNotEmpty
                  ? 'Assuntos: ${(blocoAtual['assuntos'] as List).join(', ')}'
                  : null,
            );

            sessoes.add(sessao);
          }
        }

        // Avançar para o próximo dia
        dataAtual = dataAtual.add(Duration(days: 1));
      }
    } catch (e) {
      _logger.logArmazenamento(planoId, 'erro_distribuir_blocos', {'erro': e.toString()});
      return []; // Retornar lista vazia para usar o método tradicional como fallback
    }

    return sessoes;
  }

  /// Gera sessões de estudo "tradicionalmente"
  List<SessaoEstudo> _gerarSessoesEstudo(
    String userId,
    DateTime dataInicio,
    DateTime dataFim,
    Map<String, int> horasSemanais,
    List<MateriaProficiencia> materiasProficiencia,
    List<String> ferramentas, {
    Map<String, List<int>>? horariosEspecificos,
    required String? planoId,
  }) {
    final logger = _logger;
    final logId = planoId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
    logger.logArmazenamento(logId, 'gerando_sessoes_tradicional', {
      'dataInicio': dataInicio.toIso8601String(), 'dataFim': dataFim.toIso8601String(),
      'materias': materiasProficiencia.map((mp) => mp.nomeMateria).toList(),
      'horariosEspecificos': horariosEspecificos,
    });

    // Verificar se há matérias para estudar
    if (materiasProficiencia.isEmpty) {
      logger.logArmazenamento(logId, 'erro_sem_materias', 'Nenhuma matéria para estudar');
      return [];
    }

    // Verificar se há horários específicos
    Map<String, List<int>> horariosParaUsar = horariosEspecificos ?? {};
    if (horariosParaUsar.isEmpty) {
      logger.logArmazenamento(logId, 'erro_sem_horarios_especificos', 'Nenhum horário específico fornecido');
      return [];
    }

    // Criar lista de sessões
    List<SessaoEstudo> sessoes = [];
    DateTime dataAtual = dataInicio;
    int indiceMateria = 0;

    // Distribuir as matérias pelos dias disponíveis
    while (dataAtual.isBefore(dataFim) || dataAtual.isAtSameMomentAs(dataFim)) {
      // Obter o dia da semana em português
      String diaSemana = _obterDiaSemanaPortugues(dataAtual);
      
      // Verificar se há horários disponíveis para este dia
      if (horariosParaUsar.containsKey(diaSemana) && horariosParaUsar[diaSemana]!.isNotEmpty) {
        // Para cada hora disponível neste dia
        for (int hora in horariosParaUsar[diaSemana]!) {
          // Obter a matéria atual (com rotação cíclica)
          MateriaProficiencia materiaAtual = materiasProficiencia[indiceMateria % materiasProficiencia.length];
          indiceMateria++;

          // Criar data/hora para a sessão
          DateTime horaInicio = DateTime(dataAtual.year, dataAtual.month, dataAtual.day, hora);
          int duracaoMinutos = 60; // Duração padrão de 1 hora
          DateTime horaFim = horaInicio.add(Duration(minutes: duracaoMinutos));

          // Criar a sessão
          SessaoEstudo sessao = SessaoEstudo(
            id: '${planoId ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}_$indiceMateria',
            planoId: planoId ?? 'temp',
            materiaId: 'materia_${materiaAtual.nomeMateria}', // ID temporário
            materia: materiaAtual.nomeMateria,
            assuntoIds: [], // Sem IDs de assuntos por enquanto
            dataHoraInicio: horaInicio,
            dataHoraFim: horaFim,
            duracaoMinutos: duracaoMinutos,
            ferramentas: ferramentas.isNotEmpty ? [ferramentas.first] : ['Estudo Padrão'],
          );

          sessoes.add(sessao);
        }
      }

      // Avançar para o próximo dia
      dataAtual = dataAtual.add(Duration(days: 1));
    }

    return sessoes;
  }

  /// Obtém o dia da semana em português
  String _obterDiaSemanaPortugues(DateTime data) {
    switch (data.weekday) {
      case DateTime.monday:
        return 'segunda';
      case DateTime.tuesday:
        return 'terca';
      case DateTime.wednesday:
        return 'quarta';
      case DateTime.thursday:
        return 'quinta';
      case DateTime.friday:
        return 'sexta';
      case DateTime.saturday:
        return 'sabado';
      case DateTime.sunday:
        return 'domingo';
      default:
        return 'segunda'; // Fallback
    }
  }
}
