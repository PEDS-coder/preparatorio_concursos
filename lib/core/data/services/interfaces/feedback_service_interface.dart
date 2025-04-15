import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';

/// Interface para o serviço de feedback
abstract class IFeedbackService {
  /// Inicializa o serviço de feedback
  BetterFeedback initFeedback(Widget child);

  /// Mostra o formulário de feedback
  void showFeedback(BuildContext context);
}
