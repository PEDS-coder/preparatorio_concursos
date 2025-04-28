import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/formatador_service.dart';
import '../../domain/services/plano_metadados_service.dart';
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
          value: PlanoMetadadosService.getDataProva(plano),
          cardColor: extratoService.getColorForInfoType('Data da Prova'),
          emoji: extratoService.getEmojiForInfoType('Data da Prova'),
        ),
        InfoCard(
          label: 'Local das Provas',
          value: PlanoMetadadosService.getLocalProvas(plano),
          cardColor: extratoService.getColorForInfoType('Local das Provas'),
          emoji: extratoService.getEmojiForInfoType('Local das Provas'),
        ),
        InfoCard(
          label: 'Formato',
          value: PlanoMetadadosService.getFormatoProva(plano),
          cardColor: extratoService.getColorForInfoType('Formato'),
          emoji: extratoService.getEmojiForInfoType('Formato'),
        ),
        InfoCard(
          label: 'Total de Questões',
          value: PlanoMetadadosService.getTotalQuestoes(plano),
          cardColor: extratoService.getColorForInfoType('Total de Questões'),
          emoji: extratoService.getEmojiForInfoType('Total de Questões'),
        ),
        InfoCard(
          label: 'Duração',
          value: PlanoMetadadosService.getDuracaoProva(plano),
          cardColor: extratoService.getColorForInfoType('Duração'),
          emoji: extratoService.getEmojiForInfoType('Duração'),
        ),
        InfoCard(
          label: 'Tema da Prova Subjetiva',
          value: PlanoMetadadosService.getTemaProvaSubjetiva(plano),
          cardColor: extratoService.getColorForInfoType('Tema da Prova Subjetiva'),
          emoji: extratoService.getEmojiForInfoType('Tema da Prova Subjetiva'),
        ),
        InfoCard(
          label: 'Critérios de Aprovação',
          value: FormatadorService.numerarItens(PlanoMetadadosService.getCriteriosAprovacao(plano)),
          cardColor: extratoService.getColorForInfoType('Critérios de Aprovação'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Aprovação'),
        ),
        InfoCard(
          label: 'Critérios de Desempate',
          value: FormatadorService.numerarItens(PlanoMetadadosService.getCriteriosDesempate(plano)),
          cardColor: extratoService.getColorForInfoType('Critérios de Desempate'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Desempate'),
        ),
        InfoCard(
          label: 'Cotas',
          value: _formatarCotas(PlanoMetadadosService.getCotas(plano)),
          cardColor: extratoService.getColorForInfoType('Cotas'),
          emoji: extratoService.getEmojiForInfoType('Cotas'),
        ),
        InfoCard(
          label: 'Taxa de Inscrição',
          value: PlanoMetadadosService.getTaxaInscricao(plano),
          cardColor: extratoService.getColorForInfoType('Taxa de Inscrição'),
          emoji: extratoService.getEmojiForInfoType('Taxa de Inscrição'),
        ),
      ],
    );
  }

  String _formatarCotas(List<Map<String, dynamic>> cotas) {
    if (cotas.isEmpty) return 'Não informado';
    List<String> itens = [];
    for (var cota in cotas) {
      String tipo = cota['tipo'] ?? 'Cota';
      String? percentual = cota['percentual']?.toString();
      String? vagas = cota['vagas']?.toString();
      String criterio = (cota['criterios'] is List)
          ? (cota['criterios'] as List).join('; ')
          : (cota['criterios']?.toString() ?? '');
      String texto = '$tipo';
      if (percentual != null && percentual.isNotEmpty && percentual != 'null') texto += ' ($percentual%)';
      if (vagas != null && vagas.isNotEmpty && vagas != 'null') texto += ', $vagas vagas';
      if (criterio.isNotEmpty) texto += ': $criterio';
      itens.add(texto);
    }
    return itens.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('; ');
  }
}
