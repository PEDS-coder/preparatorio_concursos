import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EditalEditScreen extends StatelessWidget {
  final String editalId;
  
  const EditalEditScreen({required this.editalId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Text('Tela de Editar Edital - ID: $editalId - Em desenvolvimento'),
      ),
    );
  }
}
