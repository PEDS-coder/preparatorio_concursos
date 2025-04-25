import 'package:flutter/foundation.dart';
import '../../core/data/models/edital.dart';

/// Classe utilitária para converter dados de cargos de diferentes formatos
class CargoConverter {
  /// Converte uma lista de dados JSON para uma lista de objetos Cargo
  static List<Cargo> converterCargos(List<dynamic> cargosJson) {
    try {
      // Verificar se a lista de cargos é válida
      if (cargosJson.isEmpty) {
        debugPrint('Lista de cargos vazia, criando cargo genérico');
        return [_criarCargoGenerico()];
      }

      return cargosJson.map<Cargo>((cargoJson) {
        try {
          // Validar o formato do cargo
          if (!_validarCargoJson(cargoJson)) {
            throw const FormatException('Formato de cargo inválido');
          }

          // Extrair dados básicos do cargo
          final Map<String, dynamic> dadosCargo = _extrairDadosBasicosCargo(cargoJson);

          // Processar conteúdo programático
          final List<ConteudoProgramatico> conteudoProgramatico =
              _processarConteudoProgramatico(cargoJson);

          // Criar e retornar o objeto Cargo
          return Cargo(
            id: DateTime.now().millisecondsSinceEpoch.toString() + dadosCargo['nome'],
            nome: dadosCargo['nome'],
            vagas: dadosCargo['vagas'],
            salario: dadosCargo['salario'],
            escolaridade: dadosCargo['escolaridade'],
            dataProva: null, // Será preenchido depois se disponível
            conteudoProgramatico: conteudoProgramatico.isEmpty ?
                _criarConteudoProgramaticoPadrao() : conteudoProgramatico,
          );
        } catch (e) {
          debugPrint('Erro ao converter cargo individual: $e');
          // Retornar um cargo padrão em caso de erro
          return _criarCargoErro();
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao converter lista de cargos: $e');
      // Retornar uma lista com um cargo padrão em caso de erro
      return [_criarCargoFallback()];
    }
  }

  /// Valida se o formato do JSON do cargo é válido
  static bool _validarCargoJson(dynamic cargoJson) {
    if (cargoJson is! Map<String, dynamic>) {
      debugPrint('Cargo não é um Map: $cargoJson');
      return false;
    }
    return true;
  }

  /// Extrai dados básicos do cargo (nome, vagas, salário, escolaridade)
  static Map<String, dynamic> _extrairDadosBasicosCargo(Map<String, dynamic> cargoJson) {
    // Extrair vagas
    int vagas = _extrairVagas(cargoJson);

    // Extrair salário
    double salario = _extrairSalario(cargoJson);

    // Extrair nome do cargo
    String nomeCargo = _extrairNomeCargo(cargoJson);

    // Extrair escolaridade
    String escolaridade = _extrairEscolaridade(cargoJson);

    return {
      'nome': nomeCargo,
      'vagas': vagas,
      'salario': salario,
      'escolaridade': escolaridade,
    };
  }

  /// Extrai o número de vagas do cargo
  static int _extrairVagas(Map<String, dynamic> cargoJson) {
    try {
      // Verificar se há um campo 'vagas' direto
      if (cargoJson.containsKey('vagas')) {
        var vagasValue = cargoJson['vagas'];

        // Se for um inteiro, usar diretamente
        if (vagasValue is int) {
          return vagasValue;
        }
        // Se for uma string, tentar converter para inteiro
        else if (vagasValue is String) {
          // Remover caracteres não numéricos
          final String vagasStr = vagasValue.replaceAll(RegExp(r'[^\d]'), '').trim();
          if (vagasStr.isNotEmpty) {
            return int.tryParse(vagasStr) ?? 0;
          }
        }
        // Se for um mapa, procurar por 'total'
        else if (vagasValue is Map && vagasValue.containsKey('total')) {
          var totalValue = vagasValue['total'];
          if (totalValue is int) {
            return totalValue;
          } else if (totalValue is String) {
            final String totalStr = totalValue.replaceAll(RegExp(r'[^\d]'), '').trim();
            if (totalStr.isNotEmpty) {
              return int.tryParse(totalStr) ?? 0;
            }
          }
        }
      }

      // Verificar campos alternativos
      final alternativeFields = ['quantidade_vagas', 'numero_vagas', 'total_vagas', 'qtd_vagas'];
      for (var field in alternativeFields) {
        if (cargoJson.containsKey(field)) {
          var value = cargoJson[field];
          if (value is int) {
            return value;
          } else if (value is String) {
            final String valueStr = value.replaceAll(RegExp(r'[^\d]'), '').trim();
            if (valueStr.isNotEmpty) {
              return int.tryParse(valueStr) ?? 0;
            }
          }
        }
      }

      // Se não encontrou nada, retornar 0
      return 0;
    } catch (e) {
      debugPrint('Erro ao extrair vagas: $e');
      return 0;
    }
  }

  /// Extrai o salário do cargo
  static double _extrairSalario(Map<String, dynamic> cargoJson) {
    try {
      // Lista de possíveis campos para salário
      final salaryFields = ['salario', 'remuneracao', 'vencimento', 'valor', 'remuneração', 'salário'];

      // Verificar cada campo possível
      for (var field in salaryFields) {
        if (cargoJson.containsKey(field)) {
          var value = cargoJson[field];

          // Se for um número, converter diretamente
          if (value is num) {
            return value.toDouble();
          }
          // Se for uma string, tentar extrair o valor numérico
          else if (value is String) {
            // Verificar se a string contém vírgula como separador decimal
            if (value.contains(',') && !value.contains('.')) {
              // Substituir vírgula por ponto para o parsing correto
              value = value.replaceAll(',', '.');
            }

            // Remover caracteres não numéricos, exceto ponto decimal
            final String valueStr = value.replaceAll(RegExp(r'[^\d.]'), '').trim();
            if (valueStr.isNotEmpty) {
              return double.tryParse(valueStr) ?? 0.0;
            }
          }
        }
      }

      // Se não encontrou nada, retornar 0.0
      return 0.0;
    } catch (e) {
      debugPrint('Erro ao extrair salário: $e');
      return 0.0;
    }
  }

  /// Extrai a escolaridade do cargo
  static String _extrairEscolaridade(Map<String, dynamic> cargoJson) {
    try {
      // Lista de possíveis campos para escolaridade
      final educationFields = ['escolaridade', 'nivel', 'formacao', 'requisito', 'nível', 'formação'];

      // Verificar cada campo possível
      for (var field in educationFields) {
        if (cargoJson.containsKey(field) &&
            cargoJson[field] != null &&
            cargoJson[field].toString().trim().isNotEmpty) {
          return cargoJson[field].toString().trim();
        }
      }

      // Se não encontrou nada, tentar inferir pela descrição ou nome do cargo
      if (cargoJson.containsKey('descricao') || cargoJson.containsKey('descrição')) {
        String descricao = (cargoJson['descricao'] ?? cargoJson['descrição'] ?? '').toString().toLowerCase();

        if (descricao.contains('superior') || descricao.contains('graduação')) {
          return 'Nível Superior';
        } else if (descricao.contains('médio') || descricao.contains('técnico')) {
          return 'Nível Médio';
        } else if (descricao.contains('fundamental')) {
          return 'Nível Fundamental';
        }
      }

      // Se não encontrou nada, retornar 'Não especificado'
      return 'Não especificado';
    } catch (e) {
      debugPrint('Erro ao extrair escolaridade: $e');
      return 'Não especificado';
    }
  }

  /// Extrai o nome do cargo
  static String _extrairNomeCargo(Map<String, dynamic> cargoJson) {
    try {
      // Lista de possíveis campos para nome do cargo
      final nameFields = ['nome', 'cargo', 'denominacao', 'denominação', 'titulo', 'título'];

      // Verificar cada campo possível
      for (var field in nameFields) {
        if (cargoJson.containsKey(field) &&
            cargoJson[field] != null &&
            cargoJson[field].toString().trim().isNotEmpty) {
          String nomeCargo = cargoJson[field].toString().trim();

          // Se o nome do cargo for muito genérico, tentar encontrar um nome mais específico
          if (nomeCargo == 'Cargo sem nome' || nomeCargo == 'Cargo não especificado') {
            return _inferirNomeCargo(cargoJson);
          }

          return nomeCargo;
        }
      }

      // Se não encontrou nada, tentar inferir pelo código ou área
      if (cargoJson.containsKey('codigo') || cargoJson.containsKey('código')) {
        String codigo = (cargoJson['codigo'] ?? cargoJson['código'] ?? '').toString();
        if (codigo.isNotEmpty) {
          return 'Cargo $codigo';
        }
      }

      if (cargoJson.containsKey('area') || cargoJson.containsKey('área')) {
        String area = (cargoJson['area'] ?? cargoJson['área'] ?? '').toString();
        if (area.isNotEmpty) {
          return 'Cargo - $area';
        }
      }

      // Se não encontrou nada, inferir pelo nível de escolaridade
      return _inferirNomeCargo(cargoJson);
    } catch (e) {
      debugPrint('Erro ao extrair nome do cargo: $e');
      return 'Cargo não identificado';
    }
  }



  /// Tenta inferir o nome do cargo com base em outras informações
  static String _inferirNomeCargo(Map<String, dynamic> cargoJson) {
    if (cargoJson['escolaridade'] != null) {
      String escolaridade = cargoJson['escolaridade'].toString().toLowerCase();
      if (escolaridade.contains('policial') || escolaridade.contains('militar')) {
        return 'Policial Militar';
      } else if (escolaridade.contains('superior')) {
        return 'Analista';
      } else if (escolaridade.contains('médio')) {
        return 'Técnico';
      }
    }
    return 'Cargo não identificado';
  }

  /// Processa o conteúdo programático do cargo
  static List<ConteudoProgramatico> _processarConteudoProgramatico(Map<String, dynamic> cargoJson) {
    List<ConteudoProgramatico> conteudoProgramatico = [];

    // Verificar se há conteúdo programático no formato de objeto aninhado
    if (cargoJson['conteudoProgramatico'] is Map<String, dynamic>) {
      conteudoProgramatico = _processarConteudoProgramaticoMapa(
        cargoJson['conteudoProgramatico'] as Map<String, dynamic>
      );
    }
    // Formato de lista (formato antigo)
    else if (cargoJson['conteudoProgramatico'] is List) {
      conteudoProgramatico = _processarConteudoProgramaticoLista(
        cargoJson['conteudoProgramatico'] as List
      );
    }
    // Formato de string (materias separadas por vírgula)
    else if (cargoJson['materias'] is List) {
      conteudoProgramatico = _processarMaterias(cargoJson['materias'] as List);
    }
    // Novo formato da LLM (conteudo_programatico)
    else if (cargoJson['conteudo_programatico'] is List) {
      conteudoProgramatico = _processarConteudoProgramaticoLista(
        cargoJson['conteudo_programatico'] as List
      );
    }

    return conteudoProgramatico;
  }

  /// Processa conteúdo programático no formato de mapa
  static List<ConteudoProgramatico> _processarConteudoProgramaticoMapa(Map<String, dynamic> conteudoMap) {
    List<ConteudoProgramatico> resultado = [];

    // Processar conteúdo comum
    _processarDisciplinaComum(conteudoMap, 'Língua Portuguesa', resultado);
    _processarDisciplinaComum(conteudoMap, 'Raciocínio Lógico', resultado);
    _processarDisciplinaComum(conteudoMap, 'Matemática', resultado);

    // Verificar se há conhecimentos específicos
    if (conteudoMap.containsKey('conhecimentos_especificos')) {
      final especificosMap = conteudoMap['conhecimentos_especificos'];
      if (especificosMap is Map<String, dynamic>) {
        // Extrair cada matéria específica
        especificosMap.forEach((materia, topicosData) {
          var topicos = _extrairTopicos(topicosData);

          // Verificar se há informações sobre número de questões, peso e critério de desempate
          int? numeroQuestoes;
          bool? pesoMaior;
          bool? criterioDesempate;

          // Verificar se topicosData é um mapa com informações adicionais
          if (topicosData is Map<String, dynamic>) {
            if (topicosData.containsKey('numero_questoes')) {
              var numQuestoesValue = topicosData['numero_questoes'];
              if (numQuestoesValue is int) {
                numeroQuestoes = numQuestoesValue;
              } else if (numQuestoesValue is String) {
                try {
                  numeroQuestoes = int.parse(numQuestoesValue);
                } catch (e) {
                  // Ignorar erro de parsing
                  print('Erro ao converter número de questões: $e');
                }
              } else if (numQuestoesValue is double) {
                numeroQuestoes = numQuestoesValue.toInt();
              }
              print('Número de questões para $materia: $numeroQuestoes');
            }

            if (topicosData.containsKey('peso_maior')) {
              pesoMaior = topicosData['peso_maior'] as bool?;
            }

            if (topicosData.containsKey('criterio_desempate')) {
              criterioDesempate = topicosData['criterio_desempate'] as bool?;
            }
          }

          // Verificar se o nome da matéria contém informações sobre o número de questões
          if (numeroQuestoes == null) {
            final RegExp regexQuestoes = RegExp(r'\(([0-9]+)\s*quest[\u00f5o]es\)', caseSensitive: false);
            final match = regexQuestoes.firstMatch(materia);
            if (match != null && match.groupCount >= 1) {
              try {
                numeroQuestoes = int.parse(match.group(1)!);
              } catch (e) {
                // Ignorar erro de parsing
              }
            }
          }

          resultado.add(ConteudoProgramatico(
            nome: materia,
            tipo: 'específico',
            topicos: topicos.isEmpty ? ['Conteúdo específico'] : topicos,
            numeroQuestoes: numeroQuestoes,
            pesoMaior: pesoMaior,
            criterioDesempate: criterioDesempate,
          ));
        });
      }
    }

    // Verificar se há conhecimentos gerais
    if (conteudoMap.containsKey('conhecimentos_gerais')) {
      final geraisMap = conteudoMap['conhecimentos_gerais'];
      if (geraisMap is Map<String, dynamic>) {
        // Extrair cada matéria de conhecimentos gerais
        geraisMap.forEach((materia, topicosData) {
          var topicos = _extrairTopicos(topicosData);
          resultado.add(ConteudoProgramatico(
            nome: materia,
            tipo: 'comum',
            topicos: topicos.isEmpty ? ['Conteúdo geral'] : topicos,
          ));
        });
      }
    }

    return resultado;
  }

  /// Processa uma disciplina comum do conteúdo programático
  static void _processarDisciplinaComum(
    Map<String, dynamic> conteudoMap,
    String nomeDisciplina,
    List<ConteudoProgramatico> resultado
  ) {
    if (conteudoMap.containsKey(nomeDisciplina)) {
      var topicos = _extrairTopicos(conteudoMap[nomeDisciplina]);

      // Verificar se há informações sobre número de questões, peso e critério de desempate
      int? numeroQuestoes;
      bool? pesoMaior;
      bool? criterioDesempate;

      // Verificar se o valor é um mapa com informações adicionais
      if (conteudoMap[nomeDisciplina] is Map<String, dynamic>) {
        final Map<String, dynamic> disciplinaMap = conteudoMap[nomeDisciplina] as Map<String, dynamic>;

        if (disciplinaMap.containsKey('numero_questoes')) {
          try {
            numeroQuestoes = int.parse(disciplinaMap['numero_questoes'].toString());
          } catch (e) {
            // Ignorar erro de parsing
          }
        }

        if (disciplinaMap.containsKey('peso_maior')) {
          pesoMaior = disciplinaMap['peso_maior'] as bool?;
        }

        if (disciplinaMap.containsKey('criterio_desempate')) {
          criterioDesempate = disciplinaMap['criterio_desempate'] as bool?;
        }
      }

      // Verificar se o nome da disciplina contém informações sobre o número de questões
      if (numeroQuestoes == null) {
        final RegExp regexQuestoes = RegExp(r'\(([0-9]+)\s*quest[\u00f5o]es\)', caseSensitive: false);
        final match = regexQuestoes.firstMatch(nomeDisciplina);
        if (match != null && match.groupCount >= 1) {
          try {
            numeroQuestoes = int.parse(match.group(1)!);
          } catch (e) {
            // Ignorar erro de parsing
          }
        }
      }

      resultado.add(ConteudoProgramatico(
        nome: nomeDisciplina,
        tipo: 'comum',
        topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
        numeroQuestoes: numeroQuestoes,
        pesoMaior: pesoMaior,
        criterioDesempate: criterioDesempate,
      ));
    }
  }

  /// Processa conteúdo programático no formato de lista
  static List<ConteudoProgramatico> _processarConteudoProgramaticoLista(List lista) {
    return lista.map((item) {
      if (item is Map<String, dynamic>) {
        // Extrair tópicos
        List<String> topicos = _extrairTopicosDeItem(item);

        // Verificar se há informações sobre número de questões, peso e critério de desempate
        int? numeroQuestoes;
        bool? pesoMaior;
        bool? criterioDesempate;

        if (item.containsKey('numero_questoes')) {
          try {
            numeroQuestoes = int.parse(item['numero_questoes'].toString());
          } catch (e) {
            // Ignorar erro de parsing
          }
        }

        if (item.containsKey('peso_maior')) {
          pesoMaior = item['peso_maior'] as bool?;
        }

        if (item.containsKey('criterio_desempate')) {
          criterioDesempate = item['criterio_desempate'] as bool?;
        }

        // Verificar se o nome da matéria contém informações sobre o número de questões
        final String nomeMateria = item['nome'] ?? 'Conteúdo não especificado';
        if (numeroQuestoes == null) {
          final RegExp regexQuestoes = RegExp(r'\(([0-9]+)\s*quest[\u00f5o]es\)', caseSensitive: false);
          final match = regexQuestoes.firstMatch(nomeMateria);
          if (match != null && match.groupCount >= 1) {
            try {
              numeroQuestoes = int.parse(match.group(1)!);
            } catch (e) {
              // Ignorar erro de parsing
            }
          }
        }

        return ConteudoProgramatico(
          nome: nomeMateria,
          tipo: item['tipo'] ?? 'comum',
          topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
          numeroQuestoes: numeroQuestoes,
          pesoMaior: pesoMaior,
          criterioDesempate: criterioDesempate,
        );
      } else if (item is String) {
        // Se for uma string, verificar se é uma matéria comum
        final String nomeMateria = item.toString().trim();
        List<String> topicos = _inferirTopicosPorMateria(nomeMateria);

        // Verificar se o nome da matéria contém informações sobre o número de questões
        int? numeroQuestoes;
        final RegExp regexQuestoes = RegExp(r'\(([0-9]+)\s*quest[\u00f5o]es\)', caseSensitive: false);
        final match = regexQuestoes.firstMatch(nomeMateria);
        if (match != null && match.groupCount >= 1) {
          try {
            numeroQuestoes = int.parse(match.group(1)!);
          } catch (e) {
            // Ignorar erro de parsing
          }
        }

        return ConteudoProgramatico(
          nome: nomeMateria,
          tipo: 'comum',
          topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
          numeroQuestoes: numeroQuestoes,
        );
      }

      // Fallback para itens de formato desconhecido
      return ConteudoProgramatico(
        nome: 'Conteúdo não especificado',
        tipo: 'comum',
        topicos: ['Conteúdo básico']
      );
    }).toList();
  }

  /// Extrai tópicos de um item de conteúdo programático
  static List<String> _extrairTopicosDeItem(Map<String, dynamic> item) {
    List<String> topicos = [];
    if (item['topicos'] is List) {
      topicos = List<String>.from(item['topicos']);
    } else if (item['topicos'] is String) {
      // Se for uma string, dividir por quebras de linha ou vírgulas
      final String topicosStr = item['topicos'].toString();
      if (topicosStr.contains('\n')) {
        topicos = topicosStr.split('\n')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      } else if (topicosStr.contains(',')) {
        topicos = topicosStr.split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      } else {
        topicos = [topicosStr];
      }
    }
    return topicos;
  }

  /// Infere tópicos comuns para matérias padrão
  static List<String> _inferirTopicosPorMateria(String nomeMateria) {
    final String materiaLower = nomeMateria.toLowerCase();

    if (materiaLower.contains('português') || materiaLower.contains('lingua portuguesa')) {
      return ['Interpretação de texto', 'Gramática', 'Ortografia', 'Pontuação'];
    } else if (materiaLower.contains('matemática')) {
      return ['Raciocínio lógico', 'Operações básicas', 'Porcentagem', 'Equações'];
    } else if (materiaLower.contains('conhecimentos gerais')) {
      return ['Atualidades', 'História', 'Geografia', 'Política'];
    } else if (materiaLower.contains('informática') || materiaLower.contains('informatica')) {
      return ['Windows', 'Microsoft Office', 'Internet', 'Segurança da Informação'];
    } else if (materiaLower.contains('direito constitucional')) {
      return ['Princípios Fundamentais', 'Direitos e Garantias Fundamentais', 'Organização do Estado'];
    } else if (materiaLower.contains('direito administrativo')) {
      return ['Princípios da Administração Pública', 'Atos Administrativos', 'Licitações e Contratos'];
    }

    return [];
  }

  /// Processa matérias no formato de lista de strings
  static List<ConteudoProgramatico> _processarMaterias(List materias) {
    return materias.map((materia) {
      final String nomeMateria = materia.toString().trim();
      List<String> topicos = _inferirTopicosPorMateria(nomeMateria);

      return ConteudoProgramatico(
        nome: nomeMateria,
        tipo: 'comum',
        topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos
      );
    }).toList();
  }

  /// Extrai tópicos de diferentes formatos de dados
  static List<String> _extrairTopicos(dynamic topicosData) {
    List<String> topicos = [];

    if (topicosData is List) {
      // Se for uma lista, converter cada item para string
      topicos = List<String>.from(topicosData.map((item) => item.toString()));
    } else if (topicosData is String) {
      // Se for uma string, dividir por quebras de linha ou vírgulas
      final String topicosStr = topicosData.toString();
      if (topicosStr.contains('\n')) {
        topicos = topicosStr.split('\n')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      } else if (topicosStr.contains(',')) {
        topicos = topicosStr.split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      } else {
        topicos = [topicosStr];
      }
    } else if (topicosData is Map<String, dynamic>) {
      // Se for um mapa, extrair valores como tópicos
      topicosData.forEach((key, value) {
        if (value is List) {
          // Adicionar cada item da lista como um tópico
          topicos.addAll(List<String>.from(value.map((item) => item.toString())));
        } else if (value is String) {
          topicos.add(value);
        }
      });
    }

    // Limpar tópicos vazios e remover duplicatas
    return topicos
      .where((t) => t.trim().isNotEmpty)
      .toSet()
      .toList();
  }

  /// Cria um cargo genérico para quando a lista de cargos está vazia
  static Cargo _criarCargoGenerico() {
    return Cargo(
      id: 'cargo_generico_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Cargo Genérico',
      vagas: 1,
      salario: 0.0,
      escolaridade: 'Não especificado',
      dataProva: null,
      conteudoProgramatico: _criarConteudoProgramaticoPadrao(),
    );
  }

  /// Cria um cargo de erro para quando há falha na conversão de um cargo individual
  static Cargo _criarCargoErro() {
    return Cargo(
      id: 'cargo_erro_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Cargo Não Identificado',
      vagas: 1,
      salario: 0.0,
      escolaridade: 'Não especificado',
      dataProva: null,
      conteudoProgramatico: _criarConteudoProgramaticoPadrao(),
    );
  }

  /// Cria um cargo de fallback para quando há falha na conversão da lista de cargos
  static Cargo _criarCargoFallback() {
    return Cargo(
      id: 'cargo_fallback_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Cargo Padrão',
      vagas: 1,
      salario: 0.0,
      escolaridade: 'Não especificado',
      dataProva: null,
      conteudoProgramatico: _criarConteudoProgramaticoPadrao(),
    );
  }

  /// Cria uma lista padrão de conteúdo programático
  static List<ConteudoProgramatico> _criarConteudoProgramaticoPadrao() {
    return [
      ConteudoProgramatico(
        nome: 'Língua Portuguesa',
        tipo: 'comum',
        topicos: ['Interpretação de texto', 'Gramática', 'Ortografia']
      ),
      ConteudoProgramatico(
        nome: 'Matemática',
        tipo: 'comum',
        topicos: ['Raciocínio lógico', 'Operações básicas']
      ),
      ConteudoProgramatico(
        nome: 'Conhecimentos Gerais',
        tipo: 'comum',
        topicos: ['Atualidades', 'História', 'Geografia']
      ),
    ];
  }
}
