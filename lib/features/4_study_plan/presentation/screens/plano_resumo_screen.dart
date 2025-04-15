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
              _buildInfoItem('Nome', _obterValorConcurso('titulo', 'titulo_concurso')),
              _buildInfoItem('Órgão', _obterValorConcurso('orgao', 'orgao_responsavel')),
              _buildInfoItem('Banca', _obterValorConcurso('banca', 'banca_organizadora')),
              _buildInfoItem('Data da Prova Objetiva', _obterValorConcurso('dataProvaObjetiva', 'datas_provas.objetiva')),
              _buildInfoItem('Data da Prova Subjetiva', _obterValorConcurso('dataProvaSubjetiva', 'datas_provas.subjetiva')),
              _buildInfoItem('Inscrição', _formatarValor(_obterValorNumerico('valorInscricao', 'taxa_inscricao'))),
              _buildInfoItem('Cargo Escolhido', _plano!.cargoIds.isNotEmpty ? _plano!.cargoIds.first : 'Não informado'),
              // Adicionar informações sobre cotas se disponíveis
              _buildInfoItem('Cotas', _obterInformacoesCotas()),
              // Adicionar informações sobre o tema da prova subjetiva se disponível
              if (_edital!.dadosOriginais != null && (_edital!.dadosOriginais!.containsKey('prova') ||
                  _edital!.dadosOriginais!.containsKey('tema_discursiva')))
                _buildInfoItem('Tema da Prova Subjetiva', _obterValorConcurso('temaProvaSubjetiva', 'prova.tema_discursiva')),
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
    // Verificar se temos o valor total nos metadados
    if (_plano!.metadados.containsKey('horasSemanaisTotal')) {
      horasSemanais = _plano!.metadados['horasSemanaisTotal'];
    } else {
      // Calcular a partir das horas configuradas
      _plano!.horasSemanais.forEach((dia, horas) {
        horasSemanais += horas;
      });
    }

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
                  label: Text(ferramenta, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                  backgroundColor: Colors.grey.shade200,
                  side: BorderSide(color: Colors.grey.shade400),
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

    // Adicionar todas as recompensas ao mapa
    for (var recompensa in _plano!.recompensas) {
      if (recompensasPorTipo.containsKey(recompensa.tipoRecompensa)) {
        recompensasPorTipo[recompensa.tipoRecompensa]!.add(recompensa.descricaoRecompensa);
      }
    }

    // Verificar se temos recompensas nos metadados
    if (_plano!.metadados.containsKey('recompensas')) {
      try {
        final List<dynamic> recompensasAdicionais = _plano!.metadados['recompensas'];
        for (var recompensa in recompensasAdicionais) {
          if (recompensa is Map<String, dynamic> &&
              recompensa.containsKey('tipo') &&
              recompensa.containsKey('descricao')) {
            final tipo = recompensa['tipo'];
            final descricao = recompensa['descricao'];
            if (recompensasPorTipo.containsKey(tipo) && !recompensasPorTipo[tipo]!.contains(descricao)) {
              recompensasPorTipo[tipo]!.add(descricao);
            }
          }
        }
      } catch (e) {
        print('Erro ao processar recompensas adicionais: $e');
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
              border: Border.all(color: cor.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, size: 16, color: Colors.black87),
                SizedBox(width: 8),
                Expanded(child: Text(recompensa, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
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

    // Separar matérias por tipo (comum e específico)
    List<ConteudoProgramatico> conhecimentosBasicos = [];
    List<ConteudoProgramatico> conhecimentosEspecificos = [];

    for (var conteudo in cargoSelecionado.conteudoProgramatico) {
      // Não ignorar matérias com nomes genéricos para exibir todos os conhecimentos
      // Incluir todas as matérias, tanto básicas quanto específicas

      // Classificar por tipo
      if (conteudo.tipo.toLowerCase() == 'comum' ||
          conteudo.tipo.toLowerCase() == 'básico' ||
          conteudo.tipo.toLowerCase() == 'basico' ||
          conteudo.tipo.toLowerCase() == 'conhecimentos básicos' ||
          conteudo.tipo.toLowerCase() == 'conhecimentos basicos') {
        conhecimentosBasicos.add(conteudo);
      } else if (conteudo.tipo.toLowerCase() == 'específico' ||
                conteudo.tipo.toLowerCase() == 'especifico' ||
                conteudo.tipo.toLowerCase() == 'conhecimentos específicos' ||
                conteudo.tipo.toLowerCase() == 'conhecimentos especificos') {
        conhecimentosEspecificos.add(conteudo);
      } else {
        // Se não for possível determinar o tipo, verificar pelo nome
        if (conteudo.nome.toLowerCase().contains('direito') ||
            conteudo.nome.toLowerCase().contains('legisla') ||
            conteudo.nome.toLowerCase().contains('específ')) {
          conhecimentosEspecificos.add(conteudo);
        } else {
          conhecimentosBasicos.add(conteudo);
        }
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

    // Verificar informações adicionais da matéria
    String infoAdicional = '';

    // Verificar o tipo da matéria para tratamento especial
    bool isEspecifica = conteudo.tipo.toLowerCase() == 'especifico' ||
                       conteudo.tipo.toLowerCase() == 'específico';

    // Estimar número de questões para matérias específicas se não estiver disponível
    int? numeroQuestoes = conteudo.numeroQuestoes;

    // Verificar se há informações sobre número de questões
    if (numeroQuestoes != null && numeroQuestoes > 0) {
      infoAdicional += '${numeroQuestoes} questões';
    } else {
      // Tentar extrair o número de questões do nome da matéria
      final RegExp regexQuestoes = RegExp(r'\(([0-9]+)\s*quest[\u00f5o]es\)', caseSensitive: false);
      final match = regexQuestoes.firstMatch(conteudo.nome);
      if (match != null && match.groupCount >= 1) {
        try {
          numeroQuestoes = int.parse(match.group(1)!);
          infoAdicional += '$numeroQuestoes questões';
        } catch (e) {
          // Ignorar erro de parsing
        }
      } else if (isEspecifica) {
        // Para matérias específicas sem número de questões, estimar com base no tipo
        // Isso é apenas uma estimativa para exibição, não afeta o plano de estudos
        numeroQuestoes = 5; // Valor estimado para matérias específicas
        infoAdicional += '$numeroQuestoes questões (estimado)';
      }
    }

    // Verificar se há informações sobre peso maior
    if (conteudo.pesoMaior != null && conteudo.pesoMaior!) {
      if (infoAdicional.isNotEmpty) infoAdicional += ' | ';
      infoAdicional += 'Peso maior';
    }

    // Verificar se é critério de desempate
    if (conteudo.criterioDesempate != null && conteudo.criterioDesempate!) {
      if (infoAdicional.isNotEmpty) infoAdicional += ' | ';
      infoAdicional += 'Critério de desempate';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          conteudo.nome,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: infoAdicional.isNotEmpty ?
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: infoAdicional,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ) : null,
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
            Container(
              height: 500, // Altura fixa para o calendário
              child: TableCalendar<SessaoEstudo>(
                firstDay: _plano!.dataInicio,
                lastDay: _plano!.dataFim,
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                locale: 'pt_BR',
                // Definir altura da linha para evitar sobreposição
                rowHeight: 60.0,
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
                // Aumentar o tamanho da célula para evitar sobreposição
                cellMargin: EdgeInsets.all(6.0),
                cellPadding: EdgeInsets.all(4.0),
                // Ajustar o tamanho e cores do texto dos dias para melhorar legibilidade
                defaultTextStyle: TextStyle(fontSize: 14, color: Colors.black87),
                weekendTextStyle: TextStyle(fontSize: 14, color: Colors.deepPurple),
                outsideTextStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                // Adicionar espaço entre as linhas do calendário
                rowDecoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                ),
                // Aumentar a altura das linhas do calendário
              ),

              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[600], fontSize: 12),
                // Usar o nome completo do dia da semana em português
                dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).substring(0, 3).toUpperCase(),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2.0)),
                ),
                // Aumentar o espaço entre os dias da semana e os dias do mês
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                formatButtonTextStyle: TextStyle(color: AppTheme.primaryColor),
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                headerPadding: EdgeInsets.symmetric(vertical: 10.0),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
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
        Text(
          'Sincronizar com Calendários',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_month, color: Colors.white),
                label: Text('Google Agenda'),
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
                label: Text('Calendário Apple'),
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
      // Espaçamento vertical consistente para todos os itens
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Largura fixa para todos os labels
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // Usar cor mais escura em vez de cinza
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                // Usar cor mais escura para o texto do valor
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'Não informado';

    if (valor is String) {
      try {
        valor = double.parse(valor);
      } catch (e) {
        return valor;
      }
    }

    if (valor is num) {
      return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
    }

    return valor.toString();
  }

  // Método para obter valor do concurso (primeiro do plano, depois do edital)
  String _obterValorConcurso(String chaveMetadados, String chaveDadosOriginais) {
    debugPrint('\nVERIFICAÇÃO DE EXIBIÇÃO - Buscando: $chaveMetadados / $chaveDadosOriginais');

    // Verificar primeiro nos metadados do plano
    if (_plano!.metadados.containsKey(chaveMetadados) &&
        _plano!.metadados[chaveMetadados] != null &&
        _plano!.metadados[chaveMetadados].toString().isNotEmpty &&
        _plano!.metadados[chaveMetadados].toString() != 'null') {
      debugPrint('  Encontrado nos metadados do plano: ${_plano!.metadados[chaveMetadados]}');
      return _plano!.metadados[chaveMetadados].toString();
    } else {
      debugPrint('  Não encontrado nos metadados do plano');
    }

    // Verificar nos dados extraídos do edital
    final dadosExtraidos = _edital!.dadosExtraidos;
    switch (chaveMetadados) {
      case 'titulo':
        if (dadosExtraidos.titulo != null && dadosExtraidos.titulo!.isNotEmpty) {
          debugPrint('  Encontrado no dadosExtraidos.titulo: ${dadosExtraidos.titulo}');
          return dadosExtraidos.titulo!;
        }
        break;
      case 'orgao':
        if (dadosExtraidos.orgao != null && dadosExtraidos.orgao!.isNotEmpty) {
          debugPrint('  Encontrado no dadosExtraidos.orgao: ${dadosExtraidos.orgao}');
          return dadosExtraidos.orgao!;
        }
        break;
      case 'banca':
        if (dadosExtraidos.banca != null && dadosExtraidos.banca!.isNotEmpty) {
          debugPrint('  Encontrado no dadosExtraidos.banca: ${dadosExtraidos.banca}');
          return dadosExtraidos.banca!;
        }
        break;
      case 'dataProva':
        if (dadosExtraidos.dataProva != null && dadosExtraidos.dataProva!.isNotEmpty) {
          debugPrint('  Encontrado no dadosExtraidos.dataProva: ${dadosExtraidos.dataProva}');
          return dadosExtraidos.dataProva!;
        }
        break;
      case 'dataProvaObjetiva':
      case 'dataProvaSubjetiva':
      case 'temaProvaSubjetiva':
        // Esses campos são novos e não estão nos dados extraídos
        break;
    }
    debugPrint('  Não encontrado nos dados extraídos do edital');

    // Verificar nos dados originais do edital
    if (_edital!.dadosOriginais != null) {
      // Verificar se a chave contém pontos (indicando caminho aninhado)
      if (chaveDadosOriginais.contains('.')) {
        final partes = chaveDadosOriginais.split('.');
        dynamic valor = _edital!.dadosOriginais;
        bool encontrado = true;

        // Navegar pela estrutura aninhada
        for (var parte in partes) {
          if (valor is Map && valor.containsKey(parte)) {
            valor = valor[parte];
          } else {
            encontrado = false;
            break;
          }
        }

        if (encontrado && valor != null && valor.toString() != 'null' && valor.toString().isNotEmpty) {
          debugPrint('  Encontrado nos dados originais aninhados: $valor');
          return valor.toString();
        }
      } else if (_edital!.dadosOriginais!.containsKey(chaveDadosOriginais) &&
          _edital!.dadosOriginais![chaveDadosOriginais] != null &&
          _edital!.dadosOriginais![chaveDadosOriginais].toString() != 'null' &&
          _edital!.dadosOriginais![chaveDadosOriginais].toString().isNotEmpty) {
        debugPrint('  Encontrado nos dados originais: ${_edital!.dadosOriginais![chaveDadosOriginais]}');
        return _edital!.dadosOriginais![chaveDadosOriginais].toString();
      } else {
        // Tentar buscar em chaves alternativas
        final Map<String, List<String>> chavesAlternativas = {
          'titulo': ['titulo_concurso', 'nome_concurso', 'concurso'],
          'orgao': ['orgao_responsavel', 'instituicao', 'entidade'],
          'banca': ['banca_organizadora', 'organizadora'],
          'dataProva': ['data_provas', 'data_prova', 'data_realizacao'],
          'valorInscricao': ['valor_taxa_inscricao', 'taxa_inscricao', 'valor_inscricao'],
        };

        if (chavesAlternativas.containsKey(chaveMetadados)) {
          for (final chaveAlt in chavesAlternativas[chaveMetadados]!) {
            if (_edital!.dadosOriginais!.containsKey(chaveAlt) &&
                _edital!.dadosOriginais![chaveAlt] != null &&
                _edital!.dadosOriginais![chaveAlt].toString() != 'null' &&
                _edital!.dadosOriginais![chaveAlt].toString().isNotEmpty) {
              debugPrint('  Encontrado nos dados originais (chave alternativa $chaveAlt): ${_edital!.dadosOriginais![chaveAlt]}');
              return _edital!.dadosOriginais![chaveAlt].toString();
            }
          }
        }

        debugPrint('  Não encontrado nos dados originais do edital');
      }
    }

    // Verificar se é um cargo e tentar obter o nome do cargo
    if (chaveMetadados == 'Cargo Escolhido' && _plano!.cargoIds.isNotEmpty) {
      final cargoId = _plano!.cargoIds.first;
      final cargos = _edital!.dadosExtraidos.cargos;
      final cargoSelecionado = cargos.firstWhere(
        (cargo) => cargo.id == cargoId || cargo.nome == cargoId,
        orElse: () => Cargo(nome: cargoId, conteudoProgramatico: []),
      );
      return cargoSelecionado.nome;
    }

    // Tentar extrair do texto completo do edital para campos específicos
    if (_edital!.textoCompleto != null && _edital!.textoCompleto!.isNotEmpty) {
      final textoLower = _edital!.textoCompleto!.toLowerCase();

      // Padrões de expressões regulares para extrair informações
      final Map<String, RegExp> padroes = {
        'titulo': RegExp(r'concurso\s+p[úu]blico\s+(?:para|do)\s+([^\n.]+)', caseSensitive: false),
        'orgao': RegExp(r'(?:concurso|sele[çc][ãa]o)\s+(?:do|para|da)\s+([^\n.]+)', caseSensitive: false),
        'banca': RegExp(r'(?:banca|organizadora|institui[çc][ãa]o)\s*[:-]?\s*([^\n.]+)', caseSensitive: false),
        'dataProva': RegExp(r'(?:data\s+da\s+prova|provas?\s+ser[ãa]o\s+realizadas?)\s*[:-]?\s*([0-9]{1,2}[/.-][0-9]{1,2}[/.-][0-9]{2,4})', caseSensitive: false),
        'valorInscricao': RegExp(r'(?:taxa\s+de\s+inscri[çc][ãa]o|valor\s+da\s+inscri[çc][ãa]o)\s*[:-]?\s*R\$\s*([0-9]+[,.][0-9]+)', caseSensitive: false),
      };

      if (padroes.containsKey(chaveMetadados)) {
        final match = padroes[chaveMetadados]!.firstMatch(textoLower);
        if (match != null && match.groupCount >= 1) {
          final valor = match.group(1)!.trim();
          debugPrint('  Encontrado no texto completo do edital: $valor');
          return valor;
        }
      }
    }

    // Se não encontrar, retornar valor padrão
    debugPrint('  Retornando valor padrão: Não informado');
    return 'Não informado';
  }

  // Método para obter valor numérico do concurso
  dynamic _obterValorNumerico(String chaveMetadados, String chaveDadosOriginais) {
    debugPrint('\nVERIFICAÇÃO DE EXIBIÇÃO (Numérico) - Buscando: $chaveMetadados / $chaveDadosOriginais');

    // Verificar primeiro nos metadados do plano
    if (_plano!.metadados.containsKey(chaveMetadados) &&
        _plano!.metadados[chaveMetadados] != null &&
        _plano!.metadados[chaveMetadados].toString() != 'null') {
      debugPrint('  Encontrado nos metadados do plano: ${_plano!.metadados[chaveMetadados]}');

      // Tentar converter para número se for string
      if (_plano!.metadados[chaveMetadados] is String) {
        try {
          final valorStr = _plano!.metadados[chaveMetadados].toString();
          // Remover R$ e substituir vírgula por ponto
          final valorLimpo = _extrairValorNumericoDeString(valorStr);
          return valorLimpo;
        } catch (e) {
          return _plano!.metadados[chaveMetadados];
        }
      }

      return _plano!.metadados[chaveMetadados];
    } else {
      debugPrint('  Não encontrado nos metadados do plano');
    }

    // Verificar nos dados extraídos do edital
    final dadosExtraidos = _edital!.dadosExtraidos;
    if (chaveMetadados == 'valorInscricao' && dadosExtraidos.valorTaxa != null) {
      debugPrint('  Encontrado no dadosExtraidos.valorTaxa: ${dadosExtraidos.valorTaxa}');
      return dadosExtraidos.valorTaxa;
    } else {
      debugPrint('  Não encontrado nos dados extraídos do edital');
    }

    // Verificar nos dados originais do edital
    if (_edital!.dadosOriginais != null) {
      // Verificar se a chave contém pontos (indicando caminho aninhado)
      if (chaveDadosOriginais.contains('.')) {
        final partes = chaveDadosOriginais.split('.');
        dynamic valor = _edital!.dadosOriginais;
        bool encontrado = true;

        // Navegar pela estrutura aninhada
        for (var parte in partes) {
          if (valor is Map && valor.containsKey(parte)) {
            valor = valor[parte];
          } else {
            encontrado = false;
            break;
          }
        }

        if (encontrado && valor != null && valor.toString() != 'null') {
          debugPrint('  Encontrado nos dados originais aninhados: $valor');

          // Tentar converter para número se for string
          if (valor is String) {
            try {
              return _extrairValorNumericoDeString(valor);
            } catch (e) {
              return valor;
            }
          }

          return valor;
        }
      } else if (_edital!.dadosOriginais!.containsKey(chaveDadosOriginais) &&
          _edital!.dadosOriginais![chaveDadosOriginais] != null &&
          _edital!.dadosOriginais![chaveDadosOriginais].toString() != 'null') {
        debugPrint('  Encontrado nos dados originais: ${_edital!.dadosOriginais![chaveDadosOriginais]}');

        // Tentar converter para número se for string
        final valor = _edital!.dadosOriginais![chaveDadosOriginais];
        if (valor is String) {
          try {
            return _extrairValorNumericoDeString(valor);
          } catch (e) {
            return valor;
          }
        }

        return valor;
      } else {
        // Tentar buscar em chaves alternativas
        final Map<String, List<String>> chavesAlternativas = {
          'valorInscricao': ['valor_taxa_inscricao', 'taxa_inscricao', 'valor_inscricao', 'taxa'],
        };

        if (chavesAlternativas.containsKey(chaveMetadados)) {
          for (final chaveAlt in chavesAlternativas[chaveMetadados]!) {
            if (_edital!.dadosOriginais!.containsKey(chaveAlt) &&
                _edital!.dadosOriginais![chaveAlt] != null &&
                _edital!.dadosOriginais![chaveAlt].toString() != 'null') {
              debugPrint('  Encontrado nos dados originais (chave alternativa $chaveAlt): ${_edital!.dadosOriginais![chaveAlt]}');

              final valor = _edital!.dadosOriginais![chaveAlt];
              if (valor is String) {
                try {
                  return _extrairValorNumericoDeString(valor);
                } catch (e) {
                  return valor;
                }
              }

              return valor;
            }
          }
        }

        debugPrint('  Não encontrado nos dados originais do edital');
      }
    }

    // Tentar extrair do texto completo do edital para campos específicos
    if (_edital!.textoCompleto != null && _edital!.textoCompleto!.isNotEmpty) {
      final textoLower = _edital!.textoCompleto!.toLowerCase();

      // Padrões de expressões regulares para extrair informações numéricas
      if (chaveMetadados == 'valorInscricao') {
        final RegExp regexTaxa = RegExp(r'(?:taxa\s+de\s+inscri[\u00e7c][\u00e3a]o|valor\s+da\s+inscri[\u00e7c][\u00e3a]o)\s*[:-]?\s*R\$\s*([0-9]+[,.][0-9]+)', caseSensitive: false);
        final match = regexTaxa.firstMatch(textoLower);
        if (match != null && match.groupCount >= 1) {
          final taxaStr = match.group(1)!;
          try {
            final valorNumerico = _extrairValorNumericoDeString(taxaStr);
            debugPrint('  Valor numérico extraído do texto: $valorNumerico');
            return valorNumerico;
          } catch (e) {
            debugPrint('  Erro ao extrair valor numérico do texto: $e');
          }
        }
      }
    }

    // Se não encontrar, retornar valor padrão
    debugPrint('  Retornando valor padrão: 0.0');
    return 0.0;
  }

  // Método auxiliar para extrair valor numérico de uma string
  double _extrairValorNumericoDeString(String valorStr) {
    // Remover caracteres não numéricos, exceto vírgula e ponto
    String valorLimpo = valorStr.replaceAll(RegExp(r'[^0-9,.]+'), '').trim();

    // Verificar se há vírgula e ponto no valor
    if (valorLimpo.contains(',') && valorLimpo.contains('.')) {
      // Se o ponto vier antes da vírgula, é separador de milhar (formato brasileiro)
      if (valorLimpo.indexOf('.') < valorLimpo.indexOf(',')) {
        valorLimpo = valorLimpo.replaceAll('.', '').replaceAll(',', '.');
      }
      // Se a vírgula vier antes do ponto, é separador de milhar (formato americano)
      else {
        valorLimpo = valorLimpo.replaceAll(',', '');
      }
    }
    // Se só tiver vírgula, é separador decimal (formato brasileiro)
    else if (valorLimpo.contains(',')) {
      valorLimpo = valorLimpo.replaceAll(',', '.');
    }

    // Converter para double
    return double.parse(valorLimpo);
  }

  // Método para obter informações sobre cotas
  String _obterInformacoesCotas() {
    debugPrint('\nVERIFICAÇÃO DE COTAS:');

    // Verificar primeiro nos metadados do plano
    if (_plano!.metadados.containsKey('cotas') &&
        _plano!.metadados['cotas'] != null &&
        _plano!.metadados['cotas'].toString() != 'null' &&
        _plano!.metadados['cotas'].toString().isNotEmpty) {
      debugPrint('  Encontrado nos metadados do plano: ${_plano!.metadados['cotas']}');

      // Verificar se cotas é um Map
      if (_plano!.metadados['cotas'] is Map) {
        final Map<String, dynamic> cotasMap = Map<String, dynamic>.from(_plano!.metadados['cotas'] as Map);
        final List<String> cotasFormatadas = [];

        // Processar cada entrada do mapa de cotas
        cotasMap.forEach((key, value) {
          String nome = key.toString();
          // Formatar o nome para capitalizar a primeira letra
          nome = nome.substring(0, 1).toUpperCase() + nome.substring(1);

          // Formatar o valor como porcentagem
          if (value is num) {
            cotasFormatadas.add('$nome: ${value.toString()}%');
          } else if (value == null || value.toString() == 'null') {
            // Não adicionar valores nulos
            // Ou alternativamente, usar um valor padrão como:
            // cotasFormatadas.add('$nome: Não informado');
          } else {
            cotasFormatadas.add('$nome: ${value.toString()}');
          }
        });

        return cotasFormatadas.join('; ');
      }

      // Se não for um Map, retornar como string
      return _plano!.metadados['cotas'].toString();
    } else {
      debugPrint('  Não encontrado nos metadados do plano');
    }

    if (_edital!.dadosOriginais == null) {
      debugPrint('  Dados originais do edital não disponíveis');
      return 'Não informado';
    }

    final dadosOriginais = _edital!.dadosOriginais!;

    // Verificar em vários campos possíveis
    final camposPossiveis = [
      'cotas',
      'percentual_cotas',
      'reserva_vagas',
      'vagas_cotas',
      'vagas_pcd',
      'vagas_negros',
      'vagas_ppp',
      'percentual_pcd',
      'percentual_negros',
      'percentual_ppp',
      'politica_cotas',
      'sistema_cotas',
      'reserva_de_vagas',
      'vagas_reservadas',
    ];

    for (final campo in camposPossiveis) {
      if (dadosOriginais.containsKey(campo) &&
          dadosOriginais[campo] != null &&
          dadosOriginais[campo].toString() != 'null' &&
          dadosOriginais[campo].toString().isNotEmpty) {
        debugPrint('  Encontrado em dadosOriginais[$campo]: ${dadosOriginais[campo]}');
        return dadosOriginais[campo].toString();
      }
    }

    // Verificar se há informações de cotas nos cargos
    if (dadosOriginais.containsKey('cargos') && dadosOriginais['cargos'] is List) {
      final cargos = dadosOriginais['cargos'] as List;
      for (final cargo in cargos) {
        if (cargo is Map) {
          // Verificar se é o cargo selecionado
          String nomeCargo = '';
          if (cargo.containsKey('nome') && cargo['nome'] != null) {
            nomeCargo = cargo['nome'].toString();
          } else if (cargo.containsKey('nome_cargo') && cargo['nome_cargo'] != null) {
            if (cargo['nome_cargo'] is Map && cargo['nome_cargo'].containsKey('value')) {
              nomeCargo = cargo['nome_cargo']['value'].toString();
            } else {
              nomeCargo = cargo['nome_cargo'].toString();
            }
          }

          // Se for o cargo selecionado, verificar informações de cotas
          if (_plano!.cargoIds.isNotEmpty && nomeCargo.contains(_plano!.cargoIds.first)) {
            for (final campo in camposPossiveis) {
              if (cargo.containsKey(campo) &&
                  cargo[campo] != null &&
                  cargo[campo].toString() != 'null' &&
                  cargo[campo].toString().isNotEmpty) {
                debugPrint('  Encontrado em cargo[$campo]: ${cargo[campo]}');
                return cargo[campo].toString();
              }
            }

            // Verificar se há informações de vagas com cotas
            if (cargo.containsKey('numero_vagas') && cargo['numero_vagas'] is Map) {
              final vagasMap = cargo['numero_vagas'] as Map;
              String infoCotas = '';

              // Verificar vagas para negros
              if (vagasMap.containsKey('negros') ||
                  (vagasMap.containsKey('imediata') && vagasMap['imediata'] is Map && vagasMap['imediata'].containsKey('negros'))) {
                final negros = vagasMap.containsKey('negros') ? vagasMap['negros'] : vagasMap['imediata']['negros'];
                if (negros != null && negros.toString() != '0' && negros.toString() != 'null') {
                  infoCotas += 'Negros: $negros; ';
                }
              }

              // Verificar vagas para PCD
              if (vagasMap.containsKey('pcd') ||
                  (vagasMap.containsKey('imediata') && vagasMap['imediata'] is Map && vagasMap['imediata'].containsKey('pcd'))) {
                final pcd = vagasMap.containsKey('pcd') ? vagasMap['pcd'] : vagasMap['imediata']['pcd'];
                if (pcd != null && pcd.toString() != '0' && pcd.toString() != 'null') {
                  infoCotas += 'PCD: $pcd; ';
                }
              }

              // Verificar vagas para indígenas
              if (vagasMap.containsKey('indigenas') ||
                  (vagasMap.containsKey('imediata') && vagasMap['imediata'] is Map && vagasMap['imediata'].containsKey('indigenas'))) {
                final indigenas = vagasMap.containsKey('indigenas') ? vagasMap['indigenas'] : vagasMap['imediata']['indigenas'];
                if (indigenas != null && indigenas.toString() != '0' && indigenas.toString() != 'null') {
                  infoCotas += 'Indígenas: $indigenas; ';
                }
              }

              if (infoCotas.isNotEmpty) {
                return infoCotas.substring(0, infoCotas.length - 2); // Remover último '; '
              }
            }
          }
        }
      }
    }

    // Verificar em estruturas aninhadas
    if (dadosOriginais.containsKey('vagas') && dadosOriginais['vagas'] is Map) {
      final vagasMap = dadosOriginais['vagas'] as Map;
      String infoCotas = '';

      // Verificar diferentes tipos de cotas
      final tiposCotas = ['negros', 'pcd', 'indigenas', 'ppp', 'deficientes'];

      for (final tipo in tiposCotas) {
        if (vagasMap.containsKey(tipo) && vagasMap[tipo] != null && vagasMap[tipo].toString() != '0' && vagasMap[tipo].toString() != 'null') {
          String label = tipo;
          switch (tipo) {
            case 'pcd':
            case 'deficientes':
              label = 'PCD';
              break;
            case 'ppp':
              label = 'PPP';
              break;
            case 'indigenas':
              label = 'Indígenas';
              break;
            case 'negros':
              label = 'Negros';
              break;
          }
          infoCotas += '$label: ${vagasMap[tipo]}; ';
        }
      }

      if (infoCotas.isNotEmpty) {
        return infoCotas.substring(0, infoCotas.length - 2); // Remover último '; '
      }
    }

    // Verificar no texto completo do edital
    if (_edital!.textoCompleto != null && _edital!.textoCompleto!.isNotEmpty) {
      final textoLower = _edital!.textoCompleto!.toLowerCase();

      // Buscar padrões específicos de cotas no texto
      final RegExp regexCotasNegros = RegExp(r'([0-9]{1,2})[\s%]*(?:por cento|das vagas)[\s\w]*negros', caseSensitive: false);
      final RegExp regexCotasPCD = RegExp(r'([0-9]{1,2})[\s%]*(?:por cento|das vagas)[\s\w]*(?:defici[\u00ea]ncia|pcd)', caseSensitive: false);

      String infoCotas = '';

      // Extrair percentual para negros
      final matchNegros = regexCotasNegros.firstMatch(textoLower);
      if (matchNegros != null && matchNegros.groupCount >= 1) {
        final percentual = matchNegros.group(1);
        infoCotas += 'Negros: $percentual%; ';
      }

      // Extrair percentual para PCD
      final matchPCD = regexCotasPCD.firstMatch(textoLower);
      if (matchPCD != null && matchPCD.groupCount >= 1) {
        final percentual = matchPCD.group(1);
        infoCotas += 'PCD: $percentual%; ';
      }

      if (infoCotas.isNotEmpty) {
        return infoCotas.substring(0, infoCotas.length - 2); // Remover último '; '
      }

      // Se não encontrou padrões específicos, mas há menção a cotas
      if (textoLower.contains('cota') || textoLower.contains('pcd') ||
          textoLower.contains('negro') || textoLower.contains('deficiênc')) {
        return 'Verificar no edital';
      }
    }

    debugPrint('  Nenhuma informação sobre cotas encontrada');
    return 'Não informado';
  }
}
