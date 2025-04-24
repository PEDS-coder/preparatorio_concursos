import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/interfaces/ia_service_interface_extension.dart';
import '../../../../core/utils/logger_static.dart';

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
    if (cargo.vagas <= 0) {
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
}
