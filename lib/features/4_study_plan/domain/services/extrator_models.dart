/// Modelos para o Extrator de Dados

/// Fonte de dados para resultados de busca
enum FonteDados {
  METADADOS,
  METADADOS_ALTERNATIVO,
  METADADOS_ANINHADOS,
  DADOS_EXTRAIDOS,
  DADOS_PROVA,
  DADOS_ORIGINAIS,
}

/// Representa as chaves de busca e suas alternativas para extração de dados
class ChaveBusca {
  final String chaveMetadados;
  final String chaveDadosOriginais;
  final String eventoLog;
  final List<String> alternativasMetadados;
  final List<String> alternativasOriginais;

  const ChaveBusca({
    required this.chaveMetadados,
    required this.chaveDadosOriginais,
    required this.eventoLog,
    this.alternativasMetadados = const [],
    this.alternativasOriginais = const [],
  });
}

/// Representa o resultado de uma operação de busca de dado
class ResultadoBusca {
  final String valor;
  final FonteDados origem;
  final String? caminho;

  const ResultadoBusca({
    required this.valor,
    required this.origem,
    this.caminho,
  });
}
