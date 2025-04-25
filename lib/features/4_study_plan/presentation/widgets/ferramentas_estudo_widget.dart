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
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plano.ferramentas.map((ferramenta) {
                return Chip(
                  label: Text(ferramenta),
                  backgroundColor: _getColorForFerramenta(ferramenta),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: Colors.white,
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
      return Colors.orange;
    } else if (ferramentaNormalizada.contains('lei seca')) {
      return Colors.red;
    } else if (ferramentaNormalizada.contains('video')) {
      return Colors.teal;
    } else if (ferramentaNormalizada.contains('audio')) {
      return Colors.indigo;
    } else {
      return Colors.grey;
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
