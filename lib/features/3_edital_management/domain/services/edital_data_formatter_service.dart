import '../../../../../core/data/models/edital.dart';

/// Serviço para formatação de dados do edital
class EditalDataFormatterService {
  /// Formata uma data para exibição
  static String formatDate(DateTime? date) {
    if (date == null) return 'Não informado';
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// Formata o nome do nível para exibição
  static String formatarNivel(String nivel) {
    // Formatar o nome do nível para exibição
    switch (nivel.toLowerCase()) {
      case 'nivel_superior':
        return 'Nível Superior';
      case 'nivel_medio':
        return 'Nível Médio';
      case 'nivel_fundamental':
        return 'Nível Fundamental';
      case 'analista':
        return 'Analista';
      case 'tecnico':
        return 'Técnico';
      default:
        // Capitalizar a primeira letra de cada palavra
        return nivel.split('_').map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
        ).join(' ');
    }
  }

  /// Agrupa matérias por tipo (comum/específico)
  static Map<String, List<ConteudoProgramatico>> agruparMateriasPorCategoria(Cargo cargo) {
    Map<String, List<ConteudoProgramatico>> materiasPorCategoria = {};

    for (var materia in cargo.conteudoProgramatico) {
      // Verificar o tipo da matéria (comum ou específico/especifico)
      String categoria;
      if (materia.tipo == 'comum') {
        categoria = 'Conhecimentos Básicos';
      } else if (materia.tipo == 'específico' || materia.tipo == 'especifico') {
        categoria = 'Conhecimentos Específicos';
      } else {
        // Fallback para tipos desconhecidos
        categoria = 'Outros Conhecimentos';
      }

      if (!materiasPorCategoria.containsKey(categoria)) {
        materiasPorCategoria[categoria] = [];
      }

      materiasPorCategoria[categoria]!.add(materia);
    }

    return materiasPorCategoria;
  }
}
