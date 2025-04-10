import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/edital.dart';

class EditalService extends ChangeNotifier {
  List<Edital> _editais = [];

  List<Edital> get editais => _editais;

  // Carregar editais do armazenamento local
  Future<void> loadEditais() async {
    final prefs = await SharedPreferences.getInstance();
    final editaisJson = prefs.getStringList('editais') ?? [];

    _editais = editaisJson.map((json) => Edital.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }

  // Salvar editais no armazenamento local
  Future<void> _saveEditais() async {
    final prefs = await SharedPreferences.getInstance();
    final editaisJson = _editais.map((edital) => jsonEncode(edital.toMap())).toList();

    await prefs.setStringList('editais', editaisJson);
  }

  // Adicionar um novo edital
  Future<Edital> addEdital(String userId, String nomeConcurso, String textoCompleto, DadosExtraidos dadosExtraidos, {Map<String, dynamic>? dadosOriginais}) async {
    final edital = Edital(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      nomeConcurso: nomeConcurso,
      textoCompleto: textoCompleto,
      dataUpload: DateTime.now(),
      dadosExtraidos: dadosExtraidos,
      dadosOriginais: dadosOriginais,
    );

    _editais.add(edital);
    await _saveEditais();
    notifyListeners();

    return edital;
  }

  // Obter um edital pelo ID
  Edital? getEditalById(String id) {
    try {
      return _editais.firstWhere((edital) => edital.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obter editais de um usuário
  List<Edital> getEditaisByUserId(String userId) {
    return _editais.where((edital) => edital.userId == userId).toList();
  }

  // Atualizar um edital
  Future<bool> updateEdital(Edital editalAtualizado) async {
    final index = _editais.indexWhere((edital) => edital.id == editalAtualizado.id);

    if (index != -1) {
      _editais[index] = editalAtualizado;
      await _saveEditais();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Remover um edital
  Future<bool> removeEdital(String id) async {
    final index = _editais.indexWhere((edital) => edital.id == id);

    if (index != -1) {
      _editais.removeAt(index);
      await _saveEditais();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Extrair dados de um edital (simulação)
  Future<DadosExtraidos> extrairDadosEdital(String textoEdital) async {
    // Simulação de processamento de extração
    await Future.delayed(Duration(seconds: 2));

    // Simulação de dados extraídos
    final cargo = Cargo(
      id: '1',
      nome: 'Analista Administrativo',
      vagas: 10,
      salario: 5000.0,
      escolaridade: 'Superior',
      conteudoProgramatico: [
        ConteudoProgramatico(nome: 'Língua Portuguesa', tipo: 'comum', topicos: ['Interpretação de texto', 'Gramática']),
        ConteudoProgramatico(nome: 'Raciocínio Lógico', tipo: 'comum', topicos: ['Lógica proposicional', 'Probabilidade']),
        ConteudoProgramatico(nome: 'Direito Administrativo', tipo: 'específico', topicos: ['Princípios', 'Atos administrativos']),
        ConteudoProgramatico(nome: 'Direito Constitucional', tipo: 'específico', topicos: ['Direitos fundamentais', 'Organização do Estado']),
        ConteudoProgramatico(nome: 'Administração Pública', tipo: 'específico', topicos: ['Gestão de pessoas', 'Orçamento público']),
      ],
      dataProva: DateTime.now().add(Duration(days: 90)),
    );

    final dadosExtraidos = DadosExtraidos(
      inicioInscricao: DateTime.now(),
      fimInscricao: DateTime.now().add(Duration(days: 30)),
      valorTaxa: 100.0,
      cargos: [cargo],
      localProva: 'Brasília - DF',
    );

    return dadosExtraidos;
  }
}
