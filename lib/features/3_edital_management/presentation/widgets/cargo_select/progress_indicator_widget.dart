import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que exibe um indicador de progresso com mensagem
class ProgressIndicatorWidget extends StatelessWidget {
  final double progressValue;
  final String progressMessage;

  const ProgressIndicatorWidget({
    Key? key,
    required this.progressValue,
    required this.progressMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progressValue > 0 ? progressValue : null,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 6,
          ),
          SizedBox(height: 8),
          Text(
            progressMessage.isNotEmpty ? progressMessage : 'Processando...',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
