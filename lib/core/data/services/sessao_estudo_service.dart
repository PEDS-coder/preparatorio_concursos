import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/sessao_estudo.dart';

class SessaoEstudoService extends ChangeNotifier {
  List<SessaoEstudo> _sessoes = [];

  List<SessaoEstudo> get sessoes => _sessoes;

  // Carregar sessões do armazenamento local
  Future<void> loadSessoes() async {
    final prefs = await SharedPreferences.getInstance();
    final sessoesJson = prefs.getStringList('sessoes_estudo') ?? [];

    _sessoes = sessoesJson.map((json) => SessaoEstudo.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }

  // Salvar sessões no armazenamento local
  Future<void> _saveSessoes() async {
    final prefs = await SharedPreferences.getInstance();
    final sessoesJson = _sessoes.map((sessao) => jsonEncode(sessao.toMap())).toList();

    await prefs.setStringList('sessoes_estudo', sessoesJson);
  }

  // Adicionar uma nova sessão de estudo
  Future<SessaoEstudo> addSessao(
    String planoId,
    String materiaId,
    String materia,
    List<String> assuntoIds,
    DateTime dataHoraInicio,
    DateTime dataHoraFim,
    List<String> ferramentas,
    String? observacoes,
    {String tipoTimer = 'progressivo'}
  ) async {
    final sessao = SessaoEstudo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planoId: planoId,
      materiaId: materiaId,
      materia: materia,
      assuntoIds: assuntoIds,
      dataHoraInicio: dataHoraInicio,
      dataHoraFim: dataHoraFim,
      duracaoMinutos: SessaoEstudo.calcularDuracao(dataHoraInicio, dataHoraFim),
      ferramentas: ferramentas,
      observacoes: observacoes,
      tipoTimer: tipoTimer,
    );

    _sessoes.add(sessao);
    await _saveSessoes();
    notifyListeners();

    return sessao;
  }

  // Obter sessões de um plano
  List<SessaoEstudo> getSessoesByPlanoId(String planoId) {
    return _sessoes.where((sessao) => sessao.planoId == planoId).toList();
  }

  // Obter sessões de um período específico
  List<SessaoEstudo> getSessoesByPeriodo(String planoId, DateTime inicio, DateTime fim) {
    return _sessoes.where((sessao) =>
      sessao.planoId == planoId &&
      sessao.dataHoraInicio.isAfter(inicio) &&
      sessao.dataHoraFim.isBefore(fim)
    ).toList();
  }

  // Calcular tempo total de estudo (em minutos)
  int calcularTempoTotalEstudo(String planoId) {
    return _sessoes
      .where((sessao) => sessao.planoId == planoId)
      .fold(0, (total, sessao) => total + sessao.duracaoMinutos);
  }

  // Calcular tempo de estudo por matéria
  Map<String, int> calcularTempoEstudoPorMateria(String planoId) {
    final map = <String, int>{};

    for (final sessao in _sessoes.where((s) => s.planoId == planoId)) {
      map[sessao.materia] = (map[sessao.materia] ?? 0) + sessao.duracaoMinutos;
    }

    return map;
  }

  // Remover uma sessão
  Future<bool> removeSessao(String id) async {
    final index = _sessoes.indexWhere((sessao) => sessao.id == id);

    if (index != -1) {
      _sessoes.removeAt(index);
      await _saveSessoes();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Obter sessões por matéria
  List<SessaoEstudo> getSessoesByMateria(String materiaId) {
    return _sessoes.where((sessao) => sessao.materiaId == materiaId).toList();
  }

  // Obter sessões por assunto
  List<SessaoEstudo> getSessoesByAssunto(String assuntoId) {
    return _sessoes.where((sessao) => sessao.assuntoIds.contains(assuntoId)).toList();
  }

  // Atualizar uma sessão de estudo
  Future<bool> updateSessao(SessaoEstudo sessao) async {
    final index = _sessoes.indexWhere((s) => s.id == sessao.id);

    if (index != -1) {
      _sessoes[index] = sessao;
      await _saveSessoes();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Adicionar assuntos a uma sessão existente
  Future<bool> addAssuntosToSessao(String sessaoId, List<String> assuntoIds) async {
    final index = _sessoes.indexWhere((s) => s.id == sessaoId);

    if (index != -1) {
      final sessao = _sessoes[index];
      final novosAssuntos = List<String>.from(sessao.assuntoIds);

      // Adicionar apenas assuntos que ainda não estão na lista
      for (final assuntoId in assuntoIds) {
        if (!novosAssuntos.contains(assuntoId)) {
          novosAssuntos.add(assuntoId);
        }
      }

      _sessoes[index] = sessao.copyWith(assuntoIds: novosAssuntos);
      await _saveSessoes();
      notifyListeners();
      return true;
    }

    return false;
  }
}
