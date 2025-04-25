import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:concursos_ia/core/data/models/edital.dart';
import 'package:concursos_ia/core/data/models/models.dart';
import 'package:concursos_ia/core/utils/date_formatter.dart';
import 'package:intl/intl.dart';
import 'package:concursos_ia/features/4_study_plan/domain/services/concurso_service.dart';
import 'package:concursos_ia/features/4_study_plan/domain/services/prova_service.dart';
import 'package:concursos_ia/features/4_study_plan/domain/services/inscricao_service.dart';
import 'package:concursos_ia/features/4_study_plan/domain/services/cotas_service.dart';

/// Classe para formatar dados do edital para exibição na UI
class EditalFormatter {
  /// Obtém o nome do concurso formatado
  static String obterNomeConcurso(Edital edital) {
    // Criar um PlanoEstudo temporário para usar com o ConcursoService
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      titulo: edital.nomeConcurso,
      metadados: {},
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 30)),
      cargoIds: [],
    );

    String titulo = ConcursoService.obterTitulo(planoTemp, edital);
    if (titulo != 'Não informado') {
      return titulo;
    }

    // Fallback para o comportamento original
    if (edital.dadosExtraidos.titulo != null && edital.dadosExtraidos.titulo!.isNotEmpty) {
      return edital.dadosExtraidos.titulo!;
    }
    return edital.nomeConcurso.isNotEmpty ? edital.nomeConcurso : 'Concurso não especificado';
  }

  /// Obtém o nome do órgão formatado
  static String obterNomeOrgao(Edital edital) {
    // Criar um PlanoEstudo temporário para usar com o ConcursoService
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      titulo: edital.nomeConcurso,
      metadados: {},
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 30)),
      cargoIds: [],
    );

    String orgao = ConcursoService.obterOrgao(planoTemp, edital);
    if (orgao != 'Não informado') {
      return orgao;
    }

    // Fallback para o comportamento original
    if (edital.dadosExtraidos.orgao != null && edital.dadosExtraidos.orgao!.isNotEmpty) {
      return edital.dadosExtraidos.orgao!;
    }
    return 'Órgão não especificado';
  }

  /// Obtém o nome da banca formatado
  static String obterNomeBanca(Edital edital) {
    // Criar um PlanoEstudo temporário para usar com o ConcursoService
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      titulo: edital.nomeConcurso,
      metadados: {},
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 30)),
      cargoIds: [],
    );

    String banca = ConcursoService.obterBanca(planoTemp, edital);
    if (banca != 'Não informado') {
      return banca;
    }

    // Fallback para o comportamento original
    if (edital.dadosExtraidos.banca != null && edital.dadosExtraidos.banca!.isNotEmpty) {
      return edital.dadosExtraidos.banca!;
    }
    return 'Banca não especificada';
  }

  /// Obtém a data da prova formatada
  static String obterDataProva(Edital edital) {
    // Criar um PlanoEstudo temporário para usar com o ProvaService
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      titulo: edital.nomeConcurso,
      metadados: {},
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 30)),
      cargoIds: [],
    );

    String data = ProvaService.obterData(planoTemp, edital);
    if (data != 'Não informado') {
      return data;
    }

    // Fallback para o comportamento original
    if (edital.dadosExtraidos.dataProva != null) {
      return DateFormatter.formatDate(edital.dadosExtraidos.dataProva!);
    }
    return 'Data não especificada';
  }

  /// Obtém o valor da taxa de inscrição formatado
  static String obterValorTaxa(Edital edital) {
    // Criar um PlanoEstudo temporário para usar com o InscricaoService
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      titulo: edital.nomeConcurso,
      metadados: {},
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 30)),
      cargoIds: [],
    );

    String valor = InscricaoService.obterValor(planoTemp, edital);
    if (valor != 'Não informado') {
      // Tentar formatar o valor
      double? valorDouble = tryParseValor(valor);
      if (valorDouble != null && valorDouble > 0) {
        return formatarValor(valorDouble);
      }
      return valor;
    }

    // Fallback para o comportamento original
    if (edital.dadosExtraidos.valorTaxa != null) {
      // Converter para double se for string
      double? valorOriginal = tryParseValor(edital.dadosExtraidos.valorTaxa);
      if (valorOriginal != null && valorOriginal > 0) {
        return formatarValor(valorOriginal);
      }
    }
    return 'Valor não especificado';
  }

  /// Obtém o período de inscrição formatado
  static String obterPeriodoInscricao(Edital edital) {
    String periodo = InscricaoService.obterPeriodo(edital);
    if (periodo != 'Não informado') {
      return periodo;
    }

    // Fallback para o comportamento original
    final inicio = edital.dadosExtraidos.inicioInscricao;
    final fim = edital.dadosExtraidos.fimInscricao;

    if (inicio == null || fim == null) {
      return 'Período não especificado';
    }

    // DateFormatter.formatDate já lida com diferentes tipos de entrada
    return '${DateFormatter.formatDate(inicio)} a ${DateFormatter.formatDate(fim)}';
  }

  /// Obtém informações sobre cotas do edital
  static String obterInformacoesCotas(Edital edital) {
    String cotas = CotasService.obterInformacoes(edital);
    if (cotas != 'Não informado') {
      return cotas;
    }

    // Se o CotasService não encontrou informações, continuar com a implementação original
    print('DEBUG: Obtendo informações de cotas do edital');
    if (edital.dadosOriginais != null) {
      print('DEBUG: Chaves em dadosOriginais: ${edital.dadosOriginais!.keys.join(', ')}');
    }

    // 1. Verificar se temos cotas no formato da resposta da LLM (dentro de 'concurso')
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('concurso')) {
      final concurso = edital.dadosOriginais!['concurso'];
      if (concurso is Map<String, dynamic> && concurso.containsKey('cotas')) {
        final cotas = concurso['cotas'];
        print('DEBUG: Cotas encontradas no objeto concurso: $cotas');

        // Processar cotas como lista (formato mais comum da resposta da LLM)
        if (cotas is List) {
          List<String> cotasFormatadas = [];
          for (var cota in cotas) {
            if (cota is String) {
              cotasFormatadas.add(cota);
            } else if (cota is Map<String, dynamic>) {
              String cotaStr = '';
              if (cota.containsKey('nome') && cota.containsKey('percentual')) {
                cotaStr = '${cota['nome']}: ${cota['percentual']}';

                // Adicionar subgrupos se existirem
                if (cota.containsKey('subgrupos') && cota['subgrupos'] is List) {
                  final subgrupos = cota['subgrupos'] as List;
                  if (subgrupos.isNotEmpty) {
                    List<String> subgruposFormatados = [];
                    for (var subgrupo in subgrupos) {
                      if (subgrupo is String) {
                        subgruposFormatados.add(subgrupo);
                      } else if (subgrupo is Map) {
                        String subgrupoTexto = subgrupo['nome']?.toString() ??
                                             subgrupo['descricao']?.toString() ??
                                             subgrupo.toString();
                        subgruposFormatados.add(subgrupoTexto);
                      }
                    }
                    if (subgruposFormatados.isNotEmpty) {
                      cotaStr += ' (${subgruposFormatados.join(', ')})';
                    }
                  }
                }
              } else {
                cotaStr = cota.toString();
              }
              cotasFormatadas.add(cotaStr);
            }
          }
          return cotasFormatadas.join('; ');
        }

        // Processar cotas como string
        if (cotas is String) {
          return cotas;
        }

        // Processar cotas como mapa
        if (cotas is Map<String, dynamic>) {
          List<String> cotasFormatadas = [];
          cotas.forEach((key, value) {
            cotasFormatadas.add('$key: $value');
          });
          return cotasFormatadas.join('; ');
        }

        // Se não conseguiu processar, retornar como string
        return cotas.toString();
      }
    }

    // 2. Verificar o formato alternativo de cotas (lista separada)
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cotas_lista')) {
      final cotasList = edital.dadosOriginais!['cotas_lista'];
      print('DEBUG: Tipo de cotas_lista: ${cotasList.runtimeType}');
      print('DEBUG: Conteúdo de cotas_lista: $cotasList');

      if (cotasList is List) {
        List<String> cotasFormatadas = [];
        for (var cota in cotasList) {
          if (cota is Map<String, dynamic>) {
            // Extrair nome e percentual da cota
            final nome = cota['nome']?.toString() ?? '';
            final percentual = cota['percentual']?.toString() ?? '';

            if (nome.isNotEmpty) {
              String cotaStr = '$nome: $percentual';

              // Se tiver subgrupos, adicionar entre parênteses
              if (cota.containsKey('subgrupos') && cota['subgrupos'] is List) {
                final subgrupos = cota['subgrupos'] as List;
                print('DEBUG: Subgrupos para $nome: $subgrupos');

                if (subgrupos.isNotEmpty) {
                  // Processar cada subgrupo para extrair apenas o nome ou valor relevante
                  List<String> subgruposFormatados = [];
                  for (var subgrupo in subgrupos) {
                    print('DEBUG: Processando subgrupo: $subgrupo (${subgrupo.runtimeType})');

                    if (subgrupo is String) {
                      // Limpar a formatação da string
                      String subgrupoLimpo = _limparFormatacaoString(subgrupo);
                      subgruposFormatados.add(subgrupoLimpo);
                    } else if (subgrupo is Map) {
                      // Extrair o nome ou descrição do subgrupo
                      String subgrupoTexto = subgrupo['nome']?.toString() ??
                                           subgrupo['descricao']?.toString() ??
                                           subgrupo.toString();
                      // Limpar a formatação
                      subgrupoTexto = _limparFormatacaoString(subgrupoTexto);
                      subgruposFormatados.add(subgrupoTexto);
                    }
                  }

                  print('DEBUG: Subgrupos formatados: $subgruposFormatados');
                  if (subgruposFormatados.isNotEmpty) {
                    cotaStr += ' (${subgruposFormatados.join(', ')})';
                  }
                }
              }
              cotasFormatadas.add(cotaStr);
            }
          }
        }

        // Se encontrou cotas no formato de lista, retornar
        if (cotasFormatadas.isNotEmpty) {
          String resultado = cotasFormatadas.join('; ');
          print('DEBUG: Informações de cotas formatadas: $resultado');
          return resultado;
        }
      }
    }

    // 3. Verificar o formato antigo (mapa)
    // Mapeamento de chaves possíveis para labels amigáveis
    final mapeamentoCotas = {
      'negros': 'Negros',
      'pcd': 'PcD',
      'deficientes': 'PcD',
      'ppp': 'PPP',
      'indigenas': 'Indígenas',
      'cotaracial': 'Cota Racial',
      'cotapcd': 'Cota PcD',
    };

    // Verificar no mapa de cotas
    if (edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cotas')) {
      final cotasMap = edital.dadosOriginais!['cotas'];
      if (cotasMap is Map) {
        List<String> cotasFormatadas = [];
        cotasMap.forEach((key, value) {
          if (value != null && value.toString() != '0' && value.toString() != 'null' && value.toString().isNotEmpty) {
            final keyLower = key.toString().toLowerCase();
            if (mapeamentoCotas.containsKey(keyLower)) {
               final label = mapeamentoCotas[keyLower]!;
               // Adicionar apenas se não começar com 'total' ou 'ampla'
               if (!keyLower.startsWith('total') && !keyLower.contains('ampla')) {
                 cotasFormatadas.add('$label: $value');
               }
            }
            // Verificar se o valor é um mapa (ex: { 'percentual': 20 })
            else if (value is Map<String, dynamic> && value.containsKey('percentual')) {
               if (mapeamentoCotas.containsKey(keyLower)) {
                  final label = mapeamentoCotas[keyLower]!;
                  cotasFormatadas.add('$label: ${value['percentual']}%');
               }
            }
          }
        });
        if (cotasFormatadas.isNotEmpty) {
          return cotasFormatadas.join('; ');
        }
      }
    }

    // 4. Verificar no texto completo do edital (fallback)
    if (edital.textoCompleto != null && edital.textoCompleto.isNotEmpty) {
      final textoLower = edital.textoCompleto.toLowerCase();
      List<String> cotasFormatadas = [];

      // Buscar padrões específicos de cotas no texto
      final RegExp regexCotasNegros = RegExp(r'([0-9]{1,2})[\s%]*(?:por cento|das vagas)[\s\w]*negros', caseSensitive: false);
      final RegExp regexCotasPCD = RegExp(r'([0-9]{1,2})[\s%]*(?:por cento|das vagas)[\s\w]*(?:defici[\u00ea]ncia|pcd)', caseSensitive: false);

      // Extrair percentual para negros
      final matchNegros = regexCotasNegros.firstMatch(textoLower);
      if (matchNegros != null && matchNegros.groupCount >= 1) {
        final percentual = matchNegros.group(1);
        cotasFormatadas.add('Negros: $percentual%');
      }

      // Extrair percentual para PcD
      final matchPCD = regexCotasPCD.firstMatch(textoLower);
      if (matchPCD != null && matchPCD.groupCount >= 1) {
        final percentual = matchPCD.group(1);
        cotasFormatadas.add('PcD: $percentual%');
      }

      if (cotasFormatadas.isNotEmpty) {
        return cotasFormatadas.join('; ');
      }
    }

    return 'Não informado';
  }

  /// Obtém o ícone apropriado para uma matéria com base em seu nome
  static IconData getIconForMateria(String materiaNome) {
    final nomeLower = materiaNome.toLowerCase();

    if (nomeLower.contains('portug') || nomeLower.contains('gram') || nomeLower.contains('redac')) {
      return Icons.menu_book;
    } else if (nomeLower.contains('matem') || nomeLower.contains('estat') || nomeLower.contains('calc')) {
      return Icons.calculate;
    } else if (nomeLower.contains('direito') || nomeLower.contains('constitu') || nomeLower.contains('admin')) {
      return Icons.gavel;
    } else if (nomeLower.contains('inform') || nomeLower.contains('comput') || nomeLower.contains('dados')) {
      return Icons.computer;
    } else if (nomeLower.contains('contab') || nomeLower.contains('finan') || nomeLower.contains('econom')) {
      return Icons.account_balance;
    } else if (nomeLower.contains('hist') || nomeLower.contains('geogr') || nomeLower.contains('atual')) {
      return Icons.public;
    } else if (nomeLower.contains('ingl') || nomeLower.contains('espa') || nomeLower.contains('franc')) {
      return Icons.translate;
    } else if (nomeLower.contains('fisica') || nomeLower.contains('quim') || nomeLower.contains('biolog')) {
      return Icons.science;
    } else if (nomeLower.contains('rac') && (nomeLower.contains('log') || nomeLower.contains('anal'))) {
      return Icons.psychology;
    }

    // Ícone padrão para outras matérias
    return Icons.school;
  }

  /// Cria um widget de badge de informação para matérias
  static Widget buildInfoBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Método para limpar a formatação de strings (remove colchetes, aspas, etc.)
  static String _limparFormatacaoString(String valor) {
    print('DEBUG: Limpando formatação da string: "$valor"');

    // Verificar se a string é vazia
    if (valor.isEmpty) {
      return '';
    }

    // Remover colchetes externos
    while (valor.startsWith('[') && valor.endsWith(']')) {
      valor = valor.substring(1, valor.length - 1);
    }

    // Remover aspas externas
    while ((valor.startsWith('"') && valor.endsWith('"')) || (valor.startsWith('\'') && valor.endsWith('\'')))
    {
      valor = valor.substring(1, valor.length - 1);
    }

    // Remover espaços extras no início e fim
    valor = valor.trim();

    // Verificar se a string é uma lista JSON
    if (valor.startsWith('[') && valor.endsWith(']')) {
      try {
        // Tentar decodificar como JSON
        List<dynamic> lista = json.decode(valor);
        // Converter cada item para string e juntar com vírgula
        valor = lista.map((item) => item.toString()).join(', ');
      } catch (e) {
        // Se não for um JSON válido, continuar com a abordagem de substituição
        print('DEBUG: Erro ao decodificar JSON: $e');
        // Remover colchetes internos e aspas em listas (simplificado)
        valor = valor.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll('\'', '');
      }
    } else {
      // Remover colchetes internos e aspas em listas (simplificado)
      valor = valor.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll('\'', '');
    }

    // Substituir múltiplas vírgulas ou espaços por vírgula e espaço
    valor = valor.split(RegExp(r'\s*,\s*')).map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

    print('DEBUG: Resultado após limpeza: "$valor"');
    return valor;
  }

  /// Formata um valor monetário
  static String formatarValor(dynamic valor) {
    // Se for nulo, retornar valor padrão
    if (valor == null) {
      return '0,00';
    }

    // Converter para double se for string
    double? valorDouble = tryParseValor(valor);
    if (valorDouble == null) {
      return valor.toString();
    }

    // Formatar com separador de milhares e duas casas decimais
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );

    return formatter.format(valorDouble);
  }

  /// Tenta converter um valor para double
  static double? tryParseValor(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is double) {
      return valor;
    }

    if (valor is int) {
      return valor.toDouble();
    }

    if (valor is String) {
      // Remover símbolos de moeda e substituir vírgula por ponto
      String valorLimpo = valor
          .replaceAll('R\$', '')
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();

      return double.tryParse(valorLimpo);
    }

    return null;
  }

  /// Cria um widget de item de informação com label e valor
  static Widget buildInfoItem(BuildContext context, String label, String value, [Color? customColor]) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color labelColor;
    Color valueColor;
    Color boxColor;
    Color shadowColor;
    String emoji = '💡 '; // Padrão

    // Definir cor e emoji baseado na label ou customColor
    if (customColor != null) {
      boxColor = customColor;
      shadowColor = customColor.withOpacity(0.7);
      labelColor = Colors.white; // Assumir texto branco para contraste em cores customizadas
      valueColor = Colors.white;
      // Definir emoji baseado na label mesmo com cor customizada
      switch (label) {
         case 'Nome': emoji = '🎓 '; break;
         case 'Órgão': emoji = '🏢 '; break;
         case 'Banca': emoji = '📚 '; break;
         case 'Data da Prova':
         case 'Data da Prova Objetiva':
         case 'Data da Prova Subjetiva': emoji = '📅 '; break;
         case 'Duração da Prova': emoji = '⏰ '; break;
         case 'Taxa de Inscrição': emoji = '💰 '; break;
         case 'Período de Inscrição': emoji = '📃 '; break;
         case 'Cargo Escolhido': emoji = '💼 '; break;
         case 'Salário': emoji = '💵 '; break;
         case 'Cotas': emoji = '🔄 '; break;
         case 'Escolaridade': emoji = '🎯 '; break;
         case 'Requisitos': emoji = '📋 '; break;
         case 'Critérios de Aprovação': emoji = '✅ '; break;
         case 'Critérios de Reprovação': emoji = '❌ '; break;
         case 'Pontuação da Prova Discursiva': emoji = '📝 '; break;
         case 'Tema da Prova Subjetiva': emoji = '📄 '; break;
         default: emoji = '💡 '; break;
      }
    } else {
      // Definir cor e emoji baseado na label
      switch (label) {
        // Datas importantes (vermelho)
        case 'Data da Prova':
        case 'Data da Prova Objetiva':
        case 'Data da Prova Subjetiva':
          boxColor = Colors.red.shade700;
          shadowColor = Colors.red.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '📅 ';
          break;
        case 'Período de Inscrição':
          boxColor = Colors.red.shade700;
          shadowColor = Colors.red.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '📃 ';
          break;
        case 'Duração da Prova':
          boxColor = Colors.red.shade700;
          shadowColor = Colors.red.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '⏰ ';
          break;

        // Informações principais do concurso (azul)
        case 'Nome':
          boxColor = Colors.blue.shade700;
          shadowColor = Colors.blue.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '🎓 ';
          break;
        case 'Órgão':
          boxColor = Colors.blue.shade700;
          shadowColor = Colors.blue.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '🏢 ';
          break;
        case 'Banca':
          boxColor = Colors.blue.shade700;
          shadowColor = Colors.blue.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '📚 ';
          break;

        // Informações financeiras (verde)
        case 'Taxa de Inscrição':
        case 'Salário':
          boxColor = Colors.green.shade700;
          shadowColor = Colors.green.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = label == 'Taxa de Inscrição' ? '💰 ' : '💵 ';
          break;

        // Informações do cargo (roxo)
        case 'Cargo Escolhido':
        case 'Escolaridade':
        case 'Requisitos':
          boxColor = Colors.purple.shade700;
          shadowColor = Colors.purple.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = label == 'Cargo Escolhido' ? '💼 ' : (label == 'Escolaridade' ? '🎯 ' : '📋 ');
          break;

        // Cotas (laranja)
        case 'Cotas':
          boxColor = Colors.orange.shade700;
          shadowColor = Colors.orange.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '🔄 ';
          break;

        // Critérios (verde/vermelho)
        case 'Critérios de Aprovação':
          boxColor = Colors.green.shade700;
          shadowColor = Colors.green.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '✅ ';
          break;
        case 'Critérios de Reprovação':
          boxColor = Colors.red.shade700;
          shadowColor = Colors.red.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = '❌ ';
          break;

        // Outras informações (teal)
        case 'Pontuação da Prova Discursiva':
        case 'Tema da Prova Subjetiva':
          boxColor = Colors.teal.shade700;
          shadowColor = Colors.teal.shade900;
          labelColor = Colors.white;
          valueColor = Colors.white;
          emoji = label == 'Pontuação da Prova Discursiva' ? '📝 ' : '📄 ';
          break;

        // Padrão (âmbar)
        default:
          boxColor = Colors.amber.shade700;
          shadowColor = Colors.amber.shade900;
          labelColor = isDarkMode ? Colors.black : Colors.black87;
          valueColor = isDarkMode ? Colors.black : Colors.black87;
          emoji = '💡 ';
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinhar no topo para textos longos
          children: [
            Text(
              '$emoji$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: labelColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor.withOpacity(0.95), // Leve transparência para valor
                  fontSize: 14,
                ),
                softWrap: true, // Permitir quebra de linha
              ),
            ),
          ],
        ),
      ),
    );
  }
}
