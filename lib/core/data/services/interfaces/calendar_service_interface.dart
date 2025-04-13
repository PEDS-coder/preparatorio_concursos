import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';

/// Interface para o serviço de calendário
abstract class ICalendarService {
  /// Verifica se o Google Calendar está disponível
  Future<bool> isGoogleCalendarAvailable();
  
  /// Verifica se o Apple Calendar está disponível
  Future<bool> isAppleCalendarAvailable();
  
  /// Verifica se o Device Calendar está disponível
  Future<bool> isDeviceCalendarAvailable();
  
  /// Solicita permissão para acessar o Device Calendar
  Future<bool> requestDeviceCalendarPermission();
  
  /// Autentica com o Google Calendar
  Future<bool> authenticateWithGoogleCalendar();
  
  /// Sincroniza um plano de estudo com o Google Calendar
  Future<bool> syncWithGoogleCalendar(PlanoEstudo plano);
  
  /// Sincroniza um plano de estudo com o Apple Calendar
  Future<bool> syncWithAppleCalendar(PlanoEstudo plano);
  
  /// Sincroniza um plano de estudo com o Device Calendar
  Future<bool> syncWithDeviceCalendar(PlanoEstudo plano);
}
