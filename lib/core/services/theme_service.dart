import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/theme_service_interface.dart';
import 'package:preparatorio_concursos/core/theme/app_theme.dart';
import 'package:preparatorio_concursos/core/theme/custom_theme.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Enum para os modos de tema
///
/// Este enum foi renomeado de ThemeMode para AppThemeMode para evitar conflitos
/// com o ThemeMode do Flutter. Ele representa os diferentes modos de tema
/// disponíveis no aplicativo.
enum AppThemeMode {
  /// Tema claro - Usa cores claras para o fundo e escuras para o texto
  light,

  /// Tema escuro - Usa cores escuras para o fundo e claras para o texto
  dark,

  /// Tema do sistema - Segue as configurações do sistema operacional
  system,
}

/// Serviço para gerenciar o tema do aplicativo
@singleton
class ThemeService extends ChangeNotifier implements IThemeService {
  static const String _tag = 'ThemeService';
  static const String _themePreferenceKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _secondaryColorKey = 'secondary_color';

  final Logger _logger;
  final IAnalyticsService _analyticsService;

  /// Modo de tema atual
  AppThemeMode _themeMode = AppThemeMode.dark;

  /// Cor primária atual
  Color _primaryColor = AppTheme.primaryColor;

  /// Cor secundária atual
  Color _secondaryColor = AppTheme.secondaryColor;

  /// Tema claro atual
  ThemeData _lightTheme = AppTheme.lightTheme;

  /// Tema escuro atual
  ThemeData _darkTheme = AppTheme.darkTheme;

  /// Construtor
  ThemeService(this._logger, this._analyticsService) {
    _loadThemePreferences();
  }

  /// Obtém o modo de tema atual
  AppThemeMode get themeMode => _themeMode;

  /// Obtém o modo de tema do Flutter
  ///
  /// Este método converte o [AppThemeMode] interno para o [ThemeMode] do Flutter,
  /// permitindo que o aplicativo use o enum interno para gerenciar o tema, mas
  /// ainda seja compatível com as APIs do Flutter que esperam um [ThemeMode].
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Obtém a cor primária atual
  Color get primaryColor => _primaryColor;

  /// Obtém a cor secundária atual
  Color get secondaryColor => _secondaryColor;

  /// Obtém o tema claro atual
  ThemeData get lightTheme => _lightTheme;

  /// Obtém o tema escuro atual
  ThemeData get darkTheme => _darkTheme;

  /// Obtém o tema atual com base no modo de tema
  ThemeData get currentTheme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return _lightTheme;
      case AppThemeMode.dark:
        return _darkTheme;
      case AppThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? _darkTheme : _lightTheme;
    }
  }

  /// Define o modo de tema
  ///
  /// Este método recebe um [ThemeMode] do Flutter e o converte para o [AppThemeMode]
  /// interno. Ele também salva a preferência do usuário, registra o evento de mudança
  /// de tema e notifica os ouvintes sobre a mudança.
  ///
  /// @param mode O modo de tema do Flutter a ser definido
  Future<void> setThemeMode(ThemeMode mode) async {
    // Converter o ThemeMode do Flutter para o AppThemeMode
    AppThemeMode appMode;
    switch (mode) {
      case ThemeMode.light:
        appMode = AppThemeMode.light;
        break;
      case ThemeMode.dark:
        appMode = AppThemeMode.dark;
        break;
      case ThemeMode.system:
        appMode = AppThemeMode.system;
        break;
    }

    if (_themeMode == appMode) return;

    _themeMode = appMode;

    // Registrar evento de mudança de tema
    _analyticsService.logEvent(
      name: 'theme_changed',
      parameters: {'theme_mode': appMode.toString()},
    );

    // Salvar preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, appMode.toString());

    _logger.info('Modo de tema alterado para: ${appMode.toString()}', tag: _tag);

    notifyListeners();
  }

  /// Define a cor primária
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor == color) return;

    _primaryColor = color;

    // Atualizar temas
    _updateThemes();

    // Registrar evento de mudança de cor primária
    _analyticsService.logEvent(
      name: 'primary_color_changed',
      parameters: {'color': color.value.toString()},
    );

    // Salvar preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.value);

    _logger.info('Cor primária alterada para: ${color.value.toString()}', tag: _tag);

    notifyListeners();
  }

  /// Define a cor secundária
  Future<void> setSecondaryColor(Color color) async {
    if (_secondaryColor == color) return;

    _secondaryColor = color;

    // Atualizar temas
    _updateThemes();

    // Registrar evento de mudança de cor secundária
    _analyticsService.logEvent(
      name: 'secondary_color_changed',
      parameters: {'color': color.value.toString()},
    );

    // Salvar preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_secondaryColorKey, color.value);

    _logger.info('Cor secundária alterada para: ${color.value.toString()}', tag: _tag);

    notifyListeners();
  }

  /// Carrega as preferências de tema
  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carregar modo de tema
      final themeModeString = prefs.getString(_themePreferenceKey);
      if (themeModeString != null) {
        switch (themeModeString) {
          case 'ThemeMode.light':
          case 'AppThemeMode.light':
            _themeMode = AppThemeMode.light;
            break;
          case 'ThemeMode.dark':
          case 'AppThemeMode.dark':
            _themeMode = AppThemeMode.dark;
            break;
          case 'ThemeMode.system':
          case 'AppThemeMode.system':
            _themeMode = AppThemeMode.system;
            break;
        }
      }

      // Carregar cor primária
      final primaryColorValue = prefs.getInt(_primaryColorKey);
      if (primaryColorValue != null) {
        _primaryColor = Color(primaryColorValue);
      }

      // Carregar cor secundária
      final secondaryColorValue = prefs.getInt(_secondaryColorKey);
      if (secondaryColorValue != null) {
        _secondaryColor = Color(secondaryColorValue);
      }

      // Atualizar temas
      _updateThemes();

      _logger.info('Preferências de tema carregadas', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao carregar preferências de tema', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao carregar preferências de tema');
    }
  }

  /// Atualiza os temas com as cores atuais
  void _updateThemes() {
    _lightTheme = CustomTheme.lightTheme(
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      errorColor: AppTheme.errorColor,
    );

    _darkTheme = CustomTheme.darkTheme(
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      backgroundColor: AppTheme.darkBackground,
      surfaceColor: AppTheme.darkSurface,
      errorColor: AppTheme.errorColor,
    );

    notifyListeners();
  }

  /// Restaura as cores padrão
  Future<void> resetColors() async {
    _primaryColor = AppTheme.primaryColor;
    _secondaryColor = AppTheme.secondaryColor;

    // Atualizar temas
    _updateThemes();

    // Registrar evento de restauração de cores
    _analyticsService.logEvent(
      name: 'colors_reset',
      parameters: null,
    );

    // Salvar preferências
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_primaryColorKey);
    await prefs.remove(_secondaryColorKey);

    _logger.info('Cores restauradas para o padrão', tag: _tag);

    notifyListeners();
  }
}
