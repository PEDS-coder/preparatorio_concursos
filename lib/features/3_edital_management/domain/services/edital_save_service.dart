import 'package:flutter/material.dart';
import '../../../../../core/auth/auth_service.dart';
import '../../../../../core/data/services/edital_service.dart';
import '../../../../../core/data/models/edital.dart';

/// Serviço para salvar editais analisados
class EditalSaveService {
  final EditalService editalService;
  final AuthService authService;

  EditalSaveService({
    required this.editalService,
    required this.authService,
  });

  /// Salva um edital analisado e retorna o objeto Edital
  Future<Edital?> salvarEdital(Map<String, dynamic> dadosMap) async {
    final usuario = authService.currentUser;

    if (usuario == null) {
      throw Exception('Você precisa estar logado para salvar o edital.');
    }

    // Extrair título do edital
    final String titulo = dadosMap['titulo'] ?? 'Edital Analisado';

    // Criar objeto DadosExtraidos a partir do Map
    final List<Cargo> cargos = [];
    if (dadosMap['cargos'] != null && dadosMap['cargos'] is List) {
      for (var cargoMap in dadosMap['cargos']) {
        // Processar o salário corretamente
        double salario = 0.0;
        if (cargoMap['salario'] != null) {
          if (cargoMap['salario'] is num) {
            salario = (cargoMap['salario'] as num).toDouble();
          } else if (cargoMap['salario'] is String) {
            try {
              // Remover caracteres não numéricos, exceto ponto e vírgula
              String cleanedString = cargoMap['salario'].toString().replaceAll(RegExp(r'[^0-9.,]'), '');
              // Substituir vírgula por ponto para o parse
              cleanedString = cleanedString.replaceAll(',', '.');
              // Remover pontos extras (milhares) se houver mais de um ponto decimal
              if (cleanedString.split('.').length > 2) {
                cleanedString = cleanedString.replaceAll(RegExp(r'\.(?=.*\.)'), ''); // Remove todos os pontos exceto o último
              }
              salario = double.parse(cleanedString);
            } catch (e) {
              debugPrint('Erro ao converter salário: $e');
              salario = 0.0;
            }
          }
        }

        // Processar a escolaridade corretamente
        String escolaridade = cargoMap['escolaridade'] ?? 'Não especificado';
        // Garantir que a escolaridade não seja truncada
        if (escolaridade is String && escolaridade.isNotEmpty) {
          // Manter a escolaridade como está, sem modificações
        } else {
          escolaridade = 'Não especificado';
        }

        cargos.add(Cargo(
          id: '${DateTime.now().millisecondsSinceEpoch}_' + (cargoMap['nome'] ?? ''),
          nome: cargoMap['nome'] ?? 'Cargo sem nome',
          vagas: cargoMap['vagas'] ?? 0,
          salario: salario,
          escolaridade: escolaridade,
          dataProva: cargoMap['dataProva'] != null ? DateTime.parse(cargoMap['dataProva']) : null,
          conteudoProgramatico: [],
        ));
      }
    }

    // Tratar datas de inscrição com segurança para evitar erros de formato
    DateTime? inicioInscricao;
    DateTime? fimInscricao;

    try {
      if (dadosMap['inicioInscricao'] != null) {
        inicioInscricao = DateTime.parse(dadosMap['inicioInscricao']);
      }
    } catch (e) {
      debugPrint('Erro ao converter data de início de inscrição: ${e.toString()}');
      // Não definir a data se houver erro
    }

    try {
      if (dadosMap['fimInscricao'] != null) {
        fimInscricao = DateTime.parse(dadosMap['fimInscricao']);
      }
    } catch (e) {
      debugPrint('Erro ao converter data de fim de inscrição: ${e.toString()}');
      // Não definir a data se houver erro
    }

    final DadosExtraidos dadosExtraidos = DadosExtraidos(
      titulo: dadosMap['titulo'],
      banca: dadosMap['banca'],
      inicioInscricao: inicioInscricao,
      fimInscricao: fimInscricao,
      valorTaxa: dadosMap['valorTaxa'],
      localProva: dadosMap['localProva'],
      cargos: cargos,
    );

    // Salvar o edital
    final Edital edital = await editalService.addEdital(
      usuario.id,
      titulo,
      '', // Texto completo não é necessário, pois temos os bytes do PDF
      dadosExtraidos,
      dadosOriginais: dadosMap,
    );

    return edital;
  }
}
