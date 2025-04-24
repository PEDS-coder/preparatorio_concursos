import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que exibe o botão para iniciar a análise do edital
class AnalyzeButtonWidget extends StatelessWidget {
  final bool hasSelectedFiles;
  final bool isLoading;
  final VoidCallback onAnalyzePressed;

  const AnalyzeButtonWidget({
    Key? key,
    required this.hasSelectedFiles,
    required this.isLoading,
    required this.onAnalyzePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 24),
      child: ElevatedButton.icon(
        onPressed: hasSelectedFiles && !isLoading ? onAnalyzePressed : null,
        icon: Icon(Icons.auto_awesome),
        label: Text(
          'Analisar com IA',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
      ),
    );
  }
}
