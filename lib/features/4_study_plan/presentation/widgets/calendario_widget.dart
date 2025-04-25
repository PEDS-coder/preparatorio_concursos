import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/calendario_service.dart';
import '../../domain/services/formatador_service.dart';

/// Widget para exibir o calendário de estudos
class CalendarioWidget extends StatefulWidget {
  final PlanoEstudo plano;
  final Map<DateTime, List<SessaoEstudo>> sessoesPorDia;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarioService calendarioService;
  final Function(DateTime) onDaySelected;
  final Function() onGerarSessoes;
  final Function() onSincronizarGoogleCalendar;
  final Function() onSincronizarAppleCalendar;

  const CalendarioWidget({
    Key? key,
    required this.plano,
    required this.sessoesPorDia,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarioService,
    required this.onDaySelected,
    required this.onGerarSessoes,
    required this.onSincronizarGoogleCalendar,
    required this.onSincronizarAppleCalendar,
  }) : super(key: key);

  @override
  _CalendarioWidgetState createState() => _CalendarioWidgetState();
}

class _CalendarioWidgetState extends State<CalendarioWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendário de Estudos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              // Botão para regenerar sessões
              if (widget.plano.sessoesEstudo.isEmpty)
                ElevatedButton.icon(
                  onPressed: widget.onGerarSessoes,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Gerar Sessões'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: widget.plano.dataInicio,
                  lastDay: widget.plano.dataFim,
                  focusedDay: widget.focusedDay,
                  selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    widget.onDaySelected(selectedDay);
                  },
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mês',
                    CalendarFormat.twoWeeks: '2 Semanas',
                    CalendarFormat.week: 'Semana',
                  },
                  locale: 'pt_BR',
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: true,
                    formatButtonDecoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    formatButtonTextStyle: const TextStyle(color: Colors.white),
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final markers = widget.calendarioService.getMarkerColors(date, widget.sessoesPorDia);
                      
                      if (markers.isEmpty) {
                        return null;
                      }
                      
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: markers.take(3).map((color) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSessoesParaDia(widget.selectedDay ?? widget.focusedDay),
                const SizedBox(height: 24),
                const Text(
                  'Sincronizar com:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: const Text('Google Calendar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onSincronizarGoogleCalendar,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: const Text('Apple Calendar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onSincronizarAppleCalendar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessoesParaDia(DateTime dia) {
    final normalizedDay = DateTime(dia.year, dia.month, dia.day);
    final sessoes = widget.sessoesPorDia[normalizedDay] ?? [];

    if (sessoes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Nenhuma sessão de estudo para ${DateFormat('dd/MM/yyyy').format(dia)}',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    // Ordenar sessões por hora
    sessoes.sort((a, b) => a.dataHoraInicio.compareTo(b.dataHoraInicio));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Sessões para ${DateFormat('dd/MM/yyyy').format(dia)}:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...sessoes.map((sessao) => _buildSessaoItem(sessao)).toList(),
      ],
    );
  }

  Widget _buildSessaoItem(SessaoEstudo sessao) {
    final horaInicio = DateFormat('HH:mm').format(sessao.dataHoraInicio);
    final horaFim = DateFormat('HH:mm').format(
      sessao.dataHoraInicio.add(Duration(minutes: sessao.duracaoMinutos)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            sessao.materia.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          sessao.materia,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$horaInicio - $horaFim (${sessao.duracaoMinutos} min)',
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        trailing: sessao.concluida
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.access_time, color: Colors.orange),
      ),
    );
  }
}
