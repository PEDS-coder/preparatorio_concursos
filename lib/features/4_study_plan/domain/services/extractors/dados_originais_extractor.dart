import 'package:flutter/foundation.dart';
import '../../../../../core/data/models/models.dart';
import '../extrator_models.dart';
import '../extrator_utils.dart';

/// Extrator de dados originais do edital
class DadosOriginaisExtractor {
  /// Busca um valor nos dados originais do edital
  static ResultadoBusca? buscar(Edital? edital, String chaveMetadados, String chaveDadosOriginais) {
    if (edital == null || edital.dadosOriginais == null) return null;

    // Dividir a chave por pontos para navegar na estrutura aninhada
    final partes = chaveDadosOriginais.split('.');

    // Log para depuração
    debugPrint('\nDadosOriginaisExtractor - Buscando: $chaveDadosOriginais');
    debugPrint('  Chaves disponíveis: ${edital.dadosOriginais!.keys.toList()}');
    if (edital.dadosOriginais!.containsKey('concurso')) {
      debugPrint('  Chaves em concurso: ${(edital.dadosOriginais!['concurso'] as Map?)?.keys.toList() ?? 'não é um Map'}');

      if (edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {
        debugPrint('  Chaves em concurso.inscricoes: ${((edital.dadosOriginais!['concurso'] as Map)['inscricoes'] as Map?)?.keys.toList() ?? 'não é um Map'}');
      }

      if (edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {
        debugPrint('  Chaves em concurso.prova: ${((edital.dadosOriginais!['concurso'] as Map)['prova'] as Map?)?.keys.toList() ?? 'não é um Map'}');
      }
    }

    // Tentar buscar em resposta_completa primeiro
    final valorRespostaCompleta = _buscarEmCaminho(edital.dadosOriginais!, ['resposta_completa', ...partes]);
    if (valorRespostaCompleta != null) {
      debugPrint('  Encontrado em resposta_completa: $valorRespostaCompleta');
      return ResultadoBusca(
        valor: valorRespostaCompleta,
        origem: FonteDados.DADOS_ORIGINAIS,
        caminho: 'dadosOriginais.resposta_completa.$chaveDadosOriginais',
      );
    }

    // Tentar buscar diretamente
    final valorDireto = _buscarEmCaminho(edital.dadosOriginais!, partes);
    if (valorDireto != null) {
      debugPrint('  Encontrado diretamente: $valorDireto');
      return ResultadoBusca(
        valor: valorDireto,
        origem: FonteDados.DADOS_ORIGINAIS,
        caminho: 'dadosOriginais.$chaveDadosOriginais',
      );
    }

    // Tentar buscar em concurso
    final valorConcurso = _buscarEmCaminho(edital.dadosOriginais!, ['concurso', ...partes]);
    if (valorConcurso != null) {
      debugPrint('  Encontrado em concurso: $valorConcurso');
      return ResultadoBusca(
        valor: valorConcurso,
        origem: FonteDados.DADOS_ORIGINAIS,
        caminho: 'dadosOriginais.concurso.$chaveDadosOriginais',
      );
    }

    // Casos especiais baseados na chave de metadados
    switch (chaveMetadados) {
      case 'valorInscricao':
        if (edital.dadosOriginais!.containsKey('taxa_inscricao')) {
          final valor = edital.dadosOriginais!['taxa_inscricao'];
          if (ExtratorUtils.isValorValido(valor)) {
            return ResultadoBusca(
              valor: valor.toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.taxa_inscricao',
            );
          }
        }
        break;

      case 'periodoInscricao':
        // Verificar se há dados de inscrição no objeto concurso
        if (edital.dadosOriginais!.containsKey('concurso') &&
            edital.dadosOriginais!['concurso'] is Map &&
            (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

          final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
          if (inscricoes is Map) {
            // Verificar se há período formatado
            if (inscricoes.containsKey('periodo')) {
              return ResultadoBusca(
                valor: inscricoes['periodo'].toString(),
                origem: FonteDados.DADOS_ORIGINAIS,
                caminho: 'dadosOriginais.concurso.inscricoes.periodo',
              );
            }

            // Verificar se há início e fim separados
            if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
              return ResultadoBusca(
                valor: '${inscricoes['inicio']} a ${inscricoes['fim']}',
                origem: FonteDados.DADOS_ORIGINAIS,
                caminho: 'dadosOriginais.concurso.inscricoes.inicio/fim',
              );
            }
          }
        }

        // Verificar se há dados de inscrição diretamente nos dados originais
        if (edital.dadosOriginais!.containsKey('inscricoes') && edital.dadosOriginais!['inscricoes'] is Map) {
          final inscricoes = edital.dadosOriginais!['inscricoes'] as Map;

          // Verificar se há período formatado
          if (inscricoes.containsKey('periodo')) {
            return ResultadoBusca(
              valor: inscricoes['periodo'].toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.inscricoes.periodo',
            );
          }

          // Verificar se há início e fim separados
          if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
            return ResultadoBusca(
              valor: '${inscricoes['inicio']} a ${inscricoes['fim']}',
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.inscricoes.inicio/fim',
            );
          }
        }
        break;

      case 'dataProva':
        // Verificar se há dados da prova no objeto concurso
        if (edital.dadosOriginais!.containsKey('concurso') &&
            edital.dadosOriginais!['concurso'] is Map &&
            (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {

          final prova = edital.dadosOriginais!['concurso']['prova'];
          if (prova is Map && prova.containsKey('data')) {
            return ResultadoBusca(
              valor: prova['data'].toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.concurso.prova.data',
            );
          }
        }

        // Verificar se há dados da prova diretamente nos dados originais
        if (edital.dadosOriginais!.containsKey('prova') && edital.dadosOriginais!['prova'] is Map) {
          final prova = edital.dadosOriginais!['prova'] as Map;
          if (prova.containsKey('data')) {
            return ResultadoBusca(
              valor: prova['data'].toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.prova.data',
            );
          }
        }
        break;

      case 'localProva':
        // Verificar se há dados da prova no objeto concurso
        if (edital.dadosOriginais!.containsKey('concurso') &&
            edital.dadosOriginais!['concurso'] is Map &&
            (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {

          final prova = edital.dadosOriginais!['concurso']['prova'];
          if (prova is Map && prova.containsKey('local')) {
            return ResultadoBusca(
              valor: prova['local'].toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.concurso.prova.local',
            );
          }
        }

        // Verificar se há dados da prova diretamente nos dados originais
        if (edital.dadosOriginais!.containsKey('prova') && edital.dadosOriginais!['prova'] is Map) {
          final prova = edital.dadosOriginais!['prova'] as Map;
          if (prova.containsKey('local')) {
            return ResultadoBusca(
              valor: prova['local'].toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.prova.local',
            );
          }
        }
        break;
    }

    return null;
  }

  /// Busca um valor em um caminho aninhado
  static String? _buscarEmCaminho(Map<String, dynamic> dados, List<String> caminho) {
    dynamic atual = dados;

    debugPrint('  _buscarEmCaminho: Buscando caminho ${caminho.join('.')}');

    for (int i = 0; i < caminho.length; i++) {
      final parte = caminho[i];

      if (atual is Map) {
        // Verificar se a chave existe diretamente
        if (atual.containsKey(parte)) {
          atual = atual[parte];

          if (i == caminho.length - 1) {
            // Chegamos ao final do caminho
            if (atual is List) {
              final resultado = atual.join(', ');
              debugPrint('    Encontrado (lista): $resultado');
              return resultado;
            } else if (ExtratorUtils.isValorValido(atual)) {
              final resultado = atual.toString();
              debugPrint('    Encontrado (valor): $resultado');
              return resultado;
            }
          }
        } else {
          // Tentar buscar com case insensitive
          final chaveEncontrada = atual.keys.firstWhere(
            (k) => k.toString().toLowerCase() == parte.toLowerCase(),
            orElse: () => '',
          );

          if (chaveEncontrada.isNotEmpty) {
            atual = atual[chaveEncontrada];

            if (i == caminho.length - 1) {
              // Chegamos ao final do caminho
              if (atual is List) {
                final resultado = atual.join(', ');
                debugPrint('    Encontrado case insensitive (lista): $resultado');
                return resultado;
              } else if (ExtratorUtils.isValorValido(atual)) {
                final resultado = atual.toString();
                debugPrint('    Encontrado case insensitive (valor): $resultado');
                return resultado;
              }
            }
          } else {
            // Caminho não existe
            debugPrint('    Chave não encontrada: $parte');
            break;
          }
        }
      } else {
        // Não é um Map, não podemos continuar
        debugPrint('    Não é um Map: $atual');
        break;
      }
    }

    debugPrint('    Não encontrado');
    return null;
  }
}
