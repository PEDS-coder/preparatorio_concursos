import 'package:intl/intl.dart';

/// Classe utilitária para formatação de datas
class DateFormatter {
  /// Formata uma data para o formato DD/MM/YYYY
  static String formatDate(dynamic date) {
    if (date == null) return 'Não informado';

    // Se for uma string, tentar converter para DateTime
    if (date is String) {
      try {
        // Tentar converter a string para DateTime
        final dateTime = DateTime.parse(date);
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      } catch (e) {
        // Se não conseguir converter, retornar a string original
        return date;
      }
    }

    // Se for DateTime, formatar
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    // Se não for nem string nem DateTime, converter para string
    return date.toString();
  }

  /// Formata uma hora para o formato HH:MM
  static String formatTime(dynamic time) {
    if (time == null) return 'Não informado';

    // Se for uma string, tentar converter para DateTime
    if (time is String) {
      try {
        // Tentar converter a string para DateTime
        final dateTime = DateTime.parse(time);
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        // Se não conseguir converter, retornar a string original
        return time;
      }
    }

    // Se for DateTime, formatar
    if (time is DateTime) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    // Se não for nem string nem DateTime, converter para string
    return time.toString();
  }

  /// Formata uma data e hora para o formato DD/MM/YYYY HH:MM
  static String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Não informado';

    // Se for uma string, tentar converter para DateTime
    if (dateTime is String) {
      try {
        // Tentar converter a string para DateTime
        final dt = DateTime.parse(dateTime);
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        // Se não conseguir converter, retornar a string original
        return dateTime;
      }
    }

    // Se for DateTime, formatar
    if (dateTime is DateTime) {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    // Se não for nem string nem DateTime, converter para string
    return dateTime.toString();
  }

  /// Formata um mês e ano para exibição
  static String formatMonthYear(DateTime date, {String? locale}) {
    final formatter = DateFormat('MMMM yyyy', locale ?? 'pt_BR');
    return formatter.format(date).capitalize();
  }
}

/// Extensão para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}