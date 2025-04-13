import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/services/feedback_service.dart';

/// Widget para exibir um botão de feedback
class FeedbackButton extends StatelessWidget {
  const FeedbackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Mostrar o formulário de feedback
        final feedbackService = Provider.of<FeedbackService>(context, listen: false);
        feedbackService.showFeedback(context);
      },
      tooltip: 'Enviar Feedback',
      child: const Icon(Icons.feedback),
    );
  }
}
