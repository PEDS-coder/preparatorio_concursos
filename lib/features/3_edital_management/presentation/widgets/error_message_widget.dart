import 'package:flutter/material.dart';

/// Widget que representa uma mensagem de erro
class ErrorMessageWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onTryAgain;
  final VoidCallback onConfigureAPI;

  const ErrorMessageWidget({
    Key? key,
    required this.errorMessage,
    required this.onTryAgain,
    required this.onConfigureAPI,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erro ao analisar o edital',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTryAgain,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tentar Novamente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onConfigureAPI,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Configurar API'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
