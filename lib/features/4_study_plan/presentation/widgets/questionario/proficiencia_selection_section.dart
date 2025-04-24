import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

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
        _buildMateriasList(),
      ],
    );
  }

  Widget _buildMateriasList() {
    return Column(
      children: materias.map((materia) => _buildMateriaItem(materia)).toList(),
    );
  }

  Widget _buildMateriaItem(String materia) {
    final nivelSelecionado = proficiencia[materia.toLowerCase()] ?? 'Intermediário';
    
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildNivelSelector(materia, nivelSelecionado),
        ],
      ),
    );
  }

  Widget _buildNivelSelector(String materia, String nivelSelecionado) {
    final niveis = ['Iniciante', 'Básico', 'Intermediário', 'Avançado', 'Especialista'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nível de conhecimento:',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              nivelSelecionado,
              style: const TextStyle(
                color: Color(0xFFf43f7d),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final nivel = niveis[index];
            final selecionado = nivel == nivelSelecionado;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  final novasProficiencias = Map<String, String>.from(proficiencia);
                  novasProficiencias[materia.toLowerCase()] = nivel;
                  onProficienciaChanged(novasProficiencias);
                },
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: selecionado ? const Color(0xFFf43f7d) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selecionado ? const Color(0xFFf43f7d) : Colors.white30,
                      width: selecionado ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: selecionado ? Colors.white : Colors.white70,
                        fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Iniciante',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const Text(
              'Especialista',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}
