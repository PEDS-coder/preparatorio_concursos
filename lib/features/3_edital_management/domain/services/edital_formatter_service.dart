/// Serviço para formatação de dados do edital
class EditalFormatterService {
  /// Formata uma data para exibição
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
