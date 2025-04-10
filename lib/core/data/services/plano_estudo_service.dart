import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/materia.dart';
import '../models/assunto.dart';

class PlanoEstudoService extends ChangeNotifier {
  List<PlanoEstudo> _planos = [];
  List<CronogramaItem> _cronogramaItems = [];
  List<Materia> _materias = [];
  List<Assunto> _assuntos = [];

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
  ) async {
    // Gerar sessões de estudo
    final List<SessaoEstudo> sessoesEstudo = _gerarSessoesEstudo(
      userId,
      dataInicio,
      dataFim,
      horasSemanais,
      materiasProficiencia,
      ferramentas,
    );

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
    );

    _planos.add(plano);
    await _savePlanos();
    notifyListeners();
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
  ) {
    final List<SessaoEstudo> sessoes = [];
    final diasDaSemana = ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];

    // Ordenar matérias por prioridade (menor proficiência primeiro)
    final materias = List<MateriaProficiencia>.from(materiasProficiencia)
      ..sort((a, b) => a.nivelProficiencia.compareTo(b.nivelProficiencia));

    // Calcular dias entre início e fim
    final diasTotais = dataFim.difference(dataInicio).inDays + 1;

    // Para cada dia no período do plano
    for (int dia = 0; dia < diasTotais; dia++) {
      final dataAtual = dataInicio.add(Duration(days: dia));
      final diaDaSemana = diasDaSemana[dataAtual.weekday - 1]; // 0 = segunda, 6 = domingo

      // Verificar se há horas disponíveis neste dia
      final horasDisponiveis = horasSemanais[diaDaSemana] ?? 0;

      if (horasDisponiveis > 0) {
        // Distribuir as horas entre as matérias
        int horasRestantes = horasDisponiveis;
        int materiaIndex = 0;

        while (horasRestantes > 0 && materias.isNotEmpty) {
          final materia = materias[materiaIndex % materias.length];

          // Criar uma sessão de estudo de 1 hora
          final horaInicio = 18 + (horasDisponiveis - horasRestantes); // Começar às 18h
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
            ferramentas: ferramentas.isNotEmpty
              ? [ferramentas[materiaIndex % ferramentas.length]]
              : ['livro'],
          );

          sessoes.add(sessao);

          horasRestantes--;
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
}
