import '../../../../core/data/models/models.dart';

/// Serviço para obtenção de dados de cotas
class CotasService {
  /// Obtém informações sobre cotas
  static String obterInformacoes(Edital? edital) {
    if (edital == null || edital.dadosExtraidos.cotas == null || edital.dadosExtraidos.cotas!.isEmpty) {
      // Verificar nos dados originais
      if (edital != null && edital.dadosOriginais != null && edital.dadosOriginais!.containsKey('cotas')) {
        final cotas = edital.dadosOriginais!['cotas'];
        if (cotas is List && cotas.isNotEmpty) {
          List<String> cotasInfo = [];
          for (var cota in cotas) {
            if (cota is Map && cota.containsKey('nome')) {
              String cotaStr = cota['nome'].toString();
              if (cota.containsKey('percentual') && cota['percentual'] != null) {
                cotaStr += ' (${cota['percentual']}%)';
              }
              cotasInfo.add(cotaStr);
            }
          }
          if (cotasInfo.isNotEmpty) {
            return cotasInfo.join(', ');
          }
        }
      }

      return 'Não informado';
    }

    List<String> cotasInfo = [];
    for (var cota in edital.dadosExtraidos.cotas!) {
      String cotaStr = cota.nome;
      if (cota.percentual != null) {
        cotaStr += ' (${cota.percentual}%)';
      }
      cotasInfo.add(cotaStr);
    }

    return cotasInfo.join(', ');
  }
}
