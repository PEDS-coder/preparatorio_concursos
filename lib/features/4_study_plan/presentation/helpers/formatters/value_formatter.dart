import 'package:intl/intl.dart';
import '../validators/value_validator.dart';
import '../../../../../core/utils/plano_data_logger.dart';

/// Classe responsável por formatar valores monetários e listas
class ValueFormatter {
  final PlanoDataLogger _logger;
  final String _planoId;

  ValueFormatter(this._planoId, this._logger);

  /// Formata valor monetário, tratando possíveis erros
  String formatCurrency(dynamic valor) {
    if (!ValueValidator.isValidValue(valor)) return 'Não informado';

    num? valorNumerico;
    if (valor is num) {
      valorNumerico = valor;
    } else if (valor is String) {
      try {
        // Remover R$, pontos de milhar e substituir vírgula por ponto
        String valorLimpo = valor.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
        if (valorLimpo.isEmpty) return 'Não informado';
        valorNumerico = double.parse(valorLimpo);
      } catch (e) {
        _logger.logRecuperacao(_planoId, 'erro_formatar_valor_parse', {'valor': valor, 'erro': e.toString()});
        // Se não conseguir parsear, retorna o valor original se for uma string válida
        return valor.toString();
      }
    }

    if (valorNumerico != null) {
      try {
        return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorNumerico);
      } catch(e) {
        _logger.logRecuperacao(_planoId, 'erro_formatar_valor_numberformat', {'valor': valorNumerico, 'erro': e.toString()});
        return valorNumerico.toString(); // Fallback
      }
    }

    // Se não for numérico nem string parseável, retorna como string
    return valor.toString();
  }

  /// Formata uma lista para exibição, tratando diferentes tipos de elementos
  String formatList(dynamic valor, {String separador = ', '}) {
    if (!ValueValidator.isValidValue(valor)) return 'Não informado';

    if (valor is List) {
      if (valor.isEmpty) return 'Não informado';
      // Mapeia cada item para string, tratando mapas internos
      return valor.map((item) {
        if (item is Map) {
          // Tenta extrair um 'nome' ou 'descricao', senão usa toString
          return item['nome']?.toString() ?? item['descricao']?.toString() ?? item.toString();
        }
        return item.toString();
      }).join(separador);
    }

    // Se não for lista, retorna como string
    return valor.toString();
  }
}
