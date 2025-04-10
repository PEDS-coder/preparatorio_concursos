import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/theme/app_theme.dart';

class EditaisTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final editalService = Provider.of<EditalService>(context);
    
    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;
    
    // Obter editais do usuário
    final editais = usuario != null 
        ? editalService.getEditaisByUserId(usuario.id)
        : [];
    
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
                'Meus Editais',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (!isPremium && editais.length >= 1)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Limite: 1/1',
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
            'Gerencie seus editais de concursos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          
          // Lista de editais
          Expanded(
            child: editais.isEmpty
                ? _buildEmptyState(context, isPremium)
                : ListView.builder(
                    itemCount: editais.length,
                    itemBuilder: (context, index) {
                      final edital = editais[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      edital.nomeConcurso,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_vert),
                                    onPressed: () {
                                      _showEditalOptions(context, edital.id);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Inscrições: ${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}',
                              ),
                              SizedBox(height: 4),
                              _buildInfoRow(
                                Icons.attach_money,
                                'Taxa: R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}',
                              ),
                              SizedBox(height: 4),
                              _buildInfoRow(
                                Icons.location_on,
                                'Local: ${edital.dadosExtraidos.localProva}',
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cargos: ${edital.dadosExtraidos.cargos.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: edital.dadosExtraidos.cargos.map((cargo) {
                                  return Chip(
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    label: Text(
                                      cargo.nome,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/edital/detalhes',
                                          arguments: edital.id,
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: BorderSide(color: AppTheme.primaryColor),
                                      ),
                                      child: Text('Ver Detalhes'),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/plano/add',
                                          arguments: edital.id,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                      child: Text('Criar Plano'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, bool isPremium) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum edital cadastrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Adicione seu primeiro edital para começar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/edital/add');
            },
            icon: Icon(Icons.add),
            label: Text('Adicionar Edital'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Versão gratuita: limite de 1 edital',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showEditalOptions(BuildContext context, String editalId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: AppTheme.primaryColor),
                title: Text('Editar Edital'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/edital/edit',
                    arguments: editalId,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy, color: AppTheme.primaryColor),
                title: Text('Duplicar Edital'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar duplicação
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir Edital'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteEdital(context, editalId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _confirmDeleteEdital(BuildContext context, String editalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Edital'),
        content: Text('Tem certeza que deseja excluir este edital? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final editalService = Provider.of<EditalService>(context, listen: false);
              await editalService.removeEdital(editalId);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edital excluído com sucesso.'),
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
