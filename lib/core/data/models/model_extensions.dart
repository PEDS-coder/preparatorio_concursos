import 'edital.dart';

/// Extensões para as classes de modelo para adicionar métodos copyWith
/// Isso permite criar cópias de objetos com algumas propriedades alteradas

/// Extensão para a classe ConteudoProgramatico
extension ConteudoProgramaticoExtension on ConteudoProgramatico {
  /// Cria uma cópia do objeto com as propriedades especificadas alteradas
  ConteudoProgramatico copyWith({
    String? nome,
    String? tipo,
    List<String>? topicos,
    bool? pesoMaior,
    bool? criterioDesempate,
    int? numeroQuestoes,
    int? totalQuestoesGrupo,
    String? grupoMateria,
    String? grupo,
  }) {
    return ConteudoProgramatico(
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      topicos: topicos ?? this.topicos,
      pesoMaior: pesoMaior ?? this.pesoMaior,
      criterioDesempate: criterioDesempate ?? this.criterioDesempate,
      numeroQuestoes: numeroQuestoes ?? this.numeroQuestoes,
      totalQuestoesGrupo: totalQuestoesGrupo ?? this.totalQuestoesGrupo,
      grupoMateria: grupoMateria ?? this.grupoMateria,
      grupo: grupo ?? this.grupo,
    );
  }
}

/// Extensão para a classe Cargo
extension CargoExtension on Cargo {
  /// Cria uma cópia do objeto com as propriedades especificadas alteradas
  Cargo copyWith({
    String? id,
    String? nome,
    int? vagas,
    double? salario,
    double? taxaInscricao,
    String? nivel,
    String? escolaridade,
    List<ConteudoProgramatico>? conteudoProgramatico,
    DateTime? dataProva,
  }) {
    return Cargo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      vagas: vagas ?? this.vagas,
      salario: salario ?? this.salario,
      taxaInscricao: taxaInscricao ?? this.taxaInscricao,
      nivel: nivel ?? this.nivel,
      escolaridade: escolaridade ?? this.escolaridade,
      conteudoProgramatico: conteudoProgramatico ?? this.conteudoProgramatico,
      dataProva: dataProva ?? this.dataProva,
    );
  }
}

/// Extensão para a classe DadosExtraidos
extension DadosExtraidosExtension on DadosExtraidos {
  /// Cria uma cópia do objeto com as propriedades especificadas alteradas
  DadosExtraidos copyWith({
    String? titulo,
    String? orgao,
    String? banca,
    DateTime? inicioInscricao,
    DateTime? fimInscricao,
    dynamic valorTaxa,
    String? localProva,
    String? dataProva,
    List<Cargo>? cargos,
    List<CriterioDesempate>? criteriosDesempate,
    String? textoCompleto,
    int? totalQuestoesProva,
    String? duracaoProva,
    String? criteriosAprovacao,
    String? criteriosReprovacao,
    String? pontuacaoProvaDiscursiva,
  }) {
    return DadosExtraidos(
      titulo: titulo ?? this.titulo,
      orgao: orgao ?? this.orgao,
      banca: banca ?? this.banca,
      inicioInscricao: inicioInscricao ?? this.inicioInscricao,
      fimInscricao: fimInscricao ?? this.fimInscricao,
      valorTaxa: valorTaxa ?? this.valorTaxa,
      localProva: localProva ?? this.localProva,
      dataProva: dataProva ?? this.dataProva,
      cargos: cargos ?? this.cargos,
      criteriosDesempate: criteriosDesempate ?? this.criteriosDesempate,
      textoCompleto: textoCompleto ?? this.textoCompleto,
      totalQuestoesProva: totalQuestoesProva ?? this.totalQuestoesProva,
      duracaoProva: duracaoProva ?? this.duracaoProva,
      criteriosAprovacao: criteriosAprovacao ?? this.criteriosAprovacao,
      criteriosReprovacao: criteriosReprovacao ?? this.criteriosReprovacao,
      pontuacaoProvaDiscursiva: pontuacaoProvaDiscursiva ?? this.pontuacaoProvaDiscursiva,
    );
  }
}

/// Extensão para a classe Edital
extension EditalExtension on Edital {
  /// Cria uma cópia do objeto com as propriedades especificadas alteradas
  Edital copyWith({
    String? id,
    String? userId,
    String? nomeConcurso,
    String? textoCompleto,
    DateTime? dataUpload,
    DadosExtraidos? dadosExtraidos,
    Map<String, dynamic>? dadosOriginais,
    bool? ativo,
  }) {
    return Edital(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nomeConcurso: nomeConcurso ?? this.nomeConcurso,
      textoCompleto: textoCompleto ?? this.textoCompleto,
      dataUpload: dataUpload ?? this.dataUpload,
      dadosExtraidos: dadosExtraidos ?? this.dadosExtraidos,
      dadosOriginais: dadosOriginais ?? this.dadosOriginais,
      ativo: ativo ?? this.ativo,
    );
  }
}
