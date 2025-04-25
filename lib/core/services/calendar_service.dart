import 'dart:async';
import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart' as add2calendar;
import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/models/calendar_event.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/calendar_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/google_calendar_adapter.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

/// Serviço para gerenciar a integração com calendários
@singleton
class CalendarService implements ICalendarService {
  static const String _tag = 'CalendarService';

  final Logger _logger;
  final IAnalyticsService _analyticsService;

  // Cliente do Google Calendar
  google_calendar.CalendarApi? _googleCalendarApi;

  // Cliente do Device Calendar
  device_calendar.DeviceCalendarPlugin? _deviceCalendarPlugin;

  /// Construtor
  CalendarService(this._logger, this._analyticsService) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _deviceCalendarPlugin = device_calendar.DeviceCalendarPlugin();
    }
  }

  /// Verifica se o Google Calendar está disponível
  @override
  Future<bool> isGoogleCalendarAvailable() async {
    try {
      if (kIsWeb) {
        return true;
      } else if (Platform.isAndroid || Platform.isIOS) {
        return true;
      }
      return false;
    } catch (e) {
      _logger.error('Erro ao verificar disponibilidade do Google Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao verificar disponibilidade do Google Calendar');
      return false;
    }
  }

  /// Verifica se o Apple Calendar está disponível
  @override
  Future<bool> isAppleCalendarAvailable() async {
    try {
      if (Platform.isIOS) {
        return true;
      }
      return false;
    } catch (e) {
      _logger.error('Erro ao verificar disponibilidade do Apple Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao verificar disponibilidade do Apple Calendar');
      return false;
    }
  }

  /// Verifica se o Device Calendar está disponível
  @override
  Future<bool> isDeviceCalendarAvailable() async {
    try {
      if (kIsWeb) {
        return false;
      } else if (Platform.isAndroid || Platform.isIOS) {
        final permissionsGranted = await _deviceCalendarPlugin?.hasPermissions();
        return permissionsGranted?.isSuccess == true && permissionsGranted?.data == true;
      }
      return false;
    } catch (e) {
      _logger.error('Erro ao verificar disponibilidade do Device Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao verificar disponibilidade do Device Calendar');
      return false;
    }
  }

  /// Solicita permissão para acessar o Device Calendar
  @override
  Future<bool> requestDeviceCalendarPermission() async {
    try {
      if (kIsWeb) {
        return false;
      } else if (Platform.isAndroid || Platform.isIOS) {
        final permissionsGranted = await _deviceCalendarPlugin?.requestPermissions();
        return permissionsGranted?.isSuccess == true && permissionsGranted?.data == true;
      }
      return false;
    } catch (e) {
      _logger.error('Erro ao solicitar permissão para o Device Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao solicitar permissão para o Device Calendar');
      return false;
    }
  }

  /// Autentica com o Google Calendar
  @override
  Future<bool> authenticateWithGoogleCalendar() async {
    try {
      // Credenciais do cliente OAuth
      const clientId = '123456789012-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com'; // TODO: Substituir pelo ID do cliente real

      // Escopos necessários
      const scopes = [google_calendar.CalendarApi.calendarScope];

      // Função para abrir a URL de autenticação
      void openUrl(String url) {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }

      // Autenticar com o Google
      final client = await clientViaUserConsent(
        ClientId(clientId, null),
        scopes,
        openUrl,
      );

      // Criar o cliente do Google Calendar
      _googleCalendarApi = google_calendar.CalendarApi(client);

      _logger.info('Autenticado com o Google Calendar', tag: _tag);

      // Registrar evento de autenticação
      _analyticsService.logEvent(
        name: 'google_calendar_authenticated',
        parameters: null,
      );

      return true;
    } catch (e) {
      _logger.error('Erro ao autenticar com o Google Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao autenticar com o Google Calendar');
      return false;
    }
  }

  /// Sincroniza um plano de estudo com o Google Calendar
  @override
  Future<bool> syncWithGoogleCalendar(PlanoEstudo plano) async {
    try {
      // Verificar se o cliente do Google Calendar está disponível
      if (_googleCalendarApi == null) {
        final authenticated = await authenticateWithGoogleCalendar();
        if (!authenticated) {
          return false;
        }
      }

      // Criar um novo calendário para o plano de estudo
      final calendar = google_calendar.Calendar()
        ..summary = 'Plano de Estudo: ${plano.titulo}'
        ..description = 'Calendário de estudos para o plano ${plano.titulo}'
        ..timeZone = 'America/Sao_Paulo';

      final createdCalendar = await _googleCalendarApi!.calendars.insert(calendar);

      // Criar eventos para cada dia de estudo
      for (final materia in plano.materias) {
        for (final dia in materia.diasEstudo) {
          // Obter a data do dia da semana
          final dataEstudo = _getNextWeekday(dia);

          // Criar lembretes
          final reminderList = [
            GoogleCalendarAdapter.createReminder(
              method: 'email',
              minutes: 24 * 60, // 1 dia antes
            ),
            GoogleCalendarAdapter.createReminder(
              method: 'popup',
              minutes: 30, // 30 minutos antes
            ),
          ];

          // Criar evento usando o adaptador
          final event = GoogleCalendarAdapter.createEvent(
            summary: materia.nome,
            description: 'Estudo de ${materia.nome}',
            startDateTime: dataEstudo,
            endDateTime: dataEstudo.add(const Duration(hours: 2)),
            timeZone: 'America/Sao_Paulo',
            useDefaultReminders: false,
            reminderOverrides: reminderList,
          );

          await _googleCalendarApi!.events.insert(event, createdCalendar.id!);
        }
      }

      _logger.info('Plano de estudo sincronizado com o Google Calendar', tag: _tag);

      // Registrar evento de sincronização
      _analyticsService.logEvent(
        name: 'google_calendar_sync',
        parameters: {'plano_id': plano.id},
      );

      return true;
    } catch (e) {
      _logger.error('Erro ao sincronizar com o Google Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao sincronizar com o Google Calendar');
      return false;
    }
  }

  /// Sincroniza um plano de estudo com o Apple Calendar
  @override
  Future<bool> syncWithAppleCalendar(PlanoEstudo plano) async {
    try {
      if (!Platform.isIOS) {
        return false;
      }

      // Criar eventos para cada dia de estudo
      for (final materia in plano.materias) {
        for (final dia in materia.diasEstudo) {
          // Obter a data do dia da semana
          final dataEstudo = _getNextWeekday(dia);

          // Criar evento
          final calendarEvent = Add2CalendarEvent(
            title: materia.nome,
            description: 'Estudo de ${materia.nome}',
            startDate: dataEstudo,
            endDate: dataEstudo.add(const Duration(hours: 2)),
            allDay: false,
            location: '',
          );

          // Converter para o formato do Add2Calendar
          final event = add2calendar.Event(
            title: calendarEvent.title,
            description: calendarEvent.description,
            startDate: calendarEvent.startDate,
            endDate: calendarEvent.endDate,
            allDay: calendarEvent.allDay,
            location: calendarEvent.location,
          );

          // Adicionar ao calendário
          final success = await add2calendar.Add2Calendar.addEvent2Cal(event);

          if (!success) {
            _logger.warning('Falha ao adicionar evento ao Apple Calendar', tag: _tag);
          }
        }
      }

      _logger.info('Plano de estudo sincronizado com o Apple Calendar', tag: _tag);

      // Registrar evento de sincronização
      _analyticsService.logEvent(
        name: 'apple_calendar_sync',
        parameters: {'plano_id': plano.id},
      );

      return true;
    } catch (e) {
      _logger.error('Erro ao sincronizar com o Apple Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao sincronizar com o Apple Calendar');
      return false;
    }
  }

  /// Sincroniza um plano de estudo com o Device Calendar
  @override
  Future<bool> syncWithDeviceCalendar(PlanoEstudo plano) async {
    try {
      if (kIsWeb) {
        return false;
      }

      // Verificar permissões
      final permissionsGranted = await _deviceCalendarPlugin?.hasPermissions();
      if (permissionsGranted?.isSuccess != true || permissionsGranted?.data != true) {
        final requestPermissions = await _deviceCalendarPlugin?.requestPermissions();
        if (requestPermissions?.isSuccess != true || requestPermissions?.data != true) {
          return false;
        }
      }

      // Obter calendários disponíveis
      final calendarsResult = await _deviceCalendarPlugin?.retrieveCalendars();
      if (calendarsResult?.isSuccess != true || calendarsResult?.data == null || calendarsResult!.data!.isEmpty) {
        return false;
      }

      // Usar o primeiro calendário disponível
      final calendarId = calendarsResult.data!.first.id;

      // Criar eventos para cada dia de estudo
      for (final materia in plano.materias) {
        for (final dia in materia.diasEstudo) {
          // Obter a data do dia da semana
          final dataEstudo = _getNextWeekday(dia);

          // Criar evento
          final calendarEvent = DeviceCalendarEvent(
            calendarId: calendarId!,
            title: materia.nome,
            description: 'Estudo de ${materia.nome}',
            startDate: dataEstudo,
            endDate: dataEstudo.add(const Duration(hours: 2)),
          );

          // Converter para o formato do Device Calendar
          final event = device_calendar.Event(
            calendarId,
            title: calendarEvent.title,
            description: calendarEvent.description,
          );

          // Configurar datas de início e fim
          // Convertendo DateTime para TZDateTime
          final startTZ = tz.TZDateTime.from(calendarEvent.startDate, tz.local);
          final endTZ = tz.TZDateTime.from(calendarEvent.endDate, tz.local);
          event.start = startTZ;
          event.end = endTZ;

          // Adicionar ao calendário
          final createEventResult = await _deviceCalendarPlugin?.createOrUpdateEvent(event);

          if (createEventResult?.isSuccess != true) {
            _logger.warning('Falha ao adicionar evento ao Device Calendar', tag: _tag);
          }
        }
      }

      _logger.info('Plano de estudo sincronizado com o Device Calendar', tag: _tag);

      // Registrar evento de sincronização
      _analyticsService.logEvent(
        name: 'device_calendar_sync',
        parameters: {'plano_id': plano.id},
      );

      return true;
    } catch (e) {
      _logger.error('Erro ao sincronizar com o Device Calendar', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao sincronizar com o Device Calendar');
      return false;
    }
  }

  /// Obtém a próxima data para um dia da semana
  DateTime _getNextWeekday(String weekday) {
    final now = DateTime.now();
    final daysOfWeek = {
      'Segunda': DateTime.monday,
      'Terça': DateTime.tuesday,
      'Quarta': DateTime.wednesday,
      'Quinta': DateTime.thursday,
      'Sexta': DateTime.friday,
      'Sábado': DateTime.saturday,
      'Domingo': DateTime.sunday,
    };

    final targetWeekday = daysOfWeek[weekday] ?? DateTime.monday;
    final daysUntilTarget = (targetWeekday - now.weekday) % 7;

    return now.add(Duration(days: daysUntilTarget > 0 ? daysUntilTarget : 7));
  }
}
