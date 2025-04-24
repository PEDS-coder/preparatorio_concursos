import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/formatador_service.dart';
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
      return SizedBox.shrink();
    }

    // Obter critérios de desempate usando o ExtratorDadosService
    String criteriosDesempateStr = extratoService.obterCriteriosDesempate(plano, edital);
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
        Padding(
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
          label: 'Duração',
          value: FormatadorService.formatarDuracaoProva(
            extratoService.obterValorConcurso(plano, edital, 'duracaoProva', 'prova.duracao')
          ),
          cardColor: extratoService.getColorForInfoType('Duração'),
          emoji: extratoService.getEmojiForInfoType('Duração'),
        ),
        InfoCard(
          label: 'Critérios de Aprovação',
          value: extratoService.obterValorConcurso(plano, edital, 'criteriosAprovacao', 'prova.criterios_aprovacao'),
          cardColor: extratoService.getColorForInfoType('Critérios de Aprovação'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Aprovação'),
        ),
        InfoCard(
          label: 'Critérios de Reprovação',
          value: extratoService.obterValorConcurso(plano, edital, 'criteriosReprovacao', 'prova.criterios_reprovacao'),
          cardColor: extratoService.getColorForInfoType('Critérios de Reprovação'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Reprovação'),
        ),
        InfoCard(
          label: 'Critérios de Desempate',
          value: extratoService.obterCriteriosDesempate(plano, edital),
          cardColor: extratoService.getColorForInfoType('Critérios de Desempate'),
          emoji: extratoService.getEmojiForInfoType('Critérios de Desempate'),
        ),
        if (criteriosDesempate != null && criteriosDesempate.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Critérios de Desempate (Detalhados)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          ...criteriosDesempate.asMap().entries.map((entry) {
            final index = entry.key;
            final criterio = entry.value;
            return CriterioDesempateCard(
              index: index + 1,
              criterio: criterio,
              color: Colors.purple,
              emoji: '📝',
            );
          }).toList(),
        ],
      ],
    );
  }
}
