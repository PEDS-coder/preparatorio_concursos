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

        // Depuração para verificar os dados recebidos
        print('Processando matéria: ${itemMap['nome']}');
        print('  Tipo: ${itemMap['tipo']}');
        if (itemMap.containsKey('numero_questoes')) {
          print('  Número de questões (original): ${itemMap['numero_questoes']} (${itemMap['numero_questoes'].runtimeType})');
        } else {
          print('  Número de questões não encontrado no JSON');
        }

        // Processar o número de questões
        int? numeroQuestoes;
        if (itemMap.containsKey('numero_questoes')) {
          var numQuestoesValue = itemMap['numero_questoes'];
          if (numQuestoesValue is int) {
            numeroQuestoes = numQuestoesValue;
            print('  Número de questões (processado como int): $numeroQuestoes');
          } else if (numQuestoesValue is String) {
            try {
              numeroQuestoes = int.tryParse(numQuestoesValue);
              print('  Número de questões (convertido de string): $numeroQuestoes');
            } catch (e) {
              print('  Erro ao converter número de questões de string: $e');
            }
          } else if (numQuestoesValue is double) {
            numeroQuestoes = numQuestoesValue.toInt();
            print('  Número de questões (convertido de double): $numeroQuestoes');
          } else {
            print('  Tipo não suportado para número de questões: ${numQuestoesValue.runtimeType}');
          }
        }

        novoConteudoProgramatico.add(
          ConteudoProgramatico(
            nome: itemMap['nome'] as String,
            tipo: itemMap['tipo'] as String,
            topicos: (itemMap['topicos'] as List<dynamic>).cast<String>(),
            pesoMaior: itemMap['peso_maior'] as bool?,
            criterioDesempate: itemMap['criterio_desempate'] as bool?,
            numeroQuestoes: numeroQuestoes,
          ),
        );

        print('  Matéria adicionada com número de questões: $numeroQuestoes');
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

      // Atualizar os dados originais com as informações do concurso, se disponíveis
      if (conteudoProgramatico.containsKey('concurso') &&
          conteudoProgramatico['concurso'] is Map<String, dynamic>) {

        // Se não houver dados originais, criar um novo mapa
        if (editalAtualizado.dadosOriginais == null) {
          editalAtualizado.dadosOriginais = {};
        }

        // Adicionar todas as informações do concurso aos dados originais
        final concursoMap = conteudoProgramatico['concurso'] as Map<String, dynamic>;
        concursoMap.forEach((key, value) {
          editalAtualizado.dadosOriginais![key] = value;
        });

        // Atualizar os dados extraídos do edital com as informações do concurso
        // Criar uma nova instância de DadosExtraidos com os valores atualizados
        editalAtualizado.dadosExtraidos = DadosExtraidos(
          titulo: concursoMap.containsKey('titulo') ? concursoMap['titulo'] as String? : editalAtualizado.dadosExtraidos.titulo,
          orgao: concursoMap.containsKey('orgao') ? concursoMap['orgao'] as String? : editalAtualizado.dadosExtraidos.orgao,
          banca: concursoMap.containsKey('banca') ? concursoMap['banca'] as String? : editalAtualizado.dadosExtraidos.banca,
          inicioInscricao: editalAtualizado.dadosExtraidos.inicioInscricao,
          fimInscricao: editalAtualizado.dadosExtraidos.fimInscricao,
          valorTaxa: concursoMap.containsKey('taxa_inscricao') ? concursoMap['taxa_inscricao'] : editalAtualizado.dadosExtraidos.valorTaxa,
          localProva: concursoMap.containsKey('local_prova') ? concursoMap['local_prova'] as String? : editalAtualizado.dadosExtraidos.localProva,
          dataProva: concursoMap.containsKey('datas_provas') && concursoMap['datas_provas'] is Map && (concursoMap['datas_provas'] as Map).containsKey('objetiva') ?
                    (concursoMap['datas_provas'] as Map)['objetiva'] as String? : editalAtualizado.dadosExtraidos.dataProva,
          cargos: editalAtualizado.dadosExtraidos.cargos,
          textoCompleto: editalAtualizado.dadosExtraidos.textoCompleto,
        );
        // Dados já atualizados na criação da nova instância de DadosExtraidos
      }

      // Atualizar os dados originais com as informações da prova, se disponíveis
      if (conteudoProgramatico.containsKey('prova') &&
          conteudoProgramatico['prova'] is Map<String, dynamic>) {

        // Se não houver dados originais, criar um novo mapa
        if (editalAtualizado.dadosOriginais == null) {
          editalAtualizado.dadosOriginais = {};
        }

        // Adicionar informações da prova aos dados originais
        editalAtualizado.dadosOriginais!['prova'] = conteudoProgramatico['prova'];
      }

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
