import '../../../../core/data/models/models.dart';

/// Serviço responsável por gerenciar o conteúdo programático
class ConteudoProgramaticoService {
  /// Agrupa matérias por categoria (comum/específico)
  static Map<String, List<ConteudoProgramatico>> agruparMateriasPorCategoria(
    List<ConteudoProgramatico> materias,
  ) {
    Map<String, List<ConteudoProgramatico>> materiasPorCategoria = {};

    for (var materia in materias) {
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

  /// Encontra uma matéria pelo nome
  static ConteudoProgramatico? encontrarMateriaPorNome(
    List<ConteudoProgramatico> materias,
    String nome,
  ) {
    for (var materia in materias) {
      if (materia.nome == nome) {
        return materia;
      }
    }
    return null;
  }

  /// Encontra um cargo pelo nome
  static Cargo? encontrarCargoPorNome(
    Map<String, List<Cargo>> gruposCargos,
    String nome,
  ) {
    for (var grupo in gruposCargos.values) {
      for (var cargo in grupo) {
        if (cargo.nome == nome) {
          return cargo;
        }
      }
    }
    return null;
  }
}
