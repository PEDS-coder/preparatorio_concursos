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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Novos tipos de recompensas
                if (recompensasPorTipo['bronze']!.isNotEmpty) ...[
                  Text(
                    'Bronze (5-15 Moedas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('bronze'),
                    ),
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
                  Text(
                    'Prata (25-40 Moedas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('prata'),
                    ),
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
                  Text(
                    'Ouro (60-100 Moedas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('ouro'),
                    ),
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
                  Text(
                    'Platina (120-200 Moedas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('platina'),
                    ),
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
                  Text(
                    'Diamante (300-500 Moedas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('diamante'),
                    ),
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
                  Text(
                    'Lendário (800+ Moedas)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('lendario'),
                    ),
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
                  Text(
                    'Diárias',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('diaria'),
                    ),
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
                  Text(
                    'Semanais',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('semanal'),
                    ),
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
                  Text(
                    'Mensais',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForRecompensaTipo('mensal'),
                    ),
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
    final color = _getColorForRecompensaTipo(recompensa.tipoRecompensa);
    return Chip(
      label: Text(
        recompensa.descricaoRecompensa,
        style: TextStyle(
          color: color, // Cor sólida para o texto
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color, width: 1),
    );
  }

  Color _getColorForRecompensaTipo(String tipo) {
    switch (tipo) {
      case 'bronze': return Colors.orange.shade700; // Substituído por laranja em vez de marrom
      case 'prata': return Colors.indigo.shade500; // Substituído por índigo em vez de cinza
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
