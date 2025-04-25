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
        cargos.add(Cargo(
          id: '${DateTime.now().millisecondsSinceEpoch}_' + (cargoMap['nome'] ?? ''),
          nome: cargoMap['nome'] ?? 'Cargo sem nome',
          vagas: cargoMap['vagas'] ?? 0,
          salario: cargoMap['salario'] ?? 0.0,
          escolaridade: cargoMap['escolaridade'] ?? 'Não especificado',
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
