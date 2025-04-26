import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import '../../../../core/utils/plano_data_logger.dart';
import '../../domain/services/calendario_service.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/plano_resumo_service.dart';
import '../../domain/services/plano_dados_service.dart';
import '../widgets/botoes_acao_widget.dart';
import '../widgets/calendario_widget.dart';
import '../widgets/cargo_info_widget.dart';
import '../widgets/concurso_info_widget.dart';
import '../widgets/conteudo_programatico_widget.dart';
import '../widgets/ferramentas_estudo_widget.dart';
import '../widgets/plano_info_widget.dart';
import '../widgets/prova_info_widget.dart';
import '../widgets/recompensas_widget.dart';
import '../widgets/section_title_widget.dart';
import 'plano_logs_screen.dart';

/// Tela de resumo do plano de estudos
class PlanoResumoScreen extends StatefulWidget {
  final String planoId;

  const PlanoResumoScreen({Key? key, required this.planoId}) : super(key: key);

  @override
  _PlanoResumoScreenState createState() => _PlanoResumoScreenState();
}

class _PlanoResumoScreenState extends State<PlanoResumoScreen> {
  // Serviços
  late final PlanoResumoService _planoResumoService;
  late final CalendarioService _calendarioService;
  late final ExtratorDadosService _extratoService;
  late final PlanoDadosService _planoDadosService;
  late final SessaoEstudoService _sessaoEstudoService;

  // Dados
  PlanoEstudo? _plano;
  Edital? _edital;
  Cargo? _cargoSelecionado;
  Map<DateTime, List<SessaoEstudo>> _sessoesPorDia = {};

  // Estado do calendário
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Estado de carregamento
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Inicializar serviços
    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final editalService = Provider.of<EditalService>(context, listen: false);
    _sessaoEstudoService = Provider.of<SessaoEstudoService>(context, listen: false);

    _extratoService = ExtratorDadosService();
    _planoDadosService = PlanoDadosService();
    _calendarioService = CalendarioService(planoService, _extratoService);
    _planoResumoService = PlanoResumoService(planoService, editalService, _calendarioService, _extratoService);

    // Carregar dados
    _carregarPlano();

    // Reproduzir som de navegação ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioExplanationService>(context, listen: false).playSuccess();
    });
  }

  /// Carrega o plano de estudos e o edital associado
  Future<void> _carregarPlano() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final resultado = await _planoResumoService.carregarPlano(widget.planoId);

      if (resultado['erro'] != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = resultado['erro'];
        });
        return;
      }

      final plano = resultado['plano'] as PlanoEstudo?;
      final edital = resultado['edital'] as Edital?;
      final sessoesPorDia = resultado['sessoesPorDia'] as Map<DateTime, List<SessaoEstudo>>;
      final focusedDay = resultado['focusedDay'] as DateTime;
      final selectedDay = resultado['selectedDay'] as DateTime?;

      // Obter o cargo selecionado
      Cargo? cargoSelecionado;
      if (plano != null && edital != null) {
        cargoSelecionado = _planoResumoService.obterCargoSelecionado(plano, edital);
      }

      // Extrair dados do edital para o plano
      if (plano != null && edital != null) {
        await _planoDadosService.extrairDadosEditalParaPlano(plano, edital);
      }

      setState(() {
        _plano = plano;
        _edital = edital;
        _cargoSelecionado = cargoSelecionado;
        _sessoesPorDia = sessoesPorDia;
        _focusedDay = focusedDay;
        _selectedDay = selectedDay;
        _isLoading = false;
      });

      // Verificar se o plano tem sessões de estudo e gerar se necessário
      if (_plano != null && _plano!.sessoesEstudo.isEmpty) {
        _gerarSessoesEstudo();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar plano: $e';
      });
    }
  }

  /// Gera sessões de estudo para o plano
  Future<void> _gerarSessoesEstudo() async {
    if (_plano == null) return;

    await _calendarioService.gerarSessoesEstudo(_plano!, (planoAtualizado) {
      setState(() {
        _plano = planoAtualizado;
        _sessoesPorDia = _calendarioService.agruparSessoesPorDia(planoAtualizado.sessoesEstudo);
      });
    });
  }

  /// Sincroniza o plano com o Google Calendar
  Future<void> _sincronizarComGoogleCalendar() async {
    if (_plano == null) return;

    final resultado = await _calendarioService.sincronizarComGoogleCalendar(_plano!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado
          ? 'Plano sincronizado com Google Calendar com sucesso!'
          : 'Erro ao sincronizar com Google Calendar'),
        backgroundColor: resultado ? Colors.green : Colors.red,
      ),
    );
  }

  /// Sincroniza o plano com o Apple Calendar
  Future<void> _sincronizarComAppleCalendar() async {
    if (_plano == null) return;

    final resultado = await _calendarioService.sincronizarComAppleCalendar(_plano!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado
          ? 'Plano sincronizado com Apple Calendar com sucesso!'
          : 'Erro ao sincronizar com Apple Calendar'),
        backgroundColor: resultado ? Colors.green : Colors.red,
      ),
    );
  }

  /// Atualiza o dia selecionado no calendário
  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = selectedDay;
    });
  }

  /// Navega para o dashboard
  void _navegarParaDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resumo do Plano'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _plano == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resumo do Plano'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar plano',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Plano não encontrado'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregarPlano,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo do Plano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.data_usage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanoLogsScreen(planoId: widget.planoId),
                ),
              );
            },
            tooltip: 'Ver Logs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título da seção Dados do Concurso
              const SectionTitleWidget(
                title: 'Dados do Concurso',
                icon: Icons.assignment,
              ),
              const SizedBox(height: 8),

              // Informações do concurso
              ConcursoInfoWidget(
                plano: _plano!,
                edital: _edital,
                extratoService: _extratoService,
              ),
              const SizedBox(height: 24),

              // Título da seção Cargo Selecionado
              const SectionTitleWidget(
                title: 'Cargo Selecionado',
                icon: Icons.work,
              ),
              const SizedBox(height: 8),

              // Informações do cargo
              CargoInfoWidget(
                plano: _plano!,
                edital: _edital,
                cargo: _cargoSelecionado,
                extratoService: _extratoService,
                planoResumoService: _planoResumoService,
              ),
              const SizedBox(height: 24),

              // Título da seção Informações da Prova
              const SectionTitleWidget(
                title: 'Informações da Prova',
                icon: Icons.quiz,
              ),
              const SizedBox(height: 8),

              // Informações da prova
              ProvaInfoWidget(
                plano: _plano!,
                edital: _edital,
                extratoService: _extratoService,
              ),
              const SizedBox(height: 24),

              // Título da seção Conteúdo Programático
              SectionTitleWidget(
                title: 'Conteúdo Programático - ${_cargoSelecionado?.nome ?? ""}',
                icon: Icons.menu_book,
              ),
              const SizedBox(height: 8),

              // Conteúdo programático
              ConteudoProgramaticoWidget(
                plano: _plano!,
                edital: _edital,
                cargo: _cargoSelecionado,
                planoResumoService: _planoResumoService,
                extratoService: _extratoService,
                sessaoEstudoService: _sessaoEstudoService,
              ),
              const SizedBox(height: 24),

              // Título da seção Plano de Estudos
              const SectionTitleWidget(
                title: 'Plano de Estudos',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 8),

              // Informações do plano
              PlanoInfoWidget(
                plano: _plano!,
              ),
              const SizedBox(height: 24),

              // Título da seção Ferramentas de Estudo
              const SectionTitleWidget(
                title: 'Ferramentas de Estudo',
                icon: Icons.build,
              ),
              const SizedBox(height: 8),

              // Ferramentas de estudo
              FerramentasEstudoWidget(
                plano: _plano!,
              ),
              const SizedBox(height: 24),

              // Título da seção Recompensas
              const SectionTitleWidget(
                title: 'Recompensas',
                icon: Icons.emoji_events,
              ),
              const SizedBox(height: 8),

              // Recompensas
              RecompensasWidget(
                plano: _plano!,
              ),
              const SizedBox(height: 24),

              // Título da seção Calendário de Estudos
              const SectionTitleWidget(
                title: 'Calendário de Estudos',
                icon: Icons.date_range,
              ),
              const SizedBox(height: 8),

              // Calendário
              CalendarioWidget(
                plano: _plano!,
                sessoesPorDia: _sessoesPorDia,
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                calendarioService: _calendarioService,
                onDaySelected: _onDaySelected,
                onGerarSessoes: _gerarSessoesEstudo,
                onSincronizarGoogleCalendar: _sincronizarComGoogleCalendar,
                onSincronizarAppleCalendar: _sincronizarComAppleCalendar,
              ),
              const SizedBox(height: 32),

              // Botão de ação
              BotoesAcaoWidget(
                onIniciarJornada: _navegarParaDashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
