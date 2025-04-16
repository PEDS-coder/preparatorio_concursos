import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/audio_explanation_service.dart';
import 'audio_explanation_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();

    // Reproduzir som de navegação ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioExplanationService>(context, listen: false).playNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        children: [

          ListTile(
            leading: Icon(Icons.record_voice_over, color: AppTheme.primaryColor),
            title: Text('Explicações em Áudio'),
            subtitle: Text('Gerenciar narrações explicativas das telas'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioExplanationSettingsScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.api, color: AppTheme.primaryColor),
            title: Text('Configurações da API'),
            subtitle: Text('Gerenciar chaves de API para IA'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/api_config');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.color_lens, color: AppTheme.primaryColor),
            title: Text('Aparência'),
            subtitle: Text('Personalizar tema e cores'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Implementar futuramente
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
          ),
        ],
      ),
    );
  }
}
