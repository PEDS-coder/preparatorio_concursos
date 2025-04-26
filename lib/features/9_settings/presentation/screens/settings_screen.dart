import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/audio_explanation_service.dart';
import 'audio_explanation_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
        title: const Text('Configurações'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        children: [

          ListTile(
            leading: const Icon(Icons.record_voice_over, color: AppTheme.primaryColor),
            title: const Text('Explicações em Áudio'),
            subtitle: const Text('Gerenciar narrações explicativas das telas'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioExplanationSettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.api, color: AppTheme.primaryColor),
            title: const Text('Configurações da API'),
            subtitle: const Text('Gerenciar chaves de API para IA'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/api_config');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history, color: AppTheme.primaryColor),
            title: const Text('Respostas da API'),
            subtitle: const Text('Visualizar respostas salvas da API'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/api_responses');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens, color: AppTheme.primaryColor),
            title: const Text('Aparência'),
            subtitle: const Text('Personalizar tema e cores'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Implementar futuramente
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
          ),
        ],
      ),
    );
  }
}
