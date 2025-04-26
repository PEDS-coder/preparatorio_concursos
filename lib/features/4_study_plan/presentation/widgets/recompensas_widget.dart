import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget para exibir as recompensas
class RecompensasWidget extends StatelessWidget {
  final PlanoEstudo plano;

  const RecompensasWidget({
    Key? key,
    required this.plano,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (plano.recompensas.isEmpty) {
      return const SizedBox.shrink();
    }

    final recompensasPorTipo = _agruparRecompensasPorTipo(plano.recompensas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Recompensas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Novos tipos de recompensas
                if (recompensasPorTipo['bronze']!.isNotEmpty) ...[
                  const Text(
                    'Bronze (5-15 Moedas)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['bronze']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['prata']!.isNotEmpty) ...[
                  const Text(
                    'Prata (25-40 Moedas)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['prata']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['ouro']!.isNotEmpty) ...[
                  const Text(
                    'Ouro (60-100 Moedas)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['ouro']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['platina']!.isNotEmpty) ...[
                  const Text(
                    'Platina (120-200 Moedas)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['platina']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['diamante']!.isNotEmpty) ...[
                  const Text(
                    'Diamante (300-500 Moedas)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['diamante']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['lendario']!.isNotEmpty) ...[
                  const Text(
                    'Lendário (800+ Moedas)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['lendario']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Compatibilidade com tipos antigos
                if (recompensasPorTipo['diaria']!.isNotEmpty) ...[
                  const Text(
                    'Diárias',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['diaria']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['semanal']!.isNotEmpty) ...[
                  const Text(
                    'Semanais',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['semanal']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (recompensasPorTipo['mensal']!.isNotEmpty) ...[
                  const Text(
                    'Mensais',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recompensasPorTipo['mensal']!.map((r) => _buildRecompensaChip(r)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<RecompensaConfig>> _agruparRecompensasPorTipo(List<RecompensaConfig> recompensas) {
    final recompensasPorTipo = {
      'bronze': <RecompensaConfig>[],
      'prata': <RecompensaConfig>[],
      'ouro': <RecompensaConfig>[],
      'platina': <RecompensaConfig>[],
      'diamante': <RecompensaConfig>[],
      'lendario': <RecompensaConfig>[],
      // Manter compatibilidade com valores antigos
      'diaria': <RecompensaConfig>[],
      'semanal': <RecompensaConfig>[],
      'mensal': <RecompensaConfig>[],
    };

    for (final recompensa in recompensas) {
      if (recompensasPorTipo.containsKey(recompensa.tipoRecompensa)) {
        recompensasPorTipo[recompensa.tipoRecompensa]!.add(recompensa);
      }
    }

    return recompensasPorTipo;
  }

  Widget _buildRecompensaChip(RecompensaConfig recompensa) {
    return Chip(
      label: Text(
        recompensa.descricaoRecompensa,
        style: const TextStyle(
          color: Colors.white, // Texto branco para melhor contraste
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getColorForRecompensaTipo(recompensa.tipoRecompensa),
    );
  }

  Color _getColorForRecompensaTipo(String tipo) {
    switch (tipo) {
      case 'bronze': return Colors.brown.shade600; // Cor mais vívida
      case 'prata': return Colors.blueGrey.shade500; // Substituído por uma cor mais vívida
      case 'ouro': return Colors.amber.shade600; // Cor mais vívida
      case 'platina': return Colors.blue.shade500; // Cor mais vívida
      case 'diamante': return Colors.cyan.shade600; // Cor mais vívida
      case 'lendario': return Colors.purple.shade500; // Cor mais vívida
      // Compatibilidade com tipos antigos
      case 'diaria': return Colors.green.shade600; // Cor mais vívida
      case 'semanal': return Colors.orange.shade600; // Cor mais vívida
      case 'mensal': return Colors.deepPurple.shade500; // Cor mais vívida
      default: return Colors.teal.shade500; // Substituído por uma cor mais vívida
    }
  }
}
