import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/formatador_service.dart';
import '../../domain/services/concurso_service.dart';
import '../../domain/services/prova_service.dart';
import '../../domain/services/inscricao_service.dart';
import '../../domain/services/cotas_service.dart';
import 'info_card.dart';

/// Widget para exibir informações do concurso
class ConcursoInfoWidget extends StatelessWidget {
  final PlanoEstudo plano;
  final Edital? edital;
  final ExtratorDadosService extratoService;

  const ConcursoInfoWidget({
    Key? key,
    required this.plano,
    required this.edital,
    required this.extratoService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Dados do Concurso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        if (edital != null) ...[
          // Informações em vermelho (datas e prazos)
          InfoCard(
            label: 'Período de Inscrições',
            value: InscricaoService.obterPeriodo(edital),
            cardColor: extratoService.getColorForInfoType('Período de Inscrições'),
            emoji: extratoService.getEmojiForInfoType('Período de Inscrições'),
          ),


          // Informações em azul (identificação)
          InfoCard(
            label: 'Nome',
            value: ConcursoService.obterTitulo(plano, edital),
            cardColor: extratoService.getColorForInfoType('Nome'),
            emoji: extratoService.getEmojiForInfoType('Nome'),
          ),
          InfoCard(
            label: 'Órgão',
            value: ConcursoService.obterOrgao(plano, edital),
            cardColor: extratoService.getColorForInfoType('Órgão'),
            emoji: extratoService.getEmojiForInfoType('Órgão'),
          ),
          InfoCard(
            label: 'Banca',
            value: ConcursoService.obterBanca(plano, edital),
            cardColor: extratoService.getColorForInfoType('Banca'),
            emoji: extratoService.getEmojiForInfoType('Banca'),
          ),


          // Informações em verde (valores)
          InfoCard(
            label: 'Taxa de Inscrição',
            value: InscricaoService.obterValor(plano, edital),
            cardColor: extratoService.getColorForInfoType('Taxa de Inscrição'),
            emoji: extratoService.getEmojiForInfoType('Taxa de Inscrição'),
          ),



          // Informações em roxo (cotas e formato)
          InfoCard(
            label: 'Cotas',
            value: CotasService.obterInformacoes(edital),
            cardColor: extratoService.getColorForInfoType('Cotas'),
            emoji: extratoService.getEmojiForInfoType('Cotas'),
          ),

        ] else ...[
          const InfoCard(
            label: 'Plano',
            value: 'Plano de estudos personalizado',
            cardColor: Colors.blue,
            emoji: '📝',
          ),
          InfoCard(
            label: 'Período',
            value: '${FormatadorService.formatarData(plano.dataInicio)} a ${FormatadorService.formatarData(plano.dataFim)}',
            cardColor: Colors.red,
            emoji: '📅',
          ),
        ],
      ],
    );
  }
}
