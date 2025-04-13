import 'package:flutter/material.dart';

/// Interface para o serviço de tema
abstract class IThemeService {
  /// Obtém o modo de tema do Flutter
  ThemeMode get flutterThemeMode;

  /// Obtém a cor primária atual
  Color get primaryColor;

  /// Obtém a cor secundária atual
  Color get secondaryColor;

  /// Obtém o tema claro atual
  ThemeData get lightTheme;

  /// Obtém o tema escuro atual
  ThemeData get darkTheme;

  /// Obtém o tema atual com base no modo de tema
  ThemeData get currentTheme;

  /// Define o modo de tema
  Future<void> setThemeMode(ThemeMode mode);

  /// Define a cor primária
  Future<void> setPrimaryColor(Color color);

  /// Define a cor secundária
  Future<void> setSecondaryColor(Color color);

  /// Restaura as cores padrão
  Future<void> resetColors();

  /// Adiciona um listener para mudanças de tema
  void addListener(VoidCallback listener);

  /// Remove um listener para mudanças de tema
  void removeListener(VoidCallback listener);
}
