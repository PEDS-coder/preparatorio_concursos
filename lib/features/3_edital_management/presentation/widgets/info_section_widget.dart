import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que representa uma seção de informações
class InfoSectionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoSectionWidget({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
