/// Classe responsável por validar valores
class ValueValidator {
  /// Verifica se um valor é válido (não nulo, não vazio, não a string "null")
  static bool isValidValue(dynamic value) {
    return value != null &&
        value.toString().trim().isNotEmpty &&
        value.toString().trim().toLowerCase() != 'null';
  }
}
