import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/bottom_navigation_helper.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/logger.dart';
import 'cargo_select_screen.dart';
import '../../../4_study_plan/presentation/screens/plano_questionario_screen.dart';
import '../widgets/edital_details/edital_header_widget.dart';
import '../widgets/edital_details/bottom_navigation_widget.dart';
import '../widgets/edital_details/resumo_tab_widget.dart';
import '../widgets/edital_details/cargos_tab_widget.dart';
import '../widgets/edital_details/conteudo_tab_widget.dart';
import '../../domain/services/cargo_grouping_service.dart';
import '../../domain/services/conteudo_programatico_service.dart';

class EditalDetailsScreen extends StatefulWidget {
  final String editalId;

  const EditalDetailsScreen({super.key, required this.editalId});

  @override
  _EditalDetailsScreenState createState() => _EditalDetailsScreenState();
}

class _EditalDetailsScreenState extends State<EditalDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editalService = Provider.of<EditalService>(context);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes do Edital'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text(
                'Edital não encontrado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('O edital solicitado não foi encontrado ou foi removido.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Edital'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Cargos'),
            Tab(text: 'Conteúdo'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edital/edit',
                arguments: widget.editalId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context, edital);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumoTab(edital),
          _buildCargosTab(edital),
          _buildConteudoTab(edital),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/plano/add',
            arguments: widget.editalId,
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_chart),
        label: const Text('Criar Plano de Estudo'),
      ),
    );
  }

  Widget _buildResumoTab(Edital edital) {
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
            'Adicionado em ${_formatDate(edital.dataUpload)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(height: 32),

          // Informações principais
          _buildInfoSection(
            'Informações Principais',
            [
              _buildInfoItem(
                'Período de Inscrições',
                '${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}',
                Icons.calendar_today,
              ),
              _buildInfoItem(
                'Taxa de Inscrição',
                'R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
              _buildInfoItem(
                'Local das Provas',
                edital.dadosExtraidos.localProva ?? 'Não informado',
                Icons.location_on,
              ),
              _buildInfoItem(
                'Total de Cargos',
                '${edital.dadosExtraidos.cargos.length}',
                Icons.work,
              ),
            ],
          ),

          // Cronograma
          const SizedBox(height: 24),
          _buildInfoSection(
            'Cronograma',
            [
              _buildTimelineItem(
                'Início das Inscrições',
                _formatDate(edital.dadosExtraidos.inicioInscricao),
                isFirst: true,
              ),
              _buildTimelineItem(
                'Fim das Inscrições',
                _formatDate(edital.dadosExtraidos.fimInscricao),
              ),
              _buildTimelineItem(
                'Data da Prova',
                edital.dadosExtraidos.cargos.isNotEmpty && edital.dadosExtraidos.cargos.first.dataProva != null
                    ? _formatDate(edital.dadosExtraidos.cargos.first.dataProva)
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
                    _tabController.animateTo(1); // Navegar para a aba de cargos
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
                      '/plano/add',
                      arguments: widget.editalId,
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

  Widget _buildCargosTab(Edital edital) {
    final cargos = edital.dadosExtraidos.cargos;

    return cargos.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum cargo encontrado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Não foram encontrados cargos neste edital.'),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cargos.length,
            itemBuilder: (context, index) {
              final cargo = cargos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    cargo.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Salário: R\$ ${cargo.salario.toStringAsFixed(2)}',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.work, color: AppTheme.primaryColor),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCargoInfoItem('Escolaridade', cargo.escolaridade),
                          const SizedBox(height: 8),
                          _buildCargoInfoItem(
                            'Data da Prova',
                            cargo.dataProva != null
                                ? _formatDate(cargo.dataProva)
                                : 'A definir',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Conteúdo Programático',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...cargo.conteudoProgramatico.map((materia) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 8, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(materia.nome)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/plano/add',
                                arguments: widget.editalId,
                              );
                            },
                            icon: const Icon(Icons.add_chart),
                            label: const Text('Criar Plano para este Cargo'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildConteudoTab(Edital edital) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Texto do Edital',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              edital.textoCompleto.length > 1000
                  ? '${edital.textoCompleto.substring(0, 1000)}...\n\n[Texto truncado]'
                  : edital.textoCompleto,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // Implementar visualização completa do edital
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade disponível em breve!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Ver Texto Completo'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String date, {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isLast ? 0 : 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCargoInfoItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Edital edital) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Edital'),
        content: Text(
          'Tem certeza que deseja excluir o edital "${edital.nomeConcurso}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final editalService = Provider.of<EditalService>(context, listen: false);
              await editalService.removeEdital(widget.editalId);

              Navigator.pop(context); // Fechar o diálogo
              Navigator.pop(context); // Voltar para a tela anterior

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edital excluído com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
