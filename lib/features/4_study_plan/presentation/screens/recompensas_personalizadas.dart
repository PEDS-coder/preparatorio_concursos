import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RecompensasPersonalizadasWidget extends StatefulWidget {
  final List<Map<String, dynamic>> recompensasPersonalizadas;
  final Function(List<Map<String, dynamic>>) onRecompensasChanged;

  const RecompensasPersonalizadasWidget({super.key, 
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
            const Text(
              'Recompensas Personalizadas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: _mostrarDialogoAdicionarRecompensa,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recompensas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma recompensa personalizada adicionada.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
          )
        else
          Column(
            children: _recompensas.map((recompensa) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(_getIconForRecompensaTipo(recompensa['tipo']), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(recompensa['nome']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _mostrarDialogoEditarRecompensa(recompensa),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                        onPressed: () => _removerRecompensaPersonalizada(recompensa),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
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
      case 'bronze': return Icons.coffee;
      case 'prata': return Icons.videogame_asset;
      case 'ouro': return Icons.movie;
      case 'platina': return Icons.tv;
      case 'diamante': return Icons.nightlife;
      case 'lendario': return Icons.celebration;
      // Compatibilidade com tipos antigos
      case 'diaria': return Icons.today;
      case 'semanal': return Icons.view_week;
      case 'mensal': return Icons.calendar_month;
      default: return Icons.emoji_events;
    }
  }

  void _mostrarDialogoAdicionarRecompensa() {
    final TextEditingController nomeController = TextEditingController();
    String tipoSelecionado = 'bronze';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Recompensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Recompensa',
                  hintText: 'Ex: Pausa de 15 min para Redes Sociais (15 Moedas)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nível de Recompensa:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tipoSelecionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'bronze', child: Text('Bronze (5-15 Moedas)')),
                  DropdownMenuItem(value: 'prata', child: Text('Prata (25-40 Moedas)')),
                  DropdownMenuItem(value: 'ouro', child: Text('Ouro (60-100 Moedas)')),
                  DropdownMenuItem(value: 'platina', child: Text('Platina (120-200 Moedas)')),
                  DropdownMenuItem(value: 'diamante', child: Text('Diamante (300-500 Moedas)')),
                  DropdownMenuItem(value: 'lendario', child: Text('Lendário (800+ Moedas)')),
                  // Compatibilidade com tipos antigos
                  DropdownMenuItem(value: 'diaria', child: Text('Pequena (Legado)')),
                  DropdownMenuItem(value: 'semanal', child: Text('Média (Legado)')),
                  DropdownMenuItem(value: 'mensal', child: Text('Grande (Legado)')),
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
              child: const Text('Cancelar'),
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
              child: const Text('Adicionar'),
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
          title: const Text('Editar Recompensa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Recompensa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nível de Recompensa:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tipoSelecionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'bronze', child: Text('Bronze (5-15 Moedas)')),
                  DropdownMenuItem(value: 'prata', child: Text('Prata (25-40 Moedas)')),
                  DropdownMenuItem(value: 'ouro', child: Text('Ouro (60-100 Moedas)')),
                  DropdownMenuItem(value: 'platina', child: Text('Platina (120-200 Moedas)')),
                  DropdownMenuItem(value: 'diamante', child: Text('Diamante (300-500 Moedas)')),
                  DropdownMenuItem(value: 'lendario', child: Text('Lendário (800+ Moedas)')),
                  // Compatibilidade com tipos antigos
                  DropdownMenuItem(value: 'diaria', child: Text('Pequena (Legado)')),
                  DropdownMenuItem(value: 'semanal', child: Text('Média (Legado)')),
                  DropdownMenuItem(value: 'mensal', child: Text('Grande (Legado)')),
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
              child: const Text('Cancelar'),
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
              child: const Text('Salvar'),
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
