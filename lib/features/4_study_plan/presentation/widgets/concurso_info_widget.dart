import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/formatador_service.dart';
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
        Padding(
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
            value: extratoService.obterPeriodoInscricoes(edital),
            cardColor: extratoService.getColorForInfoType('Período de Inscrições'),
            emoji: extratoService.getEmojiForInfoType('Período de Inscrições'),
          ),
          InfoCard(
            label: 'Data da Prova',
            value: extratoService.obterValorConcurso(plano, edital, 'dataProva', 'data_prova'),
            cardColor: extratoService.getColorForInfoType('Data da Prova'),
            emoji: extratoService.getEmojiForInfoType('Data da Prova'),
          ),

          // Informações em azul (identificação)
          InfoCard(
            label: 'Nome',
            value: extratoService.obterValorConcurso(plano, edital, 'titulo', 'titulo_concurso'),
            cardColor: extratoService.getColorForInfoType('Nome'),
            emoji: extratoService.getEmojiForInfoType('Nome'),
          ),
          InfoCard(
            label: 'Órgão',
            value: extratoService.obterValorConcurso(plano, edital, 'orgao', 'orgao_responsavel'),
            cardColor: extratoService.getColorForInfoType('Órgão'),
            emoji: extratoService.getEmojiForInfoType('Órgão'),
          ),
          InfoCard(
            label: 'Banca',
            value: extratoService.obterValorConcurso(plano, edital, 'banca', 'banca_organizadora'),
            cardColor: extratoService.getColorForInfoType('Banca'),
            emoji: extratoService.getEmojiForInfoType('Banca'),
          ),
          InfoCard(
            label: 'Total de Questões',
            value: extratoService.obterValorConcurso(plano, edital, 'totalQuestoes', 'prova.total_questoes'),
            cardColor: extratoService.getColorForInfoType('Total de Questões'),
            emoji: extratoService.getEmojiForInfoType('Total de Questões'),
          ),

          // Informações em verde (valores)
          InfoCard(
            label: 'Taxa de Inscrição',
            value: FormatadorService.formatarValor(
              extratoService.obterValorNumerico(plano, edital, 'valorInscricao', 'taxa_inscricao')
            ),
            cardColor: extratoService.getColorForInfoType('Taxa de Inscrição'),
            emoji: extratoService.getEmojiForInfoType('Taxa de Inscrição'),
          ),

          // Informações em laranja (locais)
          InfoCard(
            label: 'Local das Provas',
            value: extratoService.obterValorConcurso(plano, edital, 'localProva', 'local_prova'),
            cardColor: extratoService.getColorForInfoType('Local das Provas'),
            emoji: extratoService.getEmojiForInfoType('Local das Provas'),
          ),

          // Informações em roxo (cotas e formato)
          InfoCard(
            label: 'Cotas',
            value: extratoService.obterInformacoesCotas(edital),
            cardColor: extratoService.getColorForInfoType('Cotas'),
            emoji: extratoService.getEmojiForInfoType('Cotas'),
          ),
          InfoCard(
            label: 'Formato',
            value: extratoService.obterValorConcurso(plano, edital, 'formatoProva', 'prova.formato'),
            cardColor: extratoService.getColorForInfoType('Formato'),
            emoji: extratoService.getEmojiForInfoType('Formato'),
          ),

          // Informações adicionais
          InfoCard(
            label: 'Tema da Prova Subjetiva',
            value: extratoService.obterValorConcurso(plano, edital, 'temaProvaSubjetiva', 'prova.tema_discursiva'),
            cardColor: extratoService.getColorForInfoType('Tema da Prova Subjetiva'),
            emoji: extratoService.getEmojiForInfoType('Tema da Prova Subjetiva'),
          ),
        ] else ...[
          InfoCard(
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
