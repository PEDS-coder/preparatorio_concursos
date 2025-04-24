import 'package:flutter/material.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/edital_data_formatter_service.dart';

/// Widget que representa as informações sobre cotas
class CotasInfoWidget extends StatelessWidget {
  final Edital edital;

  const CotasInfoWidget({
    Key? key,
    required this.edital,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar se há informações sobre cotas nos dados originais
    Map<dynamic, dynamic>? cotasInfo;
    String? cotasText;

    if (edital.dadosOriginais != null) {
      // Verificar diferentes formatos possíveis de cotas nos dados
      final possiveisChavesCotas = [
        'cotas',
        'percentual_cotas',
        'reserva_vagas',
        'vagas_reservadas',
        'reserva_de_vagas',
        'politica_cotas',
        'sistema_cotas'
      ];

      // Buscar em todas as chaves possíveis
      for (final chave in possiveisChavesCotas) {
        if (edital.dadosOriginais!.containsKey(chave)) {
          var cotasData = edital.dadosOriginais![chave];
          if (cotasData is Map) {
            cotasInfo = cotasData as Map<dynamic, dynamic>;
            break;
          } else if (cotasData is String && cotasData.isNotEmpty) {
            // Se for uma string, usar como texto de cotas
            cotasText = cotasData;
            break;
          }
        }
      }

      // Verificar se há informações de cotas nos cargos
      if (cotasInfo == null &&
          edital.dadosOriginais!.containsKey('cargos') &&
          edital.dadosOriginais!['cargos'] is List) {

        final cargos = edital.dadosOriginais!['cargos'] as List;
        if (cargos.isNotEmpty && cargos.first is Map) {
          // Verificar se os cargos têm informações de cotas
          for (var cargo in cargos) {
            if (cargo is Map) {
              for (final chaveCota in possiveisChavesCotas) {
                if (cargo.containsKey(chaveCota) && cargo[chaveCota] is Map) {
                  cotasInfo = cargo[chaveCota] as Map<dynamic, dynamic>;
                  break;
                }
              }
              if (cotasInfo != null) break;
            }
          }
        }
      }

      // Verificar se há informações de cotas no texto do edital
      if (edital.textoCompleto.isNotEmpty) {
        final texto = edital.textoCompleto.toLowerCase();

        // Padrões comuns de cotas em editais
        final padroes = [
          {'termo': 'negros', 'percentual': '20%', 'nome': 'Negros'},
          {'termo': 'afrodescendentes', 'percentual': '20%', 'nome': 'Afrodescendentes'},
          {'termo': 'pcd', 'percentual': '5%', 'nome': 'PCD'},
          {'termo': 'pessoa com deficiência', 'percentual': '5%', 'nome': 'PCD'},
          {'termo': 'indígena', 'percentual': '5%', 'nome': 'Indígenas'},
          {'termo': 'indigena', 'percentual': '5%', 'nome': 'Indígenas'},
          {'termo': 'minorias étnico-raciais', 'percentual': '10%', 'nome': 'Minorias étnico-raciais'},
          {'termo': 'minorias etnico-raciais', 'percentual': '10%', 'nome': 'Minorias étnico-raciais'},
          {'termo': 'quilombola', 'percentual': '5%', 'nome': 'Quilombolas'}
        ];

        // Verificar se o texto contém termos relacionados a cotas
        if (texto.contains('cota') ||
            texto.contains('reserva de vaga') ||
            texto.contains('vagas reservadas')) {

          List<String> cotasEncontradas = [];

          // Buscar padrões de cotas no texto
          for (var padrao in padroes) {
            final termo = padrao['termo']!;
            final percentualPadrao = padrao['percentual']!;
            final nome = padrao['nome']!;

            if (texto.contains(termo)) {
              // Tentar encontrar o percentual específico no texto próximo ao termo
              String percentual = '';

              // Buscar percentuais comuns (5%, 10%, 20%, 30%)
              for (var pct in ['5%', '10%', '15%', '20%', '25%', '30%']) {
                // Verificar se o percentual está próximo ao termo (dentro de 100 caracteres)
                final termoIndex = texto.indexOf(termo);
                if (termoIndex >= 0) {
                  final inicio = (termoIndex - 50).clamp(0, texto.length);
                  final fim = (termoIndex + 50).clamp(0, texto.length);
                  final trecho = texto.substring(inicio, fim);

                  if (trecho.contains(pct)) {
                    percentual = pct;
                    break;
                  }
                }
              }

              // Se não encontrou percentual específico, usar o padrão
              if (percentual.isEmpty) {
                percentual = percentualPadrao;
              }

              cotasEncontradas.add('$nome ($percentual)');
            }
          }

          // Se encontrou cotas no texto, montar a string
          if (cotasEncontradas.isNotEmpty) {
            cotasText = cotasEncontradas.join(' / ');
          }
        }
      }
    }

    // Se encontrou informações sobre cotas, exibir
    if (cotasInfo != null || cotasText != null) {
      String displayText = 'Cotas: ';

      // Usar informações estruturadas se disponíveis
      if (cotasInfo != null && cotasInfo.isNotEmpty) {
        List<String> cotasList = [];

        cotasInfo.forEach((key, value) {
          String cotaName = key.toString().toLowerCase();
          dynamic percentual = value;

          // Mapeamento de termos comuns para nomes padronizados
          final Map<String, String> mapeamentoCotas = {
            'negro': 'Negros',
            'afrodescendente': 'Afrodescendentes',
            'pcd': 'PCD',
            'deficiente': 'PCD',
            'deficiência': 'PCD',
            'indígena': 'Indígenas',
            'indigena': 'Indígenas',
            'minoria': 'Minorias étnico-raciais',
            'étnico': 'Minorias étnico-raciais',
            'etnico': 'Minorias étnico-raciais',
            'quilombola': 'Quilombolas'
          };

          // Encontrar o tipo de cota com base no nome
          String? tipoEncontrado;
          for (var tipo in mapeamentoCotas.keys) {
            if (cotaName.contains(tipo)) {
              tipoEncontrado = mapeamentoCotas[tipo];
              break;
            }
          }

          // Se não encontrou um tipo conhecido, usar o nome original formatado
          final nomeCota = tipoEncontrado ?? EditalDataFormatterService.formatarNivel(cotaName);

          // Extrair o percentual
          String percentualStr = '';
          if (percentual is num) {
            percentualStr = '(${percentual.toInt()}%)';
          } else if (percentual is String) {
            // Tentar extrair número da string
            final match = RegExp(r'(\d+)').firstMatch(percentual.toString());
            if (match != null) {
              percentualStr = '(${match.group(1)}%)';
            }
          } else if (percentual is Map && percentual.containsKey('valor')) {
            // Alguns editais têm o percentual como um objeto com campo 'valor'
            var valorObj = percentual['valor'];
            if (valorObj is num) {
              percentualStr = '(${valorObj.toInt()}%)';
            } else if (valorObj is String) {
              final match = RegExp(r'(\d+)').firstMatch(valorObj.toString());
              if (match != null) {
                percentualStr = '(${match.group(1)}%)';
              }
            }
          }

          // Adicionar à lista de cotas
          cotasList.add(percentualStr.isNotEmpty ? '$nomeCota $percentualStr' : nomeCota);
        });

        if (cotasList.isNotEmpty) {
          displayText += cotasList.join(' / ');
        } else {
          // Se não conseguiu extrair informações estruturadas, usar o texto
          displayText += cotasText ?? 'Informações disponíveis no edital';
        }
      } else if (cotasText != null) {
        displayText += cotasText;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.diversity_3,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark ?
                     Colors.grey.shade300 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ?
                         Colors.grey.shade300 : Colors.grey.shade700
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Se não encontrou informações sobre cotas, não exibir nada
    return SizedBox.shrink();
  }
}
