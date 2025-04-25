import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrofeusScreen extends StatelessWidget {
  const TrofeusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Troféus'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: const Center(
        child: Text('Tela de Troféus - Em desenvolvimento'),
      ),
    );
  }
}
