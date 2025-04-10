import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/models/materia.dart';
import '../../../../core/data/models/assunto.dart';
import '../../../../core/data/models/sessao_estudo.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/modern_card.dart';

class IniciarSessaoScreen extends StatefulWidget {
  @override
  _IniciarSessaoScreenState createState() => _IniciarSessaoScreenState();
}

class _IniciarSessaoScreenState extends State<IniciarSessaoScreen> {
  // Referências aos serviços
  late PlanoEstudoService _planoService;
  late SessaoEstudoService _sessaoService;
  late AuthService _authService;
  
  // Estado da sessão
  String? _materiaIdSelecionada;
  List<String> _assuntosIdsSelecionados = [];
  List<String> _ferramentasSelecionadas = [];
  String _tipoTimer = 'progressivo';
  
  // Estado do timer
  bool _timerAtivo = false;
  DateTime? _horaInicio;
  DateTime? _horaFim;
  Duration _tempoDecorrido = Duration.zero;
  Duration _tempoDefinido = Duration(minutes: 30);
  Timer? _timer;
  
  // Controladores
  final _observacoesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _inicializarServicos();
  }
  
  void _inicializarServicos() {
    Future.microtask(() {
      _planoService = Provider.of<PlanoEstudoService>(context, listen: false);
      _sessaoService = Provider.of<SessaoEstudoService>(context, listen: false);
      _authService = Provider.of<AuthService>(context, listen: false);
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _observacoesController.dispose();
    super.dispose();
  }
  
  // Iniciar o timer
  void _iniciarTimer() {
    setState(() {
      _timerAtivo = true;
      _horaInicio = DateTime.now();
      
      if (_tipoTimer == 'regressivo') {
        _tempoDecorrido = _tempoDefinido;
      } else {
        _tempoDecorrido = Duration.zero;
      }
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_tipoTimer == 'progressivo') {
          _tempoDecorrido = Duration(
            seconds: DateTime.now().difference(_horaInicio!).inSeconds
          );
        } else {
          _tempoDecorrido = _tempoDefinido - Duration(
            seconds: DateTime.now().difference(_horaInicio!).inSeconds
          );
          
          // Verificar se o tempo acabou
          if (_tempoDecorrido.inSeconds <= 0) {
            _pararTimer();
          }
        }
      });
    });
  }
  
  // Parar o timer
  void _pararTimer() {
    _timer?.cancel();
    setState(() {
      _timerAtivo = false;
      _horaFim = DateTime.now();
    });
  }
  
  // Salvar a sessão de estudo
  Future<void> _salvarSessao() async {
    if (_materiaIdSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione uma matéria'))
      );
      return;
    }
    
    if (_assuntosIdsSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione pelo menos um assunto'))
      );
      return;
    }
    
    if (_horaInicio == null || _horaFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inicie e finalize o timer primeiro'))
      );
      return;
    }
    
    final usuario = _authService.currentUser;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado'))
      );
      return;
    }
    
    // Obter o plano ativo
    final planos = _planoService.getPlanosByUserId(usuario.id);
    if (planos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum plano de estudo ativo'))
      );
      return;
    }
    
    final planoAtivo = planos.first;
    
    // Obter a matéria selecionada
    final materiaSelecionada = _planoService.getMateriaById(_materiaIdSelecionada!);
    if (materiaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matéria não encontrada'))
      );
      return;
    }
    
    // Adicionar a sessão
    await _sessaoService.addSessao(
      planoAtivo.id,
      _materiaIdSelecionada!,
      materiaSelecionada.nome,
      _assuntosIdsSelecionados,
      _horaInicio!,
      _horaFim!,
      _ferramentasSelecionadas,
      _observacoesController.text,
      _tipoTimer,
    );
    
    // Marcar assuntos como estudados
    for (final assuntoId in _assuntosIdsSelecionados) {
      await _planoService.marcarAssuntoComoEstudado(assuntoId, true);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sessão de estudo salva com sucesso!'))
    );
    
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sessão de Estudo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PlanoEstudoService>(
        builder: (context, planoService, _) {
          // Obter o usuário atual
          final usuario = Provider.of<AuthService>(context).currentUser;
          
          // Obter o plano ativo
          final planos = usuario != null 
              ? planoService.getPlanosByUserId(usuario.id)
              : [];
          
          final planoAtivo = planos.isNotEmpty ? planos.first : null;
          
          // Obter matérias do plano
          final materias = planoAtivo != null 
              ? planoService.getMateriasByEditalAndCargo(planoAtivo.editalId, planoAtivo.cargoId)
              : [];
          
          // Obter assuntos da matéria selecionada
          final assuntos = _materiaIdSelecionada != null 
              ? planoService.getAssuntosByMateria(_materiaIdSelecionada!)
              : [];
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seleção de matéria
                        Text(
                          'Selecione a Matéria',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        _buildMateriaSelector(materias),
                        SizedBox(height: 24),
                        
                        // Seleção de assuntos
                        Text(
                          'Selecione os Assuntos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        _buildAssuntosSelector(assuntos),
                        SizedBox(height: 24),
                        
                        // Tipo de timer
                        Text(
                          'Tipo de Timer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        _buildTimerTypeSelector(),
                        SizedBox(height: 24),
                        
                        // Timer
                        Text(
                          'Timer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        _buildTimerWidget(),
                        SizedBox(height: 24),
                        
                        // Ferramentas utilizadas
                        Text(
                          'Ferramentas Utilizadas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        _buildFerramentasSelector(),
                        SizedBox(height: 24),
                        
                        // Observações
                        Text(
                          'Observações (opcional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        TextField(
                          controller: _observacoesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Digite suas observações sobre a sessão de estudo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            filled: true,
                            fillColor: AppTheme.darkCardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Botão de salvar
                SizedBox(height: 16),
                GradientButton(
                  text: 'SALVAR SESSÃO',
                  onPressed: _timerAtivo ? null : _salvarSessao,
                  gradient: AppTheme.primaryGradient,
                  icon: Icon(Icons.save, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Widget para seleção de matéria
  Widget _buildMateriaSelector(List<Materia> materias) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DropdownButtonFormField<String>(
          value: _materiaIdSelecionada,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            filled: true,
            fillColor: AppTheme.darkCardColor,
            hintText: 'Selecione uma matéria',
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          dropdownColor: AppTheme.darkCardColor,
          items: materias.map((materia) {
            return DropdownMenuItem<String>(
              value: materia.id,
              child: Text(
                materia.nome,
                style: TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _materiaIdSelecionada = value;
              _assuntosIdsSelecionados = []; // Limpar assuntos ao mudar de matéria
            });
          },
        ),
      ),
    );
  }
  
  // Widget para seleção de assuntos
  Widget _buildAssuntosSelector(List<Assunto> assuntos) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (assuntos.isEmpty)
              Center(
                child: Text(
                  _materiaIdSelecionada == null
                      ? 'Selecione uma matéria primeiro'
                      : 'Nenhum assunto disponível para esta matéria',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              )
            else
              ...assuntos.map((assunto) {
                return CheckboxListTile(
                  title: Text(
                    assunto.nome,
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _assuntosIdsSelecionados.contains(assunto.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _assuntosIdsSelecionados.add(assunto.id);
                      } else {
                        _assuntosIdsSelecionados.remove(assunto.id);
                      }
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
  
  // Widget para seleção do tipo de timer
  Widget _buildTimerTypeSelector() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(
                  'Progressivo',
                  style: TextStyle(color: Colors.white),
                ),
                value: 'progressivo',
                groupValue: _tipoTimer,
                onChanged: _timerAtivo ? null : (value) {
                  setState(() {
                    _tipoTimer = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(
                  'Regressivo',
                  style: TextStyle(color: Colors.white),
                ),
                value: 'regressivo',
                groupValue: _tipoTimer,
                onChanged: _timerAtivo ? null : (value) {
                  setState(() {
                    _tipoTimer = value!;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para o timer
  Widget _buildTimerWidget() {
    final String tempoFormatado = _formatarTempo(_tempoDecorrido);
    
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mostrar o tempo
            Text(
              tempoFormatado,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 16),
            
            // Controles do timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_tipoTimer == 'regressivo' && !_timerAtivo)
                  Expanded(
                    child: Slider(
                      value: _tempoDefinido.inMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '${_tempoDefinido.inMinutes} min',
                      onChanged: (value) {
                        setState(() {
                          _tempoDefinido = Duration(minutes: value.toInt());
                          _tempoDecorrido = _tempoDefinido;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                
                if (!_timerAtivo)
                  ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    label: Text('Iniciar'),
                    onPressed: _iniciarTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    icon: Icon(Icons.stop),
                    label: Text('Parar'),
                    onPressed: _pararTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para seleção de ferramentas
  Widget _buildFerramentasSelector() {
    final ferramentas = [
      {'id': 'flashcards', 'nome': 'Flashcards', 'icon': Icons.style},
      {'id': 'resumos', 'nome': 'Resumos', 'icon': Icons.description},
      {'id': 'questoes', 'nome': 'Questões', 'icon': Icons.quiz},
      {'id': 'mapas_mentais', 'nome': 'Mapas Mentais', 'icon': Icons.account_tree},
      {'id': 'livros', 'nome': 'Livros', 'icon': Icons.book},
      {'id': 'videos', 'nome': 'Vídeos', 'icon': Icons.video_library},
    ];
    
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ferramentas.map((ferramenta) {
            final selected = _ferramentasSelecionadas.contains(ferramenta['id']);
            
            return FilterChip(
              label: Text(
                ferramenta['nome'] as String,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade300,
                ),
              ),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _ferramentasSelecionadas.add(ferramenta['id'] as String);
                  } else {
                    _ferramentasSelecionadas.remove(ferramenta['id'] as String);
                  }
                });
              },
              avatar: Icon(
                ferramenta['icon'] as IconData,
                color: selected ? Colors.white : Colors.grey.shade300,
                size: 18,
              ),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.darkCardColor,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // Formatar o tempo para exibição
  String _formatarTempo(Duration duracao) {
    final horas = duracao.inHours.toString().padLeft(2, '0');
    final minutos = (duracao.inMinutes % 60).toString().padLeft(2, '0');
    final segundos = (duracao.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$horas:$minutos:$segundos';
  }
}
