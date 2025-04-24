import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';

/// Widget que exibe o cabeçalho com informações básicas do edital
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edital.nomeConcurso,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 12),
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
            'Inscrições: ${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}',
          ),
          // Local da prova
          if (edital.dadosExtraidos.localProva != null && edital.dadosExtraidos.localProva!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.location_on,
              'Local da Prova: ${edital.dadosExtraidos.localProva}',
            ),
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : Colors.grey.shade600,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Não informado';
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }
}
