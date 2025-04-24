import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/plano_data_logger.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/widgets/gradient_button.dart';

import '../../domain/services/plano_data_validator.dart';
import '../../domain/services/llm_response_processor.dart';
import '../../domain/services/plano_questionario_service.dart';

import '../widgets/questionario/questionario_header.dart';
import '../widgets/questionario/data_selection_section.dart';
import '../widgets/questionario/horarios_selection_section.dart';
import '../widgets/questionario/ferramentas_selection_section.dart';
import '../widgets/questionario/proficiencia_selection_section.dart';
import '../widgets/questionario/recompensas_selection_section.dart';
import '../widgets/questionario/progress_indicator_section.dart';

import 'plano_resumo_screen.dart';

class PlanoQuestionarioScreen extends StatefulWidget {
  final Map<String, dynamic> dadosCargo;
  final Map<String, dynamic> dadosEdital;

  const PlanoQuestionarioScreen({
    Key? key,
    required this.dadosCargo,
    required this.dadosEdital,
  }) : super(key: key);

  @override
  _PlanoQuestionarioScreenState createState() => _PlanoQuestionarioScreenState();
}

class _PlanoQuestionarioScreenState extends State<PlanoQuestionarioScreen> {
  // Serviços
  late final PlanoDataLogger _logger;
  late final PlanoDataValidator _validator;
  late final LLMResponseProcessor _llmProcessor;
  late final PlanoQuestionarioService _questionarioService;

  // Estado do questionário
  DateTime? _dataInicio;
  DateTime? _dataFim;
  Map<String, int> _horasPorDia = {
    'Segunda': 0,
    'Terça': 0,
    'Quarta': 0,
    'Quinta': 0,
    'Sexta': 0,
    'Sábado': 0,
    'Domingo': 0,
  };
  Map<String, List<int>> _horasSelecionadas = {
    'Segunda': [],
    'Terça': [],
    'Quarta': [],
    'Quinta': [],
    'Sexta': [],
    'Sábado': [],
    'Domingo': [],
  };
  List<String> _ferramentasSelecionadas = [];
  Map<String, String> _proficiencia = {};
  List<RecompensaConfig> _recompensas = [];

  // Estado da UI
  bool _isLoading = false;
  double _progressValue = 0.0;
  String _progressMessage = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _logger = PlanoDataLogger();
    _validator = PlanoDataValidator();
    _llmProcessor = LLMResponseProcessor(logger: _logger);

    // Inicializar proficiência para todas as matérias
    final materias = (widget.dadosCargo['materias'] as List<dynamic>? ?? []).map((m) => m.toString()).toList();
    print('Inicializando tela de questionário com as seguintes matérias:');
    for (var materia in materias) {
      print('- $materia');
      _proficiencia[materia.toLowerCase()] = 'Intermediário';
    }

    if (materias.isEmpty) {
      print('AVISO: Nenhuma matéria encontrada nos dados do cargo!');
    }

    // Adicionar recompensas padrão
    _recompensas = [
      RecompensaConfig(tipoRecompensa: 'diaria', descricaoRecompensa: 'Pausa para café'),
      RecompensaConfig(tipoRecompensa: 'semanal', descricaoRecompensa: 'Assistir um episódio de série'),
      RecompensaConfig(tipoRecompensa: 'mensal', descricaoRecompensa: 'Dia de folga nos estudos'),
    ];

    // Registrar dados iniciais
    _logger.logQuestionario('init', 'inicializacao_questionario', {
      'cargo': widget.dadosCargo['cargo'],
      'edital': widget.dadosEdital['titulo'],
      'materias': materias,
    });

    // Imprimir todos os dados recebidos para debug
    print('Dados do cargo recebidos:');
    widget.dadosCargo.forEach((key, value) {
      print('$key: $value');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inicializar serviço de questionário
    final iaService = Provider.of<IAServiceInterface>(context, listen: false);
    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    _questionarioService = PlanoQuestionarioService(
      iaService: iaService,
      planoService: planoService,
      authService: authService,
      logger: _logger,
      validator: _validator,
      llmProcessor: _llmProcessor,
    );
  }

  // Atualiza as datas de início e fim
  void _atualizarDataInicio(DateTime data) {
    setState(() {
      _dataInicio = data;
      // Se a data de fim for anterior à data de início, ajustar
      if (_dataFim != null && _dataFim!.isBefore(_dataInicio!)) {
        _dataFim = _dataInicio!.add(const Duration(days: 90));
      }
    });
  }

  void _atualizarDataFim(DateTime data) {
    setState(() {
      _dataFim = data;
    });
  }

  // Atualiza as horas selecionadas para um dia
  void _atualizarHorasSelecionadas(String dia, List<int> horas) {
    setState(() {
      _horasSelecionadas[dia] = horas;
      _horasPorDia[dia] = horas.length;
    });
  }

  // Atualiza as ferramentas selecionadas
  void _atualizarFerramentas(List<String> ferramentas) {
    setState(() {
      _ferramentasSelecionadas = ferramentas;
    });
  }

  // Atualiza a proficiência das matérias
  void _atualizarProficiencia(Map<String, String> proficiencia) {
    setState(() {
      _proficiencia = proficiencia;
    });
  }

  // Atualiza as recompensas
  void _atualizarRecompensas(List<RecompensaConfig> recompensas) {
    setState(() {
      _recompensas = recompensas;
    });
  }

  // Atualiza o progresso da geração do plano
  void _atualizarProgresso(double valor, String mensagem) {
    setState(() {
      _progressValue = valor;
      _progressMessage = mensagem;
    });
  }

  // Valida os dados do questionário
  bool _validarDados() {
    // Validar datas
    if (!_validator.validarDatas(_dataInicio, _dataFim)) {
      setState(() {
        _errorMessage = 'Por favor, selecione as datas de início e término do plano.';
      });
      return false;
    }

    // Validar horas de estudo
    if (!_validator.validarHorasEstudo(_horasPorDia)) {
      setState(() {
        _errorMessage = 'Por favor, selecione pelo menos um horário de estudo.';
      });
      return false;
    }

    // Validar ferramentas
    if (!_validator.validarFerramentas(_ferramentasSelecionadas)) {
      setState(() {
        _errorMessage = 'Por favor, selecione pelo menos uma ferramenta de estudo.';
      });
      return false;
    }

    // Validar proficiência das matérias
    final materias = (widget.dadosCargo['materias'] as List<dynamic>? ?? [])
        .map((m) => m.toString())
        .toList();

    print('Validando proficiência para ${materias.length} matérias');
    for (var materia in materias) {
      print('- $materia: ${_proficiencia[materia.toLowerCase()]}');
    }

    if (!_validator.validarProficienciasMaterias(materias.map((m) => m.toLowerCase()).toList(), _proficiencia)) {
      final materiaSemProficiencia = _validator.obterMateriaSemProficiencia(
        materias.map((m) => m.toLowerCase()).toList(),
        _proficiencia,
      );
      setState(() {
        _errorMessage = 'Por favor, informe sua proficiência na matéria ${materiaSemProficiencia?.toUpperCase() ?? "faltante"}.';
      });
      print('Erro de validação: Matéria sem proficiência: $materiaSemProficiencia');
      return false;
    }

    // Todos os dados são válidos
    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  // Gera o plano de estudos
  Future<void> _gerarPlano() async {
    // Validar dados
    if (!_validarDados()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _progressValue = 0.0;
      _progressMessage = 'Iniciando geração do plano...';
    });

    try {
      // Gerar plano de estudos
      final planoId = await _questionarioService.gerarPlanoEstudos(
        dadosCargo: widget.dadosCargo,
        dadosEdital: widget.dadosEdital,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        horasPorDia: _horasPorDia,
        horasSelecionadas: _horasSelecionadas,
        ferramentas: _ferramentasSelecionadas,
        proficiencia: _proficiencia,
        recompensas: _recompensas,
        onProgress: _atualizarProgresso,
      );

      if (planoId != null && mounted) {
        // Navegar para a tela de resumo do plano
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlanoResumoScreen(planoId: planoId),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao gerar plano de estudos. Por favor, tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Garantir que as matérias sejam convertidas corretamente para String
    final materias = (widget.dadosCargo['materias'] as List<dynamic>? ?? [])
        .map((m) => m.toString())
        .toList();

    print('Build da tela de questionário com ${materias.length} matérias');

    return Scaffold(
      backgroundColor: const Color(0xFF13192b),
      appBar: AppBar(
        title: const Text('Questionário do Plano'),
        backgroundColor: const Color(0xFFf43f7d),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _buildQuestionarioForm(materias),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProgressIndicatorSection(
              progress: _progressValue,
              message: _progressMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionarioForm(List<String> materias) {
    print('Construindo formulário de questionário com ${materias.length} matérias');

    // Verificar se há matérias para exibir
    if (materias.isEmpty) {
      print('AVISO: Lista de matérias vazia ao construir o formulário!');
    } else {
      print('Matérias a serem exibidas no formulário:');
      for (var materia in materias) {
        print('- $materia');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          QuestionarioHeader(
            titulo: 'Questionário do Plano',
            subtitulo: 'Preencha as informações abaixo para gerar seu plano de estudos personalizado',
            cargoSelecionado: widget.dadosCargo['cargo'],
            editalTitulo: widget.dadosEdital['titulo'],
          ),
          const SizedBox(height: 24),

          // Mensagem de erro (se houver)
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
            ),

          // Seleção de datas
          DataSelectionSection(
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            onDataInicioChanged: _atualizarDataInicio,
            onDataFimChanged: _atualizarDataFim,
          ),
          const SizedBox(height: 24),

          // Seleção de horários
          HorariosSelectionSection(
            horasPorDia: _horasPorDia,
            horasSelecionadas: _horasSelecionadas,
            onHorasSelecionadasChanged: _atualizarHorasSelecionadas,
          ),
          const SizedBox(height: 24),

          // Seleção de ferramentas
          FerramentasSelectionSection(
            ferramentasSelecionadas: _ferramentasSelecionadas,
            onFerramentasChanged: _atualizarFerramentas,
          ),
          const SizedBox(height: 24),

          // Seleção de proficiência
          ProficienciaSelectionSection(
            materias: materias,
            proficiencia: _proficiencia,
            onProficienciaChanged: _atualizarProficiencia,
          ),
          const SizedBox(height: 24),

          // Seleção de recompensas
          RecompensasSelectionSection(
            recompensas: _recompensas,
            onRecompensasChanged: _atualizarRecompensas,
          ),
          const SizedBox(height: 32),

          // Botão de gerar plano
          GradientButton(
            onPressed: _gerarPlano,
            gradient: const LinearGradient(
              colors: [Color(0xFFf43f7d), Color(0xFFe11d48)],
            ),
            child: const Text('GERAR PLANO DE ESTUDOS'),
            fullWidth: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
