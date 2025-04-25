import 'package:flutter/material.dart';
import '../../../../../core/data/models/edital.dart';

/// Widget que representa uma matéria expansível
class MateriaExpandableWidget extends StatelessWidget {
  final ConteudoProgramatico materia;
  final bool isExpanded;
  final Function(String) onToggleExpanded;

  const MateriaExpandableWidget({
    Key? key,
    required this.materia,
    required this.isExpanded,
    required this.onToggleExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip clicável para expandir/recolher
          InkWell(
            onTap: () => onToggleExpanded(materia.nome),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    materia.nome,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),

          // Tópicos (exibidos apenas se expandido)
          if (isExpanded && materia.topicos.isNotEmpty && materia.topicos.first != 'Conteúdo básico')
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: materia.topicos.map((topico) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            topico,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
