import 'extrator_models.dart';

/// Classe com as constantes para as chaves de busca
class ChavesBusca {
  // Chaves para concurso
  static const ChaveBusca TITULO = ChaveBusca(
    chaveMetadados: 'titulo',
    chaveDadosOriginais: 'concurso.titulo',
    eventoLog: 'buscar_titulo_concurso',
  );

  static const ChaveBusca ORGAO = ChaveBusca(
    chaveMetadados: 'orgao',
    chaveDadosOriginais: 'concurso.orgao',
    eventoLog: 'buscar_orgao_concurso',
  );

  static const ChaveBusca BANCA = ChaveBusca(
    chaveMetadados: 'banca',
    chaveDadosOriginais: 'concurso.banca',
    eventoLog: 'buscar_banca_concurso',
  );

  // Chaves para prova
  static const ChaveBusca FORMATO_PROVA = ChaveBusca(
    chaveMetadados: 'formatoProva',
    chaveDadosOriginais: 'prova.formato',
    eventoLog: 'buscar_formato_prova',
  );

  static const ChaveBusca DATA_PROVA = ChaveBusca(
    chaveMetadados: 'dataProva',
    chaveDadosOriginais: 'prova.data',
    eventoLog: 'buscar_data_prova',
  );

  static const ChaveBusca LOCAL_PROVA = ChaveBusca(
    chaveMetadados: 'localProva',
    chaveDadosOriginais: 'prova.local',
    eventoLog: 'buscar_local_prova',
  );

  static const ChaveBusca TOTAL_QUESTOES = ChaveBusca(
    chaveMetadados: 'totalQuestoes',
    chaveDadosOriginais: 'prova.total_questoes',
    eventoLog: 'buscar_total_questoes',
  );

  static const ChaveBusca DURACAO_PROVA = ChaveBusca(
    chaveMetadados: 'duracaoProva',
    chaveDadosOriginais: 'prova.duracao',
    eventoLog: 'buscar_duracao_prova',
  );

  static const ChaveBusca CRITERIOS_APROVACAO = ChaveBusca(
    chaveMetadados: 'criteriosAprovacao',
    chaveDadosOriginais: 'prova.criterios_aprovacao',
    eventoLog: 'buscar_criterios_aprovacao',
  );

  static const ChaveBusca CRITERIOS_REPROVACAO = ChaveBusca(
    chaveMetadados: 'criteriosReprovacao',
    chaveDadosOriginais: 'prova.criterios_reprovacao',
    eventoLog: 'buscar_criterios_reprovacao',
    alternativasOriginais: ['concurso.prova.criterios_reprovacao'],
  );

  static const ChaveBusca CRITERIOS_DESEMPATE = ChaveBusca(
    chaveMetadados: 'criteriosDesempate',
    chaveDadosOriginais: 'prova.criterios_desempate',
    eventoLog: 'buscar_criterios_desempate',
  );

  static const ChaveBusca TEMA_PROVA_SUBJETIVA = ChaveBusca(
    chaveMetadados: 'temaProvaSubjetiva',
    chaveDadosOriginais: 'prova.tema_discursiva',
    eventoLog: 'buscar_tema_prova_subjetiva',
  );

  // Chaves para inscrição
  static const ChaveBusca VALOR_INSCRICAO = ChaveBusca(
    chaveMetadados: 'valorInscricao',
    chaveDadosOriginais: 'inscricoes.taxa',
    eventoLog: 'buscar_valor_inscricao',
    alternativasOriginais: ['concurso.inscricoes.taxa', 'taxa_inscricao'],
  );

  static const ChaveBusca PERIODO_INSCRICAO = ChaveBusca(
    chaveMetadados: 'periodoInscricao',
    chaveDadosOriginais: 'inscricoes.periodo',
    eventoLog: 'buscar_periodo_inscricao',
    alternativasOriginais: ['concurso.inscricoes.periodo'],
  );

  static const ChaveBusca INICIO_INSCRICAO = ChaveBusca(
    chaveMetadados: 'inicioInscricao',
    chaveDadosOriginais: 'inscricoes.inicio',
    eventoLog: 'buscar_inicio_inscricao',
  );

  static const ChaveBusca FIM_INSCRICAO = ChaveBusca(
    chaveMetadados: 'fimInscricao',
    chaveDadosOriginais: 'inscricoes.fim',
    eventoLog: 'buscar_fim_inscricao',
  );

  // Chaves para cotas
  static const ChaveBusca COTAS = ChaveBusca(
    chaveMetadados: 'cotas',
    chaveDadosOriginais: 'cotas',
    eventoLog: 'buscar_cotas',
  );
}
