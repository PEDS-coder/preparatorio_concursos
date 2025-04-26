import 'package:flutter/foundation.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/formatador_service.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';

/// Serviço para obtenção de dados da inscrição
class InscricaoService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();

  /// Obtém o valor da inscrição
  static String obterValor(PlanoEstudo plano, Edital? edital) {
    debugPrint('\nInscricaoService.obterValor - Buscando valor da inscrição');

    // Log para depuração
    debugPrint('  Metadados do plano: ${plano.metadados.keys.toList()}');

    // Verificar se já temos o valor nos metadados do plano
    if (plano.metadados.containsKey('valorInscricao') &&
        plano.metadados['valorInscricao'] != null &&
        plano.metadados['valorInscricao'].toString() != '0.0') {
      final valor = plano.metadados['valorInscricao'].toString();
      debugPrint('  Encontrado nos metadados do plano: $valor');
      return _formatarValorTaxa(valor);
    }

    // Se não temos edital, retornar valor padrão
    if (edital == null) {
      debugPrint('  Edital é nulo, retornando "Não informado"');
      return 'Não informado';
    }

    // Log para depuração
    debugPrint('  ID do edital: ${edital.id}');
    debugPrint('  Dados originais presentes: ${edital.dadosOriginais != null}');

    // Verificar diretamente no objeto DadosExtraidos
    debugPrint('  Verificando diretamente em DadosExtraidos...');
    debugPrint('  valorTaxa: ${edital.dadosExtraidos.valorTaxa}');
    debugPrint('  taxaInscricao: ${edital.dadosExtraidos.taxaInscricao}');

    // Verificar valorTaxa
    if (edital.dadosExtraidos.valorTaxa != null &&
        edital.dadosExtraidos.valorTaxa.toString() != '0.0' &&
        edital.dadosExtraidos.valorTaxa.toString() != '0') {
      final valor = edital.dadosExtraidos.valorTaxa.toString();
      debugPrint('  Encontrado em dadosExtraidos.valorTaxa: $valor');

      // Armazenar nos metadados do plano para uso futuro
      plano.metadados['valorInscricao'] = valor;

      return _formatarValorTaxa(valor);
    }

    // Verificar taxaInscricao
    if (edital.dadosExtraidos.taxaInscricao != null &&
        edital.dadosExtraidos.taxaInscricao! > 0) {
      final valor = edital.dadosExtraidos.taxaInscricao.toString();
      debugPrint('  Encontrado em dadosExtraidos.taxaInscricao: $valor');

      // Armazenar nos metadados do plano para uso futuro
      plano.metadados['valorInscricao'] = valor;

      return _formatarValorTaxa(valor);
    }

    // Verificar se há taxa de inscrição na estrutura aninhada
    if (edital.dadosExtraidos.concurso != null &&
        edital.dadosExtraidos.concurso!.containsKey('inscricoes') &&
        edital.dadosExtraidos.concurso!['inscricoes'] is Map) {

      final inscricoes = edital.dadosExtraidos.concurso!['inscricoes'] as Map;
      debugPrint('  Verificando em dadosExtraidos.concurso.inscricoes: ${inscricoes.keys.toList()}');

      if (inscricoes.containsKey('taxa')) {
        final valor = inscricoes['taxa'].toString();
        debugPrint('  Encontrado em dadosExtraidos.concurso.inscricoes.taxa: $valor');

        // Armazenar nos metadados do plano para uso futuro
        plano.metadados['valorInscricao'] = valor;

        return _formatarValorTaxa(valor);
      }
    }

    // Tentar usar o extrator padrão
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.VALOR_INSCRICAO);
    if (resultado != 'Não informado') {
      return _formatarValorTaxa(resultado);
    }

    // Se não encontrou e temos dados originais, tentar buscar diretamente
    if (edital.dadosOriginais != null) {
      debugPrint('  Não encontrado pelo extrator padrão, tentando buscar diretamente...');

      // Verificar se há dados de inscrição no objeto concurso
      if (edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map) {
          debugPrint('  Chaves em concurso.inscricoes: ${inscricoes.keys.toList()}');

          if (inscricoes.containsKey('taxa')) {
            resultado = inscricoes['taxa'].toString();
            debugPrint('  Encontrado em concurso.inscricoes.taxa: $resultado');

            // Armazenar nos metadados do plano para uso futuro
            plano.metadados['valorInscricao'] = resultado;

            return _formatarValorTaxa(resultado);
          }
        }
      }

      // Verificar se há dados de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('inscricoes') &&
          edital.dadosOriginais!['inscricoes'] is Map) {

        final inscricoes = edital.dadosOriginais!['inscricoes'] as Map;
        debugPrint('  Chaves em inscricoes: ${inscricoes.keys.toList()}');

        if (inscricoes.containsKey('taxa')) {
          resultado = inscricoes['taxa'].toString();
          debugPrint('  Encontrado em inscricoes.taxa: $resultado');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['valorInscricao'] = resultado;

          return _formatarValorTaxa(resultado);
        }
      }

      // Verificar se há taxa de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('taxa_inscricao')) {
        resultado = edital.dadosOriginais!['taxa_inscricao'].toString();
        debugPrint('  Encontrado em dadosOriginais.taxa_inscricao: $resultado');

        // Armazenar nos metadados do plano para uso futuro
        plano.metadados['valorInscricao'] = resultado;

        return _formatarValorTaxa(resultado);
      }

      // Verificar outras chaves possíveis
      final possiveisChaves = [
        'valor_taxa',
        'taxa',
        'taxa_inscricao_valor',
        'valor_inscricao',
        'inscricao_valor',
        'inscricao_taxa'
      ];

      for (final chave in possiveisChaves) {
        if (edital.dadosOriginais!.containsKey(chave)) {
          resultado = edital.dadosOriginais![chave].toString();
          debugPrint('  Encontrado em dadosOriginais.$chave: $resultado');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['valorInscricao'] = resultado;

          return _formatarValorTaxa(resultado);
        }
      }
    }

    // Verificar se há informações de taxa nos cargos
    if (edital.dadosExtraidos.cargos.isNotEmpty) {
      debugPrint('  Verificando taxa de inscrição nos cargos (${edital.dadosExtraidos.cargos.length} cargos)');

      // Primeiro, verificar se há um cargo selecionado no plano
      if (plano.cargoIds.isNotEmpty) {
        final cargoId = plano.cargoIds.first;
        debugPrint('  Cargo selecionado no plano: $cargoId');

        try {
          // Tentar encontrar o cargo selecionado
          final cargoSelecionado = edital.dadosExtraidos.cargos.firstWhere(
            (cargo) => cargo.id == cargoId || cargo.nome.toLowerCase() == cargoId.toLowerCase(),
            orElse: () => Cargo(nome: 'Não encontrado', conteudoProgramatico: []),
          );

          if (cargoSelecionado.nome != 'Não encontrado' && cargoSelecionado.taxaInscricao > 0) {
            final valor = cargoSelecionado.taxaInscricao.toString();
            debugPrint('  Encontrado em cargoSelecionado.taxaInscricao: $valor');

            // Armazenar nos metadados do plano para uso futuro
            plano.metadados['valorInscricao'] = valor;

            return _formatarValorTaxa(valor);
          }
        } catch (e) {
          debugPrint('  Erro ao buscar cargo selecionado: $e');
        }
      }

      // Se não encontrou no cargo selecionado, verificar em todos os cargos
      for (final cargo in edital.dadosExtraidos.cargos) {
        debugPrint('  Verificando cargo: ${cargo.nome} (taxa: ${cargo.taxaInscricao})');
        if (cargo.taxaInscricao > 0) {
          final valor = cargo.taxaInscricao.toString();
          debugPrint('  Encontrado em cargo.taxaInscricao: $valor');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['valorInscricao'] = valor;

          return _formatarValorTaxa(valor);
        }
      }
    }

    // Verificar se há taxa no cargo selecionado nos dados originais
    if (edital.dadosOriginais != null &&
        edital.dadosOriginais!.containsKey('cargos') &&
        plano.cargoIds.isNotEmpty) {

      final cargoId = plano.cargoIds.first;
      final cargosOriginais = edital.dadosOriginais!['cargos'];

      if (cargosOriginais is List) {
        debugPrint('  Verificando taxa nos dados originais dos cargos (${cargosOriginais.length} cargos)');

        for (final cargoOriginal in cargosOriginais) {
          if (cargoOriginal is Map && cargoOriginal.containsKey('nome')) {
            final nomeCargo = cargoOriginal['nome'].toString();

            // Verificar se é o cargo selecionado
            if (nomeCargo.toLowerCase().contains(cargoId.toLowerCase()) ||
                (cargoOriginal.containsKey('id') && cargoOriginal['id'] == cargoId)) {

              debugPrint('  Encontrado cargo selecionado nos dados originais: $nomeCargo');

              // Verificar se tem taxa de inscrição
              if (cargoOriginal.containsKey('taxa_inscricao') && cargoOriginal['taxa_inscricao'] != null) {
                final valor = cargoOriginal['taxa_inscricao'].toString();
                debugPrint('  Encontrado em cargoOriginal.taxa_inscricao: $valor');

                // Armazenar nos metadados do plano para uso futuro
                plano.metadados['valorInscricao'] = valor;

                return _formatarValorTaxa(valor);
              }
            }
          }
        }
      }
    }

    // Se chegou até aqui e não encontrou nada, retornar valor padrão
    debugPrint('  Não foi encontrado valor de taxa de inscrição em nenhum lugar');
    return 'Não informado';
  }

  /// Formata o valor da taxa de inscrição
  static String _formatarValorTaxa(String valor) {
    if (valor == 'Não informado') return valor;

    try {
      debugPrint('  Formatando valor da taxa: "$valor"');

      // Remover símbolos de moeda e substituir vírgula por ponto
      String valorLimpo = valor.replaceAll(RegExp(r'[R$\s]'), '').replaceAll(',', '.');
      debugPrint('  Valor limpo: "$valorLimpo"');

      // Tentar extrair um número usando regex se o valor contiver caracteres não numéricos
      if (RegExp(r'[^0-9\.]').hasMatch(valorLimpo)) {
        final regex = RegExp(r'(\d+[.,]?\d*)');
        final match = regex.firstMatch(valorLimpo);

        if (match != null) {
          valorLimpo = match.group(1)!.replaceAll(',', '.');
          debugPrint('  Valor extraído com regex: "$valorLimpo"');
        }
      }

      double valorNumerico = double.tryParse(valorLimpo) ?? 0.0;
      debugPrint('  Valor numérico: $valorNumerico');

      // Se o valor for zero, retornar "Não informado"
      if (valorNumerico == 0.0) {
        debugPrint('  Valor é zero, retornando "Não informado"');
        return 'Não informado';
      }

      // Formatar com R$ e duas casas decimais
      final valorFormatado = FormatadorService.formatarValorMonetario(valorNumerico);
      debugPrint('  Valor formatado: "$valorFormatado"');
      return valorFormatado;
    } catch (e) {
      debugPrint('  Erro ao formatar valor da taxa: $e');
      return valor;
    }
  }

  /// Obtém o período de inscrições
  static String obterPeriodo(Edital? edital) {
    if (edital == null) return 'Não informado';

    debugPrint('\nInscricaoService.obterPeriodo - Buscando período de inscrição');

    // Verificar se há dados de inscrição no edital
    final inicio = edital.dadosExtraidos.inicioInscricao;
    final fim = edital.dadosExtraidos.fimInscricao;

    if (inicio != null && fim != null) {
      // Formatar as datas no formato dd/MM/yyyy
      final inicioFormatado = '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}';
      final fimFormatado = '${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}/${fim.year}';
      debugPrint('  Encontrado em dadosExtraidos: $inicioFormatado a $fimFormatado');
      return '$inicioFormatado a $fimFormatado';
    }

    // Verificar se há período de inscrição diretamente nos dados extraídos
    if (edital.dadosExtraidos.periodoInscricaoInicio != null &&
        edital.dadosExtraidos.periodoInscricaoFim != null) {
      final resultado = '${edital.dadosExtraidos.periodoInscricaoInicio} a ${edital.dadosExtraidos.periodoInscricaoFim}';
      debugPrint('  Encontrado em periodoInscricaoInicio/Fim: $resultado');
      return resultado;
    }

    // Verificar se há período de inscrição como string única
    if (edital.dadosExtraidos.concurso != null &&
        edital.dadosExtraidos.concurso!.containsKey('inscricoes') &&
        edital.dadosExtraidos.concurso!['inscricoes'] is Map) {

      final inscricoes = edital.dadosExtraidos.concurso!['inscricoes'] as Map;
      debugPrint('  Verificando em dadosExtraidos.concurso.inscricoes: ${inscricoes.keys.toList()}');

      if (inscricoes.containsKey('periodo')) {
        final resultado = inscricoes['periodo'].toString();
        debugPrint('  Encontrado em dadosExtraidos.concurso.inscricoes.periodo: $resultado');
        return resultado;
      }
    }

    // Tentar obter dos dados originais
    if (edital.dadosOriginais != null) {
      debugPrint('  Verificando dados originais...');

      // Verificar se há dados de inscrição no objeto concurso
      if (edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map) {
          debugPrint('  Chaves em concurso.inscricoes: ${inscricoes.keys.toList()}');

          // Verificar se há período formatado
          if (inscricoes.containsKey('periodo')) {
            debugPrint('  Encontrado em concurso.inscricoes.periodo: ${inscricoes['periodo']}');
            return inscricoes['periodo'];
          }

          // Verificar se há início e fim separados
          if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
            final resultado = '${inscricoes['inicio']} a ${inscricoes['fim']}';
            debugPrint('  Encontrado em concurso.inscricoes.inicio/fim: $resultado');
            return resultado;
          }
        }
      }

      // Verificar se há dados de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('inscricoes') && edital.dadosOriginais!['inscricoes'] is Map) {
        final inscricoes = edital.dadosOriginais!['inscricoes'] as Map;
        debugPrint('  Chaves em inscricoes: ${inscricoes.keys.toList()}');

        // Verificar se há período formatado
        if (inscricoes.containsKey('periodo')) {
          debugPrint('  Encontrado em inscricoes.periodo: ${inscricoes['periodo']}');
          return inscricoes['periodo'];
        }

        // Verificar se há início e fim separados
        if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
          final resultado = '${inscricoes['inicio']} a ${inscricoes['fim']}';
          debugPrint('  Encontrado em inscricoes.inicio/fim: $resultado');
          return resultado;
        }
      }

      // Verificar se há período de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('periodo_inscricao')) {
        if (edital.dadosOriginais!['periodo_inscricao'] is String) {
          return edital.dadosOriginais!['periodo_inscricao'];
        } else if (edital.dadosOriginais!['periodo_inscricao'] is Map) {
          final periodoInscricao = edital.dadosOriginais!['periodo_inscricao'] as Map;
          if (periodoInscricao.containsKey('inicio') && periodoInscricao.containsKey('fim')) {
            return '${periodoInscricao['inicio']} a ${periodoInscricao['fim']}';
          }
        }
      }
    }

    return 'Não informado';
  }
}
