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

  // Atualizar o conteúdo programático de um cargo
  Future<void> atualizarConteudoProgramaticoCargo(String editalId, String cargoNome, Map<String, dynamic> conteudoProgramatico) async {
    // Encontrar o edital
    final editalIndex = _editais.indexWhere((edital) => edital.id == editalId);
    if (editalIndex == -1) {
      throw Exception('Edital não encontrado');
    }

    // Encontrar o cargo
    final cargoIndex = _editais[editalIndex].dadosExtraidos.cargos.indexWhere(
      (cargo) => cargo.nome == cargoNome || cargo.id == cargoNome
    );

    if (cargoIndex == -1) {
      throw Exception('Cargo não encontrado');
    }

    // Verificar se o conteúdo programático contém a chave 'conteudo_programatico'
    if (conteudoProgramatico.containsKey('conteudo_programatico')) {
      // Atualizar o conteúdo programático do cargo
      final List<dynamic> novoConteudo = conteudoProgramatico['conteudo_programatico'] as List<dynamic>;

      // Converter para o formato esperado pelo modelo
      final List<ConteudoProgramatico> novoConteudoProgramatico = [];

      for (final item in novoConteudo) {
        final Map<String, dynamic> itemMap = item as Map<String, dynamic>;

        novoConteudoProgramatico.add(
          ConteudoProgramatico(
            nome: itemMap['nome'] as String,
            tipo: itemMap['tipo'] as String,
            topicos: (itemMap['topicos'] as List<dynamic>).cast<String>(),
          ),
        );
      }

      // Criar uma cópia do edital para não modificar diretamente o objeto original
      final Edital editalAtualizado = Edital(
        id: _editais[editalIndex].id,
        userId: _editais[editalIndex].userId,
        nomeConcurso: _editais[editalIndex].nomeConcurso,
        textoCompleto: _editais[editalIndex].textoCompleto,
        dataUpload: _editais[editalIndex].dataUpload,
        dadosOriginais: _editais[editalIndex].dadosOriginais,
        dadosExtraidos: DadosExtraidos(
          titulo: _editais[editalIndex].dadosExtraidos.titulo,
          orgao: _editais[editalIndex].dadosExtraidos.orgao,
          banca: _editais[editalIndex].dadosExtraidos.banca,
          inicioInscricao: _editais[editalIndex].dadosExtraidos.inicioInscricao,
          fimInscricao: _editais[editalIndex].dadosExtraidos.fimInscricao,
          valorTaxa: _editais[editalIndex].dadosExtraidos.valorTaxa,
          localProva: _editais[editalIndex].dadosExtraidos.localProva,
          dataProva: _editais[editalIndex].dadosExtraidos.dataProva,
          cargos: List.from(_editais[editalIndex].dadosExtraidos.cargos),
        ),
      );

      // Atualizar o conteúdo programático do cargo
      editalAtualizado.dadosExtraidos.cargos[cargoIndex] = Cargo(
        id: editalAtualizado.dadosExtraidos.cargos[cargoIndex].id,
        nome: editalAtualizado.dadosExtraidos.cargos[cargoIndex].nome,
        vagas: editalAtualizado.dadosExtraidos.cargos[cargoIndex].vagas,
        salario: editalAtualizado.dadosExtraidos.cargos[cargoIndex].salario,
        escolaridade: editalAtualizado.dadosExtraidos.cargos[cargoIndex].escolaridade,
        dataProva: editalAtualizado.dadosExtraidos.cargos[cargoIndex].dataProva,
        conteudoProgramatico: novoConteudoProgramatico,
      );

      // Atualizar o edital na lista
      _editais[editalIndex] = editalAtualizado;

      // Salvar as alterações
      await _saveEditais();
      notifyListeners();
    }
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
