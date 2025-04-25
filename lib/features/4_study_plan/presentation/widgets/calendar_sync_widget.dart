import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/services/calendar_service.dart';
import 'package:preparatorio_concursos/core/theme/app_theme.dart';
import 'package:preparatorio_concursos/features/4_study_plan/presentation/widgets/animated_button.dart';
import 'package:preparatorio_concursos/core/widgets/feedback_overlay.dart';

/// Widget para sincronização de calendário
class CalendarSyncWidget extends StatefulWidget {
  final PlanoEstudo plano;

  const CalendarSyncWidget({
    Key? key,
    required this.plano,
  }) : super(key: key);

  @override
  _CalendarSyncWidgetState createState() => _CalendarSyncWidgetState();
}

class _CalendarSyncWidgetState extends State<CalendarSyncWidget> {
  bool _isGoogleCalendarAvailable = false;
  bool _isAppleCalendarAvailable = false;
  bool _isDeviceCalendarAvailable = false;
  bool _isSyncingGoogle = false;
  bool _isSyncingApple = false;
  bool _isSyncingDevice = false;

  @override
  void initState() {
    super.initState();
    _checkCalendarAvailability();
  }

  /// Verifica a disponibilidade dos calendários
  Future<void> _checkCalendarAvailability() async {
    final calendarService = Provider.of<CalendarService>(context, listen: false);

    final isGoogleCalendarAvailable = await calendarService.isGoogleCalendarAvailable();
    final isAppleCalendarAvailable = await calendarService.isAppleCalendarAvailable();
    final isDeviceCalendarAvailable = await calendarService.isDeviceCalendarAvailable();

    setState(() {
      _isGoogleCalendarAvailable = isGoogleCalendarAvailable;
      _isAppleCalendarAvailable = isAppleCalendarAvailable;
      _isDeviceCalendarAvailable = isDeviceCalendarAvailable;
    });
  }

  /// Sincroniza com o Google Calendar
  Future<void> _syncWithGoogleCalendar() async {
    setState(() => _isSyncingGoogle = true);

    try {
      final calendarService = Provider.of<CalendarService>(context, listen: false);
      final success = await calendarService.syncWithGoogleCalendar(widget.plano);

      if (success) {
        FeedbackOverlay.success(
          context: context,
          message: 'Plano sincronizado com o Google Calendar',
        );
      } else {
        FeedbackOverlay.error(
          context: context,
          message: 'Falha ao sincronizar com o Google Calendar',
        );
      }
    } catch (e) {
      FeedbackOverlay.error(
        context: context,
        message: 'Erro ao sincronizar com o Google Calendar',
      );
    } finally {
      setState(() => _isSyncingGoogle = false);
    }
  }

  /// Sincroniza com o Apple Calendar
  Future<void> _syncWithAppleCalendar() async {
    setState(() => _isSyncingApple = true);

    try {
      final calendarService = Provider.of<CalendarService>(context, listen: false);
      final success = await calendarService.syncWithAppleCalendar(widget.plano);

      if (success) {
        FeedbackOverlay.success(
          context: context,
          message: 'Plano sincronizado com o Apple Calendar',
        );
      } else {
        FeedbackOverlay.error(
          context: context,
          message: 'Falha ao sincronizar com o Apple Calendar',
        );
      }
    } catch (e) {
      FeedbackOverlay.error(
        context: context,
        message: 'Erro ao sincronizar com o Apple Calendar',
      );
    } finally {
      setState(() => _isSyncingApple = false);
    }
  }

  /// Sincroniza com o Device Calendar
  Future<void> _syncWithDeviceCalendar() async {
    setState(() => _isSyncingDevice = true);

    try {
      final calendarService = Provider.of<CalendarService>(context, listen: false);

      // Verificar permissões
      if (!_isDeviceCalendarAvailable) {
        final permissionGranted = await calendarService.requestDeviceCalendarPermission();
        if (!permissionGranted) {
          FeedbackOverlay.error(
            context: context,
            message: 'Permissão para acessar o calendário negada',
          );
          setState(() => _isSyncingDevice = false);
          return;
        }

        setState(() => _isDeviceCalendarAvailable = true);
      }

      final success = await calendarService.syncWithDeviceCalendar(widget.plano);

      if (success) {
        FeedbackOverlay.success(
          context: context,
          message: 'Plano sincronizado com o calendário do dispositivo',
        );
      } else {
        FeedbackOverlay.error(
          context: context,
          message: 'Falha ao sincronizar com o calendário do dispositivo',
        );
      }
    } catch (e) {
      FeedbackOverlay.error(
        context: context,
        message: 'Erro ao sincronizar com o calendário do dispositivo',
      );
    } finally {
      setState(() => _isSyncingDevice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Sincronizar com:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Google Calendar
            if (_isGoogleCalendarAvailable)
              CalendarSyncButton(
                onPressed: _isSyncingGoogle ? null : () async {
                  await _syncWithGoogleCalendar();
                },
                isLoading: _isSyncingGoogle,
                isEnabled: !_isSyncingGoogle,
                color: Colors.white,
                textColor: Colors.black87,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/google_calendar.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Google Calendar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Apple Calendar
            if (_isAppleCalendarAvailable)
              CalendarSyncButton(
                onPressed: _isSyncingApple ? null : () async {
                  await _syncWithAppleCalendar();
                },
                isLoading: _isSyncingApple,
                isEnabled: !_isSyncingApple,
                color: Colors.white,
                textColor: Colors.black87,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/apple_calendar.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Apple Calendar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Device Calendar
            CalendarSyncButton(
              onPressed: _isSyncingDevice ? null : () async {
                await _syncWithDeviceCalendar();
              },
              isLoading: _isSyncingDevice,
              isEnabled: !_isSyncingDevice,
              color: Colors.white,
              textColor: Colors.black87,
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Calendário do Dispositivo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
