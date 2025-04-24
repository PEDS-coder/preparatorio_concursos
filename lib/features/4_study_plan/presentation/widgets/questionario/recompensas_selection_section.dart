import 'package:flutter/material.dart';
import '../../../../../core/data/models/models.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para seleção de recompensas
class RecompensasSelectionSection extends StatelessWidget {
  final List<RecompensaConfig> recompensas;
  final Function(List<RecompensaConfig>) onRecompensasChanged;

  const RecompensasSelectionSection({
    Key? key,
    required this.recompensas,
    required this.onRecompensasChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recompensas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure recompensas para manter sua motivação',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecompensasList(context),
        const SizedBox(height: 16),
        _buildAddRecompensaButton(context),
      ],
    );
  }

  Widget _buildRecompensasList(BuildContext context) {
    if (recompensas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a2240),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a3050)),
        ),
        child: const Center(
          child: Text(
            'Nenhuma recompensa configurada',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: recompensas.map((recompensa) => _buildRecompensaItem(context, recompensa)).toList(),
    );
  }

  Widget _buildRecompensaItem(BuildContext context, RecompensaConfig recompensa) {
    final tipoRecompensa = _getTipoRecompensaFormatado(recompensa.tipoRecompensa);
    final IconData icone = _getIconeRecompensa(recompensa.tipoRecompensa);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2a3050)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFf43f7d).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icone,
              color: const Color(0xFFf43f7d),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recompensa.descricaoRecompensa,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipoRecompensa,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () {
              final novasRecompensas = List<RecompensaConfig>.from(recompensas);
              novasRecompensas.remove(recompensa);
              onRecompensasChanged(novasRecompensas);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddRecompensaButton(BuildContext context) {
    return InkWell(
      onTap: () => _adicionarRecompensa(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a2240),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a3050)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: Color(0xFFf43f7d)),
            SizedBox(width: 8),
            Text(
              'Adicionar Recompensa',
              style: TextStyle(
                color: Color(0xFFf43f7d),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarRecompensa(BuildContext context) {
    final TextEditingController descricaoController = TextEditingController();
    String tipoSelecionado = 'diaria';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1a2240),
          title: const Text(
            'Adicionar Recompensa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descrição da Recompensa',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descricaoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: Assistir um episódio de série',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF13192b),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2a3050)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2a3050)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFf43f7d)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tipo de Recompensa',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              _buildTipoRecompensaSelector(
                tipoSelecionado,
                (tipo) => setState(() => tipoSelecionado = tipo),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf43f7d),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (descricaoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, informe a descrição da recompensa')),
                  );
                  return;
                }
                
                final novaRecompensa = RecompensaConfig(
                  tipoRecompensa: tipoSelecionado,
                  descricaoRecompensa: descricaoController.text.trim(),
                );
                
                final novasRecompensas = List<RecompensaConfig>.from(recompensas);
                novasRecompensas.add(novaRecompensa);
                onRecompensasChanged(novasRecompensas);
                
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoRecompensaSelector(String tipoSelecionado, Function(String) onTipoChanged) {
    final tipos = [
      {'id': 'diaria', 'nome': 'Diária'},
      {'id': 'semanal', 'nome': 'Semanal'},
      {'id': 'mensal', 'nome': 'Mensal'},
    ];
    
    return Row(
      children: tipos.map((tipo) {
        final selecionado = tipo['id'] == tipoSelecionado;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => onTipoChanged(tipo['id']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selecionado ? const Color(0xFFf43f7d) : const Color(0xFF13192b),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selecionado ? const Color(0xFFf43f7d) : const Color(0xFF2a3050),
                ),
              ),
              child: Center(
                child: Text(
                  tipo['nome']!,
                  style: TextStyle(
                    color: selecionado ? Colors.white : Colors.white70,
                    fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getTipoRecompensaFormatado(String tipo) {
    switch (tipo) {
      case 'diaria':
        return 'Recompensa Diária';
      case 'semanal':
        return 'Recompensa Semanal';
      case 'mensal':
        return 'Recompensa Mensal';
      default:
        return 'Recompensa';
    }
  }

  IconData _getIconeRecompensa(String tipo) {
    switch (tipo) {
      case 'diaria':
        return Icons.coffee;
      case 'semanal':
        return Icons.movie;
      case 'mensal':
        return Icons.celebration;
      default:
        return Icons.star;
    }
  }
}
