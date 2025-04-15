import 'package:googleapis/calendar/v3.dart' as google_calendar;

/// Classe adaptadora para o Event do googleapis
class GoogleCalendarAdapter {
  /// Cria um evento do Google Calendar
  static google_calendar.Event createEvent({
    required String summary,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String timeZone = 'America/Sao_Paulo',
    bool useDefaultReminders = false,
    List<google_calendar.EventReminder>? reminderOverrides,
  }) {
    final event = google_calendar.Event();
    
    // Definir propriedades básicas
    event.summary = summary;
    event.description = description;
    
    // Definir data/hora de início
    final startEventDateTime = google_calendar.EventDateTime();
    startEventDateTime.dateTime = startDateTime;
    startEventDateTime.timeZone = timeZone;
    event.start = startEventDateTime;
    
    // Definir data/hora de término
    final endEventDateTime = google_calendar.EventDateTime();
    endEventDateTime.dateTime = endDateTime;
    endEventDateTime.timeZone = timeZone;
    event.end = endEventDateTime;
    
    // Definir lembretes
    if (reminderOverrides != null) {
      final reminders = google_calendar.EventReminders();
      reminders.useDefault = useDefaultReminders;
      reminders.overrides = reminderOverrides;
      event.reminders = reminders;
    }
    
    return event;
  }
  
  /// Cria um lembrete para o evento
  static google_calendar.EventReminder createReminder({
    required String method,
    required int minutes,
  }) {
    final reminder = google_calendar.EventReminder();
    reminder.method = method;
    reminder.minutes = minutes;
    return reminder;
  }
}
