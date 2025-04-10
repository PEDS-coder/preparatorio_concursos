import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/models/models.dart';

class PlanoCalendarioScreen extends StatefulWidget {
  final String planoId;

  const PlanoCalendarioScreen({required this.planoId});

  @override
  _PlanoCalendarioScreenState createState() => _PlanoCalendarioScreenState();
}

class _PlanoCalendarioScreenState extends State<PlanoCalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<SessaoEstudo>> _sessoesPorDia = {};

  @override
  void initState() {
    super.initState();
    _carregarSessoes();
  }

  Future<void> _carregarSessoes() async {
    final planoEstudoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final plano = planoEstudoService.getPlanoById(widget.planoId);

    if (plano != null) {
      // Agrupar sessões por dia
      final Map<DateTime, List<SessaoEstudo>> sessoesPorDia = {};

      for (final sessao in plano.sessoesEstudo) {
        final dataKey = DateTime(
          sessao.dataHoraInicio.year,
          sessao.dataHoraInicio.month,
          sessao.dataHoraInicio.day,
        );

        if (!sessoesPorDia.containsKey(dataKey)) {
          sessoesPorDia[dataKey] = [];
        }

        sessoesPorDia[dataKey]!.add(sessao);
      }

      setState(() {
        _sessoesPorDia = sessoesPorDia;
        _focusedDay = plano.dataInicio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final planoEstudoService = Provider.of<PlanoEstudoService>(context);
    final plano = planoEstudoService.getPlanoById(widget.planoId);

    if (plano == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Calendário de Estudos'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Text('Plano não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendário de Estudos'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _exportarParaGoogleCalendar,
            tooltip: 'Exportar para Google Calendar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano de Estudos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Período: ${_formatarData(plano.dataInicio)} a ${_formatarData(plano.dataFim)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Total de Sessões: ${plano.sessoesEstudo.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Total de Horas: ${_calcularTotalHoras(plano.sessoesEstudo)} horas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Calendário
          TableCalendar(
            firstDay: plano.dataInicio,
            lastDay: plano.dataFim,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            locale: 'pt_BR',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              final dataKey = DateTime(day.year, day.month, day.day);
              return _sessoesPorDia[dataKey] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // Mostrar detalhes das sessões do dia
              _mostrarDetalhesDia(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          // Sessões do dia selecionado
          if (_selectedDay != null) ...[
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.event, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Sessões de ${_formatarData(_selectedDay!)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildSessoesDoDia(_selectedDay!),
          ],

          // Botão de iniciar jornada
          Spacer(),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _iniciarJornada,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Iniciar Jornada',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessoesDoDia(DateTime dia) {
    final dataKey = DateTime(dia.year, dia.month, dia.day);
    final sessoes = _sessoesPorDia[dataKey] ?? [];

    if (sessoes.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Nenhuma sessão de estudo programada para este dia.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: sessoes.length,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final sessao = sessoes[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                _getIconForMateria(sessao.materia),
                color: AppTheme.primaryColor,
              ),
              title: Text(sessao.materia),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatarHora(sessao.dataHoraInicio)} - ${_formatarHora(sessao.dataHoraFim)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Ferramentas: ${sessao.ferramentas.join(", ")}'),
                ],
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () => _mostrarDetalhesSessao(sessao),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalhesDia(DateTime dia) {
    final dataKey = DateTime(dia.year, dia.month, dia.day);
    final sessoes = _sessoesPorDia[dataKey] ?? [];

    if (sessoes.isEmpty) {
      // Não mostrar diálogo se não houver sessões
      return;
    }
  }

  void _mostrarDetalhesSessao(SessaoEstudo sessao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sessao.materia),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalheItem('Horário', '${_formatarHora(sessao.dataHoraInicio)} - ${_formatarHora(sessao.dataHoraFim)}'),
            _buildDetalheItem('Duração', '${sessao.duracaoMinutos ~/ 60} horas'),
            _buildDetalheItem('Ferramentas', sessao.ferramentas.join(", ")),
            SizedBox(height: 16),
            Text(
              'Dicas para esta sessão:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Foque nos pontos principais da matéria e faça resumos dos conceitos mais importantes.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar para a tela de estudo
              // Navigator.pushNamed(context, '/estudo/sessao', arguments: sessao.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Iniciar Sessão'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String valor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarParaGoogleCalendar() async {
    final planoEstudoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final plano = planoEstudoService.getPlanoById(widget.planoId);

    if (plano == null || plano.sessoesEstudo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhuma sessão de estudo para sincronizar'))
      );
      return;
    }

    // Mostrar diálogo de confirmação
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            SizedBox(width: 8),
            Text('Sincronizar com Google Agenda'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja sincronizar ${plano.sessoesEstudo.length} sessões de estudo com o Google Agenda?'),
            SizedBox(height: 16),
            Text(
              'Isso abrirá o Google Agenda no seu navegador para adicionar os eventos.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Sincronizar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Criar eventos no Google Agenda
    try {
      // Selecionar a primeira sessão para sincronizar (como exemplo)
      final sessao = plano.sessoesEstudo.first;

      // Formatar datas para o formato ISO 8601
      final dataInicio = sessao.dataHoraInicio.toIso8601String();
      final dataFim = sessao.dataHoraFim.toIso8601String();

      // Criar URL para adicionar evento ao Google Agenda
      final url = Uri.encodeFull(
        'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent("Sessão de Estudo: ${sessao.materia}")}'
        '&dates=${dataInicio.replaceAll(RegExp(r'[:\-\.]'), '').substring(0, 15)}Z/'
        '${dataFim.replaceAll(RegExp(r'[:\-\.]'), '').substring(0, 15)}Z'
        '&details=${Uri.encodeComponent("Sessão de estudo para ${sessao.materia}. "
            "Ferramentas: ${sessao.ferramentas.join(", ")}"
            "${sessao.observacoes != null ? "\n\nObservações: ${sessao.observacoes}" : ""}")}'
      );

      // Mostrar diálogo com URL para copiar
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Adicionar ao Google Agenda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Copie o link abaixo e abra no seu navegador:'),
              SizedBox(height: 12),
              SelectableText(url, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL copiada para a área de transferência'))
                  );
                },
                child: Text('Copiar URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Mostrar diálogo para sincronizar mais sessões
                if (plano.sessoesEstudo.length > 1) {
                  _mostrarDialogoSincronizarMais(plano);
                }
              },
              child: Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sincronizar: $e'))
      );
    }
  }

  void _mostrarDialogoSincronizarMais(PlanoEstudo plano) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sincronizar mais sessões?'),
        content: Text('Você sincronizou 1 de ${plano.sessoesEstudo.length} sessões. Deseja sincronizar todas as sessões de uma vez?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mais tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sincronizarTodasSessoes(plano);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Sincronizar Todas'),
          ),
        ],
      ),
    );
  }

  Future<void> _sincronizarTodasSessoes(PlanoEstudo plano) async {
    try {
      // Criar URL para adicionar vários eventos ao Google Agenda
      // Nota: O Google Agenda não suporta adicionar vários eventos de uma vez via URL
      // Então, vamos abrir a página principal do Google Agenda
      final url = 'https://calendar.google.com/';

      // Mostrar diálogo com URL para copiar
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Abrir Google Agenda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Copie o link abaixo e abra no seu navegador:'),
              SizedBox(height: 12),
              SelectableText(url, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL copiada para a área de transferência'))
                  );
                },
                child: Text('Copiar URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Mostrar instruções para o usuário
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Adicione manualmente as demais sessões no Google Agenda'),
                    duration: Duration(seconds: 5),
                  )
                );
              },
              child: Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir o Google Agenda: $e'))
      );
    }
  }

  void _iniciarJornada() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  String _formatarData(DateTime data) {
    final formatter = DateFormat('dd/MM/yyyy', 'pt_BR');
    return formatter.format(data);
  }

  String _formatarHora(DateTime data) {
    final formatter = DateFormat('HH:mm', 'pt_BR');
    return formatter.format(data);
  }

  int _calcularTotalHoras(List<SessaoEstudo> sessoes) {
    int totalMinutos = 0;
    for (final sessao in sessoes) {
      totalMinutos += sessao.duracaoMinutos;
    }
    return totalMinutos ~/ 60;
  }

  IconData _getIconForMateria(String materia) {
    // Mapear matérias comuns para ícones
    final Map<String, IconData> icones = {
      'Português': Icons.book,
      'Matemática': Icons.calculate,
      'Direito': Icons.gavel,
      'Informática': Icons.computer,
      'Raciocínio Lógico': Icons.psychology,
      'História': Icons.history,
      'Geografia': Icons.public,
      'Física': Icons.science,
      'Química': Icons.science,
      'Biologia': Icons.biotech,
    };

    // Verificar se a matéria contém alguma das palavras-chave
    for (final entry in icones.entries) {
      if (materia.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Ícone padrão
    return Icons.menu_book;
  }
}
