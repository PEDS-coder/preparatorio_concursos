import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/input_validation_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para validação de entrada de dados
@singleton
class InputValidationService implements IInputValidationService {
  static const String _tag = 'InputValidationService';
  final Logger _logger;

  InputValidationService(this._logger);

  /// Valida um endereço de e-mail
  @override
  bool isValidEmail(String email) {
    if (email.isEmpty) {
      _logger.debug('E-mail vazio', tag: _tag);
      return false;
    }

    // Expressão regular para validar e-mail
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    final isValid = emailRegex.hasMatch(email);
    if (!isValid) {
      _logger.debug('E-mail inválido: $email', tag: _tag);
    }

    return isValid;
  }

  /// Valida uma senha
  ///
  /// A senha deve ter pelo menos 8 caracteres, incluindo pelo menos:
  /// - Uma letra maiúscula
  /// - Uma letra minúscula
  /// - Um número
  /// - Um caractere especial
  @override
  bool isValidPassword(String password) {
    if (password.isEmpty) {
      _logger.debug('Senha vazia', tag: _tag);
      return false;
    }

    if (password.length < 8) {
      _logger.debug('Senha muito curta (mínimo 8 caracteres)', tag: _tag);
      return false;
    }

    // Verificar se contém pelo menos uma letra maiúscula
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _logger.debug('Senha não contém letra maiúscula', tag: _tag);
      return false;
    }

    // Verificar se contém pelo menos uma letra minúscula
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      _logger.debug('Senha não contém letra minúscula', tag: _tag);
      return false;
    }

    // Verificar se contém pelo menos um número
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      _logger.debug('Senha não contém número', tag: _tag);
      return false;
    }

    // Verificar se contém pelo menos um caractere especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _logger.debug('Senha não contém caractere especial', tag: _tag);
      return false;
    }

    return true;
  }

  /// Valida um nome
  @override
  bool isValidName(String name) {
    if (name.isEmpty) {
      _logger.debug('Nome vazio', tag: _tag);
      return false;
    }

    if (name.length < 3) {
      _logger.debug('Nome muito curto (mínimo 3 caracteres)', tag: _tag);
      return false;
    }

    // Verificar se contém apenas letras e espaços
    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    final isValid = nameRegex.hasMatch(name);

    if (!isValid) {
      _logger.debug('Nome contém caracteres inválidos', tag: _tag);
    }

    return isValid;
  }

  /// Valida um número de telefone
  @override
  bool isValidPhone(String phone) {
    if (phone.isEmpty) {
      _logger.debug('Telefone vazio', tag: _tag);
      return false;
    }

    // Remover caracteres não numéricos
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar se tem entre 10 e 11 dígitos (com ou sem DDD)
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      _logger.debug('Telefone com número incorreto de dígitos', tag: _tag);
      return false;
    }

    return true;
  }

  /// Valida um CPF
  @override
  bool isValidCPF(String cpf) {
    if (cpf.isEmpty) {
      _logger.debug('CPF vazio', tag: _tag);
      return false;
    }

    // Remover caracteres não numéricos
    final cleanCPF = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verificar se tem 11 dígitos
    if (cleanCPF.length != 11) {
      _logger.debug('CPF não tem 11 dígitos', tag: _tag);
      return false;
    }

    // Verificar se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCPF)) {
      _logger.debug('CPF com dígitos repetidos', tag: _tag);
      return false;
    }

    // Calcular o primeiro dígito verificador
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cleanCPF[i]) * (10 - i);
    }
    int resto = soma % 11;
    int dv1 = resto < 2 ? 0 : 11 - resto;

    // Verificar o primeiro dígito verificador
    if (int.parse(cleanCPF[9]) != dv1) {
      _logger.debug('Primeiro dígito verificador do CPF inválido', tag: _tag);
      return false;
    }

    // Calcular o segundo dígito verificador
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cleanCPF[i]) * (11 - i);
    }
    resto = soma % 11;
    int dv2 = resto < 2 ? 0 : 11 - resto;

    // Verificar o segundo dígito verificador
    if (int.parse(cleanCPF[10]) != dv2) {
      _logger.debug('Segundo dígito verificador do CPF inválido', tag: _tag);
      return false;
    }

    return true;
  }

  /// Valida uma URL
  @override
  bool isValidUrl(String url) {
    if (url.isEmpty) {
      _logger.debug('URL vazia', tag: _tag);
      return false;
    }

    // Expressão regular para validar URL
    final urlRegex = RegExp(
      r'^(http|https)://[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+(:[0-9]+)?(/[a-zA-Z0-9\-._~:/?#[\]@!$&\()*+,;=]*)?$',
    );

    final isValid = urlRegex.hasMatch(url);
    if (!isValid) {
      _logger.debug('URL inválida: $url', tag: _tag);
    }

    return isValid;
  }

  /// Valida uma data no formato DD/MM/YYYY
  @override
  bool isValidDate(String date) {
    if (date.isEmpty) {
      _logger.debug('Data vazia', tag: _tag);
      return false;
    }

    // Expressão regular para validar data no formato DD/MM/YYYY
    final dateRegex = RegExp(
      r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$',
    );

    if (!dateRegex.hasMatch(date)) {
      _logger.debug('Formato de data inválido: $date', tag: _tag);
      return false;
    }

    // Verificar se a data é válida
    final parts = date.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    if (month == 2) {
      // Verificar se é ano bissexto
      final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      if (day > (isLeapYear ? 29 : 28)) {
        _logger.debug('Dia inválido para fevereiro: $day', tag: _tag);
        return false;
      }
    } else if ([4, 6, 9, 11].contains(month) && day > 30) {
      _logger.debug('Dia inválido para o mês $month: $day', tag: _tag);
      return false;
    }

    return true;
  }

  /// Sanitiza uma string para evitar injeção de código
  @override
  String sanitizeInput(String input) {
    if (input.isEmpty) {
      return input;
    }

    // Remover tags HTML
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Escapar caracteres especiais
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');

    return sanitized;
  }

  /// Sanitiza uma string para uso em SQL
  @override
  String sanitizeSql(String input) {
    if (input.isEmpty) {
      return input;
    }

    // Escapar aspas simples
    String sanitized = input.replaceAll("'", "''");

    // Remover comentários SQL
    sanitized = sanitized.replaceAll(RegExp(r'--.*'), '');
    sanitized = sanitized.replaceAll(RegExp(r'/\*.*\*/'), '');

    return sanitized;
  }
}
