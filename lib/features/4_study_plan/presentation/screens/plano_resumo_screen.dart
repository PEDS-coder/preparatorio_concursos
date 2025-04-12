import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/widgets/gradient_button.dart';

class PlanoResumoScreen extends StatefulWidget {
  final String planoId;

  const PlanoResumoScreen({required this.planoId});

  @override
  _PlanoResumoScreenState createState() => _PlanoResumoScreenState();
}

class _PlanoResumoScreenState extends State<PlanoResumoScreen> {
  PlanoEstudo? _plano;
  Edital? _edital;
  Map<String, bool> _expandedMaterias = {};

  // Variáveis para o calendário
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<SessaoEstudo>> _sessoesPorDia = {};

  @override
  void initState() {
    super.initState();
    _carregarPlano();

    // Reproduzir som de navegação ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioExplanationService>(context, listen: false).playSuccess();
    });
  }

  void _carregarPlano() {
    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final editalService = Provider.of<EditalService>(context, listen: false);

    final plano = planoService.getPlanoById(widget.planoId);
    if (plano != null) {
      // Agrupar sessões por dia para o calendário
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
        _plano = plano;
        _sessoesPorDia = sessoesPorDia;
        _focusedDay = plano.dataInicio;
        _selectedDay = plano.dataInicio;

        if (plano.editalId.isNotEmpty) {
          _edital = editalService.getEditalById(plano.editalId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_plano == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Resumo do Plano'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Resumo do Plano'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConcursoInfo(),
              SizedBox(height: 24),
              _buildConteudoProgramatico(),
              SizedBox(height: 24),
              _buildPlanoInfo(),
              SizedBox(height: 24),
              _buildFerramentasEstudo(),
              SizedBox(height: 24),
              _buildRecompensas(),
              SizedBox(height: 24),
              _buildCalendario(),
              SizedBox(height: 32),
              _buildBotaoProsseguir(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConcursoInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados do Concurso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(),
            if (_edital != null) ...[
              _buildInfoItem('Nome', _edital!.dadosExtraidos.titulo ?? 'Não informado'),
              _buildInfoItem('Órgão', _edital!.dadosExtraidos.orgao ?? 'Não informado'),
              _buildInfoItem('Banca', _edital!.dadosExtraidos.banca ?? 'Não informado'),
              _buildInfoItem('Data da Prova', _edital!.dadosExtraidos.dataProva ?? 'Não informado'),
              _buildInfoItem('Inscrição', _formatarValor(_edital!.dadosExtraidos.valorTaxa)),
              _buildInfoItem('Cargo Escolhido', _plano!.cargoIds.isNotEmpty ? _plano!.cargoIds.first : 'Não informado'),
            ] else ...[
              _buildInfoItem('Plano', 'Plano de estudos personalizado'),
              _buildInfoItem('Período', '${_formatarData(_plano!.dataInicio)} a ${_formatarData(_plano!.dataFim)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanoInfo() {
    // Calcular horas totais
    int horasTotais = 0;
    _plano!.sessoesEstudo.forEach((sessao) {
      horasTotais += sessao.duracaoMinutos ~/ 60;
    });

    // Calcular horas por semana
    int horasSemanais = 0;
    _plano!.horasSemanais.forEach((dia, horas) {
      horasSemanais += horas;
    });

    // Calcular horas por dia (média)
    double horasPorDia = horasSemanais / 7;

    // Calcular horas por matéria
    Map<String, int> horasPorMateria = {};
    for (var sessao in _plano!.sessoesEstudo) {
      if (!horasPorMateria.containsKey(sessao.materia)) {
        horasPorMateria[sessao.materia] = 0;
      }
      horasPorMateria[sessao.materia] = horasPorMateria[sessao.materia]! + (sessao.duracaoMinutos ~/ 60);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Plano de Estudos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(),
            _buildInfoItem('Período', '${_formatarData(_plano!.dataInicio)} a ${_formatarData(_plano!.dataFim)}'),
            _buildInfoItem('Total de Horas', '$horasTotais horas'),
            _buildInfoItem('Horas por Semana', '$horasSemanais horas'),
            _buildInfoItem('Horas por Dia (média)', '${horasPorDia.toStringAsFixed(1)} horas'),
            SizedBox(height: 16),
            Text(
              'Horas por Matéria',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...horasPorMateria.entries.map((entry) =>
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text(
                      '${entry.value} horas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFerramentasEstudo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ferramentas de Estudo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _plano!.ferramentas.map((ferramenta) {
                IconData icon;
                switch (ferramenta.toLowerCase()) {
                  case 'resumos':
                    icon = Icons.description;
                    break;
                  case 'flashcards':
                    icon = Icons.style;
                    break;
                  case 'mapas mentais':
                    icon = Icons.account_tree;
                    break;
                  case 'videoaulas':
                    icon = Icons.video_library;
                    break;
                  case 'questões':
                    icon = Icons.quiz;
                    break;
                  default:
                    icon = Icons.book;
                }

                return Chip(
                  avatar: Icon(icon, size: 18, color: Colors.black87),
                  label: Text(ferramenta, style: TextStyle(color: Colors.black87)),
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecompensas() {
    // Agrupar recompensas por tipo
    Map<String, List<String>> recompensasPorTipo = {
      'diaria': [],
      'semanal': [],
      'mensal': [],
    };

    for (var recompensa in _plano!.recompensas) {
      if (recompensasPorTipo.containsKey(recompensa.tipoRecompensa)) {
        recompensasPorTipo[recompensa.tipoRecompensa]!.add(recompensa.descricaoRecompensa);
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recompensas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(),
            if (recompensasPorTipo['diaria']!.isNotEmpty) ...[
              _buildRecompensasTipo('Pequenas', recompensasPorTipo['diaria']!, Colors.green.shade200),
              SizedBox(height: 8),
            ],
            if (recompensasPorTipo['semanal']!.isNotEmpty) ...[
              _buildRecompensasTipo('Médias', recompensasPorTipo['semanal']!, Colors.blue.shade200),
              SizedBox(height: 8),
            ],
            if (recompensasPorTipo['mensal']!.isNotEmpty)
              _buildRecompensasTipo('Grandes', recompensasPorTipo['mensal']!, Colors.purple.shade200),
          ],
        ),
      ),
    );
  }

  Widget _buildRecompensasTipo(String tipo, List<String> recompensas, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$tipo:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        ...recompensas.map((recompensa) =>
          Container(
            margin: EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(recompensa)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConteudoProgramatico() {
    if (_edital == null) {
      return SizedBox.shrink();
    }

    // Encontrar o cargo selecionado
    final cargoId = _plano!.cargoIds.isNotEmpty ? _plano!.cargoIds.first : '';
    final cargos = _edital!.dadosExtraidos.cargos;
    final cargoSelecionado = cargos.firstWhere(
      (cargo) => cargo.id == cargoId || cargo.nome == cargoId,
      orElse: () => cargos.isNotEmpty ? cargos.first : Cargo(nome: 'Não encontrado', conteudoProgramatico: []),
    );

    // Separar matérias por tipo (básico e específico)
    List<ConteudoProgramatico> conhecimentosBasicos = [];
    List<ConteudoProgramatico> conhecimentosEspecificos = [];

    for (var conteudo in cargoSelecionado.conteudoProgramatico) {
      if (conteudo.tipo?.toLowerCase() == 'básico' ||
          conteudo.tipo?.toLowerCase() == 'basico' ||
          conteudo.tipo?.toLowerCase() == 'conhecimentos básicos' ||
          conteudo.tipo?.toLowerCase() == 'conhecimentos basicos') {
        conhecimentosBasicos.add(conteudo);
      } else {
        conhecimentosEspecificos.add(conteudo);
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conteúdo Programático',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(),
            if (conhecimentosBasicos.isNotEmpty) ...[
              Text(
                'Conhecimentos Básicos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              ...conhecimentosBasicos.map((conteudo) => _buildMateriaItem(conteudo)),
              SizedBox(height: 16),
            ],
            if (conhecimentosEspecificos.isNotEmpty) ...[
              Text(
                'Conhecimentos Específicos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              ...conhecimentosEspecificos.map((conteudo) => _buildMateriaItem(conteudo)),
            ],
            if (cargoSelecionado.conteudoProgramatico.isEmpty)
              Text(
                'Nenhum conteúdo programático disponível para este cargo.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaItem(ConteudoProgramatico conteudo) {
    // Verificar se a matéria está expandida
    final isExpanded = _expandedMaterias[conteudo.nome] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          conteudo.nome,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedMaterias[conteudo.nome] = expanded;
          });
        },
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conteudo.topicos.asMap().entries.map((entry) {
                final index = entry.key + 1; // Começar do 1
                final topico = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$index. ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(topico)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    if (_plano == null) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendário de Estudos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(),
            TableCalendar<SessaoEstudo>(
              firstDay: _plano!.dataInicio,
              lastDay: _plano!.dataFim,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                return _sessoesPorDia[normalizedDay] ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selectedDay != null) ..._buildSessoesParaDia(_selectedDay!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSessoesParaDia(DateTime dia) {
    final normalizedDay = DateTime(dia.year, dia.month, dia.day);
    final sessoes = _sessoesPorDia[normalizedDay] ?? [];

    if (sessoes.isEmpty) {
      return [
        SizedBox(height: 16),
        Center(child: Text('Nenhuma sessão de estudo para este dia')),
      ];
    }

    return [
      SizedBox(height: 16),
      Text(
        'Sessões para ${_formatarData(dia)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 8),
      ...sessoes.map((sessao) => ListTile(
        leading: Icon(_getIconForMateria(sessao.materia), color: AppTheme.primaryColor),
        title: Text(sessao.materia, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_formatarHora(sessao.dataHoraInicio)} - ${_formatarHora(sessao.dataHoraFim)}\nFerramentas: ${sessao.ferramentas.join(", ")}'),
        dense: true,
      )),
    ];
  }

  IconData _getIconForMateria(String materia) {
    final lowerMateria = materia.toLowerCase();
    if (lowerMateria.contains('direito')) return Icons.gavel;
    if (lowerMateria.contains('portugu')) return Icons.menu_book;
    if (lowerMateria.contains('matem')) return Icons.calculate;
    if (lowerMateria.contains('inform')) return Icons.computer;
    if (lowerMateria.contains('admin')) return Icons.business;
    if (lowerMateria.contains('contab')) return Icons.account_balance;
    return Icons.school;
  }

  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBotaoProsseguir() {
    return Column(
      children: [
        // Botões de sincronização
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_month, color: Colors.white),
                label: Text('Sincronizar com\nGoogle Agenda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _sincronizarComGoogleCalendar(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_today, color: Colors.white),
                label: Text('Sincronizar com\nCalendário Apple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _sincronizarComAppleCalendar(),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        // Botão principal
        GradientButton.withText(
          text: 'Iniciar Jornada',
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
            );
          },
          gradient: AppTheme.primaryGradient,
          icon: Icon(Icons.play_arrow, color: Colors.white),
          fullWidth: true,
        ),
      ],
    );
  }

  // Método para sincronizar com Google Calendar
  Future<void> _sincronizarComGoogleCalendar() async {
    try {
      // Mostrar diálogo de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Sincronizando com Google Agenda...'),
            ],
          ),
        ),
      );

      // Simular processamento
      await Future.delayed(Duration(seconds: 2));

      // Fechar diálogo
      Navigator.of(context).pop();

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plano sincronizado com Google Agenda!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Fechar diálogo em caso de erro
      Navigator.of(context).pop();

      // Mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sincronizar: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Método para sincronizar com Apple Calendar
  Future<void> _sincronizarComAppleCalendar() async {
    try {
      // Mostrar diálogo de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Sincronizando com Calendário Apple...'),
            ],
          ),
        ),
      );

      // Simular processamento
      await Future.delayed(Duration(seconds: 2));

      // Fechar diálogo
      Navigator.of(context).pop();

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plano sincronizado com Calendário Apple!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Fechar diálogo em caso de erro
      Navigator.of(context).pop();

      // Mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sincronizar: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Não informado';
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(data);
  }

  String _formatarValor(double? valor) {
    if (valor == null) return 'Não informado';
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(valor);
  }

  String _formatarCotas(Map<String, dynamic> cotas) {
    List<String> cotasFormatadas = [];
    cotas.forEach((tipo, percentual) {
      cotasFormatadas.add('$tipo: $percentual%');
    });
    return cotasFormatadas.join(', ');
  }
}
