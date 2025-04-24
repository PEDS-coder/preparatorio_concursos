import '../../../../core/data/models/models.dart';

/// Serviço para validar dados do questionário do plano de estudos
class PlanoDataValidator {
  /// Valida se as datas de início e fim foram selecionadas
  bool validarDatas(DateTime? dataInicio, DateTime? dataFim) {
    return dataInicio != null && dataFim != null;
  }

  /// Valida se há pelo menos um dia com horas de estudo
  bool validarHorasEstudo(Map<String, int> horasPorDia) {
    return horasPorDia.values.any((horas) => horas > 0);
  }

  /// Valida se há pelo menos uma ferramenta selecionada
  bool validarFerramentas(List<String> ferramentas) {
    return ferramentas.isNotEmpty;
  }

  /// Valida se todas as matérias têm proficiência definida
  bool validarProficienciasMaterias(List<String> materias, Map<String, String> proficiencia) {
    for (var materia in materias) {
      if (!proficiencia.containsKey(materia) || proficiencia[materia] == null) {
        return false;
      }
    }
    return true;
  }

  /// Obtém a matéria que não tem proficiência definida
  String? obterMateriaSemProficiencia(List<String> materias, Map<String, String> proficiencia) {
    for (var materia in materias) {
      if (!proficiencia.containsKey(materia) || proficiencia[materia] == null) {
        return materia;
      }
    }
    return null;
  }

  /// Converte nível de proficiência de string para int
  int converterNivelProficiencia(String nivel) {
    switch (nivel) {
      case 'Iniciante':
        return 1;
      case 'Básico':
        return 2;
      case 'Intermediário':
        return 3;
      case 'Avançado':
        return 4;
      case 'Especialista':
        return 5;
      default:
        return 3; // Valor padrão médio
    }
  }

  /// Cria lista de MateriaProficiencia a partir do mapa de proficiência
  List<MateriaProficiencia> criarMateriasProficiencia(Map<String, String> proficiencia) {
    List<MateriaProficiencia> materiasProficiencia = [];

    for (var entry in proficiencia.entries) {
      materiasProficiencia.add(MateriaProficiencia(
        nomeMateria: entry.key,
        nivelProficiencia: converterNivelProficiencia(entry.value),
      ));
    }

    return materiasProficiencia;
  }

  /// Cria recompensas padrão se nenhuma foi selecionada
  List<RecompensaConfig> criarRecompensasPadrao() {
    return [
      // Nível Bronze (Micro-Pausas Rápidas) - 5 a 15 Moedas
      RecompensaConfig(tipoRecompensa: 'bronze', descricaoRecompensa: 'Pausa de 5 min para alongamento (5 Moedas)', selecionada: true),
      RecompensaConfig(tipoRecompensa: 'bronze', descricaoRecompensa: 'Ouvir 1 música favorita (10 Moedas)', selecionada: true),

      // Nível Prata (Pausas Restauradoras) - 25 a 40 Moedas
      RecompensaConfig(tipoRecompensa: 'prata', descricaoRecompensa: 'Jogar 15 min de um jogo casual (25 Moedas)', selecionada: true),

      // Nível Ouro (Pequenos Prazeres) - 60 a 100 Moedas
      RecompensaConfig(tipoRecompensa: 'ouro', descricaoRecompensa: 'Assistir a 1 episódio de série/anime (60 Moedas)', selecionada: true),
    ];
  }

  /// Calcula o total de horas semanais
  int calcularTotalHorasSemanais(Map<String, int> horasPorDia) {
    return horasPorDia.values.fold(0, (sum, horas) => sum + horas);
  }
}
