import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/audio_explanation_service.dart';

class AudioExplanationSettingsScreen extends StatefulWidget {
  const AudioExplanationSettingsScreen({super.key});

  @override
  _AudioExplanationSettingsScreenState createState() => _AudioExplanationSettingsScreenState();
}

class _AudioExplanationSettingsScreenState extends State<AudioExplanationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    
    // Reproduzir explicação da tela de configurações de áudio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Não reproduzimos explicação aqui para evitar confusão
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioExplanationService = Provider.of<AudioExplanationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explicações em Áudio'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção
            const Text(
              'Explicações em Áudio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Ativar/desativar explicações
            SwitchListTile(
              title: const Text('Ativar Explicações'),
              subtitle: const Text('Ativa ou desativa as explicações em áudio das telas'),
              value: audioExplanationService.isExplanationsEnabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                audioExplanationService.setExplanationsEnabled(value);
              },
            ),
            
            // Controle de volume
            if (audioExplanationService.isExplanationsEnabled) ...[
              const SizedBox(height: 16),
              const Text('Volume das Explicações', style: TextStyle(fontSize: 16)),
              Slider(
                value: audioExplanationService.volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: AppTheme.primaryColor,
                inactiveColor: Colors.grey.shade300,
                label: '${(audioExplanationService.volume * 100).round()}%',
                onChanged: (value) {
                  audioExplanationService.setVolume(value);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Testar explicações
              const Text(
                'Testar Explicações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildExplanationTestButton(
                    context, 
                    'Login', 
                    Icons.login, 
                    () => audioExplanationService.playLoginExplanation()
                  ),
                  _buildExplanationTestButton(
                    context, 
                    'Config. API', 
                    Icons.api, 
                    () => audioExplanationService.playApiConfigExplanation()
                  ),
                  _buildExplanationTestButton(
                    context, 
                    'Análise Edital', 
                    Icons.description, 
                    () => audioExplanationService.playEditalAnalyzeExplanation()
                  ),
                  _buildExplanationTestButton(
                    context, 
                    'Seleção Cargo', 
                    Icons.work, 
                    () => audioExplanationService.playCargoSelectExplanation()
                  ),
                  _buildExplanationTestButton(
                    context, 
                    'Questionário', 
                    Icons.question_answer, 
                    () => audioExplanationService.playQuestionnaireExplanation()
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Botão para parar todas as explicações
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Parar Explicação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => audioExplanationService.stopAllExplanations(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildExplanationTestButton(
    BuildContext context, 
    String label, 
    IconData icon, 
    VoidCallback onPressed
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
