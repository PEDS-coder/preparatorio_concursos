import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/models/sessao_estudo.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/utils/date_formatter.dart';

/// Aba de calendário com visualização do plano de estudos
class CalendarioTab extends StatefulWidget {
  const CalendarioTab({Key? key}) : super(key: key);

  @override
  _CalendarioTabState createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<SessaoEstudo>> _sessoesPorDia = {};
  List<SessaoEstudo> _sessoesDodiaSelecionado = [];
  bool _isLoading = true;
  bool _mostrarTodasSessoes = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Carregar dados após a construção do widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  // Método para carregar dados com tratamento de erros
  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Obter o serviço de plano de estudo
      final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Obter o ID do usuário
      final userId = authService.currentUser?.id ?? '';

      // Obter planos do usuário
      final planos = planoService.getPlanosByUserId(userId);

      if (planos.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Ordenar planos por data de início (mais recente primeiro)
      planos.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));

      // Pegar o plano mais recente
      final planoAtivo = planos.first;

      // Organizar sessões por dia
      _sessoesPorDia = {};
      for (final sessao in planoAtivo.sessoesEstudo) {
        final dataChave = DateTime(
          sessao.dataHoraInicio.year,
          sessao.dataHoraInicio.month,
          sessao.dataHoraInicio.day,
        );

        if (!_sessoesPorDia.containsKey(dataChave)) {
          _sessoesPorDia[dataChave] = [];
        }

        _sessoesPorDia[dataChave]!.add(sessao);
      }

      // Carregar sessões do dia selecionado
      _carregarSessoesDodiaSelecionado();

    } catch (e) {
      print('Erro ao carregar dados do calendário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar calendário. Tente novamente.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Carregar sessões do dia selecionado
  void _carregarSessoesDodiaSelecionado() {
    if (_selectedDay == null) {
      _sessoesDodiaSelecionado = [];
      return;
    }

    final dataChave = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    _sessoesDodiaSelecionado = _sessoesPorDia[dataChave] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    'Calendário de Estudos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calendário
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calendário
                          TableCalendar<SessaoEstudo>(
                            firstDay: DateTime.now().subtract(const Duration(days: 365)),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            calendarFormat: _calendarFormat,
                            locale: 'pt_BR',
                            // Definir altura da linha para evitar sobreposição
                            rowHeight: 70.0,
                            daysOfWeekHeight: 40.0,
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Mês',
                              CalendarFormat.week: 'Semana',
                            },
                            eventLoader: (day) {
                              final normalizedDay = DateTime(day.year, day.month, day.day);
                              return _sessoesPorDia[normalizedDay] ?? [];
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _carregarSessoesDodiaSelecionado();
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            calendarStyle: CalendarStyle(
                              markersMaxCount: 3,
                              markerDecoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonTextStyle: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                              titleTextStyle: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              formatButtonDecoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              // Formatar o título do calendário para exibir corretamente o mês e o ano
                              titleTextFormatter: (date, locale) {
                                return DateFormatter.formatMonthYear(date, locale: locale);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sessões do dia selecionado
                  if (_selectedDay != null) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sessões de ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                if (_sessoesDodiaSelecionado.length > 2)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _mostrarTodasSessoes = !_mostrarTodasSessoes;
                                      });
                                    },
                                    child: Text(
                                      _mostrarTodasSessoes ? 'Recolher' : 'Ver mais',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_sessoesDodiaSelecionado.isEmpty)
                              Center(
                                child: Text(
                                  'Nenhuma sessão agendada para este dia',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: _sessoesDodiaSelecionado
                                    .take(_mostrarTodasSessoes ? _sessoesDodiaSelecionado.length : 2)
                                    .map((sessao) => _buildSessaoItem(sessao, isDarkMode))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // Constrói um item de sessão
  Widget _buildSessaoItem(SessaoEstudo sessao, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sessao.materia,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_formatHora(sessao.dataHoraInicio)} - ${_formatHora(sessao.dataHoraFim)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sessao.observacoes ?? 'Sessão de estudo',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/sessao/iniciar');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Iniciar Sessão'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Formata a hora
  String _formatHora(dynamic dateTime) {
    // Usar DateFormatter para lidar com diferentes tipos de entrada
    return DateFormatter.formatTime(dateTime);
  }
}
