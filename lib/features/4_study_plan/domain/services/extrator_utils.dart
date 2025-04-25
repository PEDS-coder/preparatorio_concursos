import '../../../../core/utils/formatador_service.dart';

/// Utilitários do Extrator de Dados
class ExtratorUtils {
  /// Verifica se o valor é válido (não nulo, não vazio e não string 'null')
  static bool isValorValido(dynamic value) {
    if (value == null) return false;
    final str = value.toString();
    return str.isNotEmpty && str != 'null';
  }

  /// Formata valor se for chave de formato de prova
  static String formatarSeFormato(String chave, String valor) {
    return chave.contains('formato')
        ? FormatadorService.formatarFormatoProva(valor)
        : valor;
  }
}
