import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/edital_formatter_service.dart';
import 'info_item_widget.dart';
import 'info_section_widget.dart';
import 'timeline_item_widget.dart';
import '../screens/cargo_select_screen.dart';

/// Widget que representa a aba de resumo do edital
class EditalResumoTabWidget extends StatelessWidget {
  final Edital edital;
  final String editalId;
  final TabController tabController;

  const EditalResumoTabWidget({
    Key? key,
    required this.edital,
    required this.editalId,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            edital.nomeConcurso,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicionado em ${EditalFormatterService.formatDate(edital.dataUpload)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(height: 32),

          // Informações principais
          InfoSectionWidget(
            title: 'Informações Principais',
            children: [
              InfoItemWidget(
                label: 'Período de Inscrições',
                value: '${EditalFormatterService.formatDate(edital.dadosExtraidos.inicioInscricao)} a ${EditalFormatterService.formatDate(edital.dadosExtraidos.fimInscricao)}',
                icon: Icons.calendar_today,
              ),
              InfoItemWidget(
                label: 'Taxa de Inscrição',
                value: 'R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}',
                icon: Icons.attach_money,
              ),
              InfoItemWidget(
                label: 'Local das Provas',
                value: edital.dadosExtraidos.localProva ?? 'Não informado',
                icon: Icons.location_on,
              ),
              InfoItemWidget(
                label: 'Total de Cargos',
                value: '${edital.dadosExtraidos.cargos.length}',
                icon: Icons.work,
              ),
            ],
          ),

          // Cronograma
          const SizedBox(height: 24),
          InfoSectionWidget(
            title: 'Cronograma',
            children: [
              TimelineItemWidget(
                label: 'Início das Inscrições',
                date: EditalFormatterService.formatDate(edital.dadosExtraidos.inicioInscricao),
                isFirst: true,
              ),
              TimelineItemWidget(
                label: 'Fim das Inscrições',
                date: EditalFormatterService.formatDate(edital.dadosExtraidos.fimInscricao),
              ),
              TimelineItemWidget(
                label: 'Data da Prova',
                date: edital.dadosExtraidos.cargos.isNotEmpty && edital.dadosExtraidos.cargos.first.dataProva != null
                    ? EditalFormatterService.formatDate(edital.dadosExtraidos.cargos.first.dataProva)
                    : 'A definir',
                isLast: true,
              ),
            ],
          ),

          // Botões de ação
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    tabController.animateTo(1); // Navegar para a aba de cargos
                  },
                  icon: const Icon(Icons.work),
                  label: const Text('Ver Cargos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/cargo/select',
                      arguments: editalId,
                    );
                  },
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Criar Plano'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
