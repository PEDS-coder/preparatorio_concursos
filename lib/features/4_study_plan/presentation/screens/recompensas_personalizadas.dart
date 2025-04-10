import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RecompensasPersonalizadasWidget extends StatefulWidget {
  final List<Map<String, dynamic>> recompensasPersonalizadas;
  final Function(List<Map<String, dynamic>>) onRecompensasChanged;

  const RecompensasPersonalizadasWidget({
    required this.recompensasPersonalizadas,
    required this.onRecompensasChanged,
  });

  @override
  _RecompensasPersonalizadasWidgetState createState() => _RecompensasPersonalizadasWidgetState();
}

class _RecompensasPersonalizadasWidgetState extends State<RecompensasPersonalizadasWidget> {
  late List<Map<String, dynamic>> _recompensas;

  @override
  void initState() {
    super.initState();
    _recompensas = List.from(widget.recompensasPersonalizadas);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recompensas Personalizadas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.add, size: 16),
              label: Text('Adicionar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: TextStyle(fontSize: 12),
              ),
              onPressed: _mostrarDialogoAdicionarRecompensa,
            ),
          ],
        ),
        SizedBox(height: 8),
        if (_recompensas.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma recompensa personalizada adicionada.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
          )
        else
          Column(
            children: _recompensas.map((recompensa) {
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(_getIconForRecompensaTipo(recompensa['tipo']), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(recompensa['nome']),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 16),
                        onPressed: () => _mostrarDialogoEditarRecompensa(recompensa),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 16, color: Colors.red),
                        onPressed: () => _removerRecompensaPersonalizada(recompensa),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  IconData _getIconForRecompensaTipo(String tipo) {
    switch (tipo) {
      case 'diaria': return Icons.today;
      case 'semanal': return Icons.view_week;
      case 'mensal': return Icons.calendar_month;
      default: return Icons.emoji_events;
    }
  }

  void _mostrarDialogoAdicionarRecompensa() {
    final TextEditingController nomeController = TextEditingController();
    String tipoSelecionado = 'diaria';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Adicionar Recompensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Recompensa',
                  hintText: 'Ex: Assistir um filme específico',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Text('Frequência:'),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tipoSelecionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(value: 'diaria', child: Text('Diária')),
                  DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                  DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      tipoSelecionado = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomeController.text.trim().isNotEmpty) {
                  final novaRecompensa = {
                    'id': 'personalizada_${DateTime.now().millisecondsSinceEpoch}',
                    'nome': nomeController.text.trim(),
                    'tipo': tipoSelecionado,
                  };
                  
                  setState(() {
                    _recompensas.add(novaRecompensa);
                  });
                  
                  widget.onRecompensasChanged(_recompensas);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditarRecompensa(Map<String, dynamic> recompensa) {
    final TextEditingController nomeController = TextEditingController(text: recompensa['nome']);
    String tipoSelecionado = recompensa['tipo'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Editar Recompensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Recompensa',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Text('Frequência:'),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tipoSelecionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(value: 'diaria', child: Text('Diária')),
                  DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                  DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      tipoSelecionado = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomeController.text.trim().isNotEmpty) {
                  final index = _recompensas.indexWhere((r) => r['id'] == recompensa['id']);
                  if (index != -1) {
                    setState(() {
                      _recompensas[index] = {
                        'id': recompensa['id'],
                        'nome': nomeController.text.trim(),
                        'tipo': tipoSelecionado,
                      };
                    });
                    
                    widget.onRecompensasChanged(_recompensas);
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _removerRecompensaPersonalizada(Map<String, dynamic> recompensa) {
    setState(() {
      _recompensas.removeWhere((r) => r['id'] == recompensa['id']);
      widget.onRecompensasChanged(_recompensas);
    });
  }
}
