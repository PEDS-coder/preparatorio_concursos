import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EditalEditScreen extends StatelessWidget {
  final String editalId;
  
  const EditalEditScreen({super.key, required this.editalId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Text('Tela de Editar Edital - ID: $editalId - Em desenvolvimento'),
      ),
    );
  }
}
