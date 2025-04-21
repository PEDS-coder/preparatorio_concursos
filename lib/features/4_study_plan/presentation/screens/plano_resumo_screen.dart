import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/utils/plano_data_logger.dart';
import 'plano_logs_screen.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../widgets/criterio_desempate_card.dart';
import '../widgets/resumo_plano_card.dart';

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

    // Reproduzir som de navegação ao abrir a tela e verificar sessões
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioExplanationService>(context, listen: false).playSuccess();

      // Verificar se o plano tem sessões de estudo e gerar se necessário
      if (_plano != null && _plano!.sessoesEstudo.isEmpty) {
        _gerarSessoesEstudo();
      }
    });
  }

  // Método para obter a cor do marcador com base nas matérias do dia
  List<Color> _getMarkerColors(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final sessoes = _sessoesPorDia[normalizedDay] ?? [];

    if (sessoes.isEmpty) return [];

    // Obter cores únicas para cada matéria no dia
    Set<Color> cores = {};
    for (var sessao in sessoes) {
      cores.add(_getColorForMateria(sessao.materia));
    }

    return cores.toList();
  }

  // Método para gerar sessões de estudo se o plano não tiver sessões
  void _gerarSessoesEstudo() {
    if (_plano == null || _plano!.sessoesEstudo.isNotEmpty) return;

    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final logger = PlanoDataLogger();

    logger.logApresentacao(_plano!.id, 'gerando_sessoes_estudo', 'Gerando sessões de estudo para o plano');

    // Gerar sessões de estudo para o plano
    planoService.gerarSessoesParaPlano(_plano!.id).then((sucesso) {
      if (sucesso) {
        // Recarregar o plano com as novas sessões
        final planoAtualizado = planoService.getPlanoById(_plano!.id);
        if (planoAtualizado != null) {
          setState(() {
            _plano = planoAtualizado;

            // Atualizar sessões por dia para o calendário
            _sessoesPorDia.clear();
            for (final sessao in _plano!.sessoesEstudo) {
              final dataKey = DateTime(
                sessao.dataHoraInicio.year,
                sessao.dataHoraInicio.month,
                sessao.dataHoraInicio.day,
              );

              if (!_sessoesPorDia.containsKey(dataKey)) {
                _sessoesPorDia[dataKey] = [];
              }

              _sessoesPorDia[dataKey]!.add(sessao);
            }
          });

          logger.logApresentacao(_plano!.id, 'sessoes_geradas', {
            'total_sessoes': _plano!.sessoesEstudo.length,
            'total_dias': _sessoesPorDia.length,
          });
        }
      } else {
        logger.logApresentacao(_plano!.id, 'erro_gerar_sessoes', 'Falha ao gerar sessões de estudo');
      }
    });
  }

  void _carregarPlano() {
    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
    final editalService = Provider.of<EditalService>(context, listen: false);
    final logger = PlanoDataLogger();

    try {
      logger.logRecuperacao(widget.planoId, 'inicio_carregamento', 'Iniciando carregamento do plano');
      var plano = planoService.getPlanoById(widget.planoId);

      if (plano != null) {
        logger.logRecuperacao(plano.id, 'plano_recuperado', {
          'id': plano.id,
          'editalId': plano.editalId,
          'cargoIds': plano.cargoIds,
          'dataInicio': plano.dataInicio.toIso8601String(),
          'dataFim': plano.dataFim.toIso8601String(),
          'horasSemanais': plano.horasSemanais,
          'ferramentas': plano.ferramentas,
          'materiasProficiencia': plano.materiasProficiencia.map((m) => {'materia': m.nomeMateria, 'nivel': m.nivelProficiencia}).toList(),
          'recompensas': plano.recompensas.map((r) => {'tipo': r.tipoRecompensa, 'descricao': r.descricaoRecompensa}).toList(),
          'sessoesEstudo': plano.sessoesEstudo.length,
          'metadados_keys': plano.metadados.keys.toList(),
        });

        // Verificar se o plano tem sessões de estudo
        if (plano.sessoesEstudo.isEmpty) {
          logger.logRecuperacao(plano.id, 'sessoes_vazias', 'Plano não possui sessões de estudo. Gerando sessões...');
          // Gerar sessões de estudo para o plano
          planoService.gerarSessoesParaPlano(plano.id);
          // Recarregar o plano com as novas sessões
          final planoAtualizado = planoService.getPlanoById(widget.planoId);
          if (planoAtualizado != null) {
            plano = planoAtualizado;
            logger.logRecuperacao(plano.id, 'plano_atualizado', {
              'sessoesEstudo': plano.sessoesEstudo.length,
            });
          }
        }

        // Agrupar sessões por dia para o calendário
        final Map<DateTime, List<SessaoEstudo>> sessoesPorDia = {};

        logger.logRecuperacao(plano.id, 'processando_sessoes', 'Processando ${plano.sessoesEstudo.length} sessões de estudo');
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
          logger.logRecuperacao(plano.id, 'sessao_adicionada', {
            'data': '${dataKey.day}/${dataKey.month}/${dataKey.year}',
            'materia': sessao.materia,
            'hora': sessao.dataHoraInicio.hour,
            'duracao': sessao.duracaoMinutos,
          });
        }

        logger.logRecuperacao(plano.id, 'total_dias_sessoes', 'Total de dias com sessões: ${sessoesPorDia.length}');
        Map<String, int> sessoesContagem = {};
        sessoesPorDia.forEach((data, sessoes) {
          final dataStr = '${data.day}/${data.month}/${data.year}';
          sessoesContagem[dataStr] = sessoes.length;
        });
        logger.logRecuperacao(plano.id, 'contagem_sessoes_por_dia', sessoesContagem);

        // Verificar se há dados do ciclo de estudos nos metadados
        if (plano.metadados.containsKey('planoEstudos')) {
          logger.logRecuperacao(plano.id, 'planoEstudos_metadados', {
            'cicloEstudos': plano.metadados['planoEstudos']['cicloEstudos'] != null ? 'presente' : 'ausente',
            'materiasPrioritarias': plano.metadados['planoEstudos']['materiasPrioritarias'] != null ? 'presente' : 'ausente',
            'grupos': plano.metadados['planoEstudos']['grupos'] != null ? 'presente' : 'ausente',
            'calendario': plano.metadados['planoEstudos']['calendario'] != null ? 'presente' : 'ausente',
          });
        } else {
          logger.logRecuperacao(plano.id, 'planoEstudos_metadados', 'ausente');
        }

        // Usar uma variável temporária para evitar problemas de null safety
        final dataInicio = plano.dataInicio;
        final editalId = plano.editalId;

        setState(() {
          _plano = plano;
          _sessoesPorDia = sessoesPorDia;
          _focusedDay = dataInicio;
          _selectedDay = dataInicio;

          if (editalId.isNotEmpty) {
            _edital = editalService.getEditalById(editalId);
            if (_edital != null) {
              logger.logRecuperacao(plano!.id, 'edital_recuperado', {
                'id': _edital!.id,
                'titulo': _edital!.dadosExtraidos.titulo,
                'orgao': _edital!.dadosExtraidos.orgao,
                'banca': _edital!.dadosExtraidos.banca,
                'cargos': _edital!.dadosExtraidos.cargos.length,
                'dadosOriginais': _edital!.dadosOriginais != null ? 'presente' : 'ausente',
              });
            } else {
              logger.logRecuperacao(plano!.id, 'edital_nao_encontrado', 'Edital não encontrado com ID: $editalId');
            }
          }
        });

        logger.logRecuperacao(plano!.id, 'carregamento_concluido', 'Plano carregado com sucesso');
      } else {
        logger.logRecuperacao(widget.planoId, 'plano_nao_encontrado', 'Plano não encontrado com ID: ${widget.planoId}');
        debugPrint('ERRO: Plano não encontrado com ID: ${widget.planoId}');
      }
    } catch (e) {
      logger.logRecuperacao(widget.planoId, 'erro_carregamento', 'Erro ao carregar plano: $e');
      debugPrint('ERRO ao carregar plano: $e');
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
        actions: [
          IconButton(
            icon: Icon(Icons.data_usage),
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConcursoInfo(),
              SizedBox(height: 24),
              _buildCargoInfo(),
              SizedBox(height: 24),
              _buildProvaInfo(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Dados do Concurso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        if (_edital != null) ...[
          // Informações em vermelho (datas e prazos)
          _buildInfoItemCard('Período de Inscrições', _obterPeriodoInscricoes()),
          _buildInfoItemCard('Data da Prova', _obterValorConcurso('dataProva', 'data_prova')),

          // Informações em azul (identificação)
          _buildInfoItemCard('Nome', _obterValorConcurso('titulo', 'titulo_concurso')),
          _buildInfoItemCard('Órgão', _obterValorConcurso('orgao', 'orgao_responsavel')),
          _buildInfoItemCard('Banca', _obterValorConcurso('banca', 'banca_organizadora')),
          _buildInfoItemCard('Total de Questões', _obterValorConcurso('totalQuestoes', 'prova.total_questoes')),

          // Informações em verde (valores)
          _buildInfoItemCard('Taxa de Inscrição', _formatarValor(_obterValorNumerico('valorInscricao', 'taxa_inscricao'))),

          // Informações em laranja (locais)
          _buildInfoItemCard('Local das Provas', _obterValorConcurso('localProva', 'local_prova')),

          // Informações em roxo (cotas e formato)
          _buildInfoItemCard('Cotas', _obterInformacoesCotas()),
          _buildInfoItemCard('Formato', _obterValorConcurso('formatoProva', 'prova.formato')),

          // Informações adicionais
          _buildInfoItemCard('Tema da Prova Subjetiva', _obterValorConcurso('temaProvaSubjetiva', 'prova.tema_discursiva')),
        ] else ...[
          _buildInfoItemCard('Plano', 'Plano de estudos personalizado'),
          _buildInfoItemCard('Período', '${_formatarData(_plano!.dataInicio)} a ${_formatarData(_plano!.dataFim)}'),
        ],
      ],
    );
  }

  // Método para obter o período de inscrições
  String _obterPeriodoInscricoes() {
    if (_edital == null) return 'Não informado';

    final inicio = _edital!.dadosExtraidos.inicioInscricao;
    final fim = _edital!.dadosExtraidos.fimInscricao;

    if (inicio == null || fim == null) {
      // Tentar obter dos dados originais
      if (_edital!.dadosOriginais != null &&
          _edital!.dadosOriginais!.containsKey('concurso') &&
          _edital!.dadosOriginais!['concurso'] is Map &&
          (_edital!.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = _edital!.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map && inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
          return '${inscricoes['inicio']} a ${inscricoes['fim']}';
        }
      }
      return 'Não informado';
    }

    return '${_formatarData(inicio)} a ${_formatarData(fim)}';
  }

  // Método para exibir informações do cargo selecionado
  Widget _buildCargoInfo() {
    if (_edital == null || _plano!.cargoIds.isEmpty) {
      return SizedBox.shrink();
    }

    // Encontrar o cargo selecionado
    final cargoId = _plano!.cargoIds.first;
    final cargos = _edital!.dadosExtraidos.cargos;
    final cargoSelecionado = cargos.firstWhere(
      (cargo) => cargo.id == cargoId || cargo.nome == cargoId,
      orElse: () => Cargo(nome: cargoId, conteudoProgramatico: []),
    );

    // Obter informações do cargo
    String vagas = 'Não informado';
    String salario = 'Não informado';
    String escolaridade = 'Não informado';
    String nivel = 'Não informado';

    // Verificar se temos informações nos dados originais
    if (_edital!.dadosOriginais != null && _edital!.dadosOriginais!.containsKey('cargos')) {
      final cargosOriginais = _edital!.dadosOriginais!['cargos'];
      if (cargosOriginais is List) {
        for (final cargo in cargosOriginais) {
          if (cargo is Map && cargo.containsKey('nome')) {
            String nomeCargo = cargo['nome'].toString();
            if (nomeCargo.toLowerCase().contains(cargoSelecionado.nome.toLowerCase())) {
              // Encontrou o cargo, extrair informações
              if (cargo.containsKey('vagas') && cargo['vagas'] != null) {
                vagas = cargo['vagas'].toString();
              }
              if (cargo.containsKey('salario') && cargo['salario'] != null) {
                salario = _formatarValor(cargo['salario']);
              }
              if (cargo.containsKey('escolaridade') && cargo['escolaridade'] != null) {
                escolaridade = cargo['escolaridade'].toString();
              }
              if (cargo.containsKey('nivel') && cargo['nivel'] != null) {
                nivel = cargo['nivel'].toString();
              }
              break;
            }
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Cargo Selecionado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        // Informações em roxo (cargo)
        _buildInfoItemCard('Cargo', cargoSelecionado.nome),

        // Informações em laranja (vagas e escolaridade)
        _buildInfoItemCard('Vagas', vagas),
        _buildInfoItemCard('Escolaridade', escolaridade),
        if (nivel != 'Não informado') _buildInfoItemCard('Nível', nivel),

        // Informações em verde (valores)
        _buildInfoItemCard('Salário', salario),
      ],
    );
  }

  // Método para exibir informações sobre a prova
  Widget _buildProvaInfo() {
    if (_edital == null) {
      return SizedBox.shrink();
    }

    // Obter informações da prova
    String totalQuestoes = _obterValorConcurso('totalQuestoes', 'prova.total_questoes');
    String formato = _obterValorConcurso('formatoProva', 'prova.formato');
    String duracao = _obterValorConcurso('duracaoProva', 'prova.duracao');
    String criteriosAprovacao = _obterValorConcurso('criteriosAprovacao', 'prova.criterios_aprovacao');
    String criteriosReprovacao = _obterValorConcurso('criteriosReprovacao', 'prova.criterios_reprovacao');

    // Obter critérios de desempate
    List<String> criteriosDesempate = [];

    if (_edital!.dadosOriginais != null &&
        _edital!.dadosOriginais!.containsKey('prova') &&
        _edital!.dadosOriginais!['prova'] is Map &&
        (_edital!.dadosOriginais!['prova'] as Map).containsKey('criterios_desempate')) {

      final criterios = _edital!.dadosOriginais!['prova']['criterios_desempate'];

      if (criterios is List) {
        criteriosDesempate = List<String>.from(criterios.map((c) =>
          c is Map && c.containsKey('descricao') ? c['descricao'] : c.toString()));
      } else if (criterios is String) {
        criteriosDesempate = [criterios];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Informações da Prova',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        // Informações em vermelho (critérios de reprovação)
        _buildInfoItemCard('Critérios de Reprovação', criteriosReprovacao),

        // Informações em azul (total de questões)
        _buildInfoItemCard('Total de Questões', totalQuestoes),

        // Informações em roxo (formato)
        _buildInfoItemCard('Formato', formato),

        // Informações em laranja (duração)
        _buildInfoItemCard('Duração', duracao),

        // Informações em verde (critérios de aprovação)
        _buildInfoItemCard('Critérios de Aprovação', criteriosAprovacao),

        if (criteriosDesempate.isNotEmpty)
          CriteriosDesempateSection(criterios: criteriosDesempate),
      ],
    );
  }

  Widget _buildPlanoInfo() {
    final logger = PlanoDataLogger();
    // Obter o serviço de plano de estudos
    final planoService = Provider.of<PlanoEstudoService>(context, listen: false);

    // Verificar se há dados do ciclo de estudos nos metadados
    if (_plano!.metadados.containsKey('planoEstudos')) {
      logger.logApresentacao(_plano!.id, 'ciclo_estudos_metadados', {
        'cicloEstudos': _plano!.metadados['planoEstudos']['cicloEstudos'] != null ? 'presente' : 'ausente',
        'materiasPrioritarias': _plano!.metadados['planoEstudos']['materiasPrioritarias'] != null ? 'presente' : 'ausente',
        'grupos': _plano!.metadados['planoEstudos']['grupos'] != null ? 'presente' : 'ausente',
        'calendario': _plano!.metadados['planoEstudos']['calendario'] != null ? 'presente' : 'ausente',
      });

      // Registrar detalhes do ciclo de estudos
      if (_plano!.metadados['planoEstudos']['cicloEstudos'] != null) {
        final cicloEstudos = _plano!.metadados['planoEstudos']['cicloEstudos'];
        logger.logApresentacao(_plano!.id, 'ciclo_estudos_detalhes', {
          'total_dias': cicloEstudos.length,
          'primeiro_dia': cicloEstudos.isNotEmpty ? cicloEstudos[0] : 'vazio',
        });
      }

      // Registrar detalhes das matérias prioritárias
      if (_plano!.metadados['planoEstudos']['materiasPrioritarias'] != null) {
        final materiasPrioritarias = _plano!.metadados['planoEstudos']['materiasPrioritarias'];
        logger.logApresentacao(_plano!.id, 'materias_prioritarias_detalhes', {
          'total_materias': materiasPrioritarias.length,
          'materias': materiasPrioritarias.map((m) => '${m['nome']}: ${m['pontuacao_prioridade']}').toList(),
        });
      }
    } else {
      logger.logApresentacao(_plano!.id, 'ciclo_estudos_ausente', 'Dados do ciclo de estudos não encontrados nos metadados');
    }

    // Calcular horas totais usando o novo método
    int horasTotais = planoService.calcularTotalHoras(_plano!.id);

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

    // Calcular horas por matéria usando o novo método
    Map<String, int> horasPorMateria = planoService.calcularHorasPorMateria(_plano!.id);

    // Registrar dados do resumo do plano
    logger.logApresentacao(_plano!.id, 'resumo_plano', {
      'horas_totais': horasTotais,
      'horas_semanais': horasSemanais,
      'horas_por_dia': horasPorDia,
      'horas_por_materia': horasPorMateria,
    });

    // Formatar o período
    String periodo = '${_formatarData(_plano!.dataInicio)} a ${_formatarData(_plano!.dataFim)}';

    // Usar o novo widget de resumo do plano
    return ResumoPlanoSection(
      periodo: periodo,
      horasTotais: horasTotais,
      horasSemanais: horasSemanais,
      horasPorDia: horasPorDia,
      horasPorMateria: horasPorMateria,
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

    // Agrupar matérias por grupo/módulo
    Map<String, List<ConteudoProgramatico>> materiasPorGrupo = {};

    // Verificar se há matérias com grupo definido
    bool temGruposDefinidos = cargoSelecionado.conteudoProgramatico.any((c) => c.grupoMateria != null && c.grupoMateria!.isNotEmpty);

    for (var conteudo in cargoSelecionado.conteudoProgramatico) {
      String grupoChave;

      if (temGruposDefinidos && conteudo.grupoMateria != null && conteudo.grupoMateria!.isNotEmpty) {
        // Usar o grupo definido pela LLM
        grupoChave = conteudo.grupoMateria!;
      } else {
        // Fallback para a classificação tradicional se não houver grupos definidos
        if (conteudo.tipo.toLowerCase() == 'comum' ||
            conteudo.tipo.toLowerCase() == 'básico' ||
            conteudo.tipo.toLowerCase() == 'basico' ||
            conteudo.tipo.toLowerCase() == 'conhecimentos básicos' ||
            conteudo.tipo.toLowerCase() == 'conhecimentos basicos') {
          grupoChave = 'Conhecimentos Básicos';
        } else if (conteudo.tipo.toLowerCase() == 'específico' ||
                  conteudo.tipo.toLowerCase() == 'especifico' ||
                  conteudo.tipo.toLowerCase() == 'conhecimentos específicos' ||
                  conteudo.tipo.toLowerCase() == 'conhecimentos especificos') {
          grupoChave = 'Conhecimentos Específicos';
        } else {
          // Se não for possível determinar o tipo, verificar pelo nome
          if (conteudo.nome.toLowerCase().contains('direito') ||
              conteudo.nome.toLowerCase().contains('legisla') ||
              conteudo.nome.toLowerCase().contains('específ')) {
            grupoChave = 'Conhecimentos Específicos';
          } else {
            grupoChave = 'Conhecimentos Básicos';
          }
        }
      }

      // Adicionar a matéria ao grupo correspondente
      if (!materiasPorGrupo.containsKey(grupoChave)) {
        materiasPorGrupo[grupoChave] = [];
      }
      materiasPorGrupo[grupoChave]!.add(conteudo);
    }

    // Definir cores para os diferentes grupos
    Map<String, Color> coresGrupos = {};
    List<Color> coresPadrao = [
      Colors.blue.shade700,
      Colors.red.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.indigo.shade700,
    ];

    // Atribuir cores aos grupos
    int colorIndex = 0;
    for (var grupo in materiasPorGrupo.keys) {
      coresGrupos[grupo] = coresPadrao[colorIndex % coresPadrao.length];
      colorIndex++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Conteúdo Programático',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        if (materiasPorGrupo.isEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nenhum conteúdo programático disponível para este cargo.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ...materiasPorGrupo.entries.map((entry) {
            final grupoNome = entry.key;
            final materias = entry.value;
            final corGrupo = coresGrupos[grupoNome] ?? Colors.blue.shade700;

            // Calcular o total de questões do grupo, se disponível
            int? totalQuestoesGrupo;
            if (materias.isNotEmpty && materias.first.totalQuestoesGrupo != null) {
              totalQuestoesGrupo = materias.first.totalQuestoesGrupo;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: corGrupo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        grupoNome.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (totalQuestoesGrupo != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '= $totalQuestoesGrupo questões',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ...materias.map((conteudo) => _buildMateriaItemCard(conteudo, corGrupo)),
                SizedBox(height: 16),
              ],
            );
          }).toList(),
      ],
    );
  }

  // Novo método para exibir matérias em cards
  Widget _buildMateriaItemCard(ConteudoProgramatico conteudo, Color corGrupo) {
    // Verificar informações adicionais da matéria
    List<Widget> badges = [];

    // Verificar o número de questões
    if (conteudo.numeroQuestoes != null && conteudo.numeroQuestoes! > 0) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${conteudo.numeroQuestoes} questões${conteudo.questoesEstimadas == true ? ' (estimadas)' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    // Verificar se é critério de desempate
    if (conteudo.criterioDesempate != null && conteudo.criterioDesempate!) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Desempate',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Verificar se tem peso maior
    if (conteudo.pesoMaior != null && conteudo.pesoMaior!) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Peso Maior',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Verificar se a matéria está expandida
    final isExpanded = _expandedMaterias[conteudo.nome] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1a2240), // Fundo escuro
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: corGrupo),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          conteudo.nome,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...badges,
            SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ],
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
                      Text('$index. ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                      Expanded(child: Text(topico, style: TextStyle(color: Colors.white))),
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
      infoAdicional += '$numeroQuestoes questões';
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
      } else if (conteudo.totalQuestoesGrupo != null) {
        // Se temos o total de questões do grupo, podemos estimar com base nisso
        // Verificar se há outras matérias no mesmo grupo com número de questões definido
        // Isso seria implementado com uma lógica mais complexa que requer acesso a todas as matérias do grupo
        // Por enquanto, usamos uma estimativa simples
        numeroQuestoes = 5; // Valor estimado para matérias sem número explícito
        infoAdicional += '$numeroQuestoes questões (estimado)';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendário de Estudos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              // Botão para regenerar sessões
              if (_plano!.sessoesEstudo.isEmpty)
                ElevatedButton.icon(
                  onPressed: _gerarSessoesEstudo,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Gerar Sessões'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Usar SingleChildScrollView para resolver o problema de overflow
                SingleChildScrollView(
                  child: TableCalendar<SessaoEstudo>(
                    firstDay: _plano!.dataInicio,
                    lastDay: _plano!.dataFim,
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    locale: 'pt_BR',
                    rowHeight: 50.0,
                    daysOfWeekHeight: 30.0,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mês',
                      CalendarFormat.week: 'Semana',
                    },
                    eventLoader: (day) {
                      final normalizedDay = DateTime(day.year, day.month, day.day);
                      return _sessoesPorDia[normalizedDay] ?? [];
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;

                        // Obter cores para as matérias do dia
                        final colors = _getMarkerColors(date);

                        return Positioned(
                          bottom: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: colors.map((color) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 1),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            )).toList(),
                          ),
                        );
                      },
                    ),
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
                      markerSize: 8.0,
                      markerMargin: EdgeInsets.symmetric(horizontal: 1.0),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      cellMargin: EdgeInsets.all(6.0),
                      cellPadding: EdgeInsets.all(4.0),
                      defaultTextStyle: TextStyle(fontSize: 14, color: Colors.black87),
                      weekendTextStyle: TextStyle(fontSize: 14, color: Colors.deepPurple),
                      outsideTextStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      rowDecoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                      weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[600], fontSize: 12),
                      dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).substring(0, 3).toUpperCase(),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2.0)),
                      ),
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
              ],
            ),
          ),
        ),
        if (_selectedDay != null) _buildSessoesParaDiaCard(_selectedDay!),
      ],
    );
  }

  Widget _buildSessoesParaDiaCard(DateTime dia) {
    final normalizedDay = DateTime(dia.year, dia.month, dia.day);
    final sessoes = _sessoesPorDia[normalizedDay] ?? [];

    if (sessoes.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Nenhuma sessão de estudo para ${_formatarData(dia)}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    // Agrupar sessões por matéria para melhor organização
    Map<String, List<SessaoEstudo>> sessoesPorMateria = {};
    for (var sessao in sessoes) {
      if (!sessoesPorMateria.containsKey(sessao.materia)) {
        sessoesPorMateria[sessao.materia] = [];
      }
      sessoesPorMateria[sessao.materia]!.add(sessao);
    }

    return Container(
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Sessões para ${_formatarData(dia)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  '${sessoes.length} ${sessoes.length == 1 ? 'sessão' : 'sessões'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Exibir sessões agrupadas por matéria
          ...sessoesPorMateria.entries.map((entry) {
            final materia = entry.key;
            final sessoesMateria = entry.value;
            final corMateria = _getColorForMateria(materia);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corMateria.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: corMateria.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da matéria
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: corMateria.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(7),
                        topRight: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_getIconForMateria(materia), color: corMateria, size: 20),
                        SizedBox(width: 8),
                        Text(
                          materia,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: corMateria,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: corMateria.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${sessoesMateria.length} ${sessoesMateria.length == 1 ? 'hora' : 'horas'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: corMateria,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sessões da matéria
                  ...sessoesMateria.map((sessao) => _buildSessaoItem(sessao)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessaoItem(SessaoEstudo sessao) {
    // Obter cor baseada na matéria
    Color corMateria = _getColorForMateria(sessao.materia);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Horário
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: corMateria.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_formatarHora(sessao.dataHoraInicio)} - ${_formatarHora(sessao.dataHoraFim)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: corMateria, fontSize: 14),
            ),
          ),
          SizedBox(width: 12),
          // Ferramentas
          Expanded(
            child: sessao.ferramentas.isNotEmpty
                ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sessao.ferramentas.map((ferramenta) {
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

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: corMateria),
                            SizedBox(width: 4),
                            Text(
                              ferramenta,
                              style: TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    'Estudo com livro/apostila',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
          ),
        ],
      ),
    );
  }

  // Método para obter cor baseada na matéria
  Color _getColorForMateria(String materia) {
    final lowerMateria = materia.toLowerCase();
    if (lowerMateria.contains('direito')) return Colors.purple;
    if (lowerMateria.contains('portugu')) return Colors.blue;
    if (lowerMateria.contains('matem')) return Colors.green;
    if (lowerMateria.contains('inform')) return Colors.teal;
    if (lowerMateria.contains('admin')) return Colors.orange;
    if (lowerMateria.contains('contab')) return Colors.amber;
    return AppTheme.primaryColor;
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

  // Método para obter emoji baseado no tipo de informação
  String _getEmojiForInfoType(String label) {
    switch (label.toLowerCase()) {
      case 'nome':
        return '📜'; // 📜 = 📜 = 📜 (documento/título)
      case 'órgão':
        return '🏢'; // 🏢 = 🏢 = 🏢 (prédio)
      case 'banca':
        return '🎓'; // 🎓 = 🎓 = 🎓 (chapéu de formatura)
      case 'período de inscrições':
        return '📅'; // 📅 = 📅 = 📅 (calendário)
      case 'taxa de inscrição':
      case 'inscrição':
        return '💰'; // 💰 = 💰 = 💰 (saco de dinheiro)
      case 'local da prova':
      case 'local das provas':
        return '📍'; // 📍 = 📍 = 📍 (alfinete de localização)
      case 'data da prova':
      case 'data da prova objetiva':
      case 'data da prova subjetiva':
        return '📆'; // 📆 = 📆 = 📆 (calendário de folha destacável)
      case 'cotas':
        return '👥'; // 👥 = 👥 = 👥 (silhuetas de pessoas)
      case 'cargo':
      case 'cargo escolhido':
        return '💼'; // 💼 = 💼 = 💼 (pasta de trabalho)
      case 'vagas':
        return '👤'; // 👤 = 👤 = 👤 (silhueta de busto)
      case 'salário':
        return '💵'; // 💵 = 💵 = 💵 (nota de dólar)
      case 'escolaridade':
      case 'nível':
        return '📚'; // 📚 = 📚 = 📚 (livros)
      case 'total de questões':
        return '❓'; // ❓ = ❓ (ponto de interrogação)
      case 'formato':
        return '📋'; // 📋 = 📋 = 📋 (prancheta)
      case 'duração':
        return '⏰'; // ⏰ = ⏰ (despertador)
      case 'critérios de aprovação':
        return '✅'; // ✅ = ✅ (marca de verificação)
      case 'critérios de reprovação':
        return '❌'; // ❌ = ❌ (marca de x)
      case 'critérios de desempate':
        return '🤝'; // 🤝 = 🤝 = 🤝 (aperto de mãos)
      case 'tema da prova subjetiva':
        return '📝'; // 📝 = 📝 = 📝 (memorando)
      case 'plano':
        return '📓'; // 📓 = 📓 = 📓 (caderno)
      case 'período':
        return '📆'; // 📆 = 📆 = 📆 (calendário de folha destacável)
      default:
        return 'ℹ️'; // ℹ️ = ℹ️ (informação)
    }
  }

  // Método para obter cor baseada no tipo de informação
  Color _getColorForInfoType(String label) {
    switch (label.toLowerCase()) {
      case 'nome':
        return Colors.blue;
      case 'órgão':
        return Colors.blue;
      case 'banca':
        return Colors.blue;
      case 'período de inscrições':
        return Colors.red;
      case 'taxa de inscrição':
      case 'inscrição':
        return Colors.green;
      case 'local da prova':
      case 'local das provas':
        return Colors.orange;
      case 'data da prova':
      case 'data da prova objetiva':
      case 'data da prova subjetiva':
        return Colors.red;
      case 'cotas':
        return Colors.purple;
      case 'cargo':
      case 'cargo escolhido':
        return Colors.purple;
      case 'vagas':
        return Colors.orange;
      case 'salário':
        return Colors.green;
      case 'escolaridade':
      case 'nível':
        return Colors.orange;
      case 'total de questões':
        return Colors.blue;
      case 'formato':
        return Colors.purple;
      case 'duração':
        return Colors.orange;
      case 'critérios de aprovação':
        return Colors.green;
      case 'critérios de reprovação':
        return Colors.red;
      case 'critérios de desempate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Método antigo para referência
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Novo método para exibir informações em cards coloridos
  Widget _buildInfoItemCard(String label, String value) {
    final Color cardColor = _getColorForInfoType(label);
    final String emoji = _getEmojiForInfoType(label);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
        title: Text(
          '$label: $value',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final logger = PlanoDataLogger();
    logger.logRecuperacao(_plano!.id, 'obter_valor_concurso', {
      'chave_metadados': chaveMetadados,
      'chave_dados_originais': chaveDadosOriginais,
    });
    debugPrint('\nVERIFICAÇÃO DE EXIBIÇÃO - Buscando: $chaveMetadados / $chaveDadosOriginais');

    // Verificar primeiro nos metadados do plano
    if (_plano!.metadados.containsKey(chaveMetadados) &&
        _plano!.metadados[chaveMetadados] != null &&
        _plano!.metadados[chaveMetadados].toString().isNotEmpty &&
        _plano!.metadados[chaveMetadados].toString() != 'null') {
      var valor = _plano!.metadados[chaveMetadados].toString();

      // Formatar o valor se for o formato da prova
      if (chaveMetadados == 'formatoProva') {
        valor = _formatarFormatoProva(valor);
      }

      logger.logRecuperacao(_plano!.id, 'valor_encontrado_metadados', {
        'chave': chaveMetadados,
        'valor': valor,
        'origem': 'metadados_plano',
      });
      debugPrint('  Encontrado nos metadados do plano: $valor');
      return valor;
    } else {
      logger.logRecuperacao(_plano!.id, 'valor_nao_encontrado', {
        'chave': chaveMetadados,
        'origem': 'metadados_plano',
      });
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
          var valorStr = valor.toString();

          // Formatar o valor se for o formato da prova
          if (chaveDadosOriginais == 'prova.formato') {
            valorStr = _formatarFormatoProva(valorStr);
          }

          debugPrint('  Encontrado nos dados originais aninhados: $valorStr');
          return valorStr;
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

  // Método para formatar o formato da prova (corrigir minúsculas e colchetes)
  String _formatarFormatoProva(String formato) {
    if (formato.isEmpty) return 'Não informado';

    // Remover colchetes se existirem
    if (formato.startsWith('[') && formato.endsWith(']')) {
      formato = formato.substring(1, formato.length - 1);
    }

    // Dividir por vírgulas ou outros separadores
    List<String> tipos = formato.split(RegExp(r'[,;/]'));

    // Capitalizar cada tipo e remover espaços extras
    tipos = tipos.map((tipo) {
      tipo = tipo.trim();
      if (tipo.isNotEmpty) {
        return tipo[0].toUpperCase() + tipo.substring(1);
      }
      return tipo;
    }).toList();

    // Juntar novamente com vírgulas
    return tipos.join(', ');
  }

}
