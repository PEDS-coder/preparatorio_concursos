import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/formatador_service.dart';
import '../../domain/services/plano_resumo_service.dart';
import 'info_card.dart';

/// Widget para exibir informações do cargo
class CargoInfoWidget extends StatelessWidget {
  final PlanoEstudo plano;
  final Edital? edital;
  final Cargo? cargo;
  final ExtratorDadosService extratoService;
  final PlanoResumoService planoResumoService;

  const CargoInfoWidget({
    Key? key,
    required this.plano,
    required this.edital,
    required this.cargo,
    required this.extratoService,
    required this.planoResumoService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (edital == null || cargo == null) {
      return const SizedBox.shrink();
    }

    // Obter informações do cargo
    final infoDetalhadas = planoResumoService.obterInformacoesDetalhadas(edital, cargo);
    final infoVagas = planoResumoService.obterInformacoesVagas(edital, cargo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Cargo Selecionado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        // Informações em roxo (cargo)
        InfoCard(
          label: 'Cargo',
          value: cargo!.nome,
          cardColor: extratoService.getColorForInfoType('Cargo'),
          emoji: extratoService.getEmojiForInfoType('Cargo'),
        ),

        // Informações em laranja (requisitos)
        InfoCard(
          label: 'Requisitos',
          value: FormatadorService.numerarItens(infoDetalhadas?['requisitos']),
          cardColor: extratoService.getColorForInfoType('Requisitos'),
          emoji: extratoService.getEmojiForInfoType('Requisitos'),
        ),
        if (infoDetalhadas?['nivel']?.toString() != 'Não informado')
          InfoCard(
            label: 'Nível',
            value: infoDetalhadas?['nivel']?.toString() ?? 'Não informado',
            cardColor: extratoService.getColorForInfoType('Nível'),
            emoji: extratoService.getEmojiForInfoType('Nível'),
          ),

        // Informações em verde (valores)
        InfoCard(
          label: 'Salário',
          value: FormatadorService.formatarValor(infoDetalhadas?['salario']?.toString() ?? 'Não informado'),
          cardColor: extratoService.getColorForInfoType('Salário'),
          emoji: extratoService.getEmojiForInfoType('Salário'),
        ),

        // Informações sobre vagas
        InfoCard(
          label: 'Vagas',
          value: infoVagas['texto'],
          cardColor: extratoService.getColorForInfoType('Vagas'),
          emoji: extratoService.getEmojiForInfoType('Vagas'),
        ),
      ],
    );
  }
}
