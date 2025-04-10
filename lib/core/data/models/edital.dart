class ConteudoProgramatico {
  final String nome;
  final String tipo; // 'comum' ou 'especifico'
  final List<String> topicos;

  ConteudoProgramatico({
    required this.nome,
    required this.tipo,
    required this.topicos,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'topicos': topicos,
    };
  }

  factory ConteudoProgramatico.fromMap(Map<String, dynamic> map) {
    return ConteudoProgramatico(
      nome: map['nome'] ?? 'Não informado',
      tipo: map['tipo'] ?? 'comum',
      topicos: List<String>.from(map['topicos'] ?? []),
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
  final int vagas;
  final double salario;
  final double taxaInscricao;
  final String nivel;
  final String escolaridade;
  final List<ConteudoProgramatico> conteudoProgramatico;
  final DateTime? dataProva;

  Cargo({
    required this.nome,
    this.id = '',
    this.vagas = 0,
    this.salario = 0.0,
    this.taxaInscricao = 0.0,
    this.nivel = 'Não informado',
    this.escolaridade = 'Não informado',
    required this.conteudoProgramatico,
    this.dataProva,
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
      'conteudoProgramatico': conteudoProgramatico.map((m) => m.toMap()).toList(),
      'dataProva': dataProva?.toIso8601String(),
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
      vagas: map['vagas'] is int ? map['vagas'] : 0,
      salario: map['salario'] is num ? (map['salario'] as num).toDouble() : 0.0,
      taxaInscricao: map['taxaInscricao'] is num ? (map['taxaInscricao'] as num).toDouble() : 0.0,
      nivel: map['nivel'] ?? 'Não informado',
      escolaridade: map['escolaridade'] ?? 'Não informado',
      conteudoProgramatico: materias,
      dataProva: map['dataProva'] != null ? DateTime.parse(map['dataProva']) : null,
    );
  }
}

class DadosExtraidos {
  final String? titulo;
  final String? orgao;
  final String? banca;
  final DateTime? inicioInscricao;
  final DateTime? fimInscricao;
  final double valorTaxa;
  final String? localProva;
  final String? dataProva;
  final List<Cargo> cargos;
  final String textoCompleto;

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
    };
  }

  factory DadosExtraidos.fromMap(Map<String, dynamic> map) {
    return DadosExtraidos(
      titulo: map['titulo'],
      orgao: map['orgao'],
      banca: map['banca'],
      dataProva: map['dataProva'],
      inicioInscricao: map['inicioInscricao'] != null ? DateTime.parse(map['inicioInscricao']) : null,
      fimInscricao: map['fimInscricao'] != null ? DateTime.parse(map['fimInscricao']) : null,
      valorTaxa: map['valorTaxa'] is num ? (map['valorTaxa'] as num).toDouble() : 0.0,
      cargos: map['cargos'] != null
          ? List<Cargo>.from(map['cargos'].map((x) => Cargo.fromMap(x)))
          : [],
      localProva: map['localProva'],
      textoCompleto: map['textoCompleto'] ?? '',
    );
  }
}

class Edital {
  final String id;
  final String userId;
  final String nomeConcurso;
  final String textoCompleto;
  final DateTime dataUpload;
  final DadosExtraidos dadosExtraidos;
  final Map<String, dynamic>? dadosOriginais; // Dados originais extraídos pela IA

  Edital({
    required this.id,
    required this.userId,
    required this.nomeConcurso,
    required this.textoCompleto,
    required this.dataUpload,
    required this.dadosExtraidos,
    this.dadosOriginais,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nomeConcurso': nomeConcurso,
      'textoCompleto': textoCompleto,
      'dataUpload': dataUpload.toIso8601String(),
      'dadosExtraidos': dadosExtraidos.toMap(),
      'dadosOriginais': dadosOriginais,
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
    );
  }
}
