import 'package:flutter/material.dart';

/// Widget para o cabeçalho do questionário
class QuestionarioHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String? cargoSelecionado;
  final String? editalTitulo;

  const QuestionarioHeader({
    Key? key,
    required this.titulo,
    required this.subtitulo,
    this.cargoSelecionado,
    this.editalTitulo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        if (editalTitulo != null || cargoSelecionado != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a2240),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2a3050)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (editalTitulo != null) ...[
                  const Text(
                    'Edital',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    editalTitulo!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (editalTitulo != null && cargoSelecionado != null)
                  const SizedBox(height: 12),
                if (cargoSelecionado != null) ...[
                  const Text(
                    'Cargo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cargoSelecionado!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
