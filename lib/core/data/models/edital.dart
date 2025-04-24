import 'dart:typed_data';
import 'dados_vaga.dart';

class ConteudoProgramatico {
  final String nome;
  final String tipo; // 'comum' ou 'especifico'
  final List<String> topicos;
  final bool? pesoMaior; // Indica se a matéria tem peso maior na pontuação final
  final bool? criterioDesempate; // Indica se a matéria é critério de desempate
  final int? numeroQuestoes; // Número de questões da matéria na prova
  final bool? questoesEstimadas; // Indica se o número de questões foi estimado ou está explícito no edital
  final int? totalQuestoesGrupo; // Número total de questões do grupo (conhecimentos básicos/específicos)
  final String? grupoMateria; // Nome do grupo/módulo ao qual a matéria pertence (ex: "Módulo I", "Conhecimentos Básicos")

  ConteudoProgramatico({
    required this.nome,
    required this.tipo,
    required this.topicos,
    this.pesoMaior,
    this.criterioDesempate,
    this.numeroQuestoes,
    this.questoesEstimadas,
    this.totalQuestoesGrupo,
    this.grupoMateria,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'topicos': topicos,
      'peso_maior': pesoMaior,
      'criterio_desempate': criterioDesempate,
      'numero_questoes': numeroQuestoes,
      'questoes_estimadas': questoesEstimadas,
      'total_questoes_grupo': totalQuestoesGrupo,
      'grupo_materia': grupoMateria,
    };
  }

  factory ConteudoProgramatico.fromMap(Map<String, dynamic> map) {
    return ConteudoProgramatico(
      nome: map['nome'] ?? 'Não informado',
      tipo: map['tipo'] ?? 'comum',
      topicos: List<String>.from(map['topicos'] ?? []),
      pesoMaior: map['peso_maior'],
      criterioDesempate: map['criterio_desempate'],
      numeroQuestoes: map['numero_questoes'] is int ? map['numero_questoes'] : null,
      questoesEstimadas: map['questoes_estimadas'],
      totalQuestoesGrupo: map['total_questoes_grupo'] is int ? map['total_questoes_grupo'] : null,
      grupoMateria: map['grupo_materia'],
    );
  }

  @override
  String toString() {
    return nome;
  }
}

class Cargo {
  final String id;
  final String nome;
  final int? vagas; // Agora é opcional
  final double salario;
  final double taxaInscricao;
  final String nivel;
  final String escolaridade;
  final String requisitos;
  final List<ConteudoProgramatico> conteudoProgramatico;
  final DateTime? dataProva;
  final String? horarioProva;

  Cargo({
    required this.nome,
    this.id = '',
    this.vagas, // Agora é opcional
    this.salario = 0.0,
    this.taxaInscricao = 0.0,
    this.nivel = 'Não informado',
    this.escolaridade = 'Não informado',
    this.requisitos = 'Não informado',
    required this.conteudoProgramatico,
    this.dataProva,
    this.horarioProva,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'vagas': vagas,
      'salario': salario,
      'taxaInscricao': taxaInscricao,
      'nivel': nivel,
      'escolaridade': escolaridade,
      'requisitos': requisitos,
      'conteudoProgramatico': conteudoProgramatico.map((m) => m.toMap()).toList(),
      'dataProva': dataProva?.toIso8601String(),
      'horarioProva': horarioProva,
    };
  }

  factory Cargo.fromMap(Map<String, dynamic> map) {
    List<ConteudoProgramatico> materias = [];
    if (map['conteudoProgramatico'] != null) {
      if (map['conteudoProgramatico'] is List<String>) {
        // Converter lista de strings para lista de ConteudoProgramatico
        materias = (map['conteudoProgramatico'] as List<String>).map((nome) =>
          ConteudoProgramatico(nome: nome, tipo: 'comum', topicos: ['Conteúdo básico'])
        ).toList();
      } else if (map['conteudoProgramatico'] is List) {
        try {
          materias = (map['conteudoProgramatico'] as List)
            .where((item) => item is Map<String, dynamic>)
            .map((item) => ConteudoProgramatico.fromMap(item as Map<String, dynamic>))
            .toList();
        } catch (e) {
          // Fallback para lista simples
          materias = [ConteudoProgramatico(nome: 'Conteúdo Programático', tipo: 'comum', topicos: ['Conteúdo básico'])];
        }
      }
    }

    return Cargo(
      id: map['id'] ?? '',
      nome: map['nome'] ?? 'Não informado',
      vagas: map['vagas'] is int ? map['vagas'] : null,
      salario: map['salario'] is num ? (map['salario'] as num).toDouble() : 0.0,
      taxaInscricao: map['taxaInscricao'] is num ? (map['taxaInscricao'] as num).toDouble() : 0.0,
      nivel: map['nivel'] ?? 'Não informado',
      escolaridade: map['escolaridade'] ?? 'Não informado',
      requisitos: map['requisitos'] ?? 'Não informado',
      conteudoProgramatico: materias,
      dataProva: map['dataProva'] != null ? DateTime.parse(map['dataProva']) : null,
      horarioProva: map['horarioProva'],
    );
  }
}

class DadosExtraidos {
  String? titulo;
  String? orgao;
  String? banca;
  DateTime? inicioInscricao;
  DateTime? fimInscricao;
  dynamic valorTaxa;
  String? localProva;
  String? dataProva;
  List<Cargo> cargos;
  String textoCompleto;
  DadosProva? dadosProva;
  List<DadosCota>? cotas;
  DadosVaga? dadosVaga;

  // Propriedades adicionais para compatibilidade
  String? periodoInscricaoInicio;
  String? periodoInscricaoFim;
  double? taxaInscricao;
  int? totalQuestoes;
  String? formatoProva;
  String? duracaoProva;
  String? temaDiscursiva;
  String? criteriosAprovacao;
  String? criteriosReprovacao;
  List<String>? criteriosDesempate;

  // Propriedades para estruturas aninhadas
  Map<String, dynamic>? concurso;
  Map<String, dynamic>? prova;

  DadosExtraidos({
    this.titulo,
    this.orgao,
    this.banca,
    this.dataProva,
    this.inicioInscricao,
    this.fimInscricao,
    this.valorTaxa = 0.0,
    this.localProva,
    required this.cargos,
    this.textoCompleto = '',
    this.dadosProva,
    this.cotas,
    this.dadosVaga,
    // Propriedades adicionais
    this.periodoInscricaoInicio,
    this.periodoInscricaoFim,
    this.taxaInscricao,
    this.totalQuestoes,
    this.formatoProva,
    this.duracaoProva,
    this.temaDiscursiva,
    this.criteriosAprovacao,
    this.criteriosReprovacao,
    this.criteriosDesempate,
    // Estruturas aninhadas
    this.concurso,
    this.prova,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'orgao': orgao,
      'banca': banca,
      'dataProva': dataProva,
      'inicioInscricao': inicioInscricao?.toIso8601String(),
      'fimInscricao': fimInscricao?.toIso8601String(),
      'valorTaxa': valorTaxa,
      'cargos': cargos.map((cargo) => cargo.toMap()).toList(),
      'localProva': localProva,
      'textoCompleto': textoCompleto,
      'dadosProva': dadosProva?.toMap(),
      'cotas': cotas?.map((cota) => cota.toMap()).toList(),
      'dadosVaga': dadosVaga?.toMap(),
      // Propriedades adicionais
      'periodoInscricaoInicio': periodoInscricaoInicio,
      'periodoInscricaoFim': periodoInscricaoFim,
      'taxaInscricao': taxaInscricao,
      'totalQuestoes': totalQuestoes,
      'formatoProva': formatoProva,
      'duracaoProva': duracaoProva,
      'temaDiscursiva': temaDiscursiva,
      'criteriosAprovacao': criteriosAprovacao,
      'criteriosReprovacao': criteriosReprovacao,
      'criteriosDesempate': criteriosDesempate,
      // Estruturas aninhadas
      'concurso': concurso,
      'prova': prova,
    };
  }

  factory DadosExtraidos.fromMap(Map<String, dynamic> map) {
    // Função auxiliar para parsear datas com tratamento de erro
    DateTime? parseDataSegura(dynamic valor) {
      if (valor == null) return null;

      try {
        // Se for string, tentar parsear
        if (valor is String) {
          // Verificar se é formato ISO
          if (valor.contains('T') || valor.contains('-')) {
            return DateTime.parse(valor);
          }

          // Verificar se é formato DD/MM/YYYY
          final regexBarra = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
          final matchBarra = regexBarra.firstMatch(valor);
          if (matchBarra != null) {
            final dia = int.parse(matchBarra.group(1)!);
            final mes = int.parse(matchBarra.group(2)!);
            final ano = int.parse(matchBarra.group(3)!);
            return DateTime(ano, mes, dia);
          }

          // Formato não reconhecido
          print('Formato de data não reconhecido: $valor');
          return null;
        }

        // Se já for DateTime, retornar diretamente
        if (valor is DateTime) {
          return valor;
        }

        return null;
      } catch (e) {
        print('Erro ao parsear data: $e, valor: $valor');
        return null;
      }
    }

    // Extrair estruturas aninhadas
    Map<String, dynamic>? concursoMap;
    if (map['concurso'] is Map) {
      concursoMap = Map<String, dynamic>.from(map['concurso'] as Map);
    }

    Map<String, dynamic>? provaMap;
    if (map['prova'] is Map) {
      provaMap = Map<String, dynamic>.from(map['prova'] as Map);
    }

    // Extrair critérios de desempate
    List<String>? criteriosDesempateList;
    if (map['criterios_desempate'] != null) {
      if (map['criterios_desempate'] is List) {
        criteriosDesempateList = List<String>.from(map['criterios_desempate'].map((item) => item.toString()));
      } else if (map['criterios_desempate'] is String) {
        criteriosDesempateList = [(map['criterios_desempate'] as String)];
      }
    }

    return DadosExtraidos(
      titulo: map['titulo'] ?? map['titulo_concurso'],
      orgao: map['orgao'] ?? map['orgao_responsavel'],
      banca: map['banca'] ?? map['banca_organizadora'],
      dataProva: map['dataProva'],
      inicioInscricao: parseDataSegura(map['inicioInscricao']),
      fimInscricao: parseDataSegura(map['fimInscricao']),
      valorTaxa: map['valorTaxa'] is num ? (map['valorTaxa'] as num).toDouble() : 0.0,
      cargos: map['cargos'] != null
          ? List<Cargo>.from(map['cargos'].map((x) => Cargo.fromMap(x)))
          : [],
      localProva: map['localProva'],
      textoCompleto: map['textoCompleto'] ?? '',
      dadosProva: map['prova'] != null ? DadosProva.fromMap(map['prova']) :
                  map['dadosProva'] != null ? DadosProva.fromMap(map['dadosProva']) : null,
      cotas: map['cotas'] != null
          ? List<DadosCota>.from(map['cotas'].map((x) => DadosCota.fromMap(x)))
          : null,
      dadosVaga: map['vagas'] != null ? DadosVaga.fromMap(map['vagas']) : null,
      // Propriedades adicionais
      periodoInscricaoInicio: map['periodoInscricaoInicio'] ?? map['periodo_inscricao_inicio'],
      periodoInscricaoFim: map['periodoInscricaoFim'] ?? map['periodo_inscricao_fim'],
      taxaInscricao: map['taxaInscricao'] is num ? (map['taxaInscricao'] as num).toDouble() :
                     map['taxa_inscricao'] is num ? (map['taxa_inscricao'] as num).toDouble() : null,
      totalQuestoes: map['totalQuestoes'] is int ? map['totalQuestoes'] :
                     map['total_questoes'] is int ? map['total_questoes'] : null,
      formatoProva: map['formatoProva'] ?? map['formato_prova'],
      duracaoProva: map['duracaoProva'] ?? map['duracao_prova'],
      temaDiscursiva: map['temaDiscursiva'] ?? map['tema_discursiva'],
      criteriosAprovacao: map['criteriosAprovacao'] ?? map['criterios_aprovacao'],
      criteriosReprovacao: map['criteriosReprovacao'] ?? map['criterios_reprovacao'],
      criteriosDesempate: criteriosDesempateList,
      // Estruturas aninhadas
      concurso: concursoMap,
      prova: provaMap,
    );
  }
}

class DadosProva {
  final int? totalQuestoes;
  final List<String>? formato; // ["objetiva", "discursiva", ...]
  final String? temaDiscursiva;
  final String? criteriosAprovacao;
  final List<String>? criteriosDesempate;

  // Propriedades adicionais
  final String? criteriosReprovacao;
  final String? duracao;
  final DateTime? dataRealizacao;

  DadosProva({
    this.totalQuestoes,
    this.formato,
    this.temaDiscursiva,
    this.criteriosAprovacao,
    this.criteriosDesempate,
    // Propriedades adicionais
    this.criteriosReprovacao,
    this.duracao,
    this.dataRealizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'total_questoes': totalQuestoes,
      'formato': formato,
      'tema_discursiva': temaDiscursiva,
      'criterios_aprovacao': criteriosAprovacao,
      'criterios_desempate': criteriosDesempate,
      // Propriedades adicionais
      'criterios_reprovacao': criteriosReprovacao,
      'duracao': duracao,
      'data_realizacao': dataRealizacao?.toIso8601String(),
    };
  }

  factory DadosProva.fromMap(Map<String, dynamic> map) {
    List<String>? formatoList;
    if (map['formato'] != null) {
      if (map['formato'] is List) {
        formatoList = List<String>.from(map['formato'].map((item) => item.toString()));
      } else if (map['formato'] is String) {
        formatoList = [(map['formato'] as String)];
      }
    }

    List<String>? criteriosDesempateList;
    if (map['criterios_desempate'] != null) {
      if (map['criterios_desempate'] is List) {
        criteriosDesempateList = List<String>.from(map['criterios_desempate'].map((item) => item.toString()));
      } else if (map['criterios_desempate'] is String) {
        criteriosDesempateList = [(map['criterios_desempate'] as String)];
      }
    }

    // Função auxiliar para parsear datas com tratamento de erro
    DateTime? parseDataSegura(dynamic valor) {
      if (valor == null) return null;

      try {
        // Se for string, tentar parsear
        if (valor is String) {
          // Verificar se é formato ISO
          if (valor.contains('T') || valor.contains('-')) {
            return DateTime.parse(valor);
          }

          // Verificar se é formato DD/MM/YYYY
          final regexBarra = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
          final matchBarra = regexBarra.firstMatch(valor);
          if (matchBarra != null) {
            final dia = int.parse(matchBarra.group(1)!);
            final mes = int.parse(matchBarra.group(2)!);
            final ano = int.parse(matchBarra.group(3)!);
            return DateTime(ano, mes, dia);
          }

          // Formato não reconhecido
          return null;
        }

        // Se já for DateTime, retornar diretamente
        if (valor is DateTime) {
          return valor;
        }

        return null;
      } catch (e) {
        return null;
      }
    }

    return DadosProva(
      totalQuestoes: map['total_questoes'] is int ? map['total_questoes'] : null,
      formato: formatoList,
      temaDiscursiva: map['tema_discursiva'],
      criteriosAprovacao: map['criterios_aprovacao'],
      criteriosDesempate: criteriosDesempateList,
      // Propriedades adicionais
      criteriosReprovacao: map['criterios_reprovacao'],
      duracao: map['duracao'],
      dataRealizacao: parseDataSegura(map['data_realizacao']),
    );
  }
}

// A classe DadosVaga foi movida para o arquivo dados_vaga.dart

class DadosCota {
  final String nome; // Nome exato da cota conforme aparece no edital
  final int? percentual; // Percentual de vagas reservadas
  final int? numeroVagas; // Número absoluto de vagas reservadas
  final String? criterios; // Critérios para concorrer à cota

  DadosCota({
    required this.nome,
    this.percentual,
    this.numeroVagas,
    this.criterios,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'percentual': percentual,
      'numero_vagas': numeroVagas,
      'criterios': criterios,
    };
  }

  factory DadosCota.fromMap(Map<String, dynamic> map) {
    return DadosCota(
      nome: map['nome'] ?? 'Não informado',
      percentual: map['percentual'] is int ? map['percentual'] : null,
      numeroVagas: map['numero_vagas'] is int ? map['numero_vagas'] : null,
      criterios: map['criterios'],
    );
  }
}

class Edital {
  final String id;
  final String userId;
  final String nomeConcurso;
  final String textoCompleto;
  final DateTime dataUpload;
  DadosExtraidos dadosExtraidos;
  Map<String, dynamic>? dadosOriginais; // Dados originais extraídos pela IA
  Uint8List? pdfBytes; // Bytes do PDF do edital
  String? _nomeArquivo; // Nome do arquivo PDF

  Edital({
    required this.id,
    required this.userId,
    required this.nomeConcurso,
    required this.textoCompleto,
    required this.dataUpload,
    required this.dadosExtraidos,
    this.dadosOriginais,
    this.pdfBytes,
    String? nomeArquivo,
  }) : _nomeArquivo = nomeArquivo;

  /// Retorna o nome do arquivo PDF, ou um nome padrão baseado no nome do concurso
  String get nomeArquivo => _nomeArquivo ?? '${nomeConcurso.replaceAll(' ', '_').toLowerCase()}.pdf';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nomeConcurso': nomeConcurso,
      'textoCompleto': textoCompleto,
      'dataUpload': dataUpload.toIso8601String(),
      'dadosExtraidos': dadosExtraidos.toMap(),
      'dadosOriginais': dadosOriginais,
      'nomeArquivo': _nomeArquivo,
      // Não incluir pdfBytes no toMap para evitar serialização de dados binários grandes
      // Os bytes do PDF são armazenados apenas em memória durante a execução do aplicativo
    };
  }

  factory Edital.fromMap(Map<String, dynamic> map) {
    return Edital(
      id: map['id'],
      userId: map['userId'],
      nomeConcurso: map['nomeConcurso'],
      textoCompleto: map['textoCompleto'],
      dataUpload: DateTime.parse(map['dataUpload']),
      dadosExtraidos: DadosExtraidos.fromMap(map['dadosExtraidos']),
      dadosOriginais: map['dadosOriginais'],
      nomeArquivo: map['nomeArquivo'],
    );
  }

  // Métodos para serialização JSON
  Map<String, dynamic> toJson() => toMap();

  factory Edital.fromJson(Map<String, dynamic> json) => Edital.fromMap(json);
}
