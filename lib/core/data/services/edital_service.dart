import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/edital.dart';
import '../models/cota.dart';
import '../models/dados_vaga.dart';

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
  Future<Edital> addEdital(String userId, String nomeConcurso, String textoCompleto, DadosExtraidos dadosExtraidos, {Map<String, dynamic>? dadosOriginais, String? id, Uint8List? pdfBytes, String? nomeArquivo}) async {
    final edital = Edital(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      nomeConcurso: nomeConcurso,
      textoCompleto: textoCompleto,
      dataUpload: DateTime.now(),
      dadosExtraidos: dadosExtraidos,
      dadosOriginais: dadosOriginais,
      pdfBytes: pdfBytes,
      nomeArquivo: nomeArquivo,
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
    // Log para depuração
    print('[EditalService] Atualizando conteúdo programático para cargo: $cargoNome');
    print('[EditalService] Chaves recebidas: ${conteudoProgramatico.keys.join(', ')}');

    // Encontrar o edital
    final editalIndex = _editais.indexWhere((edital) => edital.id == editalId);
    if (editalIndex == -1) {
      print('[EditalService] Edital não encontrado: $editalId');
      throw Exception('Edital não encontrado');
    }

    // Encontrar o cargo
    final cargoIndex = _editais[editalIndex].dadosExtraidos.cargos.indexWhere(
      (cargo) => cargo.nome == cargoNome || cargo.id == cargoNome
    );

    if (cargoIndex == -1) {
      print('[EditalService] Cargo não encontrado: $cargoNome');
      throw Exception('Cargo não encontrado');
    }

    // Criar uma cópia do edital para não modificar diretamente o objeto original
    final Edital editalAtualizado = Edital(
      id: _editais[editalIndex].id,
      userId: _editais[editalIndex].userId,
      nomeConcurso: _editais[editalIndex].nomeConcurso,
      textoCompleto: _editais[editalIndex].textoCompleto,
      dataUpload: _editais[editalIndex].dataUpload,
      dadosOriginais: _editais[editalIndex].dadosOriginais ?? {},
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

    // Armazenar a resposta completa nos dados originais
    editalAtualizado.dadosOriginais!['resposta_completa'] = conteudoProgramatico;

    // Processar dados da prova
    if (conteudoProgramatico.containsKey('prova') && conteudoProgramatico['prova'] is Map<String, dynamic>) {
      print('[EditalService] Processando dados da prova');
      final provaMap = conteudoProgramatico['prova'] as Map<String, dynamic>;

      // Armazenar dados da prova nos dados originais
      editalAtualizado.dadosOriginais!['prova'] = provaMap;

      // Atualizar dados extraídos com informações da prova
      DadosProva dadosProva = DadosProva();

      // Total de questões
      if (provaMap.containsKey('total_questoes')) {
        var totalQuestoes = provaMap['total_questoes'];
        if (totalQuestoes is int) {
          dadosProva.totalQuestoes = totalQuestoes;
        } else if (totalQuestoes is String) {
          dadosProva.totalQuestoes = int.tryParse(totalQuestoes);
        } else if (totalQuestoes is double) {
          dadosProva.totalQuestoes = totalQuestoes.toInt();
        }
        print('[EditalService] Total de questões: ${dadosProva.totalQuestoes}');
      }

      // Formato da prova
      if (provaMap.containsKey('formato')) {
        var formato = provaMap['formato'];
        if (formato is List) {
          dadosProva.formato = (formato).map((item) => item.toString()).toList();
        } else if (formato is String) {
          dadosProva.formato = [formato];
        }
        print('[EditalService] Formato da prova: ${dadosProva.formato?.join(', ')}');
      }

      // Tema da prova discursiva
      if (provaMap.containsKey('tema_discursiva')) {
        dadosProva.temaDiscursiva = provaMap['tema_discursiva']?.toString();
        print('[EditalService] Tema da prova discursiva: ${dadosProva.temaDiscursiva}');
      }

      // Critérios de aprovação
      if (provaMap.containsKey('criterios_aprovacao')) {
        dadosProva.criteriosAprovacao = provaMap['criterios_aprovacao']?.toString();
        print('[EditalService] Critérios de aprovação: ${dadosProva.criteriosAprovacao}');
      }

      // Critérios de reprovação
      if (provaMap.containsKey('criterios_reprovacao')) {
        dadosProva.criteriosReprovacao = provaMap['criterios_reprovacao']?.toString();
        print('[EditalService] Critérios de reprovação: ${dadosProva.criteriosReprovacao}');
      }

      // Critérios de desempate
      if (provaMap.containsKey('criterios_desempate')) {
        var criterios = provaMap['criterios_desempate'];
        if (criterios is List) {
          dadosProva.criteriosDesempate = (criterios).map((item) => item.toString()).toList();
        } else if (criterios is String) {
          dadosProva.criteriosDesempate = [criterios];
        }
        print('[EditalService] Critérios de desempate: ${dadosProva.criteriosDesempate?.join(', ')}');
      }

      // Duração da prova
      if (provaMap.containsKey('duracao')) {
        dadosProva.duracao = provaMap['duracao']?.toString();
        print('[EditalService] Duração da prova: ${dadosProva.duracao}');
      }

      // Data da prova
      if (provaMap.containsKey('data')) {
        String dataStr = provaMap['data']?.toString() ?? '';
        if (dataStr.isNotEmpty) {
          editalAtualizado.dadosExtraidos.dataProva = dataStr;
          print('[EditalService] Data da prova atualizada: $dataStr');
        }
      }

      // Local da prova
      if (provaMap.containsKey('local')) {
        String localStr = provaMap['local']?.toString() ?? '';
        if (localStr.isNotEmpty) {
          editalAtualizado.dadosExtraidos.localProva = localStr;
          print('[EditalService] Local da prova atualizado: $localStr');
        }
      }

      // Atualizar dados da prova
      editalAtualizado.dadosExtraidos.dadosProva = dadosProva;
    }

    // Processar dados de cotas
    if (conteudoProgramatico.containsKey('cotas') && conteudoProgramatico['cotas'] is List) {
      print('[EditalService] Processando dados de cotas');
      final cotasList = conteudoProgramatico['cotas'] as List;

      // Armazenar dados de cotas nos dados originais
      editalAtualizado.dadosOriginais!['cotas'] = cotasList;

      // Converter para o formato esperado pelo modelo
      List<Cota> cotas = [];
      for (var cotaItem in cotasList) {
        if (cotaItem is Map) {
          String nome = cotaItem['nome']?.toString() ?? '';
          double? percentual;

          if (cotaItem.containsKey('percentual')) {
            var percentualValue = cotaItem['percentual'];
            if (percentualValue is int) {
              percentual = percentualValue.toDouble();
            } else if (percentualValue is double) {
              percentual = percentualValue;
            } else if (percentualValue is String) {
              percentual = double.tryParse(percentualValue);
            }
          }

          if (nome.isNotEmpty) {
            cotas.add(Cota(nome: nome, percentual: percentual));
            print('[EditalService] Cota adicionada: $nome (${percentual ?? 'sem percentual'})');
          }
        }
      }

      // Atualizar cotas
      editalAtualizado.dadosExtraidos.cotas = cotas.map((cota) =>
        DadosCota(
          nome: cota.nome,
          percentual: cota.percentual?.toInt(),
          numeroVagas: cota.numeroVagas,
          criterios: cota.criterios
        )
      ).toList();
    }

    // Processar dados de vagas
    if (conteudoProgramatico.containsKey('vagas') && conteudoProgramatico['vagas'] is Map) {
      print('[EditalService] Processando dados de vagas');
      final vagasMap = conteudoProgramatico['vagas'] as Map<String, dynamic>;

      // Armazenar dados de vagas nos dados originais
      editalAtualizado.dadosOriginais!['vagas'] = vagasMap;

      // Converter para o formato esperado pelo modelo
      DadosVaga dadosVaga = DadosVaga();

      // Vagas imediatas
      if (vagasMap.containsKey('imediatas')) {
        var imediatas = vagasMap['imediatas'];
        if (imediatas is int) {
          dadosVaga.imediatas = imediatas;
        } else if (imediatas is String) {
          dadosVaga.imediatas = int.tryParse(imediatas);
        } else if (imediatas is double) {
          dadosVaga.imediatas = imediatas.toInt();
        }
      }

      // Cadastro reserva
      if (vagasMap.containsKey('cadastro_reserva')) {
        dadosVaga.cadastroReserva = vagasMap['cadastro_reserva'] == true;
      }

      // Total consolidado
      if (vagasMap.containsKey('total_consolidado')) {
        var total = vagasMap['total_consolidado'];
        if (total is int) {
          dadosVaga.totalConsolidado = total;
        } else if (total is String) {
          dadosVaga.totalConsolidado = int.tryParse(total);
        } else if (total is double) {
          dadosVaga.totalConsolidado = total.toInt();
        }
      }

      // Atualizar dados de vaga
      editalAtualizado.dadosExtraidos.dadosVaga = dadosVaga;
      print('[EditalService] Dados de vaga atualizados: imediatas=${dadosVaga.imediatas}, CR=${dadosVaga.cadastroReserva}, total=${dadosVaga.totalConsolidado}');
    }

    // Verificar se o conteúdo programático contém a chave 'conteudo_programatico'
    if (conteudoProgramatico.containsKey('conteudo_programatico')) {
      print('[EditalService] Processando conteúdo programático');
      // Atualizar o conteúdo programático do cargo
      final List<dynamic> novoConteudo = conteudoProgramatico['conteudo_programatico'] as List<dynamic>;

      // Converter para o formato esperado pelo modelo
      final List<ConteudoProgramatico> novoConteudoProgramatico = [];

      for (final item in novoConteudo) {
        final Map<String, dynamic> itemMap = item as Map<String, dynamic>;

        // Depuração para verificar os dados recebidos
        print('[EditalService] Processando matéria: ${itemMap['nome']}');
        print('[EditalService]   Tipo: ${itemMap['tipo']}');
        if (itemMap.containsKey('numero_questoes')) {
          print('[EditalService]   Número de questões (original): ${itemMap['numero_questoes']} (${itemMap['numero_questoes'].runtimeType})');
        } else {
          print('[EditalService]   Número de questões não encontrado no JSON');
        }

        // Processar o número de questões
        int? numeroQuestoes;
        int? totalQuestoesGrupo;
        String? grupoMateria;

        // Processar o grupo da matéria
        if (itemMap.containsKey('grupo_materia')) {
          grupoMateria = itemMap['grupo_materia'] as String?;
          print('[EditalService]   Grupo da matéria: $grupoMateria');
        }

        // Processar o número total de questões do grupo
        if (itemMap.containsKey('total_questoes_grupo')) {
          var totalQuestoesValue = itemMap['total_questoes_grupo'];
          if (totalQuestoesValue is int) {
            totalQuestoesGrupo = totalQuestoesValue;
            print('[EditalService]   Total de questões do grupo (processado como int): $totalQuestoesGrupo');
          } else if (totalQuestoesValue is String) {
            try {
              totalQuestoesGrupo = int.tryParse(totalQuestoesValue);
              print('[EditalService]   Total de questões do grupo (convertido de string): $totalQuestoesGrupo');
            } catch (e) {
              print('[EditalService]   Erro ao converter total de questões do grupo de string: $e');
            }
          } else if (totalQuestoesValue is double) {
            totalQuestoesGrupo = totalQuestoesValue.toInt();
            print('[EditalService]   Total de questões do grupo (convertido de double): $totalQuestoesGrupo');
          }
        }

        // Processar o número de questões da matéria
        if (itemMap.containsKey('numero_questoes')) {
          var numQuestoesValue = itemMap['numero_questoes'];
          if (numQuestoesValue is int) {
            numeroQuestoes = numQuestoesValue;
            print('[EditalService]   Número de questões (processado como int): $numeroQuestoes');
          } else if (numQuestoesValue is String) {
            try {
              numeroQuestoes = int.tryParse(numQuestoesValue);
              print('[EditalService]   Número de questões (convertido de string): $numeroQuestoes');
            } catch (e) {
              print('[EditalService]   Erro ao converter número de questões de string: $e');
            }
          } else if (numQuestoesValue is double) {
            numeroQuestoes = numQuestoesValue.toInt();
            print('[EditalService]   Número de questões (convertido de double): $numeroQuestoes');
          } else {
            print('[EditalService]   Tipo não suportado para número de questões: ${numQuestoesValue.runtimeType}');
          }
        }

        // Garantir que tópicos seja uma lista de strings
        List<String> topicos = [];
        if (itemMap.containsKey('topicos')) {
          var topicosValue = itemMap['topicos'];
          if (topicosValue is List) {
            topicos = topicosValue.map((t) => t.toString()).toList();
          }
        }

        novoConteudoProgramatico.add(
          ConteudoProgramatico(
            nome: itemMap['nome'] as String,
            tipo: itemMap['tipo'] as String,
            topicos: topicos,
            pesoMaior: itemMap['peso_maior'] as bool?,
            criterioDesempate: itemMap['criterio_desempate'] as bool?,
            numeroQuestoes: numeroQuestoes,
            totalQuestoesGrupo: totalQuestoesGrupo,
            grupoMateria: grupoMateria,
          ),
        );

        print('[EditalService]   Matéria adicionada com número de questões: $numeroQuestoes');
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
    }

    // Atualizar o edital na lista
    _editais[editalIndex] = editalAtualizado;

    // Salvar as alterações
    await _saveEditais();
    notifyListeners();

    print('[EditalService] Conteúdo programático atualizado com sucesso');
  }

  // Extrair dados de um edital (simulação)
  Future<DadosExtraidos> extrairDadosEdital(String textoEdital) async {
    // Simulação de processamento de extração
    await Future.delayed(const Duration(seconds: 2));

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
      dataProva: DateTime.now().add(const Duration(days: 90)),
    );

    final dadosExtraidos = DadosExtraidos(
      inicioInscricao: DateTime.now(),
      fimInscricao: DateTime.now().add(const Duration(days: 30)),
      valorTaxa: 100.0,
      cargos: [cargo],
      localProva: 'Brasília - DF',
    );

    return dadosExtraidos;
  }
}
