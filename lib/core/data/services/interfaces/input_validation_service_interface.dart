/// Interface para o serviço de validação de entrada de dados
abstract class IInputValidationService {
  /// Valida um endereço de e-mail
  bool isValidEmail(String email);

  /// Valida uma senha
  bool isValidPassword(String password);

  /// Valida um nome
  bool isValidName(String name);

  /// Valida um número de telefone
  bool isValidPhone(String phone);

  /// Valida um CPF
  bool isValidCPF(String cpf);

  /// Valida uma URL
  bool isValidUrl(String url);

  /// Valida uma data no formato DD/MM/YYYY
  bool isValidDate(String date);

  /// Sanitiza uma string para evitar injeção de código
  String sanitizeInput(String input);

  /// Sanitiza uma string para uso em SQL
  String sanitizeSql(String input);
}
