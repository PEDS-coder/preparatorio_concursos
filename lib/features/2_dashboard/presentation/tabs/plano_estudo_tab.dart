import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/models/cronograma_item.dart';

class PlanoEstudoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final planoService = Provider.of<PlanoEstudoService>(context);

    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;

    // Obter planos do usuário
    final planos = usuario != null
        ? planoService.getPlanosByUserId(usuario.id)
        : [];

    // Obter cronograma do dia atual
    final hoje = DateTime.now();
    final cronogramaHoje = planoService.getCronogramaByDate(hoje);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plano de Estudos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (!isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Básico',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Organize seus estudos de forma eficiente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),

          // Cronograma do dia
          Text(
            'Cronograma de Hoje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Lista de atividades do dia
          cronogramaHoje.isEmpty
              ? _buildEmptyCronograma()
              : Expanded(
                  child: ListView.builder(
                    itemCount: cronogramaHoje.length,
                    itemBuilder: (context, index) {
                      final item = cronogramaHoje[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(item.status).withOpacity(0.2),
                            child: Icon(
                              _getStatusIcon(item.status),
                              color: _getStatusColor(item.status),
                            ),
                          ),
                          title: Text(
                            item.nomeMateria,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                '${_formatHora(item.dataHoraInicio)} - ${_formatHora(item.dataHoraFim)}',
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Atividade: ${item.atividadeSugerida} (${item.ferramentaSugerida})',
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(Icons.more_vert),
                            onSelected: (String value) {
                              _handleItemAction(context, value, item.id);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'iniciar',
                                child: Text('Iniciar Sessão'),
                              ),
                              PopupMenuItem(
                                value: 'concluir',
                                child: Text('Marcar como Concluído'),
                              ),
                              PopupMenuItem(
                                value: 'pular',
                                child: Text('Pular'),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/sessao/iniciar',
                              arguments: item.id,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

          // Botão para criar plano
          if (planos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/plano/add');
                  },
                  icon: Icon(Icons.add),
                  label: Text('Criar Plano de Estudos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCronograma() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma atividade para hoje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crie um plano de estudos ou adicione atividades manualmente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemAction(BuildContext context, String action, String itemId) async {
    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);

    switch (action) {
      case 'iniciar':
        Navigator.pushNamed(
          context,
          '/sessao/iniciar',
          arguments: itemId,
        );
        break;
      case 'concluir':
        await planoService.updateCronogramaItemStatus(itemId, StatusItem.concluido);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Atividade marcada como concluída!'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'pular':
        await planoService.updateCronogramaItemStatus(itemId, StatusItem.pulado);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Atividade pulada.'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
    }
  }

  IconData _getStatusIcon(StatusItem status) {
    switch (status) {
      case StatusItem.pendente:
        return Icons.access_time;
      case StatusItem.concluido:
        return Icons.check_circle;
      case StatusItem.pulado:
        return Icons.skip_next;
    }
    return Icons.help_outline; // Default fallback
  }

  Color _getStatusColor(StatusItem status) {
    switch (status) {
      case StatusItem.pendente:
        return Colors.blue;
      case StatusItem.concluido:
        return Colors.green;
      case StatusItem.pulado:
        return Colors.orange;
    }
    return Colors.grey; // Default fallback
  }

  String _formatHora(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
