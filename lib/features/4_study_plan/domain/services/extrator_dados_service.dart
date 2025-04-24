import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/plano_data_logger.dart';
import 'formatador_service.dart';

/// Serviço para extração de dados do edital e plano
class ExtratorDadosService {
  final PlanoDataLogger _logger = PlanoDataLogger();

  /// Obtém o valor do concurso a partir de chaves nos metadados e dados originais
  String obterValorConcurso(PlanoEstudo plano, Edital? edital, String chaveMetadados, String chaveDadosOriginais) {
    _logger.logRecuperacao(plano.id, 'obter_valor_concurso', {
      'chave_metadados': chaveMetadados,
      'chave_dados_originais': chaveDadosOriginais,
    });
    debugPrint('\nVERIFICAÇÃO DE EXIBIÇÃO - Buscando: $chaveMetadados / $chaveDadosOriginais');

    // Verificar primeiro nos metadados do plano
    if (plano.metadados.containsKey(chaveMetadados) &&
        plano.metadados[chaveMetadados] != null &&
        plano.metadados[chaveMetadados].toString().isNotEmpty &&
        plano.metadados[chaveMetadados].toString() != 'null') {
      var valor = plano.metadados[chaveMetadados].toString();

      // Formatar o valor se for o formato da prova
      if (chaveMetadados == 'formatoProva') {
        valor = FormatadorService.formatarFormatoProva(valor);
      }

      _logger.logRecuperacao(plano.id, 'valor_encontrado_metadados', {
        'chave': chaveMetadados,
        'valor': valor,
        'origem': 'metadados_plano',
      });
      debugPrint('  Encontrado nos metadados do plano: $valor');
      return valor;
    }

    // Verificar em chaves alternativas nos metadados do plano
    Map<String, List<String>> chavesAlternativas = {
      'titulo': ['titulo_concurso', 'nome_concurso', 'nome', 'concurso.titulo', 'concurso.nome'],
      'orgao': ['orgao_responsavel', 'instituicao', 'entidade', 'concurso.orgao', 'concurso.orgao_responsavel'],
      'banca': ['banca_organizadora', 'organizadora', 'concurso.banca', 'concurso.banca_organizadora'],
      'dataProva': ['data_prova', 'data_realizacao', 'data', 'prova.data', 'concurso.data_prova', 'prova.data_realizacao'],
      'localProva': ['local_prova', 'local_realizacao', 'local', 'prova.local', 'concurso.local_prova', 'prova.local_realizacao'],
      'formatoProva': ['formato', 'tipo_prova', 'prova.formato', 'concurso.formato_prova', 'prova.tipo'],
      'temaProvaSubjetiva': ['tema_discursiva', 'tema_subjetiva', 'tema_redacao', 'prova.tema_discursiva', 'concurso.tema_discursiva'],
      'totalQuestoes': ['total_questoes', 'numero_questoes', 'qtd_questoes', 'prova.total_questoes', 'concurso.total_questoes'],
      'criteriosAprovacao': ['criterios_aprovacao', 'criterios_de_aprovacao', 'prova.criterios_aprovacao'],
      'criteriosReprovacao': ['criterios_reprovacao', 'criterios_de_reprovacao', 'prova.criterios_reprovacao'],
      'duracaoProva': ['duracao_prova', 'duracao', 'tempo_prova', 'prova.duracao', 'concurso.duracao_prova'],
      'valorInscricao': ['valor_inscricao', 'taxa_inscricao', 'valor_taxa', 'concurso.valor_inscricao', 'inscricao.valor'],
    };

    if (chavesAlternativas.containsKey(chaveMetadados)) {
      for (String chaveAlt in chavesAlternativas[chaveMetadados]!) {
        if (plano.metadados.containsKey(chaveAlt) &&
            plano.metadados[chaveAlt] != null &&
            plano.metadados[chaveAlt].toString().isNotEmpty &&
            plano.metadados[chaveAlt].toString() != 'null') {
          var valor = plano.metadados[chaveAlt].toString();

          // Formatar o valor se for o formato da prova
          if (chaveMetadados == 'formatoProva') {
            valor = FormatadorService.formatarFormatoProva(valor);
          }

          _logger.logRecuperacao(plano.id, 'valor_encontrado_metadados_alt', {
            'chave_original': chaveMetadados,
            'chave_alternativa': chaveAlt,
            'valor': valor,
            'origem': 'metadados_plano',
          });
          debugPrint('  Encontrado nos metadados do plano (chave alternativa $chaveAlt): $valor');
          return valor;
        }
      }
    }

    // Se não encontrou nos metadados ou não há edital, retornar valor padrão
    if (edital == null) {
      return 'Não informado';
    }

    // Verificar em estruturas aninhadas nos metadados do plano
    List<String> estruturasAninhadas = ['concurso', 'prova', 'edital', 'planoEstudos'];
    for (String estrutura in estruturasAninhadas) {
      if (plano.metadados.containsKey(estrutura) && plano.metadados[estrutura] is Map) {
        Map<String, dynamic> estruturaMap = Map<String, dynamic>.from(plano.metadados[estrutura] as Map);

        // Verificar a chave direta na estrutura
        if (estruturaMap.containsKey(chaveMetadados) &&
            estruturaMap[chaveMetadados] != null &&
            estruturaMap[chaveMetadados].toString().isNotEmpty &&
            estruturaMap[chaveMetadados].toString() != 'null') {
          var valor = estruturaMap[chaveMetadados].toString();

          // Formatar o valor se for o formato da prova
          if (chaveMetadados == 'formatoProva' || (estrutura == 'prova' && chaveMetadados == 'formato')) {
            valor = FormatadorService.formatarFormatoProva(valor);
          }

          _logger.logRecuperacao(plano.id, 'valor_encontrado_metadados_aninhados', {
            'chave': chaveMetadados,
            'estrutura': estrutura,
            'valor': valor,
            'origem': 'metadados_plano.$estrutura',
          });
          debugPrint('  Encontrado nos metadados do plano (estrutura aninhada $estrutura): $valor');
          return valor;
        }

        // Verificar chaves alternativas na estrutura
        if (chavesAlternativas.containsKey(chaveMetadados)) {
          for (String chaveAlt in chavesAlternativas[chaveMetadados]!) {
            if (estruturaMap.containsKey(chaveAlt) &&
                estruturaMap[chaveAlt] != null &&
                estruturaMap[chaveAlt].toString().isNotEmpty &&
                estruturaMap[chaveAlt].toString() != 'null') {
              var valor = estruturaMap[chaveAlt].toString();

              // Formatar o valor se for o formato da prova
              if (chaveMetadados == 'formatoProva') {
                valor = FormatadorService.formatarFormatoProva(valor);
              }

              _logger.logRecuperacao(plano.id, 'valor_encontrado_metadados_aninhados_alt', {
                'chave_original': chaveMetadados,
                'chave_alternativa': chaveAlt,
                'estrutura': estrutura,
                'valor': valor,
                'origem': 'metadados_plano.$estrutura',
              });
              debugPrint('  Encontrado nos metadados do plano (estrutura aninhada $estrutura, chave alternativa $chaveAlt): $valor');
              return valor;
            }
          }
        }
      }
    }

    // Verificar nos dados extraídos do edital
    final dadosExtraidos = edital.dadosExtraidos;

    // Primeiro, verificar usando o switch para campos conhecidos
    String? valorExtraido;
    switch (chaveMetadados) {
      case 'titulo':
        if (dadosExtraidos.titulo != null && dadosExtraidos.titulo!.isNotEmpty) {
          valorExtraido = dadosExtraidos.titulo;
        }
        break;
      case 'orgao':
        if (dadosExtraidos.orgao != null && dadosExtraidos.orgao!.isNotEmpty) {
          valorExtraido = dadosExtraidos.orgao;
        }
        break;
      case 'banca':
        if (dadosExtraidos.banca != null && dadosExtraidos.banca!.isNotEmpty &&
            dadosExtraidos.banca!.toLowerCase() != 'não especificado') {
          valorExtraido = dadosExtraidos.banca;
        }
        break;
      case 'dataProva':
        if (dadosExtraidos.dataProva != null && dadosExtraidos.dataProva!.isNotEmpty) {
          valorExtraido = dadosExtraidos.dataProva;
        }
        break;
      case 'localProva':
        if (dadosExtraidos.localProva != null && dadosExtraidos.localProva!.isNotEmpty) {
          valorExtraido = dadosExtraidos.localProva;
        }
        break;
      case 'valorInscricao':
        if (dadosExtraidos.valorTaxa != null) {
          valorExtraido = dadosExtraidos.valorTaxa.toString();
        }
        break;
    }

    // Se encontrou valor, retornar
    if (valorExtraido != null && valorExtraido.isNotEmpty) {
      debugPrint('  Encontrado no dadosExtraidos.$chaveMetadados: $valorExtraido');

      // Formatar o valor se for o formato da prova
      if (chaveMetadados == 'formatoProva') {
        valorExtraido = FormatadorService.formatarFormatoProva(valorExtraido);
      }

      return valorExtraido;
    }

    // Verificar em dadosProva
    if (dadosExtraidos.dadosProva != null) {
      switch (chaveMetadados) {
        case 'totalQuestoes':
          if (dadosExtraidos.dadosProva!.totalQuestoes != null) {
            valorExtraido = dadosExtraidos.dadosProva!.totalQuestoes.toString();
          }
          break;
        case 'formatoProva':
          if (dadosExtraidos.dadosProva!.formato != null && dadosExtraidos.dadosProva!.formato!.isNotEmpty) {
            valorExtraido = FormatadorService.formatarFormatoProva(dadosExtraidos.dadosProva!.formato!.join(', '));
          }
          break;
        case 'temaProvaSubjetiva':
          if (dadosExtraidos.dadosProva!.temaDiscursiva != null && dadosExtraidos.dadosProva!.temaDiscursiva!.isNotEmpty) {
            valorExtraido = dadosExtraidos.dadosProva!.temaDiscursiva;
          }
          break;
        case 'criteriosAprovacao':
          if (dadosExtraidos.dadosProva!.criteriosAprovacao != null && dadosExtraidos.dadosProva!.criteriosAprovacao!.isNotEmpty) {
            valorExtraido = dadosExtraidos.dadosProva!.criteriosAprovacao;
          }
          break;
        case 'criteriosReprovacao':
          if (dadosExtraidos.dadosProva!.criteriosReprovacao != null && dadosExtraidos.dadosProva!.criteriosReprovacao!.isNotEmpty) {
            valorExtraido = dadosExtraidos.dadosProva!.criteriosReprovacao;
          }
          break;
        case 'duracaoProva':
          if (dadosExtraidos.dadosProva!.duracao != null && dadosExtraidos.dadosProva!.duracao!.isNotEmpty) {
            valorExtraido = dadosExtraidos.dadosProva!.duracao;
          }
          break;
        case 'dataProva':
          if (dadosExtraidos.dadosProva!.dataRealizacao != null) {
            valorExtraido = FormatadorService.formatarData(dadosExtraidos.dadosProva!.dataRealizacao!);
          }
          break;
      }

      // Se encontrou valor em dadosProva, retornar
      if (valorExtraido != null && valorExtraido.isNotEmpty) {
        debugPrint('  Encontrado no dadosExtraidos.dadosProva.$chaveMetadados: $valorExtraido');
        return valorExtraido;
      }
    }

    // Verificar nos dados originais do edital
    if (edital.dadosOriginais != null) {
      // Verificar se a chave contém pontos (indicando caminho aninhado)
      if (chaveDadosOriginais.contains('.')) {
        final partes = chaveDadosOriginais.split('.');
        dynamic valor = edital.dadosOriginais;
        bool encontrado = true;

        // Navegar pela estrutura aninhada
        for (var parte in partes) {
          if (valor is Map && valor.containsKey(parte)) {
            valor = valor[parte];
          } else {
            encontrado = false;
            break;
          }
        }

        if (encontrado && valor != null && valor.toString() != 'null' && valor.toString().isNotEmpty) {
          var valorStr = valor.toString();

          // Formatar o valor se for o formato da prova
          if (chaveDadosOriginais.contains('formato') || chaveDadosOriginais.contains('tipo_prova')) {
            valorStr = FormatadorService.formatarFormatoProva(valorStr);
          }

          debugPrint('  Encontrado nos dados originais aninhados: $valorStr');
          return valorStr;
        }
      }

      // Verificar a chave direta nos dados originais
      if (edital.dadosOriginais!.containsKey(chaveDadosOriginais) &&
          edital.dadosOriginais![chaveDadosOriginais] != null &&
          edital.dadosOriginais![chaveDadosOriginais].toString() != 'null' &&
          edital.dadosOriginais![chaveDadosOriginais].toString().isNotEmpty) {
        var valorStr = edital.dadosOriginais![chaveDadosOriginais].toString();

        // Formatar o valor se for o formato da prova
        if (chaveDadosOriginais.contains('formato') || chaveDadosOriginais.contains('tipo_prova')) {
          valorStr = FormatadorService.formatarFormatoProva(valorStr);
        }

        debugPrint('  Encontrado nos dados originais: $valorStr');
        return valorStr;
      }

      // Verificar chaves alternativas nos dados originais
      Map<String, List<String>> chavesAlternativasDadosOriginais = {
        'titulo': ['titulo', 'titulo_concurso', 'nome_concurso', 'nome'],
        'orgao': ['orgao', 'orgao_responsavel', 'instituicao', 'entidade'],
        'banca': ['banca', 'banca_organizadora', 'organizadora'],
        'dataProva': ['data_prova', 'data_realizacao', 'data'],
        'localProva': ['local_prova', 'local_realizacao', 'local'],
        'formatoProva': ['formato_prova', 'formato', 'tipo_prova'],
        'temaProvaSubjetiva': ['tema_prova_subjetiva', 'tema_discursiva', 'tema_subjetiva', 'tema_redacao'],
        'totalQuestoes': ['total_questoes', 'numero_questoes', 'qtd_questoes'],
        'criteriosAprovacao': ['criterios_aprovacao', 'criterios_de_aprovacao'],
        'criteriosReprovacao': ['criterios_reprovacao', 'criterios_de_reprovacao'],
        'duracaoProva': ['duracao_prova', 'duracao', 'tempo_prova'],
        'valorInscricao': ['valor_inscricao', 'taxa_inscricao', 'valor_taxa'],
      };

      if (chavesAlternativasDadosOriginais.containsKey(chaveMetadados)) {
        for (String chaveAlt in chavesAlternativasDadosOriginais[chaveMetadados]!) {
          if (edital.dadosOriginais!.containsKey(chaveAlt) &&
              edital.dadosOriginais![chaveAlt] != null &&
              edital.dadosOriginais![chaveAlt].toString() != 'null' &&
              edital.dadosOriginais![chaveAlt].toString().isNotEmpty) {
            var valorStr = edital.dadosOriginais![chaveAlt].toString();

            // Formatar o valor se for o formato da prova
            if (chaveMetadados == 'formatoProva') {
              valorStr = FormatadorService.formatarFormatoProva(valorStr);
            }

            debugPrint('  Encontrado nos dados originais (chave alternativa $chaveAlt): $valorStr');
            return valorStr;
          }
        }
      }

      // Verificar em concurso nos dados originais
      if (edital.dadosOriginais!.containsKey('concurso') && edital.dadosOriginais!['concurso'] is Map) {
        Map<String, dynamic> concursoMap = Map<String, dynamic>.from(edital.dadosOriginais!['concurso'] as Map);

        // Verificar a chave direta em concurso
        if (concursoMap.containsKey(chaveMetadados.replaceAll('concurso.', '')) &&
            concursoMap[chaveMetadados.replaceAll('concurso.', '')] != null &&
            concursoMap[chaveMetadados.replaceAll('concurso.', '')].toString() != 'null' &&
            concursoMap[chaveMetadados.replaceAll('concurso.', '')].toString().isNotEmpty) {
          var valorStr = concursoMap[chaveMetadados.replaceAll('concurso.', '')].toString();

          // Formatar o valor se for o formato da prova
          if (chaveMetadados == 'formatoProva') {
            valorStr = FormatadorService.formatarFormatoProva(valorStr);
          }

          debugPrint('  Encontrado nos dados originais (concurso): $valorStr');
          return valorStr;
        }

        // Verificar chaves alternativas em concurso
        if (chavesAlternativasDadosOriginais.containsKey(chaveMetadados)) {
          for (String chaveAlt in chavesAlternativasDadosOriginais[chaveMetadados]!) {
            if (concursoMap.containsKey(chaveAlt) &&
                concursoMap[chaveAlt] != null &&
                concursoMap[chaveAlt].toString() != 'null' &&
                concursoMap[chaveAlt].toString().isNotEmpty) {
              var valorStr = concursoMap[chaveAlt].toString();

              // Formatar o valor se for o formato da prova
              if (chaveMetadados == 'formatoProva') {
                valorStr = FormatadorService.formatarFormatoProva(valorStr);
              }

              debugPrint('  Encontrado nos dados originais (concurso, chave alternativa $chaveAlt): $valorStr');
              return valorStr;
            }
          }
        }
      }
    }

    // Se não encontrou nada, retornar valor padrão
    debugPrint('  Não encontrado em nenhum lugar. Retornando valor padrão.');
    return 'Não informado';
  }

  /// Obtém o valor numérico do concurso
  double obterValorNumerico(PlanoEstudo plano, Edital? edital, String chaveMetadados, String chaveDadosOriginais) {
    String valorStr = obterValorConcurso(plano, edital, chaveMetadados, chaveDadosOriginais);
    
    if (valorStr == 'Não informado') {
      return 0.0;
    }
    
    return FormatadorService.extrairValorNumericoDeString(valorStr);
  }

  /// Obtém o período de inscrições
  String obterPeriodoInscricoes(Edital? edital) {
    if (edital == null) return 'Não informado';

    final inicio = edital.dadosExtraidos.inicioInscricao;
    final fim = edital.dadosExtraidos.fimInscricao;

    if (inicio == null || fim == null) {
      // Tentar obter dos dados originais
      if (edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map && inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
          return '${inscricoes['inicio']} a ${inscricoes['fim']}';
        }
      }
      return 'Não informado';
    }

    return '${FormatadorService.formatarData(inicio)} a ${FormatadorService.formatarData(fim)}';
  }

  /// Obtém informações sobre cotas
  String obterInformacoesCotas(Edital? edital) {
    if (edital == null || edital.dadosExtraidos.cotas == null || edital.dadosExtraidos.cotas!.isEmpty) {
      // Verificar nos dados originais
      if (edital != null && edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cotas')) {
        final cotas = edital.dadosOriginais!['cotas'];
        if (cotas is List && cotas.isNotEmpty) {
          List<String> cotasInfo = [];
          for (var cota in cotas) {
            if (cota is Map && cota.containsKey('nome')) {
              String cotaStr = cota['nome'].toString();
              if (cota.containsKey('percentual') && cota['percentual'] != null) {
                cotaStr += ' (${cota['percentual']}%)';
              }
              cotasInfo.add(cotaStr);
            }
          }
          if (cotasInfo.isNotEmpty) {
            return cotasInfo.join(', ');
          }
        }
      }
      
      debugPrint('  Nenhuma informação sobre cotas encontrada');
      return 'Não informado';
    }

    List<String> cotasInfo = [];
    for (var cota in edital.dadosExtraidos.cotas!) {
      String cotaStr = cota.nome;
      if (cota.percentual != null) {
        cotaStr += ' (${cota.percentual}%)';
      }
      cotasInfo.add(cotaStr);
    }

    return cotasInfo.join(', ');
  }

  /// Obtém emoji para o tipo de informação
  String getEmojiForInfoType(String label) {
    final labelLower = label.toLowerCase();
    
    switch (labelLower) {
      case 'período de inscrições':
      case 'data da prova':
        return '📅';
      case 'nome':
      case 'título':
        return '📝';
      case 'órgão':
        return '🏢';
      case 'banca':
        return '👨‍⚖️';
      case 'cargo':
        return '👔';
      case 'vagas':
        return '🎯';
      case 'local das provas':
        return '🏫';
      case 'cotas':
        return '♿';
      case 'taxa de inscrição':
        return '💰';
      case 'salário':
        return '💵';
      case 'escolaridade':
      case 'nível':
        return '🎓';
      case 'total de questões':
        return '❓';
      case 'formato':
        return '📋';
      case 'duração':
        return '⏱️';
      case 'critérios de aprovação':
        return '✅';
      case 'critérios de reprovação':
        return '❌';
      case 'critérios de desempate':
        return '🔄';
      case 'tema da prova subjetiva':
        return '📄';
      default:
        return '📌';
    }
  }

  /// Obtém cor para o tipo de informação
  Color getColorForInfoType(String label) {
    final labelLower = label.toLowerCase();
    
    switch (labelLower) {
      case 'período de inscrições':
      case 'data da prova':
        return Colors.red;
      case 'nome':
      case 'título':
      case 'órgão':
      case 'banca':
        return Colors.blue;
      case 'cargo':
        return Colors.purple;
      case 'vagas':
        return Colors.orange;
      case 'local das provas':
        return Colors.orange;
      case 'cotas':
        return Colors.purple;
      case 'taxa de inscrição':
      case 'salário':
        return Colors.green;
      case 'escolaridade':
      case 'nível':
        return Colors.orange;
      case 'total de questões':
        return Colors.blue;
      case 'formato':
        return Colors.purple;
      case 'duração':
        return Colors.orange;
      case 'critérios de aprovação':
        return Colors.green;
      case 'critérios de reprovação':
        return Colors.red;
      case 'critérios de desempate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Obtém cor para a matéria
  Color getColorForMateria(String nomeMateria) {
    final nomeNormalizado = nomeMateria.toLowerCase();
    
    if (nomeNormalizado.contains('português') || 
        nomeNormalizado.contains('lingua portuguesa') || 
        nomeNormalizado.contains('gramática')) {
      return Colors.blue;
    } else if (nomeNormalizado.contains('matemática') || 
               nomeNormalizado.contains('raciocínio lógico') || 
               nomeNormalizado.contains('estatística')) {
      return Colors.red;
    } else if (nomeNormalizado.contains('direito') || 
               nomeNormalizado.contains('constitucional') || 
               nomeNormalizado.contains('administrativo')) {
      return Colors.purple;
    } else if (nomeNormalizado.contains('informática') || 
               nomeNormalizado.contains('tecnologia')) {
      return Colors.teal;
    } else if (nomeNormalizado.contains('história') || 
               nomeNormalizado.contains('geografia')) {
      return Colors.brown;
    } else if (nomeNormalizado.contains('física') || 
               nomeNormalizado.contains('química') || 
               nomeNormalizado.contains('biologia')) {
      return Colors.green;
    } else if (nomeNormalizado.contains('inglês') || 
               nomeNormalizado.contains('espanhol') || 
               nomeNormalizado.contains('língua estrangeira')) {
      return Colors.orange;
    } else if (nomeNormalizado.contains('atualidades') || 
               nomeNormalizado.contains('conhecimentos gerais')) {
      return Colors.cyan;
    } else {
      // Gerar uma cor baseada no hash do nome da matéria para ter consistência
      final int hash = nomeMateria.hashCode;
      final int r = (hash & 0xFF0000) >> 16;
      final int g = (hash & 0x00FF00) >> 8;
      final int b = hash & 0x0000FF;
      
      return Color.fromRGBO(
        r < 100 ? r + 100 : r, // Garantir que não seja muito escuro
        g < 100 ? g + 100 : g,
        b < 100 ? b + 100 : b,
        1.0,
      );
    }
  }
}
