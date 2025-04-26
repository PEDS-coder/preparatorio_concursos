import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget para exibir as ferramentas de estudo
class FerramentasEstudoWidget extends StatelessWidget {
  final PlanoEstudo plano;

  const FerramentasEstudoWidget({
    Key? key,
    required this.plano,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (plano.ferramentas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Ferramentas de Estudo',
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
            color: Colors.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plano.ferramentas.map((ferramenta) {
                final color = _getColorForFerramenta(ferramenta);
                return Chip(
                  label: Text(ferramenta),
                  backgroundColor: color.withOpacity(0.2),
                  side: BorderSide(color: color, width: 1),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Text(
                      _getEmojiForFerramenta(ferramenta),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForFerramenta(String ferramenta) {
    final ferramentaNormalizada = ferramenta.toLowerCase();

    if (ferramentaNormalizada.contains('flashcard')) {
      return Colors.blue;
    } else if (ferramentaNormalizada.contains('resumo')) {
      return Colors.green;
    } else if (ferramentaNormalizada.contains('mapa mental')) {
      return Colors.purple;
    } else if (ferramentaNormalizada.contains('questão') || ferramentaNormalizada.contains('questoes')) {
      return Colors.deepOrange; // Alterado de Colors.orange para uma cor mais vívida
    } else if (ferramentaNormalizada.contains('lei seca')) {
      return Colors.red;
    } else if (ferramentaNormalizada.contains('video')) {
      return Colors.teal;
    } else if (ferramentaNormalizada.contains('audio')) {
      return Colors.indigo;
    } else {
      return Colors.deepPurple; // Alterado de Colors.grey para uma cor mais vívida
    }
  }

  String _getEmojiForFerramenta(String ferramenta) {
    final ferramentaNormalizada = ferramenta.toLowerCase();

    if (ferramentaNormalizada.contains('flashcard')) {
      return '📇';
    } else if (ferramentaNormalizada.contains('resumo')) {
      return '📝';
    } else if (ferramentaNormalizada.contains('mapa mental')) {
      return '🧠';
    } else if (ferramentaNormalizada.contains('questão') || ferramentaNormalizada.contains('questoes')) {
      return '❓';
    } else if (ferramentaNormalizada.contains('lei seca')) {
      return '📚';
    } else if (ferramentaNormalizada.contains('video')) {
      return '🎬';
    } else if (ferramentaNormalizada.contains('audio')) {
      return '🎧';
    } else {
      return '🔍';
    }
  }
}
