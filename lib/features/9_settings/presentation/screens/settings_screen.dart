import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Text('Tela de Configurações - Em desenvolvimento'),
      ),
    );
  }
}
