import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/formatador_service.dart';
import '../../domain/services/prova_service.dart';
import 'info_card.dart';
import 'criterio_desempate_card.dart';

/// Widget para exibir informações da prova
class ProvaInfoWidget extends StatelessWidget {
  final PlanoEstudo plano;
  final Edital? edital;
  final ExtratorDadosService extratoService;

  const ProvaInfoWidget({
    Key? key,
    required this.plano,
    required this.edital,
    required this.extratoService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (edital == null) {
      return const SizedBox.shrink();
    }

    // Obter critérios de desempate usando o ProvaService
    String criteriosDesempateStr = ProvaService.obterCriteriosDesempate(plano, edital);
    List<String>? criteriosDesempate;

    // Verificar se os critérios foram encontrados
    if (criteriosDesempateStr != 'Não informado') {
      // Verificar se os critérios estão em formato de lista (separados por quebra de linha)
      if (criteriosDesempateStr.contains('\n')) {
        criteriosDesempate = criteriosDesempateStr.split('\n');
      } else {
        criteriosDesempate = [criteriosDesempateStr];
      }
    } else {
      // Tentar obter dos dados extraídos diretamente
      if (edital!.dadosExtraidos.dadosProva != null &&
          edital!.dadosExtraidos.dadosProva!.criteriosDesempate != null &&
          edital!.dadosExtraidos.dadosProva!.criteriosDesempate!.isNotEmpty) {
        criteriosDesempate = edital!.dadosExtraidos.dadosProva!.criteriosDesempate;
      } else if (edital!.dadosOriginais != null &&
                edital!.dadosOriginais!.containsKey('prova') &&
                edital!.dadosOriginais!['prova'] is Map &&
                (edital!.dadosOriginais!['prova'] as Map).containsKey('criterios_desempate')) {
        final criterios = edital!.dadosOriginais!['prova']['criterios_desempate'];
        if (criterios is List) {
          criteriosDesempate = criterios.map((c) => c.toString()).toList();
        } else if (criterios is String) {
          criteriosDesempate = [criterios];
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Informações da Prova',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        InfoCard(
          label: 'Data da Prova',
          value: ProvaService.obterData(plano, edital),
          cardColor: extratoService.getColorForInfoType('Data da Prova'),
          emoji: extratoService.getEmojiForInfoType('Data da Prova'),
        ),
        InfoCard(
          label: 'Local das Provas',
          value: ProvaService.obterLocal(plano, edital),
          cardColor: extratoService.getColorForInfoType('Local das Provas'),
          emoji: extratoService.getEmojiForInfoType('Local das Provas'),
        ),
        InfoCard(
          label: 'Formato',
          value: ProvaService.obterFormato(plano, edital),
          cardColor: extratoService.getColorForInfoType('Formato'),
          emoji: extratoService.getEmojiForInfoType('Formato'),
        ),
        InfoCard(
          label: 'Total de Questões',
          value: ProvaService.obterTotalQuestoes(plano, edital),
          cardColor: extratoService.getColorForInfoType('Total de Questões'),
          emoji: extratoService.getEmojiForInfoType('Total de Questões'),
        ),
        InfoCard(
          label: 'Duração',
          value: ProvaService.obterDuracao(plano, edital),
          cardColor: extratoService.getColorForInfoType('Duração'),
          emoji: extratoService.getEmojiForInfoType('Duração'),
        ),
        InfoCard(
          label: 'Tema da Prova Subjetiva',
          value: ProvaService.obterTemaProvaSubjetiva(plano, edital),
          cardColor: extratoService.getColorForInfoType('Tema da Prova Subjetiva'),
          emoji: extratoService.getEmojiForInfoType('Tema da Prova Subjetiva'),
        ),
        InfoCard(
          label: 'Critérios de Aprovação',
          value: FormatadorService.numerarItens(ProvaService.obterCriteriosAprovacao(plano, edital)),
          cardColor: extratoService.getColorForInfoType('Critérios de Aprovação'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Aprovação'),
        ),

        InfoCard(
          label: 'Critérios de Desempate',
          value: FormatadorService.numerarItens(ProvaService.obterCriteriosDesempate(plano, edital)),
          cardColor: extratoService.getColorForInfoType('Critérios de Desempate'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Desempate'),
        ),
      ],
    );
  }
}
