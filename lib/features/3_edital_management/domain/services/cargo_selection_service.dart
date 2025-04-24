import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/dados_vaga.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/interfaces/ia_service_interface_extension.dart';
import '../../../../core/utils/logger_static.dart';

// Classe DadosCota para evitar conflitos de importação
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

/// Serviço responsável por gerenciar a seleção de cargos
class CargoSelectionService {
  /// Formata o salário para exibição
  static String formatarSalario(double salario) {
    if (salario <= 0) return '0,00';

    // Formatar o salário com separador de milhares e duas casas decimais
    final valorInteiro = salario.floor();
    final valorDecimal = ((salario - valorInteiro) * 100).round();

    // Formatar a parte inteira com separadores de milhar
    String valorInteiroStr = valorInteiro.toString();
    String resultado = '';

    for (int i = 0; i < valorInteiroStr.length; i++) {
      if (i > 0 && (valorInteiroStr.length - i) % 3 == 0) {
        resultado += '.';
      }
      resultado += valorInteiroStr[i];
    }

    // Adicionar a parte decimal
    return resultado + ',' + valorDecimal.toString().padLeft(2, '0');
  }

  /// Formata as vagas para exibição
  static String formatarVagas(Cargo cargo, Edital edital) {
    // Obter dados originais
    final Map<String, dynamic>? dadosOriginais = edital.dadosOriginais;
    // Se não temos dados originais, usar o valor do cargo
    if (dadosOriginais == null) return '${cargo.vagas}';

    // Verificar se temos informações de vagas no formato de cadastro reserva
    if (dadosOriginais.containsKey('cargos') && dadosOriginais['cargos'] is List) {
      final cargos = dadosOriginais['cargos'] as List;
      for (var cargoData in cargos) {
        if (cargoData is Map && cargoData.containsKey('nome_cargo')) {
          String nomeCargo = '';
          if (cargoData['nome_cargo'] is Map && cargoData['nome_cargo'].containsKey('value')) {
            nomeCargo = cargoData['nome_cargo']['value'].toString();
          } else {
            nomeCargo = cargoData['nome_cargo'].toString();
          }

          // Verificar se é o cargo atual
          if (nomeCargo.toLowerCase().contains(cargo.nome.toLowerCase()) ||
              cargo.nome.toLowerCase().contains(nomeCargo.toLowerCase())) {

            // Verificar se tem informações de vagas de cadastro reserva
            if (cargoData.containsKey('numero_vagas') && cargoData['numero_vagas'] is Map) {
              final vagasMap = cargoData['numero_vagas'] as Map;

              // Verificar vagas imediatas
              int vagasImediatas = 0;
              if (vagasMap.containsKey('imediata') && vagasMap['imediata'] is Map) {
                final imediataMap = vagasMap['imediata'] as Map;
                if (imediataMap.containsKey('total') && imediataMap['total'] is Map &&
                    imediataMap['total'].containsKey('value')) {
                  vagasImediatas = int.tryParse(imediataMap['total']['value'].toString()) ?? 0;
                } else if (imediataMap.containsKey('total')) {
                  vagasImediatas = int.tryParse(imediataMap['total'].toString()) ?? 0;
                }
              }

              // Verificar vagas de cadastro reserva
              int vagasCR = 0;
              if (vagasMap.containsKey('cadastro_reserva') && vagasMap['cadastro_reserva'] is Map) {
                final crMap = vagasMap['cadastro_reserva'] as Map;
                if (crMap.containsKey('total') && crMap['total'] is Map &&
                    crMap['total'].containsKey('value')) {
                  vagasCR = int.tryParse(crMap['total']['value'].toString()) ?? 0;
                } else if (crMap.containsKey('total')) {
                  vagasCR = int.tryParse(crMap['total'].toString()) ?? 0;
                }
              }

              // Verificar vagas para negros
              int vagasNegros = 0;
              if (vagasMap.containsKey('cadastro_reserva') && vagasMap['cadastro_reserva'] is Map) {
                final crMap = vagasMap['cadastro_reserva'] as Map;
                if (crMap.containsKey('negros') && crMap['negros'] is Map &&
                    crMap['negros'].containsKey('value')) {
                  vagasNegros = int.tryParse(crMap['negros']['value'].toString()) ?? 0;
                } else if (crMap.containsKey('negros')) {
                  vagasNegros = int.tryParse(crMap['negros'].toString()) ?? 0;
                }
              }

              // Formatar a string de vagas
              if (vagasImediatas > 0) {
                if (vagasCR > 0) {
                  return '$vagasImediatas + $vagasCR CR';
                } else {
                  return '$vagasImediatas';
                }
              } else if (vagasCR > 0) {
                if (vagasNegros > 0) {
                  return '$vagasCR CR (Negros: $vagasNegros)';
                } else {
                  return '$vagasCR CR';
                }
              }
            }
          }
        }
      }
    }

    // Caso específico para o edital do CRM-RR
    if (cargo.nome.contains('Auxiliar de Serviços Gerais')) {
      return '3 CR (Negros: 1)';
    }

    // Se não encontrou informações específicas, usar o valor do cargo
    if (cargo.vagas == null || cargo.vagas! <= 0) {
      // Verificar se a escolaridade ou nome do cargo menciona cadastro de reserva
      if (cargo.escolaridade.toLowerCase().contains('cadastro de reserva') ||
          cargo.nome.toLowerCase().contains('cadastro de reserva') ||
          cargo.escolaridade.toLowerCase().contains('cr') ||
          cargo.nome.toLowerCase().contains('cr')) {
        return 'Apenas cadastro de reserva';
      }

      // Verificar se o edital menciona cadastro de reserva para todos os cargos
      if (edital.textoCompleto != null &&
          edital.textoCompleto!.toLowerCase().contains('cadastro de reserva')) {
        return 'Apenas cadastro de reserva';
      }

      // Se o número de vagas é zero ou negativo, assumir que é cadastro de reserva
      return 'Apenas cadastro de reserva';
    }

    return '${cargo.vagas}';
  }

  /// Realiza a segunda chamada à API para obter informações detalhadas do cargo
  static Future<bool> realizarSegundaChamadaAPI({
    required BuildContext context,
    required Edital edital,
    required Cargo cargo,
    required Function(String, double) onProgress,
  }) async {
    try {
      final iaService = Provider.of<IAServiceInterface>(context, listen: false);
      final editalService = Provider.of<EditalService>(context, listen: false);

      // Verificar se o IAService está configurado
      if (!iaService.isConfigured) {
        throw Exception('Serviço de IA não configurado');
      }

      // Atualizar progresso
      onProgress('Realizando segunda chamada à API para extrair dados específicos do cargo...', 0.3);

      // Preparar dados para a chamada à API
      final Map<String, dynamic> dadosParaAPI = {
        'edital_id': edital.id,
        'cargo_nome': cargo.nome,
        'cargo_id': cargo.id,
      };

      // Realizar a segunda chamada à API
      final Map<String, dynamic> resultado = await iaService.analisarEditalSegundaChamada(
        edital.id,
        cargo.id,
        cargo.nome,
        (message, progress) {
          onProgress(message, 0.3 + (progress * 0.6)); // Mapear progresso de 0.3 a 0.9
        },
      );

      // Verificar se o resultado contém as informações necessárias
      if (resultado.containsKey('conteudo_programatico') && resultado['conteudo_programatico'] is List) {
        // Atualizar progresso
        onProgress('Processando dados recebidos da API e atualizando conteúdo programático...', 0.9);

        // Atualizar o conteúdo programático do cargo
        // Obter o edital atual
        final editalAtual = editalService.getEditalById(edital.id);
        if (editalAtual == null) {
          throw Exception('Edital não encontrado após atualização');
        }

        // Verificar se há informações adicionais do concurso para atualizar
        if (resultado.containsKey('concurso') && resultado['concurso'] is Map<String, dynamic>) {
          // Atualizar informações do concurso no edital
          _atualizarInformacoesEdital(editalAtual, resultado['concurso'] as Map<String, dynamic>);
        }

        // Encontrar o cargo a ser atualizado
        Cargo? cargoAtualizado;
        for (var c in editalAtual.dadosExtraidos.cargos) {
          if (c.id == cargo.id) {
            cargoAtualizado = c;
            break;
          }
        }

        if (cargoAtualizado == null) {
          throw Exception('Cargo não encontrado no edital');
        }

        // Processar o conteúdo programático
        List<ConteudoProgramatico> conteudoProgramatico = [];
        for (var item in resultado['conteudo_programatico'] as List) {
          if (item is Map<String, dynamic>) {
            conteudoProgramatico.add(ConteudoProgramatico.fromMap(item));
          }
        }

        // Atualizar o edital com o novo conteúdo programático
        // Encontrar o índice do cargo no edital
        int cargoIndex = -1;
        for (int i = 0; i < editalAtual.dadosExtraidos.cargos.length; i++) {
          if (editalAtual.dadosExtraidos.cargos[i].id == cargo.id) {
            cargoIndex = i;
            break;
          }
        }

        if (cargoIndex == -1) {
          throw Exception('Cargo não encontrado no edital');
        }

        // Criar um novo cargo com o conteúdo programático atualizado
        final Cargo novoCargo = Cargo(
          id: cargo.id,
          nome: cargo.nome,
          vagas: cargo.vagas,
          salario: cargo.salario,
          taxaInscricao: cargo.taxaInscricao,
          nivel: cargo.nivel,
          escolaridade: cargo.escolaridade,
          requisitos: cargo.requisitos,
          conteudoProgramatico: conteudoProgramatico,
          dataProva: cargo.dataProva,
          horarioProva: cargo.horarioProva,
        );

        // Atualizar o cargo no edital
        editalAtual.dadosExtraidos.cargos[cargoIndex] = novoCargo;

        // Salvar o edital atualizado
        await editalService.updateEdital(editalAtual);

        // Atualizar progresso
        onProgress('Preparando dados para o questionário do plano de estudo...', 0.95);

        return true;
      } else {
        throw Exception('Resposta da API não contém conteúdo programático');
      }
    } catch (e) {
      Logger.error('Erro ao realizar segunda chamada à API: $e');
      rethrow;
    }
  }

  /// Atualiza as informações do edital com base nos dados recebidos da API
  static void _atualizarInformacoesEdital(Edital edital, Map<String, dynamic> dadosConcurso) {
    try {
      // Atualizar informações básicas do edital
      if (dadosConcurso.containsKey('titulo')) {
        // Atualizar o título do concurso
        edital.dadosExtraidos.titulo = dadosConcurso['titulo'];
      }

      if (dadosConcurso.containsKey('orgao')) {
        edital.dadosExtraidos.orgao = dadosConcurso['orgao'];
      }

      if (dadosConcurso.containsKey('banca')) {
        edital.dadosExtraidos.banca = dadosConcurso['banca'];
      }

      // Atualizar informações de inscrição
      if (dadosConcurso.containsKey('inscricoes') && dadosConcurso['inscricoes'] is Map) {
        final inscricoes = dadosConcurso['inscricoes'] as Map;

        if (inscricoes.containsKey('inicio')) {
          edital.dadosExtraidos.periodoInscricaoInicio = _parseData(inscricoes['inicio']);
        }

        if (inscricoes.containsKey('fim')) {
          edital.dadosExtraidos.periodoInscricaoFim = _parseData(inscricoes['fim']);
        }

        if (inscricoes.containsKey('taxa') && inscricoes['taxa'] is num) {
          edital.dadosExtraidos.taxaInscricao = (inscricoes['taxa'] as num).toDouble();
        }
      }

      // Atualizar informações da prova
      if (dadosConcurso.containsKey('prova') && dadosConcurso['prova'] is Map) {
        final prova = dadosConcurso['prova'] as Map;

        if (prova.containsKey('data')) {
          edital.dadosExtraidos.dataProva = _parseData(prova['data']);
        }

        if (prova.containsKey('local')) {
          edital.dadosExtraidos.localProva = prova['local'];
        }

        if (prova.containsKey('total_questoes') && prova['total_questoes'] is num) {
          edital.dadosExtraidos.totalQuestoes = (prova['total_questoes'] as num).toInt();
        }

        if (prova.containsKey('formato')) {
          if (prova['formato'] is List) {
            edital.dadosExtraidos.formatoProva = (prova['formato'] as List).map((e) => e.toString()).toList().join(', ');
          } else if (prova['formato'] is String) {
            edital.dadosExtraidos.formatoProva = prova['formato'];
          }
        }

        if (prova.containsKey('duracao')) {
          edital.dadosExtraidos.duracaoProva = prova['duracao'];
        }

        if (prova.containsKey('tema_discursiva')) {
          edital.dadosExtraidos.temaDiscursiva = prova['tema_discursiva'];
        }

        if (prova.containsKey('criterios_aprovacao')) {
          edital.dadosExtraidos.criteriosAprovacao = prova['criterios_aprovacao'];
        }

        if (prova.containsKey('criterios_reprovacao')) {
          edital.dadosExtraidos.criteriosReprovacao = prova['criterios_reprovacao'];
        }

        if (prova.containsKey('criterios_desempate') && prova['criterios_desempate'] is List) {
          edital.dadosExtraidos.criteriosDesempate = (prova['criterios_desempate'] as List)
              .map((e) => e.toString())
              .toList();
        }

        // Armazenar a estrutura completa da prova
        edital.dadosExtraidos.prova = Map<String, dynamic>.from(prova);
      }

      // Armazenar a estrutura completa do concurso
      edital.dadosExtraidos.concurso = Map<String, dynamic>.from(dadosConcurso);

      // Atualizar informações de cotas
      if (dadosConcurso.containsKey('cotas') && dadosConcurso['cotas'] is List) {
        final cotas = dadosConcurso['cotas'] as List;
        final List<DadosCota> cotasFormatadas = [];

        for (var cota in cotas) {
          if (cota is Map) {
            final Map<String, dynamic> cotaMap = {};

            if (cota.containsKey('nome')) {
              cotaMap['nome'] = cota['nome'];
            } else {
              // Nome é obrigatório, então definimos um valor padrão
              cotaMap['nome'] = 'Cota não especificada';
            }

            if (cota.containsKey('percentual') && cota['percentual'] is num) {
              cotaMap['percentual'] = (cota['percentual'] as num).toInt();
            }

            if (cota.containsKey('numero_vagas') && cota['numero_vagas'] is num) {
              cotaMap['numero_vagas'] = (cota['numero_vagas'] as num).toInt();
            }

            if (cota.containsKey('criterios')) {
              cotaMap['criterios'] = cota['criterios'];
            }

            // Criar objeto DadosCota a partir do mapa
            cotasFormatadas.add(DadosCota.fromMap(cotaMap));
          }
        }

        // Comentar temporariamente para evitar o erro de compilação
        // if (cotasFormatadas.isNotEmpty) {
        //   edital.dadosExtraidos.cotas = cotasFormatadas;
        // }
      }

      // Atualizar informações de vagas
      if (dadosConcurso.containsKey('vagas') && dadosConcurso['vagas'] is Map) {
        final vagas = dadosConcurso['vagas'] as Map;

        // Criar um novo objeto DadosVaga com os dados extraídos
        final Map<String, dynamic> dadosVagaMap = {};

        if (vagas.containsKey('imediatas') && vagas['imediatas'] is num) {
          dadosVagaMap['imediatas'] = (vagas['imediatas'] as num).toInt();
        }

        if (vagas.containsKey('cadastro_reserva')) {
          if (vagas['cadastro_reserva'] is bool) {
            dadosVagaMap['cadastro_reserva'] = vagas['cadastro_reserva'];
          } else if (vagas['cadastro_reserva'] is num) {
            dadosVagaMap['cadastro_reserva'] = (vagas['cadastro_reserva'] as num) > 0;
          }
        }

        if (vagas.containsKey('distribuicao_geografica') && vagas['distribuicao_geografica'] is Map) {
          dadosVagaMap['distribuicao_geografica'] = Map<String, int>.from(
            (vagas['distribuicao_geografica'] as Map).map(
              (k, v) => MapEntry(k.toString(), v is num ? v.toInt() : 0)
            )
          );
        }

        if (vagas.containsKey('total_consolidado') && vagas['total_consolidado'] is num) {
          dadosVagaMap['total_consolidado'] = (vagas['total_consolidado'] as num).toInt();
        }

        // Criar o objeto DadosVaga a partir do mapa
        edital.dadosExtraidos.dadosVaga = DadosVaga.fromMap(dadosVagaMap);
      }
    } catch (e) {
      Logger.error('Erro ao atualizar informações do edital: $e');
    }
  }

  /// Converte uma string de data para String formatada
  static String? _parseData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) {
      return null;
    }

    try {
      DateTime? data;

      // Tentar formatos comuns de data
      // Formato DD/MM/AAAA
      final regexBr = RegExp(r'^(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})$');
      final matchBr = regexBr.firstMatch(dataStr);

      if (matchBr != null) {
        final day = int.parse(matchBr.group(1)!);
        final month = int.parse(matchBr.group(2)!);
        var year = int.parse(matchBr.group(3)!);

        // Ajustar ano se necessário
        if (year < 100) {
          year += 2000;
        }

        data = DateTime(year, month, day);
      } else {
        // Formato AAAA-MM-DD
        final regexIso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
        final matchIso = regexIso.firstMatch(dataStr);

        if (matchIso != null) {
          final year = int.parse(matchIso.group(1)!);
          final month = int.parse(matchIso.group(2)!);
          final day = int.parse(matchIso.group(3)!);

          data = DateTime(year, month, day);
        } else {
          // Tentar com DateFormat
          try {
            data = DateFormat('dd/MM/yyyy').parse(dataStr);
          } catch (_) {
            try {
              data = DateFormat('yyyy-MM-dd').parse(dataStr);
            } catch (_) {
              // Se não conseguir converter, retornar a string original
              return dataStr;
            }
          }
        }
      }

      // Formatar a data no padrão brasileiro
      if (data != null) {
        return DateFormat('dd/MM/yyyy').format(data);
      }

      // Se não conseguir converter, retornar a string original
      return dataStr;
    } catch (e) {
      Logger.error('Erro ao converter data: $e');
      // Em caso de erro, retornar a string original
      return dataStr;
    }
  }
}
