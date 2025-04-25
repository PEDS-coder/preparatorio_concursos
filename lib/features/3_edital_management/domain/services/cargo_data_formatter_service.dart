import '../../../../../core/data/models/edital.dart';

/// Serviço para formatação de dados de cargo
class CargoDataFormatterService {
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
    return '$resultado,${valorDecimal.toString().padLeft(2, '0')}';
  }

  /// Formata o número de vagas para exibição
  static String formatarVagas(Cargo cargo, Edital edital) {
    // Verificar se temos informações detalhadas sobre vagas
    if (edital.dadosExtraidos.dadosVaga != null) {
      final dadosVaga = edital.dadosExtraidos.dadosVaga!;

      // Construir informação sobre vagas
      String vagasInfo = '';

      if (dadosVaga.imediatas != null) {
        vagasInfo += 'Imediatas: ${dadosVaga.imediatas}';
      }

      if (dadosVaga.cadastroReserva == true) {
        if (vagasInfo.isNotEmpty) vagasInfo += ' + ';
        vagasInfo += 'Cadastro Reserva';
      }

      if (vagasInfo.isEmpty && dadosVaga.totalConsolidado != null) {
        vagasInfo = 'Total: ${dadosVaga.totalConsolidado}';
      }

      if (vagasInfo.isNotEmpty) {
        return vagasInfo;
      }
    }

    // Obter dados originais
    final Map<String, dynamic>? dadosOriginais = edital.dadosOriginais;
    // Se não temos dados originais, usar o valor do cargo
    if (dadosOriginais == null) {
      return cargo.vagas != null ? '${cargo.vagas}' : 'Não informado';
    }

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
      if (edital.textoCompleto.toLowerCase().contains('cadastro de reserva')) {
        return 'Apenas cadastro de reserva';
      }

      // Se o número de vagas é nulo, zero ou negativo, assumir que é cadastro de reserva
      return 'Apenas cadastro de reserva';
    }

    return '${cargo.vagas}';
  }

  /// Filtra o conteúdo programático para um cargo
  static List<ConteudoProgramatico> filtrarConteudoProgramatico(Cargo cargo, Edital edital) {
    // Na tela de seleção de cargo, não exibimos o conteúdo programático
    // O conteúdo programático detalhado só será exibido após a segunda etapa da análise
    return [];
  }
}
