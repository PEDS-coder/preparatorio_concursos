import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/materia.dart';
import '../models/assunto.dart';
import '../../../features/4_study_plan/domain/services/plano_dados_service.dart';

class PlanoEstudoService extends ChangeNotifier {
  List<PlanoEstudo> _planos = [];
  List<CronogramaItem> _cronogramaItems = [];
  List<Materia> _materias = [];
  List<Assunto> _assuntos = [];

  final PlanoDadosService _planoDadosService = PlanoDadosService();

  List<PlanoEstudo> get planos => _planos;
  List<CronogramaItem> get cronogramaItems => _cronogramaItems;
  List<Materia> get materias => _materias;
  List<Assunto> get assuntos => _assuntos;

  // Carregar planos e cronogramas do armazenamento local
  Future<void> loadPlanos() async {
    final prefs = await SharedPreferences.getInstance();
    final planosJson = prefs.getStringList('planos') ?? [];
    final cronogramaJson = prefs.getStringList('cronograma_items') ?? [];
    final materiasJson = prefs.getStringList('materias') ?? [];
    final assuntosJson = prefs.getStringList('assuntos') ?? [];

    _planos = planosJson.map((json) => PlanoEstudo.fromMap(jsonDecode(json))).toList();
    _cronogramaItems = cronogramaJson.map((json) => CronogramaItem.fromMap(jsonDecode(json))).toList();
    _materias = materiasJson.map((json) => Materia.fromMap(jsonDecode(json))).toList();
    _assuntos = assuntosJson.map((json) => Assunto.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }

  // Salvar planos no armazenamento local
  Future<void> _savePlanos() async {
    final prefs = await SharedPreferences.getInstance();
    final planosJson = _planos.map((plano) => jsonEncode(plano.toMap())).toList();

    await prefs.setStringList('planos', planosJson);
  }

  // Salvar matérias no armazenamento local
  Future<void> _saveMaterias() async {
    final prefs = await SharedPreferences.getInstance();
    final materiasJson = _materias.map((materia) => jsonEncode(materia.toMap())).toList();

    await prefs.setStringList('materias', materiasJson);
  }

  // Salvar assuntos no armazenamento local
  Future<void> _saveAssuntos() async {
    final prefs = await SharedPreferences.getInstance();
    final assuntosJson = _assuntos.map((assunto) => jsonEncode(assunto.toMap())).toList();

    await prefs.setStringList('assuntos', assuntosJson);
  }

  // Salvar cronograma no armazenamento local
  Future<void> _saveCronograma() async {
    final prefs = await SharedPreferences.getInstance();
    final cronogramaJson = _cronogramaItems.map((item) => jsonEncode(item.toMap())).toList();

    await prefs.setStringList('cronograma_items', cronogramaJson);
  }

  // Adicionar um novo plano de estudo
  Future<PlanoEstudo> criarPlanoEstudo(
    String userId,
    String? editalId,
    List<String> cargoIds,
    DateTime dataInicio,
    DateTime dataFim,
    Map<String, int> horasSemanais,
    List<String> ferramentas,
    List<MateriaProficiencia> materiasProficiencia,
    List<RecompensaConfig> recompensas,
    {Map<String, List<int>>? horariosEspecificos,
     Map<String, dynamic>? dadosAdicionais}
  ) async {
    // Log para depuração
    debugPrint('[PlanoEstudoService] Criando plano de estudo para usuário: $userId');
    if (dadosAdicionais != null) {
      debugPrint('[PlanoEstudoService] Dados adicionais recebidos com ${dadosAdicionais.keys.length} chaves: ${dadosAdicionais.keys.join(', ')}');
    }

    // Gerar sessões de estudo
    final List<SessaoEstudo> sessoesEstudo = _gerarSessoesEstudo(
      userId,
      dataInicio,
      dataFim,
      horasSemanais,
      materiasProficiencia,
      ferramentas,
      horariosEspecificos: horariosEspecificos,
    );

    // Criar mapa de metadados com dados adicionais
    final Map<String, dynamic> metadados = {};

    // Adicionar dados adicionais se fornecidos
    if (dadosAdicionais != null) {
      metadados.addAll(dadosAdicionais);

      // Verificar se há dados de prova
      if (dadosAdicionais.containsKey('prova')) {
        debugPrint('[PlanoEstudoService] Dados de prova encontrados nos dados adicionais');
      }

      // Verificar se há conteúdo programático
      if (dadosAdicionais.containsKey('conteudo_programatico')) {
        debugPrint('[PlanoEstudoService] Conteúdo programático encontrado nos dados adicionais');
      }

      // Verificar se há dados de concurso
      if (dadosAdicionais.containsKey('concurso')) {
        debugPrint('[PlanoEstudoService] Dados de concurso encontrados nos dados adicionais');
      }
    }

    final plano = PlanoEstudo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      editalId: editalId ?? '',
      cargoIds: cargoIds,
      dataCriacao: DateTime.now(),
      dataInicio: dataInicio,
      dataFim: dataFim,
      horasSemanais: horasSemanais,
      ferramentas: ferramentas,
      materiasProficiencia: materiasProficiencia,
      recompensas: recompensas,
      sessoesEstudo: sessoesEstudo,
      metadados: metadados,
    );

    _planos.add(plano);
    await _savePlanos();
    notifyListeners();

    debugPrint('[PlanoEstudoService] Plano criado com ID: ${plano.id}');
    debugPrint('[PlanoEstudoService] Metadados do plano contém ${plano.metadados.keys.length} chaves');

    return plano;
  }

  // Gerar sessões de estudo para um plano
  List<SessaoEstudo> _gerarSessoesEstudo(
    String userId,
    DateTime dataInicio,
    DateTime dataFim,
    Map<String, int> horasSemanais,
    List<MateriaProficiencia> materiasProficiencia,
    List<String> ferramentas,
    {Map<String, List<int>>? horariosEspecificos}
  ) {
    final List<SessaoEstudo> sessoes = [];
    final diasDaSemana = ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];

    // Verificar se há matérias para gerar sessões
    if (materiasProficiencia.isEmpty) {
      debugPrint('Erro ao gerar sessões: Lista de matérias vazia');
      return [];
    }

    // Ordenar matérias por prioridade (menor proficiência primeiro)
    final materias = List<MateriaProficiencia>.from(materiasProficiencia)
      ..sort((a, b) => a.nivelProficiencia.compareTo(b.nivelProficiencia));

    debugPrint('Gerando sessões para ${materias.length} matérias: ${materias.map((m) => "${m.nomeMateria} (${m.nivelProficiencia})").join(", ")}');

    // Calcular dias entre início e fim
    final diasTotais = dataFim.difference(dataInicio).inDays + 1;

    // Para cada dia no período do plano
    for (int dia = 0; dia < diasTotais; dia++) {
      final dataAtual = dataInicio.add(Duration(days: dia));
      final diaDaSemana = diasDaSemana[dataAtual.weekday - 1]; // 0 = segunda, 6 = domingo

      // Verificar se há horas disponíveis neste dia
      final horasDisponiveis = horasSemanais[diaDaSemana] ?? 0;

      if (horasDisponiveis > 0) {
        // Verificar se há horários específicos para este dia
        final List<int> horariosDoDia = horariosEspecificos?[diaDaSemana] ?? [];

        // Se não houver horários específicos, usar horários padrão
        final List<int> horariosParaUsar = horariosDoDia.isNotEmpty
            ? horariosDoDia
            : List.generate(horasDisponiveis, (index) => 18 + index); // Começar às 18h por padrão

        // Limitar a quantidade de horários ao número de horas disponíveis
        final List<int> horariosLimitados = horariosParaUsar.length > horasDisponiveis
            ? horariosParaUsar.sublist(0, horasDisponiveis)
            : horariosParaUsar;

        // Distribuir as matérias pelos horários disponíveis
        // Usar um índice baseado no dia da semana para variar as matérias
        int materiaIndex = dia % materias.length;

        for (final horaInicio in horariosLimitados) {
          // Selecionar matéria com base no índice e na hora
          // Isso garante uma distribuição mais equilibrada das matérias
          final materiaPos = (materiaIndex + horaInicio) % materias.length;
          final materia = materias[materiaPos];

          // Selecionar ferramentas de estudo de forma variada
          final List<String> ferramentasSessao = [];
          if (ferramentas.isNotEmpty) {
            // Verificar se a matéria é jurídica para usar a ferramenta "Lei seca"
            bool isJuridica = _isMateriasJuridica(materia.nomeMateria);

            // Criar uma lista de ferramentas disponíveis para esta matéria
            List<String> ferramentasDisponiveis = List.from(ferramentas);

            // Remover "Lei Seca" se não for matéria jurídica
            if (!isJuridica && (
                ferramentasDisponiveis.contains('Lei Seca') ||
                ferramentasDisponiveis.contains('lei_seca') ||
                ferramentasDisponiveis.contains('Lei seca')
            )) {
              ferramentasDisponiveis.removeWhere((f) =>
                f == 'Lei Seca' || f == 'lei_seca' || f == 'Lei seca'
              );
            }

            // Se não houver ferramentas disponíveis após a filtragem, usar todas as ferramentas
            if (ferramentasDisponiveis.isEmpty) {
              ferramentasDisponiveis = List.from(ferramentas);
            }

            // Adicionar 1-2 ferramentas por sessão
            final numFerramentas = 1 + (materiaPos % 2); // 1 ou 2 ferramentas
            for (int i = 0; i < numFerramentas && i < ferramentasDisponiveis.length; i++) {
              final ferramentaIndex = (materiaPos + i) % ferramentasDisponiveis.length;
              ferramentasSessao.add(ferramentasDisponiveis[ferramentaIndex]);
            }
          } else {
            ferramentasSessao.add('livro');
          }

          // Criar uma sessão de estudo de 1 hora
          final sessao = SessaoEstudo(
            id: '${userId}_${dataAtual.toIso8601String()}_$horaInicio',
            planoId: 'temp', // Será atualizado depois
            materiaId: 'materia_${materia.nomeMateria.replaceAll(' ', '_').toLowerCase()}',
            materia: materia.nomeMateria,
            assuntoIds: [],
            dataHoraInicio: DateTime(
              dataAtual.year,
              dataAtual.month,
              dataAtual.day,
              horaInicio,
              0,
            ),
            dataHoraFim: DateTime(
              dataAtual.year,
              dataAtual.month,
              dataAtual.day,
              horaInicio + 1,
              0,
            ),
            duracaoMinutos: 60,
            ferramentas: ferramentasSessao,
          );

          sessoes.add(sessao);
          materiaIndex++;
        }
      }
    }

    return sessoes;
  }

  // Obter um plano pelo ID
  PlanoEstudo? getPlanoById(String id) {
    try {
      return _planos.firstWhere((plano) => plano.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obter planos de um usuário
  List<PlanoEstudo> getPlanosByUserId(String userId) {
    return _planos.where((plano) => plano.userId == userId).toList();
  }

  // Obter itens de cronograma de um plano
  List<CronogramaItem> getCronogramaByPlanoId(String planoId) {
    return _cronogramaItems.where((item) => item.planoId == planoId).toList();
  }

  // Obter itens de cronograma para uma data específica
  List<CronogramaItem> getCronogramaByDate(DateTime data) {
    return _cronogramaItems.where((item) =>
      item.dataHoraInicio.year == data.year &&
      item.dataHoraInicio.month == data.month &&
      item.dataHoraInicio.day == data.day
    ).toList();
  }

  // Atualizar status de um item de cronograma
  Future<bool> updateCronogramaItemStatus(String itemId, StatusItem novoStatus) async {
    final index = _cronogramaItems.indexWhere((item) => item.id == itemId);

    if (index != -1) {
      _cronogramaItems[index] = _cronogramaItems[index].copyWith(status: novoStatus);
      await _saveCronograma();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Remover um plano e seu cronograma
  Future<bool> removePlano(String id) async {
    final index = _planos.indexWhere((plano) => plano.id == id);

    if (index != -1) {
      _planos.removeAt(index);
      _cronogramaItems.removeWhere((item) => item.planoId == id);

      await _savePlanos();
      await _saveCronograma();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Métodos para gerenciar matérias

  // Adicionar uma nova matéria
  Future<Materia> addMateria(String nome, String? editalId, String? cargoId, int nivelProficiencia) async {
    final materia = Materia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      editalId: editalId,
      cargoId: cargoId,
      nivelProficiencia: nivelProficiencia,
    );

    _materias.add(materia);
    await _saveMaterias();
    notifyListeners();
    return materia;
  }

  // Obter matérias por edital e cargo
  List<Materia> getMateriasByEditalAndCargo(String? editalId, String? cargoId) {
    return _materias.where((materia) =>
      (editalId == null || materia.editalId == editalId) &&
      (cargoId == null || materia.cargoId == cargoId)
    ).toList();
  }

  // Obter uma matéria pelo ID
  Materia? getMateriaById(String id) {
    try {
      return _materias.firstWhere((materia) => materia.id == id);
    } catch (e) {
      return null;
    }
  }

  // Atualizar uma matéria
  Future<bool> updateMateria(Materia materia) async {
    final index = _materias.indexWhere((m) => m.id == materia.id);

    if (index != -1) {
      _materias[index] = materia;
      await _saveMaterias();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Remover uma matéria
  Future<bool> removeMateria(String id) async {
    final index = _materias.indexWhere((materia) => materia.id == id);

    if (index != -1) {
      _materias.removeAt(index);
      // Remover também os assuntos relacionados
      _assuntos.removeWhere((assunto) => assunto.materiaId == id);

      await _saveMaterias();
      await _saveAssuntos();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Métodos para gerenciar assuntos

  // Adicionar um novo assunto
  Future<Assunto> addAssunto(String nome, String materiaId, int ordem) async {
    final assunto = Assunto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      materiaId: materiaId,
      ordem: ordem,
    );

    _assuntos.add(assunto);
    await _saveAssuntos();
    notifyListeners();
    return assunto;
  }

  // Obter assuntos por matéria
  List<Assunto> getAssuntosByMateria(String materiaId) {
    return _assuntos
      .where((assunto) => assunto.materiaId == materiaId)
      .toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
  }

  // Obter um assunto pelo ID
  Assunto? getAssuntoById(String id) {
    try {
      return _assuntos.firstWhere((assunto) => assunto.id == id);
    } catch (e) {
      return null;
    }
  }

  // Atualizar um assunto
  Future<bool> updateAssunto(Assunto assunto) async {
    final index = _assuntos.indexWhere((a) => a.id == assunto.id);

    if (index != -1) {
      _assuntos[index] = assunto;
      await _saveAssuntos();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Marcar um assunto como estudado
  Future<bool> marcarAssuntoComoEstudado(String id, bool isEstudado) async {
    final index = _assuntos.indexWhere((assunto) => assunto.id == id);

    if (index != -1) {
      _assuntos[index] = _assuntos[index].copyWith(isEstudado: isEstudado);
      await _saveAssuntos();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Remover um assunto
  Future<bool> removeAssunto(String id) async {
    final index = _assuntos.indexWhere((assunto) => assunto.id == id);

    if (index != -1) {
      _assuntos.removeAt(index);
      await _saveAssuntos();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Verificar se uma matéria é jurídica
  bool _isMateriasJuridica(String nomeMateria) {
    final nomeLower = nomeMateria.toLowerCase();

    // Lista de termos que indicam matérias jurídicas
    final termos = [
      'direito',
      'constitucional',
      'administrativo',
      'civil',
      'penal',
      'processual',
      'tributário',
      'trabalho',
      'previdenciário',
      'legislação',
      'lei',
      'código',
      'jurídico',
      'jurídica',
    ];

    // Verificar se o nome da matéria contém algum dos termos
    for (final termo in termos) {
      if (nomeLower.contains(termo)) {
        return true;
      }
    }

    return false;
  }

  // Gerar sessões para um plano de estudo
  Future<List<SessaoEstudo>> gerarSessoesParaPlano(String planoId) async {
    final plano = getPlanoById(planoId);
    if (plano == null) {
      throw Exception('Plano não encontrado');
    }

    try {
      // Verificar se há matérias para gerar sessões
      if (plano.materiasProficiencia.isEmpty) {
        debugPrint('Erro ao gerar sessões: Não há matérias configuradas no plano');
        return [];
      }

      // Verificar se há horas configuradas
      if (plano.horasSemanais.isEmpty) {
        debugPrint('Erro ao gerar sessões: Não há horas semanais configuradas no plano');
        return [];
      }

      // Converter as chaves do mapa horasSemanais para minúsculas para compatibilidade
      Map<String, int> horasSemanaisNormalizado = {};
      plano.horasSemanais.forEach((key, value) {
        String chaveNormalizada = key;
        if (key == 'Segunda') {
          chaveNormalizada = 'segunda';
        } else if (key == 'Terça') chaveNormalizada = 'terca';
        else if (key == 'Quarta') chaveNormalizada = 'quarta';
        else if (key == 'Quinta') chaveNormalizada = 'quinta';
        else if (key == 'Sexta') chaveNormalizada = 'sexta';
        else if (key == 'Sábado') chaveNormalizada = 'sabado';
        else if (key == 'Domingo') chaveNormalizada = 'domingo';
        horasSemanaisNormalizado[chaveNormalizada] = value;
      });

      // Verificar se há horas configuradas após a normalização
      if (horasSemanaisNormalizado.isEmpty) {
        debugPrint('Erro ao gerar sessões: Não há horas semanais válidas após normalização');
        return [];
      }

      // Verificar se há pelo menos um dia com horas > 0
      bool temHorasDisponiveis = false;
      horasSemanaisNormalizado.forEach((dia, horas) {
        if (horas > 0) temHorasDisponiveis = true;
      });

      if (!temHorasDisponiveis) {
        debugPrint('Erro ao gerar sessões: Todos os dias estão configurados com 0 horas');
        return [];
      }

      // Gerar sessões de estudo com base no plano
      final List<SessaoEstudo> sessoes = _gerarSessoesEstudo(
        plano.userId,
        plano.dataInicio,
        plano.dataFim,
        horasSemanaisNormalizado, // Usar o mapa normalizado
        plano.materiasProficiencia,
        plano.ferramentas,
        horariosEspecificos: plano.metadados.containsKey('horariosEspecificos') ?
            (plano.metadados['horariosEspecificos'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as List<dynamic>).cast<int>())
            ) : null,
      );

      // Atualizar o ID do plano nas sessões
      for (int i = 0; i < sessoes.length; i++) {
        sessoes[i] = sessoes[i].copyWith(planoId: planoId);
      }

      // Persistir as sessões no plano e salvar
      final planoAtualizado = plano.copyWith(
        sessoesEstudo: [...plano.sessoesEstudo, ...sessoes]
      );

      // Atualizar o plano na lista
      final index = _planos.indexWhere((p) => p.id == planoId);
      if (index != -1) {
        _planos[index] = planoAtualizado;
      }

      await _savePlanos();
      notifyListeners();

      return sessoes;
    } catch (e) {
      debugPrint('Erro ao gerar sessões de estudo: $e');
      return []; // Retornar lista vazia em caso de erro
    }
  }

  // Calcular o total de horas de estudo de um plano
  double calcularTotalHoras(String planoId) {
    final plano = getPlanoById(planoId);
    if (plano == null) return 0;

    // Calcular total de horas com base nas sessões de estudo
    double totalHoras = 0;
    for (var sessao in plano.sessoesEstudo) {
      totalHoras += sessao.duracaoMinutos / 60;
    }

    // Se não houver sessões, calcular com base nas horas semanais
    if (totalHoras == 0) {
      int totalHorasSemanais = 0;
      plano.horasSemanais.forEach((dia, horas) {
        totalHorasSemanais += horas;
      });

      // Calcular número de semanas no período do plano
      int diasTotais = plano.dataFim.difference(plano.dataInicio).inDays + 1;
      double semanas = diasTotais / 7;

      totalHoras = totalHorasSemanais * semanas;
    }

    return totalHoras;
  }

  // Calcular horas por matéria em um plano
  Map<String, double> calcularHorasPorMateria(String planoId) {
    final plano = getPlanoById(planoId);
    if (plano == null) {
      return {};
    }

    // Calcular horas por matéria
    final Map<String, double> horasPorMateria = {};
    for (final sessao in plano.sessoesEstudo) {
      final materia = sessao.materia;
      final horas = sessao.duracaoMinutos / 60.0;

      if (horasPorMateria.containsKey(materia)) {
        horasPorMateria[materia] = horasPorMateria[materia]! + horas;
      } else {
        horasPorMateria[materia] = horas;
      }
    }

    return horasPorMateria;
  }

  // Atualizar metadados de um plano
  Future<bool> atualizarMetadados(String planoId, Map<String, dynamic> novosMetadados) async {
    debugPrint('[PlanoEstudoService] Atualizando metadados do plano: $planoId');
    debugPrint('[PlanoEstudoService] Novos metadados com ${novosMetadados.keys.length} chaves: ${novosMetadados.keys.join(', ')}');

    final index = _planos.indexWhere((plano) => plano.id == planoId);

    if (index != -1) {
      // Criar uma cópia dos metadados atuais
      Map<String, dynamic> metadadosAtualizados = Map.from(_planos[index].metadados);

      // Adicionar ou atualizar com os novos metadados
      novosMetadados.forEach((key, value) {
        metadadosAtualizados[key] = value;
      });

      // Criar uma cópia do plano com os metadados atualizados
      _planos[index] = _planos[index].copyWith(
        metadados: metadadosAtualizados,
      );

      await _savePlanos();
      notifyListeners();

      debugPrint('[PlanoEstudoService] Metadados atualizados com sucesso. Total de chaves: ${metadadosAtualizados.keys.length}');
      return true;
    }

    debugPrint('[PlanoEstudoService] Plano não encontrado: $planoId');
    return false;
  }

  /// Atualiza os metadados do plano com os dados da resposta LLM
  Future<bool> atualizarMetadadosComRespostaLLM(String planoId, String jsonResponse) async {
    final plano = getPlanoById(planoId);
    if (plano == null) {
      debugPrint('[PlanoEstudoService] Plano não encontrado com ID: $planoId');
      return false;
    }

    try {
      // Extrair dados da resposta LLM
      await _planoDadosService.extrairDadosLLMParaPlano(plano, jsonResponse);

      // Salvar o plano atualizado
      await _savePlanos();
      notifyListeners();

      debugPrint('[PlanoEstudoService] Metadados do plano atualizados com sucesso: $planoId');
      return true;
    } catch (e) {
      debugPrint('[PlanoEstudoService] Erro ao atualizar metadados do plano: $e');
      return false;
    }
  }
}
