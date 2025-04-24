import '../validators/value_validator.dart';
import '../../../../../core/utils/plano_data_logger.dart';

/// Classe responsável por formatar durações
class DurationFormatter {
  final PlanoDataLogger _logger;
  final String _planoId;

  DurationFormatter(this._planoId, this._logger);

  /// Formata a duração da prova
  String formatDuration(dynamic duracao) {
    if (!ValueValidator.isValidValue(duracao)) return 'Não informado';

    String duracaoStr = duracao.toString();

    // Remover textos explicativos comuns
    duracaoStr = duracaoStr.replaceAll('(horas)', '').replaceAll('horas', '').replaceAll('hora', '').trim();

    // Verificar se é apenas um número (horas)
    if (RegExp(r'^\d+$').hasMatch(duracaoStr)) {
      int horas = int.tryParse(duracaoStr) ?? 0;
      return horas == 1 ? '1 hora' : '$horas horas';
    }

    // Verificar se é um número decimal (horas com minutos)
    if (RegExp(r'^\d+[.,]\d+$').hasMatch(duracaoStr)) {
      duracaoStr = duracaoStr.replaceAll(',', '.');
      double horasDecimal = double.tryParse(duracaoStr) ?? 0;
      int horas = horasDecimal.floor();
      int minutos = ((horasDecimal - horas) * 60).round();

      if (horas == 0) {
        return minutos == 1 ? '1 minuto' : '$minutos minutos';
      } else {
        String hStr = horas == 1 ? '1 hora' : '$horas horas';
        String mStr = minutos == 0 ? '' : (minutos == 1 ? ' e 1 minuto' : ' e $minutos minutos');
        return '$hStr$mStr';
      }
    }

    // Se já estiver formatado como texto (tentativa)
    if (duracaoStr.toLowerCase().contains('hora') || duracaoStr.toLowerCase().contains('minuto')) {
      return duracaoStr;
    }

    // Fallback: Retorna a string original se não conseguiu formatar
    _logger.logRecuperacao(_planoId, 'formatar_duracao_fallback', {'valor_original': duracaoStr});
    return duracaoStr;
  }
}
