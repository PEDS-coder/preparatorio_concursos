import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../../core/data/models/models.dart';

class CalendarSection extends StatefulWidget {
  final PlanoEstudo plano;
  final Map<DateTime, List<SessaoEstudo>> sessoesPorDia;
  final Function(DateTime) onDaySelected;

  const CalendarSection({
    Key? key,
    required this.plano,
    required this.sessoesPorDia,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: const Color(0xFF1a2240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendário de Estudos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar<SessaoEstudo>(
              firstDay: widget.plano.dataInicio,
              lastDay: widget.plano.dataFim,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
                holidayTextStyle: TextStyle(color: Colors.red),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFf43f7d),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF22c55e),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFF22c55e),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white70),
                weekendStyle: TextStyle(color: Colors.red),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, false, false);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, true, false);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, false, true);
                },
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22c55e),
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDaySelected(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDay != null) _buildSelectedDayEvents(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, bool isToday, bool isSelected) {
    final events = _getEventsForDay(day);
    final hasEvents = events.isNotEmpty;
    
    Color textColor = Colors.white;
    Color backgroundColor = Colors.transparent;
    
    if (isToday) {
      backgroundColor = const Color(0xFFf43f7d);
      textColor = Colors.white;
    } else if (isSelected) {
      backgroundColor = const Color(0xFF22c55e);
      textColor = Colors.white;
    }
    
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: hasEvents && !isToday && !isSelected
            ? Border.all(color: const Color(0xFF22c55e), width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          day.day.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: hasEvents || isToday || isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<SessaoEstudo> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return widget.sessoesPorDia[normalizedDay] ?? [];
  }

  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Nenhuma sessão de estudo para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Sessões de estudo para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}:',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...events.map((sessao) => _buildSessaoItem(sessao)).toList(),
      ],
    );
  }

  Widget _buildSessaoItem(SessaoEstudo sessao) {
    final horaInicio = DateFormat('HH:mm').format(sessao.dataHoraInicio);
    final horaFim = DateFormat('HH:mm').format(sessao.dataHoraFim);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: const Color(0xFF13192b),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          sessao.materia,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$horaInicio - $horaFim (${sessao.duracao} min)',
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: Icon(
          _getIconForFerramenta(sessao.ferramenta),
          color: const Color(0xFF22c55e),
        ),
      ),
    );
  }

  IconData _getIconForFerramenta(String ferramenta) {
    switch (ferramenta.toLowerCase()) {
      case 'videoaula':
        return Icons.video_library;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'livro':
        return Icons.book;
      case 'questões':
        return Icons.quiz;
      case 'resumos':
        return Icons.summarize;
      case 'simulados':
        return Icons.assignment;
      case 'mapa mental':
        return Icons.account_tree;
      case 'flashcards':
        return Icons.style;
      default:
        return Icons.school;
    }
  }
}
