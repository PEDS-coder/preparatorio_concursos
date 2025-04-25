import '../../../../core/data/models/models.dart';
import '../../../../core/utils/plano_data_logger.dart';
import '../../presentation/helpers/validators/value_validator.dart';
import 'concurso_service.dart';
import 'prova_service.dart';
import 'inscricao_service.dart';

/// Serviço responsável por buscar e processar dados do plano de estudo
class PlanoDataService {
  final PlanoEstudo plano;
  final Edital? edital;
  final PlanoDataLogger logger;

  PlanoDataService({
    required this.plano,
    this.edital,
    required this.logger,
  });

  /// Método centralizado para buscar dados (prioridade: metadados aninhados -> metadados -> edital extraído -> edital original)
  String obterValorPlano(String chaveMetadados, {bool formatarComoLista = false, String separadorLista = ', '}) {
    final String campoLog = 'obterValorPlano($chaveMetadados)';
    logger.logRecuperacao(plano.id, 'inicio_busca', {'campo': campoLog});

    // Verificar se podemos usar os serviços específicos
    String resultado = _buscarComServicosEspecificos(chaveMetadados);
    if (resultado != 'Não informado') {
      logger.logRecuperacao(plano.id, 'valor_encontrado_servicos_especificos', {
        'campo': campoLog,
        'valor': resultado,
      });
      return resultado;
    }

    dynamic valorEncontrado;
    String fonte = 'nenhuma';

    // 1. Verificar Metadados Aninhados (planoEstudos, concurso, prova)
    List<String> caminhosAninhados = [
      'planoEstudos.$chaveMetadados',
      'concurso.$chaveMetadados',
      'prova.$chaveMetadados',
    ];

    // Adicionar caminhos específicos para cada chave
    if (chaveMetadados == 'titulo') {
      caminhosAninhados.addAll([
        'titulo_concurso',
        'concurso.titulo_concurso',
        'concurso.titulo',
        'edital.titulo',
        'edital.titulo_concurso'
      ]);
    } else if (chaveMetadados == 'orgao') {
      caminhosAninhados.addAll([
        'orgao_responsavel',
        'concurso.orgao_responsavel',
        'concurso.orgao',
        'edital.orgao',
        'edital.orgao_responsavel'
      ]);
    } else if (chaveMetadados == 'banca') {
      caminhosAninhados.addAll([
        'banca_organizadora',
        'concurso.banca_organizadora',
        'concurso.banca',
        'edital.banca',
        'edital.banca_organizadora'
      ]);
    } else if (chaveMetadados == 'dataProva') {
      caminhosAninhados.addAll([
        'data_prova',
        'concurso.data_prova',
        'prova.data_prova',
        'prova.data',
        'edital.data_prova',
        'edital.prova.data'
      ]);
    } else if (chaveMetadados == 'localProva') {
      caminhosAninhados.addAll([
        'local_prova',
        'concurso.local_prova',
        'prova.local_prova',
        'prova.local',
        'edital.local_prova',
        'edital.prova.local'
      ]);
    } else if (chaveMetadados == 'formatoProva') {
      caminhosAninhados.addAll([
        'formato',
        'prova.formato',
        'concurso.prova.formato',
        'edital.prova.formato'
      ]);
    } else if (chaveMetadados == 'temaProvaSubjetiva') {
      caminhosAninhados.addAll([
        'tema_discursiva',
        'prova.tema_discursiva',
        'concurso.prova.tema_discursiva',
        'edital.prova.tema_discursiva'
      ]);
    }

    for (String path in caminhosAninhados) {
      logger.logRecuperacao(plano.id, 'verificando_metadados_aninhados', {'campo': campoLog, 'path': path});
      valorEncontrado = _verificarMetadadosAninhados(path);
      if (ValueValidator.isValidValue(valorEncontrado)) {
        fonte = 'metadados_aninhados ($path)';
        logger.logRecuperacao(plano.id, 'valor_encontrado', {'campo': campoLog, 'fonte': fonte, 'valor_bruto': valorEncontrado});
        break;
      } else {
        logger.logRecuperacao(plano.id, 'valor_invalido_ou_nulo', {'campo': campoLog, 'path': path, 'valor_bruto': valorEncontrado});
      }
    }

    // 2. Verificar Metadados Diretos
    if (!ValueValidator.isValidValue(valorEncontrado)) {
      // Verificar chaves alternativas
      List<String> chavesAlternativas = [chaveMetadados];

      if (chaveMetadados == 'titulo') {
        chavesAlternativas.addAll(['titulo_concurso', 'nome_concurso', 'nome']);
      } else if (chaveMetadados == 'orgao') {
        chavesAlternativas.addAll(['orgao_responsavel', 'instituicao']);
      } else if (chaveMetadados == 'banca') {
        chavesAlternativas.addAll(['banca_organizadora', 'organizadora']);
      } else if (chaveMetadados == 'dataProva') {
        chavesAlternativas.addAll(['data_prova', 'data_realizacao', 'data']);
      } else if (chaveMetadados == 'localProva') {
        chavesAlternativas.addAll(['local_prova', 'local_realizacao', 'local']);
      } else if (chaveMetadados == 'formatoProva') {
        chavesAlternativas.addAll(['formato', 'tipo_prova']);
      } else if (chaveMetadados == 'temaProvaSubjetiva') {
        chavesAlternativas.addAll(['tema_discursiva', 'tema_subjetiva', 'tema_redacao']);
      }

      for (String chave in chavesAlternativas) {
        if (plano.metadados.containsKey(chave)) {
          logger.logRecuperacao(plano.id, 'verificando_metadados_diretos', {'campo': campoLog, 'chave': chave});
          valorEncontrado = plano.metadados[chave];
          if (ValueValidator.isValidValue(valorEncontrado)) {
            fonte = 'metadados_plano ($chave)';
            logger.logRecuperacao(plano.id, 'valor_encontrado', {'campo': campoLog, 'fonte': fonte, 'valor_bruto': valorEncontrado});
            break;
          } else {
            logger.logRecuperacao(plano.id, 'valor_invalido_ou_nulo', {'campo': campoLog, 'fonte': 'metadados_plano', 'valor_bruto': valorEncontrado});
          }
        }
      }
    }

    // 3. Verificar Edital - Dados Extraídos (se ainda não encontrou)
    if (!ValueValidator.isValidValue(valorEncontrado) && edital != null) {
      dynamic valorEditalExtraido;
      String fonteEditalExtraido = 'nenhuma';

      logger.logRecuperacao(plano.id, 'verificando_edital_extraido', {'campo': campoLog, 'chave': chaveMetadados});

      // Primeiro, verificar usando o switch para campos conhecidos
      switch (chaveMetadados) {
        case 'titulo':
          valorEditalExtraido = edital!.dadosExtraidos.titulo; fonteEditalExtraido = 'dados_extraidos.titulo'; break;
        case 'orgao':
          valorEditalExtraido = edital!.dadosExtraidos.orgao; fonteEditalExtraido = 'dados_extraidos.orgao'; break;
        case 'banca':
          // Tratar 'Não especificado' como inválido
          if (edital!.dadosExtraidos.banca != null && edital!.dadosExtraidos.banca!.toLowerCase() != 'não especificado') {
            valorEditalExtraido = edital!.dadosExtraidos.banca; fonteEditalExtraido = 'dados_extraidos.banca';
          }
          break;
        case 'localProva':
          valorEditalExtraido = edital!.dadosExtraidos.localProva; fonteEditalExtraido = 'dados_extraidos.localProva'; break;
        case 'valorInscricao':
          valorEditalExtraido = edital!.dadosExtraidos.valorTaxa; fonteEditalExtraido = 'dados_extraidos.valorTaxa'; break;
        // Campos específicos de DadosProva
        case 'totalQuestoes':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.totalQuestoes; fonteEditalExtraido = 'dados_extraidos.dadosProva.totalQuestoes';
          }
          break;
        case 'formatoProva':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.formato; fonteEditalExtraido = 'dados_extraidos.dadosProva.formato';
          }
          break;
        case 'temaProvaSubjetiva':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.temaDiscursiva; fonteEditalExtraido = 'dados_extraidos.dadosProva.temaDiscursiva';
          }
          break;
        case 'criteriosAprovacao':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.criteriosAprovacao; fonteEditalExtraido = 'dados_extraidos.dadosProva.criteriosAprovacao';
          }
          break;
        case 'criteriosReprovacao':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.criteriosReprovacao; fonteEditalExtraido = 'dados_extraidos.dadosProva.criteriosReprovacao';
          }
          break;
        case 'duracaoProva':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.duracao; fonteEditalExtraido = 'dados_extraidos.dadosProva.duracao';
          }
          break;
        case 'dataProva':
          if (edital!.dadosExtraidos.dadosProva != null) {
            valorEditalExtraido = edital!.dadosExtraidos.dadosProva!.dataRealizacao; fonteEditalExtraido = 'dados_extraidos.dadosProva.dataRealizacao';
          }
          if (!ValueValidator.isValidValue(valorEditalExtraido)) {
            valorEditalExtraido = edital!.dadosExtraidos.dataProva; fonteEditalExtraido = 'dados_extraidos.dataProva';
          }
          break;
      }

      // Se não encontrou pelo switch, verificar em dadosExtraidos.concurso
      if (!ValueValidator.isValidValue(valorEditalExtraido) && edital!.dadosExtraidos.concurso != null) {
        Map<String, dynamic>? concursoMap = edital!.dadosExtraidos.concurso;
        if (concursoMap != null) {
          // Mapeamento de chaves para buscar em concurso
          Map<String, List<String>> chavesConcurso = {
            'titulo': ['titulo', 'nome', 'titulo_concurso'],
            'orgao': ['orgao', 'orgao_responsavel', 'instituicao'],
            'banca': ['banca', 'banca_organizadora', 'organizadora'],
            'dataProva': ['data_prova', 'data', 'data_realizacao'],
            'localProva': ['local_prova', 'local', 'local_realizacao'],
            'formatoProva': ['formato_prova', 'formato', 'tipo_prova'],
            'temaProvaSubjetiva': ['tema_prova_subjetiva', 'tema_discursiva', 'tema_redacao'],
            'totalQuestoes': ['total_questoes', 'numero_questoes', 'qtd_questoes'],
            'criteriosAprovacao': ['criterios_aprovacao', 'criterios_de_aprovacao'],
            'criteriosReprovacao': ['criterios_reprovacao', 'criterios_de_reprovacao'],
            'duracaoProva': ['duracao_prova', 'duracao', 'tempo_prova'],
            'valorInscricao': ['valor_inscricao', 'taxa_inscricao', 'valor_taxa'],
          };

          if (chavesConcurso.containsKey(chaveMetadados)) {
            for (String chave in chavesConcurso[chaveMetadados]!) {
              if (concursoMap.containsKey(chave)) {
                valorEditalExtraido = concursoMap[chave];
                if (ValueValidator.isValidValue(valorEditalExtraido)) {
                  fonteEditalExtraido = 'dados_extraidos.concurso.$chave';
                  break;
                }
              }
            }
          }
        }
      }

      // Se ainda não encontrou, verificar em dadosExtraidos.prova
      if (!ValueValidator.isValidValue(valorEditalExtraido) && edital!.dadosExtraidos.prova != null) {
        Map<String, dynamic>? provaMap = edital!.dadosExtraidos.prova;
        if (provaMap != null) {
          // Mapeamento de chaves para buscar em prova
          Map<String, List<String>> chavesProva = {
            'dataProva': ['data', 'data_prova', 'data_realizacao'],
            'localProva': ['local', 'local_prova', 'local_realizacao'],
            'formatoProva': ['formato', 'tipo', 'tipo_prova'],
            'temaProvaSubjetiva': ['tema_discursiva', 'tema_subjetiva', 'tema_redacao'],
            'totalQuestoes': ['total_questoes', 'numero_questoes', 'qtd_questoes'],
            'criteriosAprovacao': ['criterios_aprovacao', 'criterios_de_aprovacao'],
            'criteriosReprovacao': ['criterios_reprovacao', 'criterios_de_reprovacao'],
            'duracaoProva': ['duracao', 'tempo', 'tempo_prova'],
          };

          if (chavesProva.containsKey(chaveMetadados)) {
            for (String chave in chavesProva[chaveMetadados]!) {
              if (provaMap.containsKey(chave)) {
                valorEditalExtraido = provaMap[chave];
                if (ValueValidator.isValidValue(valorEditalExtraido)) {
                  fonteEditalExtraido = 'dados_extraidos.prova.$chave';
                  break;
                }
              }
            }
          }
        }
      }

      if (ValueValidator.isValidValue(valorEditalExtraido)) {
        valorEncontrado = valorEditalExtraido;
        fonte = fonteEditalExtraido;
        logger.logRecuperacao(plano.id, 'valor_encontrado', {'campo': campoLog, 'fonte': fonte, 'valor_bruto': valorEncontrado});
      } else {
        logger.logRecuperacao(plano.id, 'valor_invalido_ou_nulo', {'campo': campoLog, 'fonte': fonteEditalExtraido, 'valor_bruto': valorEditalExtraido});
      }
    }

    // 4. Verificar Edital - Dados Originais (se ainda não encontrou)
    if (!ValueValidator.isValidValue(valorEncontrado) && edital != null && edital!.dadosOriginais != null) {
      logger.logRecuperacao(plano.id, 'verificando_edital_original', {'campo': campoLog, 'chave': chaveMetadados});
      dynamic valorEditalOriginal;
      String fonteEditalOriginal = 'nenhuma';
      Map<String, dynamic> originais = edital!.dadosOriginais!;

      // Mapeamento de chaves comuns para dados originais
      Map<String, List<String>> chavesPossiveis = {
        'titulo': ['titulo', 'nome_concurso'],
        'orgao': ['orgao', 'instituicao'],
        'banca': ['banca', 'organizadora'],
        'localProva': ['local_prova', 'locais_prova', 'cidades_prova', 'local', 'locais', 'cidades'],
        'valorInscricao': ['valor_inscricao', 'taxa_inscricao', 'valor_taxa', 'inscricao.valor'],
        'totalQuestoes': ['total_questoes', 'numero_questoes', 'prova.total_questoes'],
        'formatoProva': ['formato_prova', 'tipo_prova', 'prova.formato', 'formato'],
        'temaProvaSubjetiva': ['tema_discursiva', 'tema_subjetiva', 'tema_redacao', 'prova.tema_discursiva', 'prova.discursiva.tema', 'prova.subjetiva.tema'],
      };

      // Adicionar verificações aninhadas em 'concurso' e 'prova'
      if (originais.containsKey('concurso') && originais['concurso'] is Map) {
        Map<String, dynamic> concursoMap = originais['concurso'];
        if (chavesPossiveis.containsKey(chaveMetadados)) {
          for (String chave in chavesPossiveis[chaveMetadados]!) {
            if (concursoMap.containsKey(chave)) {
              valorEditalOriginal = concursoMap[chave];
              if (ValueValidator.isValidValue(valorEditalOriginal)) {
                fonteEditalOriginal = 'dados_originais.concurso.$chave';
                break;
              }
            }
          }
        }
      }
      if (!ValueValidator.isValidValue(valorEditalOriginal) && originais.containsKey('prova') && originais['prova'] is Map) {
        Map<String, dynamic> provaMap = originais['prova'];
        if (chavesPossiveis.containsKey(chaveMetadados)) {
          for (String chave in chavesPossiveis[chaveMetadados]!) {
            // Tratar chaves como 'prova.formato' -> busca 'formato' dentro de 'prova'
            List<String> partesChave = chave.split('.');
            dynamic valorAninhado = provaMap;
            bool encontradoAninhado = true;
            for(String parte in partesChave) {
              if (valorAninhado is Map && valorAninhado.containsKey(parte)) {
                valorAninhado = valorAninhado[parte];
              } else {
                encontradoAninhado = false;
                break;
              }
            }

            if (encontradoAninhado && ValueValidator.isValidValue(valorAninhado)) {
              valorEditalOriginal = valorAninhado;
              fonteEditalOriginal = 'dados_originais.prova.$chave';
              break;
            } else if (provaMap.containsKey(chave)) { // Verificar chave direta se aninhada falhar
              valorEditalOriginal = provaMap[chave];
              if (ValueValidator.isValidValue(valorEditalOriginal)) {
                fonteEditalOriginal = 'dados_originais.prova.$chave';
                break;
              }
            }
          }
        }
      }

      // Verificar chaves no nível raiz se não encontrado em 'concurso' ou 'prova'
      if (!ValueValidator.isValidValue(valorEditalOriginal) && chavesPossiveis.containsKey(chaveMetadados)) {
        for (String chave in chavesPossiveis[chaveMetadados]!) {
          if (originais.containsKey(chave)) {
            valorEditalOriginal = originais[chave];
            if (ValueValidator.isValidValue(valorEditalOriginal)) {
              fonteEditalOriginal = 'dados_originais.$chave';
              break;
            }
          }
        }
      }

      if (ValueValidator.isValidValue(valorEditalOriginal)) {
        valorEncontrado = valorEditalOriginal;
        fonte = fonteEditalOriginal;
        logger.logRecuperacao(plano.id, 'valor_encontrado', {'campo': campoLog, 'fonte': fonte, 'valor_bruto': valorEncontrado});
      } else {
        logger.logRecuperacao(plano.id, 'valor_invalido_ou_nulo_originais', {'campo': campoLog, 'chave': chaveMetadados});
      }
    }

    // Log final e formatação
    String resultadoFinal;
    if (ValueValidator.isValidValue(valorEncontrado)) {
      if (formatarComoLista) {
        resultadoFinal = _formatarLista(valorEncontrado, separador: separadorLista);
      } else {
        resultadoFinal = valorEncontrado.toString();
      }
      logger.logRecuperacao(plano.id, 'busca_concluida', {'campo': campoLog, 'resultado': resultadoFinal, 'fonte': fonte});
    } else {
      resultadoFinal = 'Não informado';
      logger.logRecuperacao(plano.id, 'busca_concluida_sem_valor', {'campo': campoLog, 'fonte_final': fonte});
    }

    return resultadoFinal;
  }

  /// Método para buscar valores usando os serviços específicos
  String _buscarComServicosEspecificos(String chaveMetadados) {
    switch (chaveMetadados) {
      // ConcursoService
      case 'titulo':
        return ConcursoService.obterTitulo(plano, edital);
      case 'orgao':
        return ConcursoService.obterOrgao(plano, edital);
      case 'banca':
        return ConcursoService.obterBanca(plano, edital);
      
      // ProvaService
      case 'formatoProva':
        return ProvaService.obterFormato(plano, edital);
      case 'dataProva':
        return ProvaService.obterData(plano, edital);
      case 'localProva':
        return ProvaService.obterLocal(plano, edital);
      case 'totalQuestoes':
        return ProvaService.obterTotalQuestoes(plano, edital);
      case 'duracaoProva':
        return ProvaService.obterDuracao(plano, edital);
      case 'criteriosAprovacao':
        return ProvaService.obterCriteriosAprovacao(plano, edital);
      case 'criteriosReprovacao':
        return ProvaService.obterCriteriosReprovacao(plano, edital);
      case 'criteriosDesempate':
        return ProvaService.obterCriteriosDesempate(plano, edital);
      case 'temaProvaSubjetiva':
        return ProvaService.obterTemaProvaSubjetiva(plano, edital);
      
      // InscricaoService
      case 'valorInscricao':
        return InscricaoService.obterValor(plano, edital);
      case 'periodoInscricao':
        if (edital != null) {
          return InscricaoService.obterPeriodo(edital);
        }
        break;
      
      // Outros casos
      default:
        break;
    }
    
    return 'Não informado';
  }

  /// Método auxiliar para buscar valores em metadados aninhados
  dynamic _verificarMetadadosAninhados(String path) {
    if (!ValueValidator.isValidValue(plano.metadados)) {
      return null;
    }

    List<String> keys = path.split('.');
    dynamic currentValue = plano.metadados;

    for (String key in keys) {
      if (currentValue is Map && currentValue.containsKey(key)) {
        currentValue = currentValue[key];
        if (currentValue == null) { // Parar se encontrar um nulo no caminho
          return null;
        }
      } else {
        return null; // Chave não encontrada ou não é um mapa
      }
    }
    // Retorna o valor final encontrado, mesmo que seja uma string "null" (a validação será feita depois)
    return currentValue;
  }

  /// Formata uma lista para exibição, tratando diferentes tipos de elementos
  String _formatarLista(dynamic valor, {String separador = ', '}) {
    if (!ValueValidator.isValidValue(valor)) return 'Não informado';

    if (valor is List) {
      if (valor.isEmpty) return 'Não informado';
      // Mapeia cada item para string, tratando mapas internos
      return valor.map((item) {
        if (item is Map) {
          // Tenta extrair um 'nome' ou 'descricao', senão usa toString
          return item['nome']?.toString() ?? item['descricao']?.toString() ?? item.toString();
        }
        return item.toString();
      }).join(separador);
    }

    // Se não for lista, retorna como string
    return valor.toString();
  }

  /// Obtém a data da prova de várias fontes possíveis
  String obterDataProva() {
    return ProvaService.obterData(plano, edital);
  }

  /// Obtém as matérias do plano
  List<ConteudoProgramatico> obterMaterias() {
    if (edital == null || plano.cargoIds.isEmpty) {
      return [];
    }

    final cargoId = plano.cargoIds.first;
    try {
      Cargo? cargo = edital!.dadosExtraidos.cargos.firstWhere(
        (c) => c.id == cargoId || c.nome.toLowerCase() == cargoId.toLowerCase()
      );
      return cargo.conteudoProgramatico;
    } catch (e) {
      logger.logRecuperacao(plano.id, 'erro_obter_materias', {'erro': e.toString()});
      return [];
    }
  }

  /// Mapeia chaves do plano para chaves do edital
  String _mapearChavePlanoParaEdital(String chavePlano) {
    // Mapeamento de chaves do plano para chaves do edital
    Map<String, List<String>> mapeamentoChaves = {
      'titulo': ['titulo', 'nome', 'titulo_concurso', 'nome_concurso'],
      'orgao': ['orgao', 'orgao_responsavel', 'instituicao'],
      'banca': ['banca', 'banca_organizadora', 'organizadora'],
      'dataProva': ['data_prova', 'data', 'data_realizacao'],
      'localProva': ['local_prova', 'local', 'local_realizacao', 'cidades_prova'],
      'valorInscricao': ['valor_inscricao', 'taxa_inscricao', 'valor_taxa', 'inscricao.valor'],
      'totalQuestoes': ['total_questoes', 'numero_questoes', 'qtd_questoes'],
      'formatoProva': ['formato_prova', 'formato', 'tipo_prova'],
      'temaProvaSubjetiva': ['tema_discursiva', 'tema_subjetiva', 'tema_redacao'],
      'criteriosAprovacao': ['criterios_aprovacao', 'criterios_de_aprovacao'],
      'criteriosReprovacao': ['criterios_reprovacao', 'criterios_de_reprovacao'],
      'duracaoProva': ['duracao_prova', 'duracao', 'tempo_prova'],
      'cotas': ['cotas', 'vagas_reservadas', 'reserva_vagas'],
    };

    // Retornar a primeira chave mapeada ou a própria chave se não houver mapeamento
    if (mapeamentoChaves.containsKey(chavePlano)) {
      return mapeamentoChaves[chavePlano]!.first;
    }

    // Converter camelCase para snake_case se não houver mapeamento específico
    if (chavePlano.contains(RegExp(r'[A-Z]'))) {
      return chavePlano.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}'
      );
    }

    return chavePlano;
  }
}
