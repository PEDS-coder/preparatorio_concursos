import 'package:intl/intl.dart';
import '../validators/value_validator.dart';
import '../../../../../core/utils/plano_data_logger.dart';

/// Classe responsável por formatar datas
class DateFormatter {
  final PlanoDataLogger _logger;
  final String _planoId;

  DateFormatter(this._planoId, this._logger);

  /// Formata data, tratando possíveis erros
  String formatDate(DateTime data) {
    try {
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (e) {
      _logger.logRecuperacao(_planoId, 'erro_formatar_data', {'data': data, 'erro': e.toString()});
      return data.toIso8601String(); // Fallback
    }
  }

  /// Tenta parsear e formatar data, com fallback para string original
  String tryParseAndFormatDate(dynamic value, String debugCampo) {
    if (!ValueValidator.isValidValue(value)) return 'Não informado';
    try {
      // Se já for DateTime
      if (value is DateTime) {
        return formatDate(value);
      }
      // Tentar parsear como String
      final date = DateTime.parse(value.toString());
      return formatDate(date);
    } catch (e) {
      _logger.logRecuperacao(_planoId, 'parse_date_fallback', {'campo': debugCampo, 'valor_original': value.toString()});
      // Se não for uma data válida, mas for uma string não vazia, retornar a string
      return value.toString();
    }
  }

  /// Tenta parsear e formatar período, com fallback
  String tryParseAndFormatDateRange(dynamic startValue, dynamic endValue, String debugCampo) {
    String startDateStr = 'Não informado';
    String endDateStr = 'Não informado';

    if (ValueValidator.isValidValue(startValue)) {
      startDateStr = tryParseAndFormatDate(startValue, '$debugCampo (início)');
    }
    if (ValueValidator.isValidValue(endValue)) {
      endDateStr = tryParseAndFormatDate(endValue, '$debugCampo (fim)');
    }

    if (startDateStr != 'Não informado' && endDateStr != 'Não informado') {
      return '$startDateStr a $endDateStr';
    } else if (startDateStr != 'Não informado') {
      return 'A partir de $startDateStr';
    } else if (endDateStr != 'Não informado') {
      return 'Até $endDateStr';
    } else {
      return 'Não informado';
    }
  }
}
