import 'package:flutter/material.dart';
import '../../../../../core/data/models/models.dart';
import '../../../../../core/utils/plano_data_logger.dart';
import '../../../domain/services/plano_data_service.dart';
import '../../helpers/formatters/date_formatter.dart';
import '../../helpers/formatters/value_formatter.dart';
import '../../helpers/formatters/duration_formatter.dart';

class InfoSection extends StatelessWidget {
  final PlanoEstudo plano;
  final Edital? edital;
  final PlanoDataLogger logger;

  const InfoSection({
    Key? key,
    required this.plano,
    this.edital,
    required this.logger,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final planoDataService = PlanoDataService(
      plano: plano,
      edital: edital,
      logger: logger,
    );
    
    final dateFormatter = DateFormatter(plano.id, logger);
    final valueFormatter = ValueFormatter(plano.id, logger);
    final durationFormatter = DurationFormatter(plano.id, logger);

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: const Color(0xFF1a2240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Concurso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              'Concurso:',
              planoDataService.obterValorPlano('titulo'),
            ),
            _buildInfoItem(
              context,
              'Órgão:',
              planoDataService.obterValorPlano('orgao'),
            ),
            _buildInfoItem(
              context,
              'Banca:',
              planoDataService.obterValorPlano('banca'),
            ),
            _buildInfoItem(
              context,
              'Data da Prova:',
              dateFormatter.tryParseAndFormatDate(
                planoDataService.obterDataProva(),
                'dataProva',
              ),
            ),
            _buildInfoItem(
              context,
              'Local da Prova:',
              planoDataService.obterValorPlano('localProva'),
            ),
            _buildInfoItem(
              context,
              'Taxa de Inscrição:',
              valueFormatter.formatCurrency(
                planoDataService.obterValorPlano('valorInscricao'),
              ),
            ),
            _buildInfoItem(
              context,
              'Formato da Prova:',
              planoDataService.obterValorPlano('formatoProva', formatarComoLista: true),
            ),
            _buildInfoItem(
              context,
              'Total de Questões:',
              planoDataService.obterValorPlano('totalQuestoes'),
            ),
            _buildInfoItem(
              context,
              'Duração da Prova:',
              durationFormatter.formatDuration(
                planoDataService.obterValorPlano('duracaoProva'),
              ),
            ),
            _buildInfoItem(
              context,
              'Tema da Prova Subjetiva:',
              planoDataService.obterValorPlano('temaProvaSubjetiva'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
