import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrofeusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Troféus'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Text('Tela de Troféus - Em desenvolvimento'),
      ),
    );
  }
}
