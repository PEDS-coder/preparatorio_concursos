import 'package:flutter/material.dart';

/// Classe que define os temas específicos para cada ferramenta de IA
class ToolThemes {
  // Cores das ferramentas
  static const Color flashcardsColor = Color(0xFFFF3D8A); // Rosa
  static const Color resumosColor = Color(0xFF00CFFD); // Ciano
  static const Color questoesColor = Color(0xFF00E096); // Verde
  static const Color mapasMentaisColor = Color(0xFFFFAA00); // Âmbar

  // Gradientes para cada ferramenta
  static final LinearGradient flashcardsGradient = LinearGradient(
    colors: [
      flashcardsColor.withOpacity(0.8),
      Color(0xFF9C1AFF).withOpacity(0.6), // Roxo-elétrico
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient resumosGradient = LinearGradient(
    colors: [
      resumosColor.withOpacity(0.8),
      Color(0xFF2E7BFF).withOpacity(0.6), // Azul-elétrico
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient questoesGradient = LinearGradient(
    colors: [
      questoesColor.withOpacity(0.8),
      Color(0xFF00CFFD).withOpacity(0.6), // Ciano
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final LinearGradient mapasMentaisGradient = LinearGradient(
    colors: [
      mapasMentaisColor.withOpacity(0.8),
      Color(0xFFFF6D00).withOpacity(0.6), // Laranja
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Efeitos de brilho para cada ferramenta
  static BoxShadow flashcardsGlow = BoxShadow(
    color: flashcardsColor.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
  );

  static BoxShadow resumosGlow = BoxShadow(
    color: resumosColor.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
  );

  static BoxShadow questoesGlow = BoxShadow(
    color: questoesColor.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
  );

  static BoxShadow mapasMentaisGlow = BoxShadow(
    color: mapasMentaisColor.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: -5,
  );

  // Método para obter o tema de uma ferramenta específica
  static ToolTheme getThemeForTool(String toolType) {
    switch (toolType) {
      case 'flashcards':
        return ToolTheme(
          color: flashcardsColor,
          gradient: flashcardsGradient,
          glow: flashcardsGlow,
          icon: Icons.flash_on,
        );
      case 'resumos':
        return ToolTheme(
          color: resumosColor,
          gradient: resumosGradient,
          glow: resumosGlow,
          icon: Icons.summarize,
        );
      case 'questoes':
        return ToolTheme(
          color: questoesColor,
          gradient: questoesGradient,
          glow: questoesGlow,
          icon: Icons.quiz,
        );
      case 'mapas_mentais':
        return ToolTheme(
          color: mapasMentaisColor,
          gradient: mapasMentaisGradient,
          glow: mapasMentaisGlow,
          icon: Icons.account_tree,
        );
      default:
        return ToolTheme(
          color: flashcardsColor,
          gradient: flashcardsGradient,
          glow: flashcardsGlow,
          icon: Icons.flash_on,
        );
    }
  }
}

/// Classe que representa o tema de uma ferramenta específica
class ToolTheme {
  final Color color;
  final LinearGradient gradient;
  final BoxShadow glow;
  final IconData icon;

  ToolTheme({
    required this.color,
    required this.gradient,
    required this.glow,
    required this.icon,
  });
}
