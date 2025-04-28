import '../../../../core/data/models/models.dart';

class PlanoMetadadosService {
  static String getTaxaInscricao(PlanoEstudo plano) {
    final val = plano.metadados['valorInscricao'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }

  static List<String> getCriteriosAprovacao(PlanoEstudo plano) {
    final val = plano.metadados['criteriosAprovacao'];
    if (val is List) {
      return val.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (val is String && val.trim().isNotEmpty && val.toLowerCase() != 'null') {
      return [val];
    }
    return [];
  }

  static List<String> getCriteriosDesempate(PlanoEstudo plano) {
    final val = plano.metadados['criteriosDesempate'];
    if (val is List) {
      return val.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (val is String && val.trim().isNotEmpty && val.toLowerCase() != 'null') {
      return [val];
    }
    return [];
  }

  static List<Map<String, dynamic>> getCotas(PlanoEstudo plano) {
    final val = plano.metadados['cotas'];
    if (val is List) {
      return val.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static String getDataProva(PlanoEstudo plano) {
    final val = plano.metadados['dataProva'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }

  static String getLocalProvas(PlanoEstudo plano) {
    final val = plano.metadados['localProva'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }

  static String getFormatoProva(PlanoEstudo plano) {
    final val = plano.metadados['formatoProva'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }

  static String getTotalQuestoes(PlanoEstudo plano) {
    final val = plano.metadados['totalQuestoes'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }

  static String getDuracaoProva(PlanoEstudo plano) {
    final val = plano.metadados['duracaoProva'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }

  static String getTemaProvaSubjetiva(PlanoEstudo plano) {
    final val = plano.metadados['temaProvaSubjetiva'];
    if (val == null || val.toString().trim().isEmpty || val.toString().toLowerCase() == 'null') {
      return 'Não informado';
    }
    return val.toString();
  }
}
