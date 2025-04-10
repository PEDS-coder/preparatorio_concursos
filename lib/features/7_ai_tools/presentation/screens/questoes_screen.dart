import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../../core/services/document_classifier_service.dart';

class QuestoesScreen extends StatefulWidget {
  @override
  _QuestoesScreenState createState() => _QuestoesScreenState();
}

class _QuestoesScreenState extends State<QuestoesScreen> {
  // Variáveis para upload de documento
  File? _selectedFile;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileContent;
  bool _isProcessingFile = false;
  String _processingMessage = '';
  Map<String, dynamic>? _classificacao;
  List<Map<String, dynamic>>? _sugestoes;

  // Controladores para configuração das questões
  final _materiaController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '5');

  bool _isLoading = false;
  String? _resultado;
  String? _errorMessage;
  String _dificuldade = 'média'; // fácil, média, difícil

  // Dados para identificação automática
  String? _materiaId;
  String? _assuntoId;

  @override
  void dispose() {
    _materiaController.dispose();
    _quantidadeController.dispose();
    super.dispose();
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
        _assuntoId = assuntoIds.isNotEmpty ? assuntoIds.first : null;
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

        // Gerar questões automaticamente
        _gerarQuestoes();
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

  Future<void> _gerarQuestoes() async {
    // Validar entrada
    if (_fileContent == null && _materiaController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, faça upload de um documento ou informe a matéria para as questões.';
      });
      return;
    }

    int quantidade;
    try {
      quantidade = int.parse(_quantidadeController.text);
      if (quantidade <= 0 || quantidade > 10) {
        setState(() {
          _errorMessage = 'A quantidade deve ser entre 1 e 10.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Por favor, insira um número válido para a quantidade.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultado = null;
    });

    try {
      final iaService = Provider.of<IAService>(context, listen: false);

      if (!iaService.isConfigured) {
        setState(() {
          _errorMessage = 'Você precisa configurar sua chave de API primeiro.';
          _isLoading = false;
        });
        return;
      }

      // Gerar questões usando o IAService

      final resultado = await iaService.gerarQuestoes(
        _fileContent ?? '',
        _materiaController.text,
        _dificuldade,
        quantidade
      );

      setState(() {
        _resultado = resultado;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro ao processar o texto: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPremium = authService.isPremium;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Questões'),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
      ),
      body: !isPremium
          ? _buildPremiumRequired()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerar Questões com IA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crie questões de múltipla escolha para testar seus conhecimentos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Área de upload de documento
                  GestureDetector(
                    onTap: _isProcessingFile ? null : _pickFile,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade700),
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
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _processingMessage,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: 48,
                                      color: AppTheme.accentColor,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _fileName ?? (_selectedFile?.path.split('/').last ?? 'Arquivo selecionado'),
                                      style: TextStyle(
                                        color: Colors.white,
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
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Matéria',
                      hintText: 'Ex: Direito Constitucional',
                      prefixIcon: Icon(Icons.category, color: AppTheme.accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: _materiaController,
                  ),
                  SizedBox(height: 16),

                  // Configurações
                  Row(
                    children: [
                      // Quantidade
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Quantidade',
                            hintText: '1-10',
                            prefixIcon: Icon(Icons.numbers, color: AppTheme.accentColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: _quantidadeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16),

                      // Dificuldade
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DIFICULDADE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.darkCardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: _dificuldade,
                                isExpanded: true,
                                dropdownColor: AppTheme.darkCardColor,
                                style: TextStyle(color: Colors.white),
                                underline: SizedBox(),
                                icon: Icon(Icons.arrow_drop_down, color: AppTheme.accentColor),
                                items: [
                                  DropdownMenuItem(value: 'fácil', child: Text('Fácil')),
                                  DropdownMenuItem(value: 'média', child: Text('Média')),
                                  DropdownMenuItem(value: 'difícil', child: Text('Difícil')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _dificuldade = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Campo de texto
                  // Campo de texto base removido - agora usamos upload de documento
                  SizedBox(height: 8),

                  // Botão de gerar
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: Icon((_selectedFile == null && _fileBytes == null) ? Icons.upload_file : Icons.quiz),
                          label: Text((_selectedFile == null && _fileBytes == null) ? 'SELECIONAR ARQUIVO' : 'GERAR QUESTÕES'),
                          onPressed: (_selectedFile == null && _fileBytes == null) ? _pickFile : _gerarQuestoes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                  // Mensagem de erro
                  if (_errorMessage != null)
                    Container(
                      margin: EdgeInsets.only(top: 24),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Resultado
                  if (_resultado != null)
                    Container(
                      margin: EdgeInsets.only(top: 24),
                      child: ModernCard(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Questões Geradas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _resultado!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: Icon(Icons.play_arrow),
                                  label: Text('INICIAR QUIZ'),
                                  onPressed: () {
                                    // Implementar início do quiz
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Iniciando quiz...'),
                                        backgroundColor: AppTheme.accentColor,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accentColor,
                                    side: BorderSide(color: AppTheme.accentColor),
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildPremiumRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 80,
            color: Colors.amber,
          ),
          SizedBox(height: 24),
          Text(
            'Funcionalidade Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Esta funcionalidade está disponível apenas para usuários premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              // Simulação de upgrade
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.upgradeToPremium();

              // Mostrar confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Parabéns! Você agora é um usuário Premium.'),
                  backgroundColor: AppTheme.successColor,
                ),
              );

              // Recarregar a tela
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('FAZER UPGRADE'),
          ),
        ],
      ),
    );
  }
}
