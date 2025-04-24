import 'package:flutter/material.dart';

/// Widget para indicador de progresso
class ProgressIndicatorSection extends StatelessWidget {
  final double progress;
  final String message;

  const ProgressIndicatorSection({
    Key? key,
    required this.progress,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFf43f7d),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf43f7d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF13192b),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFf43f7d)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          const Text(
            'Isso pode levar alguns minutos. Por favor, aguarde...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
