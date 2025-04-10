import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/models/edital.dart';

class EditalDetailsScreen extends StatefulWidget {
  final String editalId;

  const EditalDetailsScreen({required this.editalId});

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
          title: Text('Detalhes do Edital'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
              SizedBox(height: 16),
              Text(
                'Edital não encontrado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('O edital solicitado não foi encontrado ou foi removido.'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Edital'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Resumo'),
            Tab(text: 'Cargos'),
            Tab(text: 'Conteúdo'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edital/edit',
                arguments: widget.editalId,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
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
        icon: Icon(Icons.add_chart),
        label: Text('Criar Plano de Estudo'),
      ),
    );
  }

  Widget _buildResumoTab(Edital edital) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            edital.nomeConcurso,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Adicionado em ${_formatDate(edital.dataUpload)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Divider(height: 32),

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
          SizedBox(height: 24),
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
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(1); // Navegar para a aba de cargos
                  },
                  icon: Icon(Icons.work),
                  label: Text('Ver Cargos'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/plano/add',
                      arguments: widget.editalId,
                    );
                  },
                  icon: Icon(Icons.add_chart),
                  label: Text('Criar Plano'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
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
                SizedBox(height: 16),
                Text(
                  'Nenhum cargo encontrado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Não foram encontrados cargos neste edital.'),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: cargos.length,
            itemBuilder: (context, index) {
              final cargo = cargos[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    cargo.nome,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Vagas: ${cargo.vagas} | Salário: R\$ ${cargo.salario.toStringAsFixed(2)}',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.work, color: AppTheme.primaryColor),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCargoInfoItem('Escolaridade', cargo.escolaridade),
                          SizedBox(height: 8),
                          _buildCargoInfoItem(
                            'Data da Prova',
                            cargo.dataProva != null
                                ? _formatDate(cargo.dataProva)
                                : 'A definir',
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Conteúdo Programático',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          ...cargo.conteudoProgramatico.map((materia) => Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(materia.nome)),
                                  ],
                                ),
                              )),
                          SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/plano/add',
                                arguments: widget.editalId,
                              );
                            },
                            icon: Icon(Icons.add_chart),
                            label: Text('Criar Plano para este Cargo'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primaryColor),
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Texto do Edital',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              edital.textoCompleto.length > 1000
                  ? '${edital.textoCompleto.substring(0, 1000)}...\n\n[Texto truncado]'
                  : edital.textoCompleto,
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // Implementar visualização completa do edital
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Funcionalidade disponível em breve!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: Icon(Icons.visibility),
            label: Text('Ver Texto Completo'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor),
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          SizedBox(width: 12),
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
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
              child: Icon(Icons.check, size: 12, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Edital edital) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Edital'),
        content: Text(
          'Tem certeza que deseja excluir o edital "${edital.nomeConcurso}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final editalService = Provider.of<EditalService>(context, listen: false);
              await editalService.removeEdital(widget.editalId);

              Navigator.pop(context); // Fechar o diálogo
              Navigator.pop(context); // Voltar para a tela anterior

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edital excluído com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Excluir'),
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
