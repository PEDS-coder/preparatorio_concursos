import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/models/models.dart';

class PlanoDetailsScreen extends StatelessWidget {
  final String planoId;

  const PlanoDetailsScreen({required this.planoId});

  @override
  Widget build(BuildContext context) {
    final planoEstudoService = Provider.of<PlanoEstudoService>(context);
    final plano = planoEstudoService.getPlanoById(planoId);

    if (plano == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Detalhes do Plano'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Text('Plano não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Plano'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navegar para a tela de edição do plano
              Navigator.pushNamed(context, '/plano/edit', arguments: planoId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Text(
              'Plano de Estudos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Criado em ${_formatarData(plano.dataCriacao)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Divider(height: 32),

            // Informações gerais
            _buildSectionTitle('Informações Gerais'),
            _buildInfoItem('Período', '${_formatarData(plano.dataInicio)} a ${_formatarData(plano.dataFim)}'),
            _buildInfoItem('Total de Sessões', '${plano.sessoesEstudo.length}'),
            _buildInfoItem('Cargos', plano.cargoIds.isEmpty ? 'Nenhum cargo selecionado' : plano.cargoIds.join(', ')),
            SizedBox(height: 24),

            // Disponibilidade semanal
            _buildSectionTitle('Disponibilidade Semanal'),
            _buildHorasSemanais(plano.horasSemanais),
            SizedBox(height: 24),

            // Ferramentas de estudo
            _buildSectionTitle('Ferramentas de Estudo'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plano.ferramentas.map((ferramenta) {
                return Chip(
                  label: Text(ferramenta),
                  backgroundColor: Colors.blue.shade100,
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Recompensas
            _buildSectionTitle('Recompensas'),
            _buildRecompensas(plano.recompensas),
            SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text('Ver Calendário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/plano/calendario',
                        arguments: planoId,
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    label: Text('Iniciar Jornada'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.green),
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorasSemanais(Map<String, int> horasSemanais) {
    final diasSemana = {
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    return Column(
      children: diasSemana.entries.map((entry) {
        final dia = entry.key;
        final nomeDia = entry.value;
        final horas = horasSemanais[dia] ?? 0;

        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(nomeDia),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: horas / 8, // Considerando 8h como máximo
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              SizedBox(width: 8),
              Text('$horas h'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecompensas(List<RecompensaConfig> recompensas) {
    final recompensasPorTipo = {
      'diaria': <RecompensaConfig>[],
      'semanal': <RecompensaConfig>[],
      'mensal': <RecompensaConfig>[],
    };

    for (final recompensa in recompensas) {
      if (recompensasPorTipo.containsKey(recompensa.tipoRecompensa)) {
        recompensasPorTipo[recompensa.tipoRecompensa]!.add(recompensa);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recompensasPorTipo['diaria']!.isNotEmpty) ...[
          Text(
            'Diárias',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recompensasPorTipo['diaria']!.map((r) => _buildRecompensaChip(r)).toList(),
          ),
          SizedBox(height: 16),
        ],

        if (recompensasPorTipo['semanal']!.isNotEmpty) ...[
          Text(
            'Semanais',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recompensasPorTipo['semanal']!.map((r) => _buildRecompensaChip(r)).toList(),
          ),
          SizedBox(height: 16),
        ],

        if (recompensasPorTipo['mensal']!.isNotEmpty) ...[
          Text(
            'Mensais',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recompensasPorTipo['mensal']!.map((r) => _buildRecompensaChip(r)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRecompensaChip(RecompensaConfig recompensa) {
    return Chip(
      label: Text(recompensa.descricaoRecompensa),
      backgroundColor: _getColorForRecompensaTipo(recompensa.tipoRecompensa),
    );
  }

  Color _getColorForRecompensaTipo(String tipo) {
    switch (tipo) {
      case 'diaria': return Colors.green.shade100;
      case 'semanal': return Colors.orange.shade100;
      case 'mensal': return Colors.purple.shade100;
      default: return Colors.grey.shade100;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
