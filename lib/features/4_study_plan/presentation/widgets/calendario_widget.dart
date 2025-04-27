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
                  // Aumentar a altura das linhas e dos dias da semana para evitar sobreposição
                  rowHeight: 60.0,
                  daysOfWeekHeight: 30.0,
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
                    titleTextFormatter: (date, locale) {
                      // Formatar o mês com a primeira letra maiúscula
                      String month = DateFormat.MMMM(locale).format(date);
                      return '${month[0].toUpperCase()}${month.substring(1)} de ${date.year}';
                    },
                  ),
                  // Estilo dos dias da semana (DOM, SEG, TER, etc.)
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    // Estilo para dias da semana (SEG a SEX)
                    weekdayStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    // Estilo para fins de semana (SÁB e DOM)
                    weekendStyle: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    // Decoração para criar uma faixa branca atrás das iniciais
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0)),
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
                    // Adicionar padding para evitar sobreposição
                    cellMargin: const EdgeInsets.all(4.0),
                  ),
                  calendarBuilders: CalendarBuilders(
                    // Construtor personalizado para os dias da semana
                    dowBuilder: (context, day) {
                      // Obter a inicial do dia da semana em caixa alta
                      final weekdayString = DateFormat.E('pt_BR').format(day);
                      final weekdayUpper = weekdayString.substring(0, 3).toUpperCase();

                      // Definir a cor com base no dia da semana (DOM e SÁB em vermelho)
                      final isWeekend = day.weekday == DateTime.sunday || day.weekday == DateTime.saturday;
                      final textColor = isWeekend ? Colors.red : Colors.black;

                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Text(
                            weekdayUpper,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, date, events) {
                      // Obter sessões para o dia
                      final normalizedDay = DateTime(date.year, date.month, date.day);
                      final sessoes = widget.sessoesPorDia[normalizedDay] ?? [];

                      if (sessoes.isEmpty) {
                        return null;
                      }

                      // Obter cores baseadas nas matérias
                      final List<Color> colors = [];
                      for (var sessao in sessoes) {
                        colors.add(_getColorForMateria(sessao.materia));
                        if (colors.length >= 3) break; // Limitar a 3 marcadores
                      }

                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: colors.map((color) {
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
              color: AppTheme.primaryColor, // Cor primária para destaque
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

    // Obter cor baseada na matéria
    final materiaColor = _getColorForMateria(sessao.materia);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: materiaColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: materiaColor,
          child: Text(
            sessao.materia.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          sessao.materia.toUpperCase(), // Matéria em caixa alta
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: materiaColor.shade800, // Cor mais escura para o texto
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

  // Método para obter cor baseada na matéria
  MaterialColor _getColorForMateria(String materia) {
    // Normalizar a matéria para comparação
    final materiaNormalizada = materia.toLowerCase();

    // Lista de cores disponíveis
    final List<MaterialColor> cores = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
    ];

    // Mapear matérias comuns para cores específicas
    if (materiaNormalizada.contains('direito') && materiaNormalizada.contains('constitucional')) {
      return Colors.blue;
    } else if (materiaNormalizada.contains('direito') && materiaNormalizada.contains('administrativo')) {
      return Colors.red;
    } else if (materiaNormalizada.contains('direito') && materiaNormalizada.contains('penal')) {
      return Colors.deepPurple;
    } else if (materiaNormalizada.contains('direito') && materiaNormalizada.contains('civil')) {
      return Colors.orange;
    } else if (materiaNormalizada.contains('português') || materiaNormalizada.contains('lingua portuguesa')) {
      return Colors.green;
    } else if (materiaNormalizada.contains('raciocínio') || materiaNormalizada.contains('lógico')) {
      return Colors.teal;
    } else if (materiaNormalizada.contains('informática')) {
      return Colors.cyan;
    }

    // Para outras matérias, usar um hash baseado no nome para escolher uma cor
    final int hashCode = materia.hashCode.abs();
    return cores[hashCode % cores.length];
  }
}
