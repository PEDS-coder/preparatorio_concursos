import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/edital_data_formatter_service.dart';
import 'taxa_inscricao_widget.dart';
import 'cotas_info_widget.dart';

/// Widget que representa o cabeçalho do edital
class EditalHeaderWidget extends StatelessWidget {
  final Edital edital;

  const EditalHeaderWidget({
    Key? key,
    required this.edital,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edital.nomeConcurso,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          // Órgão responsável
          if (edital.dadosExtraidos.orgao != null && edital.dadosExtraidos.orgao!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.business,
              'Órgão: ${edital.dadosExtraidos.orgao}',
            ),
          // Banca organizadora
          if (edital.dadosExtraidos.banca != null && edital.dadosExtraidos.banca!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.school,
              'Banca: ${edital.dadosExtraidos.banca}',
            ),
          // Inscrições
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Inscrições: ${EditalDataFormatterService.formatDate(edital.dadosExtraidos.inicioInscricao)} a ${EditalDataFormatterService.formatDate(edital.dadosExtraidos.fimInscricao)}',
          ),
          // Taxa
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark ?
                         Colors.grey.shade300 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TaxaInscricaoWidget(edital: edital),
                ),
              ],
            ),
          ),
          // Local da prova
          if (edital.dadosExtraidos.localProva != null && edital.dadosExtraidos.localProva!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.location_on,
              'Local da Prova: ${edital.dadosExtraidos.localProva}',
            ),

          // Cotas
          CotasInfoWidget(edital: edital),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).brightness == Brightness.dark ?
                   Colors.grey.shade300 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ?
                       Colors.grey.shade300 : Colors.grey.shade700
              ),
            ),
          ),
        ],
      ),
    );
  }
}
