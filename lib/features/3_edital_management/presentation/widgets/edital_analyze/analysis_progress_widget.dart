import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/matrix_rain_animation.dart';

/// Widget que exibe o progresso da análise do edital
class AnalysisProgressWidget extends StatelessWidget {
  final String progressMessage;
  final List<String> statusMessages;

  const AnalysisProgressWidget({
    Key? key,
    required this.progressMessage,
    required this.statusMessages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: MatrixRainAnimation(
          width: 350,
          height: 300,
          primaryColor: AppTheme.primaryColor,
          secondaryColor: AppTheme.accentColor,
          message: 'Analisando Edital',
          statusMessages: [
            ...statusMessages,
            progressMessage,
          ],
        ),
      ),
    );
  }
}
