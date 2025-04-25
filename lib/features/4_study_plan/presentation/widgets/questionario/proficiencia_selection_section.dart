import 'package:flutter/material.dart';

/// Widget para seleção de proficiência por matéria
class ProficienciaSelectionSection extends StatelessWidget {
  final List<String> materias;
  final Map<String, String> proficiencia;
  final Function(Map<String, String>) onProficienciaChanged;

  const ProficienciaSelectionSection({
    Key? key,
    required this.materias,
    required this.proficiencia,
    required this.onProficienciaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proficiência nas Matérias',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Indique seu nível de conhecimento em cada matéria',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        _buildLegenda(),
        const SizedBox(height: 16),
        _buildMateriasList(context),
      ],
    );
  }

  Widget _buildLegenda() {
    final niveis = [
      {'nivel': 'Iniciante', 'cor': Colors.red[400]!},
      {'nivel': 'Básico', 'cor': Colors.orange[400]!},
      {'nivel': 'Intermediário', 'cor': Colors.yellow[400]!},
      {'nivel': 'Avançado', 'cor': Colors.green[400]!},
      {'nivel': 'Especialista', 'cor': Colors.blue[400]!},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2a3050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legenda de Proficiência:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: niveis.map((nivel) => _buildLegendaItem(
              nivel['nivel'] as String,
              nivel['cor'] as Color,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(String nivel, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          nivel,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMateriasList(BuildContext context) {
    // Organizar as matérias em uma única coluna
    return Column(
      children: materias.map((materia) => _buildMateriaItem(materia)).toList(),
    );
  }

  Widget _buildMateriaItem(String materia) {
    final nivelSelecionado = proficiencia[materia.toLowerCase()] ?? 'Intermediário';
    final niveis = ['Iniciante', 'Básico', 'Intermediário', 'Avançado', 'Especialista'];
    final cores = [
      Colors.red[400]!,
      Colors.orange[400]!,
      Colors.yellow[400]!,
      Colors.green[400]!,
      Colors.blue[400]!,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2a3050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            materia.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final nivel = niveis[index];
              final selecionado = nivel == nivelSelecionado;
              final cor = cores[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    final novasProficiencias = Map<String, String>.from(proficiencia);
                    novasProficiencias[materia.toLowerCase()] = nivel;
                    onProficienciaChanged(novasProficiencias);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selecionado ? cor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cor,
                        width: 3,
                      ),
                    ),
                    child: selecionado
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
