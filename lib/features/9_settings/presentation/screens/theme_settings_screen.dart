import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/services/theme_service.dart';
import 'package:preparatorio_concursos/core/theme/app_theme.dart';
import 'package:preparatorio_concursos/core/widgets/animated_card.dart';
import 'package:preparatorio_concursos/core/widgets/animated_button.dart';
import 'package:preparatorio_concursos/core/widgets/feedback_overlay.dart';
import 'package:preparatorio_concursos/core/widgets/gesture_detector_screen.dart';

// Importar AppThemeMode diretamente
import 'package:preparatorio_concursos/core/services/theme_service.dart' show AppThemeMode;

/// Tela de configurações de tema
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return GestureDetectorScreen(
      enableSwipeBack: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações de Tema'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modo de tema
              _buildSectionTitle('Modo de Tema'),
              const SizedBox(height: 8),
              _buildThemeModeSelector(themeService),
              const SizedBox(height: 24),

              // Cores
              _buildSectionTitle('Cores'),
              const SizedBox(height: 8),
              _buildColorSelector(themeService),
              const SizedBox(height: 24),

              // Botão para restaurar cores padrão
              Center(
                child: AnimatedButton(
                  onPressed: () async {
                    await themeService.resetColors();
                    FeedbackOverlay.success(
                      context: context,
                      message: 'Cores restauradas para o padrão',
                    );
                  },
                  child: const Text('Restaurar Cores Padrão'),
                ),
              ),
              const SizedBox(height: 24),

              // Visualização
              _buildSectionTitle('Visualização'),
              const SizedBox(height: 16),
              _buildThemePreview(themeService),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o título da seção
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Constrói o seletor de modo de tema
  Widget _buildThemeModeSelector(ThemeService themeService) {
    return AnimatedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Tema claro
          RadioListTile<AppThemeMode>(
            title: const Text('Tema Claro'),
            value: AppThemeMode.light,
            groupValue: themeService.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await themeService.setThemeMode(ThemeMode.light);
                FeedbackOverlay.success(
                  context: context,
                  message: 'Tema claro ativado',
                );
              }
            },
            secondary: const Icon(Icons.light_mode),
          ),

          // Tema escuro
          RadioListTile<AppThemeMode>(
            title: const Text('Tema Escuro'),
            value: AppThemeMode.dark,
            groupValue: themeService.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await themeService.setThemeMode(ThemeMode.dark);
                FeedbackOverlay.success(
                  context: context,
                  message: 'Tema escuro ativado',
                );
              }
            },
            secondary: const Icon(Icons.dark_mode),
          ),

          // Tema do sistema
          RadioListTile<AppThemeMode>(
            title: const Text('Tema do Sistema'),
            value: AppThemeMode.system,
            groupValue: themeService.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await themeService.setThemeMode(ThemeMode.system);
                FeedbackOverlay.success(
                  context: context,
                  message: 'Tema do sistema ativado',
                );
              }
            },
            secondary: const Icon(Icons.settings_suggest),
          ),
        ],
      ),
    );
  }

  /// Constrói o seletor de cores
  Widget _buildColorSelector(ThemeService themeService) {
    // Lista de cores disponíveis
    final List<Color> primaryColors = [
      AppTheme.primaryColor,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];

    final List<Color> secondaryColors = [
      AppTheme.secondaryColor,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepPurple,
      Colors.lightGreen,
      Colors.deepOrange,
      Colors.lightBlue,
    ];

    return AnimatedCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cor primária
          const Text(
            'Cor Primária',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: primaryColors.length,
              itemBuilder: (context, index) {
                final color = primaryColors[index];
                final isSelected = themeService.primaryColor.value == color.value;

                return GestureDetector(
                  onTap: () async {
                    await themeService.setPrimaryColor(color);
                    FeedbackOverlay.success(
                      context: context,
                      message: 'Cor primária alterada',
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Cor secundária
          const Text(
            'Cor Secundária',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: secondaryColors.length,
              itemBuilder: (context, index) {
                final color = secondaryColors[index];
                final isSelected = themeService.secondaryColor.value == color.value;

                return GestureDetector(
                  onTap: () async {
                    await themeService.setSecondaryColor(color);
                    FeedbackOverlay.success(
                      context: context,
                      message: 'Cor secundária alterada',
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a visualização do tema
  Widget _buildThemePreview(ThemeService themeService) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visualização do Tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Botões
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Botão Primário'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Botão Secundário'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campos de texto
          const TextField(
            decoration: InputDecoration(
              labelText: 'Campo de Texto',
              hintText: 'Digite algo...',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 16),

          // Cards
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card de Exemplo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Este é um exemplo de card com o tema atual.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ícones
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.home),
              Icon(Icons.favorite),
              Icon(Icons.settings),
              Icon(Icons.person),
            ],
          ),
        ],
      ),
    );
  }
}
