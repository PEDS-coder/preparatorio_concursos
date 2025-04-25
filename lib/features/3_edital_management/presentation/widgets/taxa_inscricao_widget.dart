import 'package:flutter/material.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/edital_data_formatter_service.dart';

/// Widget que representa as informações sobre a taxa de inscrição
class TaxaInscricaoWidget extends StatelessWidget {
  final Edital edital;

  const TaxaInscricaoWidget({
    Key? key,
    required this.edital,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar se há taxas por nível no dadosOriginais
    if (edital.dadosOriginais != null) {
      // Verificar diferentes formatos possíveis para taxas por nível
      Map<dynamic, dynamic>? taxasPorNivel;

      // Verificar diferentes chaves possíveis para taxas
      final possiveisChavesTaxas = [
        'taxas_por_nivel',
        'valor_taxa_inscricao',
        'taxa_inscricao',
        'taxas_inscricao',
        'taxas',
        'valores_taxa'
      ];

      // Buscar em todas as chaves possíveis
      for (final chave in possiveisChavesTaxas) {
        if (edital.dadosOriginais!.containsKey(chave) &&
            edital.dadosOriginais![chave] is Map) {
          taxasPorNivel = edital.dadosOriginais![chave] as Map<dynamic, dynamic>?;
          break;
        }
      }

      // Verificar se há um valor direto de taxa
      double valorTaxaDireta = 0.0;
      final possiveisChavesTaxaDireta = [
        'valorTaxa',
        'valor_taxa',
        'taxa',
        'taxa_inscricao_valor',
        'valor_inscricao'
      ];

      // Buscar em todas as chaves possíveis para taxa direta
      for (final chave in possiveisChavesTaxaDireta) {
        if (edital.dadosOriginais!.containsKey(chave)) {
          var valorTaxa = edital.dadosOriginais![chave];
          if (valorTaxa is num) {
            valorTaxaDireta = valorTaxa.toDouble();
            break;
          } else if (valorTaxa is String) {
            try {
              // Remover caracteres não numéricos, exceto ponto e vírgula
              final valorStr = valorTaxa.toString().replaceAll(RegExp(r'[^\d.,]'), '');
              if (valorStr.isNotEmpty) {
                valorTaxaDireta = double.parse(valorStr.replaceAll(',', '.'));
                break;
              }
            } catch (e) {
              print('Erro ao converter taxa direta ($chave): $e');
            }
          }
        }
      }

      // Verificar se há taxas por cargo
      Map<dynamic, dynamic>? taxasPorCargo;
      if (edital.dadosOriginais!.containsKey('cargos') &&
          edital.dadosOriginais!['cargos'] is List) {

        final cargos = edital.dadosOriginais!['cargos'] as List;
        if (cargos.isNotEmpty && cargos.first is Map) {
          // Verificar se os cargos têm taxas individuais
          bool temTaxasIndividuais = false;
          for (var cargo in cargos) {
            if (cargo is Map &&
                (cargo.containsKey('taxa_inscricao') ||
                 cargo.containsKey('taxa') ||
                 cargo.containsKey('valor_taxa'))) {
              temTaxasIndividuais = true;
              break;
            }
          }

          if (temTaxasIndividuais) {
            taxasPorCargo = {};
            for (var cargo in cargos) {
              if (cargo is Map) {
                String nomeCargo = '';
                if (cargo.containsKey('nome')) {
                  nomeCargo = cargo['nome'].toString();
                } else if (cargo.containsKey('nome_cargo')) {
                  nomeCargo = cargo['nome_cargo'].toString();
                }

                if (nomeCargo.isNotEmpty) {
                  double valorTaxa = 0.0;

                  // Buscar taxa em diferentes campos
                  for (final chaveTaxa in ['taxa_inscricao', 'taxa', 'valor_taxa']) {
                    if (cargo.containsKey(chaveTaxa)) {
                      var taxa = cargo[chaveTaxa];
                      if (taxa is num) {
                        valorTaxa = taxa.toDouble();
                        break;
                      } else if (taxa is String) {
                        try {
                          final valorStr = taxa.toString().replaceAll(RegExp(r'[^\d.,]'), '');
                          if (valorStr.isNotEmpty) {
                            valorTaxa = double.parse(valorStr.replaceAll(',', '.'));
                            break;
                          }
                        } catch (e) {
                          print('Erro ao converter taxa do cargo: $e');
                        }
                      }
                    }
                  }

                  if (valorTaxa > 0) {
                    taxasPorCargo[nomeCargo] = valorTaxa;
                  }
                }
              }
            }
          }
        }
      }

      // Prioridade de exibição: 1. Taxas por nível, 2. Taxas por cargo, 3. Taxa direta

      // Se temos taxas por nível, exibir todas
      if (taxasPorNivel != null && taxasPorNivel.isNotEmpty) {
        // Construir uma lista de taxas por nível
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxas de inscrição:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ?
                       Colors.grey.shade300 : Colors.grey.shade700
              ),
            ),
            ...taxasPorNivel.entries.map((entry) {
              final nivel = entry.key.toString();
              double valor = 0.0;

              // Extrair o valor numérico da taxa
              if (entry.value is num) {
                valor = (entry.value as num).toDouble();
              } else if (entry.value is String) {
                // Tentar extrair valor numérico da string
                try {
                  final valorStr = entry.value.toString().replaceAll(RegExp(r'[^\d.,]'), '');
                  if (valorStr.isNotEmpty) {
                    valor = double.parse(valorStr.replaceAll(',', '.'));
                  }
                } catch (e) {
                  print('Erro ao converter taxa: $e');
                }
              } else if (entry.value is Map) {
                // Alguns editais têm a taxa como um objeto com campo 'valor'
                final taxaMap = entry.value as Map;
                if (taxaMap.containsKey('valor')) {
                  var valorObj = taxaMap['valor'];
                  if (valorObj is num) {
                    valor = valorObj.toDouble();
                  } else if (valorObj is String) {
                    try {
                      final valorStr = valorObj.toString().replaceAll(RegExp(r'[^\d.,]'), '');
                      if (valorStr.isNotEmpty) {
                        valor = double.parse(valorStr.replaceAll(',', '.'));
                      }
                    } catch (e) {
                      print('Erro ao converter taxa do objeto: $e');
                    }
                  }
                }
              }

              // Só exibir se o valor for maior que zero
              if (valor > 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                  child: Text(
                    '${EditalDataFormatterService.formatarNivel(nivel)}: R\$ ${valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark ?
                             Colors.grey.shade300 : Colors.grey.shade700
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink(); // Não exibir se o valor for zero
              }
            }).toList(),
          ],
        );
      }

      // Se temos taxas por cargo, exibir
      else if (taxasPorCargo != null && taxasPorCargo.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxas de inscrição:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ?
                       Colors.grey.shade300 : Colors.grey.shade700
              ),
            ),
            ...taxasPorCargo.entries.map((entry) {
              final cargo = entry.key.toString();
              final valor = entry.value as double;

              // Só exibir se o valor for maior que zero
              if (valor > 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                  child: Text(
                    '$cargo: R\$ ${valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark ?
                             Colors.grey.shade300 : Colors.grey.shade700
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink(); // Não exibir se o valor for zero
              }
            }).toList(),
          ],
        );
      }

      // Se temos um valor direto de taxa, exibir
      else if (valorTaxaDireta > 0) {
        return Text(
          'Taxa: R\$ ${valorTaxaDireta.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark ?
                   Colors.grey.shade300 : Colors.grey.shade700
          ),
        );
      }
    }

    // Verificar se o valor da taxa nos dados extraídos é válido
    if (edital.dadosExtraidos.valorTaxa > 0) {
      return Text(
        'Taxa: R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark ?
                 Colors.grey.shade300 : Colors.grey.shade700
        ),
      );
    }

    // Se chegou aqui, não encontrou nenhum valor válido
    return Text(
      'Taxa: Consulte o edital',
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).brightness == Brightness.dark ?
               Colors.grey.shade300 : Colors.grey.shade700
      ),
    );
  }
}
