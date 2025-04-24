import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para seleção de ferramentas de estudo
class FerramentasSelectionSection extends StatelessWidget {
  final List<String> ferramentasSelecionadas;
  final Function(List<String>) onFerramentasChanged;

  const FerramentasSelectionSection({
    Key? key,
    required this.ferramentasSelecionadas,
    required this.onFerramentasChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ferramentas de Estudo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione as ferramentas que você pretende utilizar',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        _buildFerramentasGrid(context),
      ],
    );
  }

  Widget _buildFerramentasGrid(BuildContext context) {
    final ferramentas = [
      {'id': 'Videoaulas', 'nome': 'Videoaulas', 'icone': Icons.play_circle_outline},
      {'id': 'Resumos', 'nome': 'Resumos', 'icone': Icons.description_outlined},
      {'id': 'Questões', 'nome': 'Questões', 'icone': Icons.quiz_outlined},
      {'id': 'Flashcards', 'nome': 'Flashcards', 'icone': Icons.flip_outlined},
      {'id': 'Mapas Mentais', 'nome': 'Mapas Mentais', 'icone': Icons.account_tree_outlined},
      {'id': 'Leitura', 'nome': 'Leitura', 'icone': Icons.menu_book_outlined},
      {'id': 'Podcasts', 'nome': 'Podcasts', 'icone': Icons.headset_outlined},
      {'id': 'Simulados', 'nome': 'Simulados', 'icone': Icons.assignment_outlined},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ferramentas.length,
      itemBuilder: (context, index) {
        final ferramenta = ferramentas[index];
        final selecionada = ferramentasSelecionadas.contains(ferramenta['id']);

        return InkWell(
          onTap: () {
            List<String> novasSelecionadas = List.from(ferramentasSelecionadas);
            if (selecionada) {
              novasSelecionadas.remove(ferramenta['id']);
            } else {
              novasSelecionadas.add(ferramenta['id'] as String);
            }
            onFerramentasChanged(novasSelecionadas);
          },
          child: Container(
            decoration: BoxDecoration(
              color: selecionada ? const Color(0xFFf43f7d).withOpacity(0.2) : const Color(0xFF1a2240),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selecionada ? const Color(0xFFf43f7d) : const Color(0xFF2a3050),
                width: selecionada ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ferramenta['icone'] as IconData,
                  color: selecionada ? const Color(0xFFf43f7d) : Colors.white70,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  ferramenta['nome'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selecionada ? const Color(0xFFf43f7d) : Colors.white70,
                    fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
