import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/utils/edital_analyzer.dart';
import 'recompensas_personalizadas.dart';

class PlanoAddScreen extends StatefulWidget {
  final String? editalId;
  final List<String>? cargoIds;

  const PlanoAddScreen({this.editalId, this.cargoIds});

  @override
  _PlanoAddScreenState createState() => _PlanoAddScreenState();
}

class _PlanoAddScreenState extends State<PlanoAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Controles para os campos do formulário
  List<String> _cargosSelecionados = [];
  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(Duration(days: 90));
  Map<String, int> _horasSemanais = {
    'segunda': 2,
    'terca': 2,
    'quarta': 2,
    'quinta': 2,
    'sexta': 2,
    'sabado': 4,
    'domingo': 0,
  };
  List<String> _ferramentasSelecionadas = [];
  List<MateriaProficiencia> _materiasProficiencia = [];
  List<RecompensaConfig> _recompensasConfig = [
    RecompensaConfig(
      tipoRecompensa: 'diaria',
      descricaoRecompensa: 'Pausa para café',
    ),
    RecompensaConfig(
      tipoRecompensa: 'semanal',
      descricaoRecompensa: 'Assistir um episódio de série',
    ),
  ];

  bool _isLoading = false;
  bool _isGeneratingPlan = false;
  String? _errorMessage;
  String _progressMessage = '';
  double _progressValue = 0.0;
  bool _isApiLlmConfigured = false;
  bool _respostasConfirmadas = false;

  // Plano de estudo gerado pela IA
  Map<String, dynamic>? _planoGeradoIA;

  // Lista de ferramentas disponíveis
  final List<Map<String, dynamic>> _ferramentasDisponiveis = [
    {'id': 'videoaulas', 'nome': 'Videoaulas', 'icon': Icons.video_library},
    {'id': 'audioaulas', 'nome': 'Audioaulas', 'icon': Icons.headphones},
    {'id': 'pdfs', 'nome': 'PDFs/Livros', 'icon': Icons.book},
    {'id': 'questoes', 'nome': 'Plataforma de Questões', 'icon': Icons.question_answer},
    {'id': 'flashcards', 'nome': 'Flashcards', 'icon': Icons.style},
    {'id': 'lei_seca', 'nome': 'Leitura de Lei Seca', 'icon': Icons.gavel},
    {'id': 'resumos', 'nome': 'Resumos', 'icon': Icons.notes},
  ];

  // Lista de recompensas disponíveis
  final List<Map<String, dynamic>> _recompensasDisponiveis = [
    {'id': 'cafe', 'nome': 'Pausa para café/lanche', 'tipo': 'diaria'},
    {'id': 'redes_sociais', 'nome': '15 min de redes sociais', 'tipo': 'diaria'},
    {'id': 'musica', 'nome': 'Ouvir música favorita', 'tipo': 'diaria'},
    {'id': 'serie', 'nome': 'Assistir um episódio de série', 'tipo': 'semanal'},
    {'id': 'filme', 'nome': 'Assistir um filme', 'tipo': 'semanal'},
    {'id': 'jogo', 'nome': 'Jogar por 1h', 'tipo': 'semanal'},
    {'id': 'passeio', 'nome': 'Passeio/Encontro com amigos', 'tipo': 'mensal'},
    {'id': 'folga', 'nome': 'Dia de folga nos estudos', 'tipo': 'mensal'},
  ];

  // Recompensas personalizadas adicionadas pelo usuário
  List<Map<String, dynamic>> _recompensasPersonalizadas = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
    _verificarApiLlmConfigurada();

    // Inicializar cargos selecionados a partir dos argumentos
    if (widget.cargoIds != null && widget.cargoIds!.isNotEmpty) {
      _cargosSelecionados = List.from(widget.cargoIds!);
    }
  }

  // Verifica se a API LLM está configurada
  Future<void> _verificarApiLlmConfigurada() async {
    final iaService = Provider.of<IAService>(context, listen: false);
    setState(() {
      _isApiLlmConfigured = iaService.isConfigured;
    });
  }

  // Método para confirmar as respostas do usuário
  void _confirmarRespostas() {
    if (_validarFormulario()) {
      setState(() {
        _respostasConfirmadas = true;
      });

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Respostas confirmadas! Agora configure a API LLM para gerar o plano de estudo.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Valida o formulário antes de confirmar as respostas
  bool _validarFormulario() {
    // Verificar se há pelo menos um cargo selecionado
    if (_cargosSelecionados.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos um cargo para continuar.';
      });
      return false;
    }

    // Verificar se há pelo menos uma ferramenta selecionada
    if (_ferramentasSelecionadas.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos uma ferramenta de estudo.';
      });
      return false;
    }

    // Verificar se há pelo menos uma hora de estudo configurada
    bool temHorasEstudo = _horasSemanais.values.any((horas) => horas > 0);
    if (!temHorasEstudo) {
      setState(() {
        _errorMessage = 'Configure pelo menos uma hora de estudo semanal.';
      });
      return false;
    }

    // Limpar mensagem de erro se tudo estiver ok
    setState(() {
      _errorMessage = null;
    });

    return true;
  }

  // Método para configurar a API LLM
  void _configurarApiLLM() {
    Navigator.pushNamed(context, '/api_config').then((value) {
      // Verificar se a API foi configurada
      _verificarApiLlmConfigurada();
    });
  }

  @override
  void dispose() {
    // Liberar recursos
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    if (widget.editalId != null) {
      final editalService = Provider.of<EditalService>(context, listen: false);
      final edital = editalService.getEditalById(widget.editalId!);

      if (edital != null) {
        // Carregar materias do edital para o formulário
        final materias = <MateriaProficiencia>[];

        for (final cargo in edital.dadosExtraidos.cargos) {
          for (final materia in cargo.conteudoProgramatico) {
            // Verificar se a matéria já existe na lista
            if (!materias.any((m) => m.nomeMateria == materia.nome)) {
              materias.add(MateriaProficiencia(
                nomeMateria: materia.nome,
                nivelProficiencia: 3, // Nível médio como padrão
              ));
            }
          }
        }

        setState(() {
          _materiasProficiencia = materias;

          // Definir data da prova como data fim, se disponível
          if (edital.dadosExtraidos.cargos.isNotEmpty &&
              edital.dadosExtraidos.cargos.first.dataProva != null) {
            _dataFim = edital.dadosExtraidos.cargos.first.dataProva!;
          }

          // Adicionar cargos disponíveis
          if (edital.dadosExtraidos.cargos.isNotEmpty) {
            _cargosSelecionados = [edital.dadosExtraidos.cargos.first.nome];
          }
        });

        // Não mostrar o diálogo de geração de plano com IA automaticamente
        // O usuário deve preencher os dados do formulário primeiro
      }
    }
  }



  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _gerarPlanoEstudoIA(Edital edital) async {
    setState(() {
      _isGeneratingPlan = true;
      _progressValue = 0.1;
      _progressMessage = 'Iniciando geração do plano...';
    });

    try {
      final iaService = Provider.of<IAService>(context, listen: false);

      // Criar analisador de edital
      final editalAnalyzer = EditalAnalyzer(
        iaService: iaService,
        onProgress: (progress, message) {
          setState(() {
            _progressValue = progress;
            _progressMessage = message;
          });
        },
      );

      // Selecionar cargo para o plano
      final String cargoSelecionado = _cargosSelecionados.isNotEmpty
          ? _cargosSelecionados.first
          : edital.dadosExtraidos.cargos.isNotEmpty
              ? edital.dadosExtraidos.cargos.first.nome
              : 'Geral';

      // Gerar plano de estudo
      final planoEstudo = await editalAnalyzer.gerarPlanoEstudo(
        edital.textoCompleto,
        cargoSelecionado,
        _dataInicio,
        _dataFim,
      );

      // Atualizar estado com o plano gerado
      setState(() {
        _planoGeradoIA = planoEstudo;
        _progressValue = 0.8;
        _progressMessage = 'Criando plano de estudo...';
      });

      // Atualizar matérias com base no plano gerado
      final List<MateriaProficiencia> novasMaterias = [];
      if (planoEstudo.containsKey('materiasPrioritarias')) {
        final List<dynamic> materiasPrioritarias = planoEstudo['materiasPrioritarias'];

        for (final materia in materiasPrioritarias) {
          novasMaterias.add(MateriaProficiencia(
            nomeMateria: materia['nome'],
            nivelProficiencia: 6 - (materia['peso'] as int), // Converter peso (1-5) para proficiência (5-1)
          ));
        }
      }

      // Atualizar horas semanais com base no plano gerado
      final Map<String, int> novasHoras = {
        'segunda': 2,
        'terca': 2,
        'quarta': 2,
        'quinta': 2,
        'sexta': 2,
        'sabado': 4,
        'domingo': 0,
      };

      if (planoEstudo.containsKey('cronogramaSemanal')) {
        final Map<String, dynamic> cronograma = planoEstudo['cronogramaSemanal'];

        cronograma.forEach((dia, materias) {
          int horasTotal = 0;
          for (final materia in materias) {
            horasTotal += (materia['horas'] as int);
          }
          novasHoras[dia] = horasTotal;
        });
      }

      // Criar o plano de estudo automaticamente
      try {
        setState(() {
          _progressValue = 0.9;
          _progressMessage = 'Salvando plano de estudo...';
        });

        final authService = Provider.of<AuthService>(context, listen: false);
        final planoService = Provider.of<PlanoEstudoService>(context, listen: false);

        // Verificar se o usuário está autenticado
        final usuario = authService.currentUser;
        if (usuario == null) {
          throw Exception('Você precisa estar autenticado para criar um plano de estudo.');
        }

        // Definir ferramentas padrão se não houver selecionadas
        if (_ferramentasSelecionadas.isEmpty) {
          _ferramentasSelecionadas = ['videoaulas', 'pdfs', 'questoes'];
        }

        // Criar lista de recompensas padrão
        final List<RecompensaConfig> recompensas = [
          RecompensaConfig(tipoRecompensa: 'diaria', descricaoRecompensa: 'Pausa para café'),
          RecompensaConfig(tipoRecompensa: 'semanal', descricaoRecompensa: 'Assistir um episódio de série'),
          RecompensaConfig(tipoRecompensa: 'mensal', descricaoRecompensa: 'Dia de folga nos estudos'),
        ];

        // Criar o plano de estudo
        final plano = await planoService.criarPlanoEstudo(
          usuario.id,
          widget.editalId!,
          _cargosSelecionados,
          _dataInicio,
          _dataFim,
          novasHoras,
          _ferramentasSelecionadas,
          novasMaterias.isEmpty ? _materiasProficiencia : novasMaterias,
          recompensas,
        );

        setState(() {
          _progressValue = 1.0;
          _progressMessage = 'Plano criado com sucesso!';
          _isGeneratingPlan = false;
        });

        // Mostrar mensagem de sucesso e redirecionar automaticamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plano de estudo criado com sucesso! Redirecionando...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Pequeno delay para mostrar a mensagem antes de redirecionar
        await Future.delayed(Duration(milliseconds: 500));

        // Navegar para a tela de calendário
        Navigator.pushReplacementNamed(
          context,
          '/plano/calendario',
          arguments: plano.id,
        );
      } catch (e) {
        setState(() {
          _isGeneratingPlan = false;
          _errorMessage = 'Erro ao criar plano de estudo: $e';
        });

        // Mostrar mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar plano: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingPlan = false;
        _errorMessage = 'Erro ao gerar plano de estudo: $e';
      });
    }
  }

  Future<void> _criarPlanoAntigo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final planoService = Provider.of<PlanoEstudoService>(context, listen: false);

        // Verificar se o usuário está autenticado
        final usuario = authService.currentUser;
        if (usuario == null) {
          setState(() {
            _errorMessage = 'Você precisa estar autenticado para criar um plano de estudo.';
            _isLoading = false;
          });
          return;
        }

        // Verificar se há um edital selecionado
        if (widget.editalId == null) {
          setState(() {
            _errorMessage = 'Você precisa selecionar um edital para criar um plano de estudo.';
            _isLoading = false;
          });
          return;
        }

        // Verificar se há pelo menos uma ferramenta selecionada
        if (_ferramentasSelecionadas.isEmpty) {
          setState(() {
            _errorMessage = 'Selecione pelo menos uma ferramenta de estudo.';
            _isLoading = false;
          });
          return;
        }

        // Verificar se há pelo menos uma matéria
        if (_materiasProficiencia.isEmpty) {
          setState(() {
            _errorMessage = 'Não há matérias disponíveis para este edital.';
            _isLoading = false;
          });
          return;
        }

        // Criar o plano de estudo
        final plano = await planoService.criarPlanoEstudo(
          usuario.id,
          widget.editalId!,
          _cargosSelecionados.isEmpty ? ['todos'] : _cargosSelecionados,
          _dataInicio,
          _dataFim,
          _horasSemanais,
          _ferramentasSelecionadas,
          _materiasProficiencia,
          _recompensasConfig,
        );

        // Registrar atividade de gamificação
        // (Isso seria feito através do GamificacaoService em um app real)

        // Navegar para a tela de calendário
        Navigator.pushReplacementNamed(
          context,
          '/plano/calendario',
          arguments: plano.id,
        );

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plano de estudo criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Ocorreu um erro ao criar o plano de estudo. Tente novamente.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editalService = Provider.of<EditalService>(context);
    final edital = widget.editalId != null ? editalService.getEditalById(widget.editalId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Plano de Estudo'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          // Conteúdo principal
          edital == null && widget.editalId != null
              ? _buildEditalNaoEncontrado()
              : _buildFormulario(edital),

          // Overlay de progresso para geração de plano com IA
          if (_isGeneratingPlan)
            _buildProgressOverlay(),
        ],
      ),
    );
  }

  Widget _buildProgressOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 300,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Gerando Plano de Estudo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _progressMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 24),
                LinearProgressIndicator(value: _progressValue),
                SizedBox(height: 8),
                Text(
                  '${(_progressValue * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditalNaoEncontrado() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text(
            'Edital não encontrado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('O edital selecionado não foi encontrado ou foi removido.'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario(Edital? edital) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Text(
              'Criar Plano de Estudo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              edital != null
                  ? 'Edital: ${edital.nomeConcurso}'
                  : 'Configure seu plano de estudos personalizado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            Divider(height: 32),

            // Período de estudo
            _buildSectionTitle('Período de Estudo'),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Data de Início',
                    _dataInicio,
                    (date) => setState(() => _dataInicio = date),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'Data de Término',
                    _dataFim,
                    (date) => setState(() => _dataFim = date),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Disponibilidade semanal
            _buildSectionTitle('Disponibilidade Semanal'),
            Text(
              'Quantas horas você pode dedicar ao estudo em cada dia da semana?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            _buildHorasSemanaisSelector(),
            SizedBox(height: 24),

            // Ferramentas de estudo
            _buildSectionTitle('Ferramentas de Estudo'),
            Text(
              'Selecione as ferramentas que você tem disponíveis para estudar:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            _buildFerramentasSelector(),
            SizedBox(height: 24),

            // Recompensas
            _buildSectionTitle('Sistema de Recompensas'),
            Text(
              'Selecione recompensas para se motivar após cumprir suas metas:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            _buildRecompensasSelector(),
            SizedBox(height: 16),
            RecompensasPersonalizadasWidget(
              recompensasPersonalizadas: _recompensasPersonalizadas,
              onRecompensasChanged: (recompensas) {
                setState(() {
                  _recompensasPersonalizadas = recompensas;
                });
              },
            ),
            SizedBox(height: 24),

            // Proficiência nas matérias
            if (_materiasProficiencia.isNotEmpty) ...[
              _buildSectionTitle('Proficiência nas Matérias'),
              Text(
                'Indique seu nível de conhecimento em cada matéria:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              _buildMateriasProficienciaSelector(),
              SizedBox(height: 24),
            ],

            // Plano gerado pela IA
            if (_planoGeradoIA != null) ...[
              _buildSectionTitle('Plano Gerado pela IA'),
              Text(
                'A IA gerou um plano personalizado com base no edital:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              _buildPlanoGeradoIA(),
              SizedBox(height: 24),
            ],

            // Mensagem de erro
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Botões de ação
            SizedBox(height: 32),
            Row(
              children: [
                // Botão de confirmar respostas
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _respostasConfirmadas ? null : _confirmarRespostas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Confirmar Respostas',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                SizedBox(width: 16),
                // Botão de configurar API LLM
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || !_respostasConfirmadas ? null : _configurarApiLLM,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Text(
                      'Configurar API LLM',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            // Botão de gerar plano (aparece após configurar API LLM)
            if (_isApiLlmConfigured && _respostasConfirmadas && edital != null) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _gerarPlanoEstudoIA(edital),
                  icon: Icon(Icons.auto_awesome),
                  label: Text('Gerar Plano de Estudo com IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],

            // Botão de cancelar
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
                child: Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime initialDate, Function(DateTime) onDateSelected) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${initialDate.day.toString().padLeft(2, '0')}/${initialDate.month.toString().padLeft(2, '0')}/${initialDate.year}',
            ),
            Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildHorasSemanaisSelector() {
    return Column(
      children: [
        for (var entry in [
          {'dia': 'segunda', 'nome': 'Segunda-feira'},
          {'dia': 'terca', 'nome': 'Terça-feira'},
          {'dia': 'quarta', 'nome': 'Quarta-feira'},
          {'dia': 'quinta', 'nome': 'Quinta-feira'},
          {'dia': 'sexta', 'nome': 'Sexta-feira'},
          {'dia': 'sabado', 'nome': 'Sábado'},
          {'dia': 'domingo', 'nome': 'Domingo'},
        ])
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(entry['nome']!),
                ),
                Expanded(
                  flex: 3,
                  child: Slider(
                    value: _horasSemanais[entry['dia']!]!.toDouble(),
                    min: 0,
                    max: 8,
                    divisions: 8,
                    label: '${_horasSemanais[entry['dia']]} horas',
                    onChanged: (value) {
                      setState(() {
                        _horasSemanais[entry['dia']!] = value.toInt();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${_horasSemanais[entry['dia']]} h',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: ${_horasSemanais.values.reduce((a, b) => a + b)} horas por semana',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFerramentasSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ferramentasDisponiveis.map((ferramenta) {
        final isSelected = _ferramentasSelecionadas.contains(ferramenta['id']);
        return FilterChip(
          selected: isSelected,
          label: Text(ferramenta['nome']),
          avatar: Icon(
            ferramenta['icon'],
            size: 18,
            color: isSelected ? Colors.white : AppTheme.primaryColor,
          ),
          backgroundColor: Colors.grey.shade100,
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _ferramentasSelecionadas.add(ferramenta['id']);
              } else {
                _ferramentasSelecionadas.remove(ferramenta['id']);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRecompensasSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recompensas Diárias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildRecompensasPorTipo('diaria'),
        SizedBox(height: 16),

        Text(
          'Recompensas Semanais',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildRecompensasPorTipo('semanal'),
        SizedBox(height: 16),

        Text(
          'Recompensas Mensais',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildRecompensasPorTipo('mensal'),
      ],
    );
  }

  Widget _buildRecompensasPorTipo(String tipo) {
    final recompensasFiltradas = _recompensasDisponiveis.where((r) => r['tipo'] == tipo).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recompensasFiltradas.map((recompensa) {
        final isSelected = _recompensasConfig.any((r) =>
          r.tipoRecompensa == tipo && r.descricaoRecompensa == recompensa['nome']);

        return FilterChip(
          selected: isSelected,
          label: Text(recompensa['nome']),
          backgroundColor: Colors.grey.shade100,
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _recompensasConfig.add(RecompensaConfig(
                  tipoRecompensa: tipo,
                  descricaoRecompensa: recompensa['nome'],
                ));
              } else {
                _recompensasConfig.removeWhere((r) =>
                  r.tipoRecompensa == tipo && r.descricaoRecompensa == recompensa['nome']);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMateriasProficienciaSelector() {
    return Column(
      children: _materiasProficiencia.map((materia) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                materia.nomeMateria,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text('Iniciante'),
                  Expanded(
                    child: Slider(
                      value: materia.nivelProficiencia.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _getNivelProficienciaLabel(materia.nivelProficiencia),
                      onChanged: (value) {
                        setState(() {
                          final index = _materiasProficiencia.indexWhere(
                            (m) => m.nomeMateria == materia.nomeMateria);
                          if (index != -1) {
                            _materiasProficiencia[index] = MateriaProficiencia(
                              nomeMateria: materia.nomeMateria,
                              nivelProficiencia: value.toInt(),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  Text('Avançado'),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getNivelProficienciaLabel(int nivel) {
    switch (nivel) {
      case 1: return 'Iniciante';
      case 2: return 'Básico';
      case 3: return 'Intermediário';
      case 4: return 'Avançado';
      case 5: return 'Especialista';
      default: return 'Intermediário';
    }
  }

  Widget _buildPlanoGeradoIA() {
    if (_planoGeradoIA == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matérias prioritárias
          if (_planoGeradoIA!.containsKey('materiasPrioritarias')) ...[
            Text(
              'Matérias Prioritárias',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._buildMateriasPrioritarias(_planoGeradoIA!['materiasPrioritarias']),
            Divider(height: 24),
          ],

          // Cronograma semanal
          if (_planoGeradoIA!.containsKey('cronogramaSemanal')) ...[
            Text(
              'Cronograma Semanal Sugerido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._buildCronogramaSemanal(_planoGeradoIA!['cronogramaSemanal']),
            Divider(height: 24),
          ],

          // Recursos recomendados
          if (_planoGeradoIA!.containsKey('recursosRecomendados')) ...[
            Text(
              'Recursos Recomendados',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._buildRecursosRecomendados(_planoGeradoIA!['recursosRecomendados']),
            Divider(height: 24),
          ],

          // Dicas gerais
          if (_planoGeradoIA!.containsKey('dicasGerais')) ...[
            Text(
              'Dicas Gerais',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._buildDicasGerais(_planoGeradoIA!['dicasGerais']),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMateriasPrioritarias(List<dynamic> materias) {
    if (materias == null || materias.isEmpty) {
      return [Text('Nenhuma matéria prioritária encontrada')];
    }

    return materias.map<Widget>((materia) {
      final nome = materia['nome'] ?? 'Matéria sem nome';
      final peso = materia['peso'] ?? 1;
      final estrategia = materia['estrategia'];

      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nome,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: List.generate(
                    peso,
                    (index) => Icon(Icons.star, size: 16, color: Colors.amber),
                  ),
                ),
              ],
            ),
            if (estrategia != null && estrategia.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  estrategia,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildCronogramaSemanal(Map<String, dynamic>? cronograma) {
    if (cronograma == null || cronograma.isEmpty) {
      return [Text('Nenhum cronograma semanal encontrado')];
    }

    final diasSemana = {
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    return diasSemana.entries.map<Widget>((entry) {
      final dia = entry.key;
      final nomeDia = entry.value;
      final materias = cronograma[dia] ?? [];

      if (materias.isEmpty) {
        return SizedBox.shrink();
      }

      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomeDia,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...materias.map<Widget>((materia) {
              return Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('${materia['materia']} (${materia['horas']}h)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecursosRecomendados(List<dynamic>? recursos) {
    if (recursos == null || recursos.isEmpty) {
      return [Text('Nenhum recurso recomendado encontrado')];
    }

    return recursos.map<Widget>((recurso) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recurso['tipo'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (recurso['descricao'] != null)
                    Text(
                      recurso['descricao'],
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildDicasGerais(List<dynamic>? dicas) {
    if (dicas == null || dicas.isEmpty) {
      return [Text('Nenhuma dica geral encontrada')];
    }

    return dicas.map<Widget>((dica) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb, size: 16, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(child: Text(dica)),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _criarPlano() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final planoService = Provider.of<PlanoEstudoService>(context, listen: false);

        // Verificar se o usuário está autenticado
        final usuario = authService.currentUser;
        if (usuario == null) {
          setState(() {
            _errorMessage = 'Você precisa estar autenticado para criar um plano de estudo.';
            _isLoading = false;
          });
          return;
        }

        // Criar lista de recompensas
        final List<RecompensaConfig> recompensas = [];

        // Adicionar recompensas selecionadas das predefinidas
        for (final recompensa in _recompensasConfig) {
          recompensas.add(recompensa);
        }

        // Adicionar recompensas personalizadas
        for (final recompensa in _recompensasPersonalizadas) {
          recompensas.add(RecompensaConfig(
            tipoRecompensa: recompensa['tipo'],
            descricaoRecompensa: recompensa['nome'],
          ));
        }

        // Criar o plano de estudo
        final plano = await planoService.criarPlanoEstudo(
          usuario.id,
          widget.editalId,
          _cargosSelecionados,
          _dataInicio,
          _dataFim,
          _horasSemanais,
          _ferramentasSelecionadas,
          _materiasProficiencia,
          recompensas,
        );

        // Navegar para a tela de calendário
        Navigator.pushReplacementNamed(
          context,
          '/plano/calendario',
          arguments: plano.id,
        );

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plano de estudo criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Ocorreu um erro ao criar o plano de estudo: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

}
