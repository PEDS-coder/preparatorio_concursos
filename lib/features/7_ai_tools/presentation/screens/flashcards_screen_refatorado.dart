import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/navigation/bottom_navigation_helper.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/document_storage_service.dart';

import '../widgets/flashcards/create_flashcards_tab.dart';
import '../widgets/flashcards/stored_files_tab.dart';
import '../widgets/flashcards/premium_required_view.dart';
import '../../domain/services/flashcards_service.dart';

class FlashcardsScreen extends StatefulWidget {
  final bool showBottomNavigationBar;

  const FlashcardsScreen({super.key, this.showBottomNavigationBar = true});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> with SingleTickerProviderStateMixin {
  // Controladores
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _materiaController = TextEditingController();
  late TabController _tabController;
  
  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  String? _resultado;
  String _modoEntrada = 'texto'; // 'texto' ou 'upload'
  String? _textoUpload;
  String? _materiaId;
  String? _assuntoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _materiaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Altera o modo de entrada (texto ou upload)
  void _alterarModo(String modo) {
    setState(() {
      _modoEntrada = modo;
    });
  }

  /// Processa um documento carregado
  void _processarDocumento(String texto, String? materiaId, String? assuntoId) {
    setState(() {
      _textoUpload = texto;
      _materiaId = materiaId;
      _assuntoId = assuntoId;
    });

    // Processar automaticamente
    _gerarFlashcards();
  }

  /// Gera flashcards com base no texto ou documento
  Future<void> _gerarFlashcards() async {
    // Validar entrada com base no modo
    if (_modoEntrada == 'texto') {
      if (_textController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, insira um texto para processar.';
        });
        return;
      }
      if (_materiaController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, informe a matéria.';
        });
        return;
      }
    } else { // modo upload
      if (_textoUpload == null) {
        setState(() {
          _errorMessage = 'Por favor, faça upload de um documento para processar.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultado = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final iaService = Provider.of<IAServiceInterface>(context, listen: false);
      final storageService = Provider.of<DocumentStorageService>(context, listen: false);
      final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
      
      final usuario = authService.currentUser;
      if (usuario == null) {
        setState(() {
          _errorMessage = 'Você precisa estar autenticado para usar esta funcionalidade.';
          _isLoading = false;
        });
        return;
      }

      // Criar serviço de flashcards
      final flashcardsService = FlashcardsService(
        iaService: iaService,
        storageService: storageService,
      );

      // Obter texto e matéria com base no modo
      final texto = _modoEntrada == 'texto' ? _textController.text : _textoUpload!;
      String materia;

      if (_modoEntrada == 'texto') {
        materia = _materiaController.text;
      } else {
        // Obter nome da matéria pelo ID
        final materiaObj = planoService.getMateriaById(_materiaId!);
        materia = materiaObj?.nome ?? 'Não especificado';
      }

      // Gerar flashcards
      final flashcards = await flashcardsService.gerarFlashcards(
        userId: usuario.id,
        texto: texto,
        materia: materia,
      );

      // Formatar resultado
      final resultado = flashcardsService.formatarFlashcardsComoTexto(flashcards);

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

  /// Manipula a seleção de um arquivo armazenado
  void _onArquivoSelecionado(String conteudo) {
    setState(() {
      if (_tabController.index == 1) { // Aba de documentos enviados
        _textoUpload = conteudo;
        _modoEntrada = 'upload';
        _tabController.animateTo(0); // Voltar para a aba de criação
      } else if (_tabController.index == 2) { // Aba de flashcards gerados
        _resultado = conteudo;
        _tabController.animateTo(0); // Voltar para a aba de criação
      }
    });
  }

  /// Realiza upgrade para premium
  Future<void> _fazerUpgrade() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.upgradeToPremium();

    // Mostrar confirmação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parabéns! Você agora é um usuário Premium.'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // Recarregar a tela
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPremium = authService.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Criar'),
            Tab(text: 'Enviados'),
            Tab(text: 'Gerados'),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigationBar ? BottomNavigationHelper.buildBottomNavigationBar(
        context,
        currentIndex: 4, // Índice do Ferramentas
        useDarkTheme: true,
      ) : null,
      body: !isPremium
          ? PremiumRequiredView(onUpgradePressed: _fazerUpgrade)
          : TabBarView(
              controller: _tabController,
              children: [
                // Aba de criação
                CreateFlashcardsTab(
                  modoEntrada: _modoEntrada,
                  onModeChanged: _alterarModo,
                  textController: _textController,
                  materiaController: _materiaController,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  resultado: _resultado,
                  textoUpload: _textoUpload,
                  onGeneratePressed: _gerarFlashcards,
                  onDocumentProcessed: _processarDocumento,
                ),
                
                // Aba de documentos enviados
                StoredFilesTab(
                  title: 'Documentos Enviados',
                  description: 'Documentos que você enviou para gerar flashcards',
                  showUploaded: true,
                  showGenerated: false,
                  onFileSelected: _onArquivoSelecionado,
                ),
                
                // Aba de flashcards gerados
                StoredFilesTab(
                  title: 'Flashcards Gerados',
                  description: 'Flashcards que você gerou com a IA',
                  showUploaded: false,
                  showGenerated: true,
                  onFileSelected: _onArquivoSelecionado,
                ),
              ],
            ),
    );
  }
}
