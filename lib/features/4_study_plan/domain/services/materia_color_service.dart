import 'package:flutter/material.dart';

/// Serviço que fornece cor para matérias
class MateriaColorService {
  /// Retorna uma cor baseada no nome da matéria
  static Color getColorForMateria(String nomeMateria) {
    final nomeNormalizado = nomeMateria.toLowerCase();

    if (nomeNormalizado.contains('português') ||
        nomeNormalizado.contains('lingua portuguesa') ||
        nomeNormalizado.contains('gramática')) {
      return Colors.blue;
    } else if (nomeNormalizado.contains('matemática') ||
               nomeNormalizado.contains('raciocínio lógico') ||
               nomeNormalizado.contains('estatística')) {
      return Colors.red;
    } else if (nomeNormalizado.contains('direito') ||
               nomeNormalizado.contains('constitucional') ||
               nomeNormalizado.contains('administrativo')) {
      return Colors.purple;
    } else if (nomeNormalizado.contains('informática') ||
               nomeNormalizado.contains('tecnologia')) {
      return Colors.teal;
    } else if (nomeNormalizado.contains('história') ||
               nomeNormalizado.contains('geografia')) {
      return Colors.brown;
    } else if (nomeNormalizado.contains('física') ||
               nomeNormalizado.contains('química') ||
               nomeNormalizado.contains('biologia')) {
      return Colors.green;
    } else if (nomeNormalizado.contains('inglês') ||
               nomeNormalizado.contains('espanhol') ||
               nomeNormalizado.contains('língua estrangeira')) {
      return Colors.orange;
    } else if (nomeNormalizado.contains('atualidades') ||
               nomeNormalizado.contains('conhecimentos gerais')) {
      return Colors.cyan;
    } else {
      // Gerar uma cor baseada no hash do nome da matéria
      final int hash = nomeMateria.hashCode;
      final int r = (hash & 0xFF0000) >> 16;
      final int g = (hash & 0x00FF00) >> 8;
      final int b = hash & 0x0000FF;

      return Color.fromRGBO(
        r < 100 ? r + 100 : r,
        g < 100 ? g + 100 : g,
        b < 100 ? b + 100 : b,
        1.0,
      );
    }
  }
}
