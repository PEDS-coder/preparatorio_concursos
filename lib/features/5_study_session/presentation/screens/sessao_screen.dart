import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/data/models/cronograma_item.dart';
import '../../../../core/data/models/materia.dart';
import '../../../../core/data/models/assunto.dart';
import '../../../../core/services/document_classifier_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/modern_card.dart';

class SessaoScreen extends StatefulWidget {
  final String? itemId;

  const SessaoScreen({this.itemId});

  @override
  _SessaoScreenState createState() => _SessaoScreenState();
}

class _SessaoScreenState extends State<SessaoScreen> {
  bool _sessaoIniciada = false;
  DateTime? _horaInicio;
  DateTime? _horaFim;
  Timer? _timer;
  Duration _duracaoDecorrida = Duration.zero;

  // Controles para sessão livre
  final _materiaController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Campos adicionais para a sessão
  String? _materiaId;
  List<String> _assuntosSelecionados = [];
  String _tipoTimer = 'progressivo';

  // Informações do item do cronograma (se houver)
  CronogramaItem? _itemCronograma;

  // Variáveis para upload de documento
  File? _selectedFile;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileContent;
  bool _isProcessingFile = false;
  String _processingMessage = '';
  Map<String, dynamic>? _classificacao;
  List<Map<String, dynamic>>? _sugestoes;

  @override
  void initState() {
    super.initState();
    _carregarItemCronograma();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _materiaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _carregarItemCronograma() {
    if (widget.itemId != null) {
      final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
      final itens = planoService.cronogramaItems;

      for (final item in itens) {
        if (item.id == widget.itemId) {
          setState(() {
            _itemCronograma = item;
            _materiaController.text = item.nomeMateria;
          });
          break;
        }
      }
    }
  }

  // Selecionar arquivo
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'html'],
        withData: true, // Importante para web
      );

      if (result != null) {
        setState(() {
          _isProcessingFile = true;
          _processingMessage = 'Processando arquivo...';

          if (kIsWeb) {
            // No web, usamos os bytes do arquivo
            _fileBytes = result.files.single.bytes;
            _fileName = result.files.single.name;
            _selectedFile = null;
          } else {
            // Em plataformas nativas, usamos o caminho do arquivo
            if (result.files.single.path != null) {
              _selectedFile = File(result.files.single.path!);
              _fileName = result.files.single.name;
              _fileBytes = null;
            }
          }
        });

        // Processar o arquivo
        await _processFile();
      }
    } catch (e) {
      print('Erro ao selecionar arquivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessingFile = false;
      });
    }
  }

  // Processar arquivo
  Future<void> _processFile() async {
    if (_selectedFile == null && _fileBytes == null) {
      setState(() {
        _isProcessingFile = false;
      });
      return;
    }

    try {
      // Extrair texto do arquivo
      String texto;
      if (kIsWeb && _fileBytes != null) {
        // No web, convertemos os bytes para string
        texto = String.fromCharCodes(_fileBytes!);
      } else if (_selectedFile != null) {
        // Em plataformas nativas, lemos o arquivo
        texto = await _selectedFile!.readAsString();
      } else {
        throw Exception('Nenhum arquivo selecionado');
      }

      setState(() {
        _fileContent = texto;
        _processingMessage = 'Identificando matéria e assunto...';
      });

      // Identificar matéria e assunto
      final classifier = Provider.of<DocumentClassifierService>(context, listen: false);
      final classificacao = await classifier.identificarMateriaAssunto(texto);
      final sugestoes = await classifier.sugerirMateriasAssuntos(texto);

      // Encontrar matéria correspondente
      final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
      final materias = planoService.materias;

      String? materiaId;
      List<String> assuntoIds = [];

      // Buscar matéria pelo nome
      final materiaIdentificada = classificacao['materia'] as String;
      for (final materia in materias) {
        if (materia.nome.toLowerCase().contains(materiaIdentificada.toLowerCase()) ||
            materiaIdentificada.toLowerCase().contains(materia.nome.toLowerCase())) {
          materiaId = materia.id;
          _materiaController.text = materia.nome;

          // Buscar assuntos relacionados
          final assuntos = planoService.getAssuntosByMateria(materia.id);
          final assuntoIdentificado = classificacao['assunto'] as String;

          for (final assunto in assuntos) {
            if (assunto.nome.toLowerCase().contains(assuntoIdentificado.toLowerCase()) ||
                assuntoIdentificado.toLowerCase().contains(assunto.nome.toLowerCase())) {
              assuntoIds.add(assunto.id);
            }
          }

          break;
        }
      }

      setState(() {
        _classificacao = classificacao;
        _sugestoes = sugestoes.cast<Map<String, dynamic>>();
        _materiaId = materiaId;
        _assuntosSelecionados = assuntoIds;
        _isProcessingFile = false;

        // Se encontrou uma matéria, atualizar o campo
        if (materiaId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Matéria identificada: ${_materiaController.text}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (materiaIdentificada != 'Não identificado') {
          // Se não encontrou uma matéria correspondente, mas identificou algo
          _materiaController.text = materiaIdentificada;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Matéria identificada: $materiaIdentificada'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      });
    } catch (e) {
      print('Erro ao processar arquivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar arquivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessingFile = false;
      });
    }
  }

  void _iniciarSessao() {
    setState(() {
      _sessaoIniciada = true;
      _horaInicio = DateTime.now();
      _duracaoDecorrida = Duration.zero;
    });

    // Iniciar timer para atualizar a duração
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_horaInicio != null) {
        setState(() {
          _duracaoDecorrida = DateTime.now().difference(_horaInicio!);
        });
      }
    });
  }

  Future<void> _finalizarSessao() async {
    // Parar o timer
    _timer?.cancel();

    setState(() {
      _horaFim = DateTime.now();
    });

    // Verificar se a sessão durou pelo menos 1 minuto
    final duracaoMinutos = _duracaoDecorrida.inMinutes;
    if (duracaoMinutos < 1) {
      _showSessaoMuitoCurtaDialog();
      return;
    }

    // Salvar a sessão
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final sessaoService = Provider.of<SessaoEstudoService>(context, listen: false);
      final planoService = Provider.of<PlanoEstudoService>(context, listen: false);

      final usuario = authService.currentUser;
      if (usuario == null) {
        _showErroDialog('Você precisa estar autenticado para registrar uma sessão de estudo.');
        return;
      }

      // Registrar a sessão
      await sessaoService.addSessao(
        widget.itemId ?? 'plano_temp',
        _materiaId ?? 'materia_temp',
        _materiaController.text,
        _assuntosSelecionados,
        _horaInicio!,
        _horaFim!,
        ['livro', 'resumo'],
        _observacoesController.text.isEmpty ? null : _observacoesController.text,
        tipoTimer: _tipoTimer,
      );

      // Se for um item do cronograma, marcar como concluído
      if (widget.itemId != null) {
        await planoService.updateCronogramaItemStatus(widget.itemId!, StatusItem.concluido);
      }

      // Registrar atividade de gamificação
      // (Isso seria feito através do GamificacaoService em um app real)

      // Mostrar diálogo de sucesso
      _showSessaoConcluidaDialog(duracaoMinutos);
    } catch (e) {
      _showErroDialog('Ocorreu um erro ao salvar a sessão de estudo. Tente novamente.');
    }
  }

  void _cancelarSessao() {
    _timer?.cancel();
    setState(() {
      _sessaoIniciada = false;
      _horaInicio = null;
      _horaFim = null;
      _duracaoDecorrida = Duration.zero;
    });
  }

  void _showSessaoMuitoCurtaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sessão Muito Curta'),
        content: Text('A sessão de estudo durou menos de 1 minuto. Deseja continuar estudando?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelarSessao();
            },
            child: Text('Cancelar Sessão'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _iniciarSessao();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Continuar Estudando'),
          ),
        ],
      ),
    );
  }

  void _showSessaoConcluidaDialog(int duracaoMinutos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Sessão Concluída'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parabéns! Você estudou por $duracaoMinutos minutos.'),
            SizedBox(height: 16),
            Text(
              'Você ganhou ${duracaoMinutos} pontos de experiência!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fechar o diálogo
              Navigator.pop(context); // Voltar para a tela anterior
            },
            child: Text('Voltar ao Dashboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fechar o diálogo
              setState(() {
                _sessaoIniciada = false;
                _horaInicio = null;
                _horaFim = null;
                _duracaoDecorrida = Duration.zero;
                _observacoesController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Nova Sessão'),
          ),
        ],
      ),
    );
  }

  void _showErroDialog(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erro'),
        content: Text(mensagem),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDuracao(Duration duracao) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final horas = twoDigits(duracao.inHours);
    final minutos = twoDigits(duracao.inMinutes.remainder(60));
    final segundos = twoDigits(duracao.inSeconds.remainder(60));
    return '$horas:$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sessão de Estudo'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _sessaoIniciada ? _buildSessaoAtiva() : _buildIniciarSessao(),
    );
  }

  Widget _buildIniciarSessao() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            'Iniciar Sessão de Estudo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _itemCronograma != null
                ? 'Sessão planejada: ${_itemCronograma!.nomeMateria}'
                : 'Configure sua sessão de estudo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Divider(height: 32),

          // Informações da sessão
          if (_itemCronograma != null) ...[
            _buildInfoItem('Matéria', _itemCronograma!.nomeMateria),
            SizedBox(height: 8),
            _buildInfoItem('Atividade', _itemCronograma!.atividadeSugerida),
            SizedBox(height: 8),
            _buildInfoItem('Ferramenta', _itemCronograma!.ferramentaSugerida),
            SizedBox(height: 24),
          ],

          // Upload de documento para identificação automática
          if (_itemCronograma == null) ...[
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material de Estudo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),

                  // Área de upload de documento
                  GestureDetector(
                    onTap: _isProcessingFile ? null : _pickFile,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: (_selectedFile == null && _fileBytes == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Clique para selecionar um arquivo',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'PDF, DOCX, TXT, HTML',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                          : _isProcessingFile
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(_processingMessage),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _selectedFile != null
                                          ? Icons.description
                                          : Icons.description,
                                      size: 48,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _fileName ?? (_selectedFile?.path.split('/').last ?? 'Arquivo selecionado'),
                                      style: TextStyle(
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Campo de matéria (preenchido automaticamente após upload)
                  Text(
                    'Matéria',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _materiaController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Direito Constitucional',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Observações (para ambos os tipos de sessão)
          Text(
            'Observações (opcional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _observacoesController,
            decoration: InputDecoration(
              hintText: 'Ex: Estudar artigos 5º ao 17º da Constituição',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 32),

          // Botão de iniciar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_itemCronograma == null && _materiaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor, informe a matéria a ser estudada.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _iniciarSessao();
              },
              icon: Icon(Icons.play_arrow),
              label: Text('Iniciar Sessão de Estudo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ),

          // Dicas
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dicas para uma sessão produtiva:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                _buildDicaItem('Elimine distrações (silenciar notificações, afastar-se de ruídos)'),
                _buildDicaItem('Faça pausas curtas a cada 25-30 minutos de estudo intenso'),
                _buildDicaItem('Tenha água por perto para se manter hidratado'),
                _buildDicaItem('Ao final, revise brevemente o que aprendeu'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessaoAtiva() {
    return Column(
      children: [
        // Cabeçalho com cronometro
        Container(
          width: double.infinity,
          color: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                'Tempo de Estudo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 8),
              Text(
                _formatDuracao(_duracaoDecorrida),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Matéria: ${_materiaController.text}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // Conteúdo principal
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações da sessão
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes da Sessão',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInfoItem('Início', _formatHora(_horaInicio)),
                        SizedBox(height: 8),
                        if (_itemCronograma != null) ...[
                          _buildInfoItem('Atividade', _itemCronograma!.atividadeSugerida),
                          SizedBox(height: 8),
                          _buildInfoItem('Ferramenta', _itemCronograma!.ferramentaSugerida),
                          SizedBox(height: 8),
                        ],
                        _buildInfoItem('Observações', _observacoesController.text.isEmpty ? 'Nenhuma' : _observacoesController.text),
                      ],
                    ),
                  ),
                ),

                // Dicas durante o estudo
                SizedBox(height: 24),
                Text(
                  'Mantenha o Foco',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildFocusCard(
                  'Técnica Pomodoro',
                  'Estude por 25 minutos, faça uma pausa de 5 minutos e repita.',
                  Icons.timer,
                ),
                SizedBox(height: 12),
                _buildFocusCard(
                  'Anotações Ativas',
                  'Faça resumos ou mapas mentais enquanto estuda para melhor retenção.',
                  Icons.edit_note,
                ),
                SizedBox(height: 12),
                _buildFocusCard(
                  'Revise Periodicamente',
                  'A cada 20 minutos, revise rapidamente o que acabou de estudar.',
                  Icons.replay,
                ),
              ],
            ),
          ),
        ),

        // Botões de ação
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelarSessao,
                  icon: Icon(Icons.cancel),
                  label: Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _finalizarSessao,
                  icon: Icon(Icons.check_circle),
                  label: Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildDicaItem(String dica) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Expanded(child: Text(dica)),
        ],
      ),
    );
  }

  Widget _buildFocusCard(String title, String description, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHora(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
