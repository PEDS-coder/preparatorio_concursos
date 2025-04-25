
/// Classe base para eventos de calendário
abstract class BaseCalendarEvent {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String location;

  BaseCalendarEvent({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.allDay = false,
    this.location = '',
  });
}

/// Evento para o Add2Calendar (Apple Calendar)
class Add2CalendarEvent extends BaseCalendarEvent {
  Add2CalendarEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    bool allDay = false,
    String location = '',
  }) : super(
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          allDay: allDay,
          location: location,
        );

  /// Converte para o formato do Add2Calendar
  dynamic toAdd2CalendarEvent() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'allDay': allDay,
      'location': location,
    };
  }
}

/// Evento para o Device Calendar
class DeviceCalendarEvent extends BaseCalendarEvent {
  final String calendarId;

  DeviceCalendarEvent({
    required this.calendarId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    bool allDay = false,
    String location = '',
  }) : super(
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          allDay: allDay,
          location: location,
        );
}

/// Evento para o Google Calendar
class GoogleCalendarEvent extends BaseCalendarEvent {
  final String timeZone;
  final List<Map<String, dynamic>> reminders;

  GoogleCalendarEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    this.timeZone = 'America/Sao_Paulo',
    this.reminders = const [],
    bool allDay = false,
    String location = '',
  }) : super(
          title: title,
          description: description,
          startDate: startDate,
          endDate: endDate,
          allDay: allDay,
          location: location,
        );
}
