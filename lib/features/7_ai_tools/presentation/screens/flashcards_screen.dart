import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/data/services/document_storage_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../../core/services/document_classifier_service.dart';
import '../../presentation/widgets/stored_files_widget.dart';

class FlashcardsScreen extends StatefulWidget {
  final bool showBottomNavigationBar;

  const FlashcardsScreen({super.key, this.showBottomNavigationBar = true});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _materiaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _resultado;
  String _modoEntrada = 'texto'; // 'texto' ou 'upload'
  String? _textoUpload;
  String? _materiaId;
  String? _assuntoId;

  late TabController _tabController;

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

      final usuario = authService.currentUser;
      if (usuario == null) {
        setState(() {
          _errorMessage = 'Você precisa estar autenticado para usar esta funcionalidade.';
          _isLoading = false;
        });
        return;
      }

      if (!iaService.isConfigured) {
        setState(() {
          _errorMessage = 'Você precisa configurar sua chave de API primeiro.';
          _isLoading = false;
        });
        return;
      }

      // Obter texto e matéria com base no modo
      final texto = _modoEntrada == 'texto' ? _textController.text : _textoUpload!;
      String materia;

      if (_modoEntrada == 'texto') {
        materia = _materiaController.text;
      } else {
        // Obter nome da matéria pelo ID
        final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
        final materiaObj = planoService.getMateriaById(_materiaId!);
        materia = materiaObj?.nome ?? 'Não especificado';
      }

      // Salvar o documento enviado
      if (_modoEntrada == 'texto') {
        await storageService.addUploadedDocument(
          usuario.id,
          'Texto para flashcards - $materia',
          'txt',
          DocumentStorageService.FLASHCARDS,
          texto.codeUnits,
        );
      }

      final flashcards = await iaService.gerarFlashcards(
        userId: usuario.id,
        editalId: null, // editalId opcional
        materia: materia,
        texto: texto,
      );

      String resultado = 'Foram gerados ${flashcards.length} flashcards:\n\n';
      for (int i = 0; i < flashcards.length; i++) {
        final flashcard = flashcards[i];
        resultado += 'Flashcard ${i + 1}:\n';
        resultado += 'Pergunta: ${flashcard.pergunta}\n';
        resultado += 'Resposta: ${flashcard.resposta}\n\n';
      }

      // Salvar o resultado gerado
      await storageService.addGeneratedFile(
        usuario.id,
        'Flashcards - $materia',
        'txt',
        DocumentStorageService.FLASHCARDS,
        resultado,
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
      bottomNavigationBar: widget.showBottomNavigationBar ? _buildBottomNavigationBar(context) : null,
      body: !isPremium
          ? _buildPremiumRequired()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCreateTab(),
                _buildUploadedTab(),
                _buildGeneratedTab(),
              ],
            ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Criar Flashcards com IA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Faça upload de um documento ou insira um texto para gerar flashcards automaticamente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Seleção de modo
          _buildModeSelector(),
          const SizedBox(height: 24),

          // Conteúdo baseado no modo selecionado
          _modoEntrada == 'texto'
              ? _buildTextoMode()
              : _buildUploadMode(),

          // Mensagem de erro
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Resultado
          if (_resultado != null)
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Flashcards Gerados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _resultado!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('BAIXAR'),
                          onPressed: () {
                            // Implementar download
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download iniciado'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
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
    );
  }

  Widget _buildUploadedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documentos Enviados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Documentos que você enviou para gerar flashcards',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          StoredFilesWidget(
            toolType: DocumentStorageService.FLASHCARDS,
            title: 'Seus Documentos',
            showUploaded: true,
            showGenerated: false,
            onFileSelected: (content) {
              setState(() {
                _textoUpload = content;
                _modoEntrada = 'upload';
                _tabController.animateTo(0); // Voltar para a aba de criação
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flashcards Gerados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Flashcards que você gerou com a IA',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          StoredFilesWidget(
            toolType: DocumentStorageService.FLASHCARDS,
            title: 'Seus Flashcards',
            showUploaded: false,
            showGenerated: true,
            onFileSelected: (content) {
              setState(() {
                _resultado = content;
                _tabController.animateTo(0); // Voltar para a aba de criação
              });
            },
          ),
        ],
      ),
    );
  }

  // Modo de texto
  Widget _buildTextoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de matéria
        const Text(
          'Matéria',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        StyledTextField(
          controller: _materiaController,
          hintText: 'Ex: Direito Constitucional',
          prefixIcon: Icons.subject,
        ),
        const SizedBox(height: 16),

        // Campo de texto
        const Text(
          'Texto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        StyledTextField(
          controller: _textController,
          hintText: 'Cole aqui o texto para gerar flashcards...',
          prefixIcon: Icons.text_fields,
          maxLines: 10,
        ),
        const SizedBox(height: 24),

        // Botão de gerar
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : GradientButton(
                onPressed: _gerarFlashcards,
                fullWidth: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('GERAR FLASHCARDS'),
                  ],
                ),
              ),
      ],
    );
  }

  // Modo de upload de documento
  Widget _buildUploadMode() {
    return DocumentUploadWidget(
      title: 'Upload de Documento',
      description: 'Faça upload de um documento para gerar flashcards automaticamente',
      onDocumentProcessed: (texto, materiaId, assuntoId) {
        setState(() {
          _textoUpload = texto;
          _materiaId = materiaId;
          _assuntoId = assuntoId;
        });

        // Processar automaticamente
        _gerarFlashcards();
      },
    );
  }

  // Seletor de modo (upload ou texto)
  Widget _buildModeSelector() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildModeButton(
                'upload',
                'Upload de Documento',
                Icons.upload_file,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModeButton(
                'texto',
                'Inserir Texto',
                Icons.text_fields,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botão de modo
  Widget _buildModeButton(String modo, String label, IconData icon) {
    final isSelected = _modoEntrada == modo;

    return InkWell(
      onTap: () {
        setState(() {
          _modoEntrada = modo;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 4, // Índice do Ferramentas
          onTap: (index) {
            if (index != 4) { // Se não for o índice atual (Ferramentas)
              switch (index) {
                case 0: // Início
                  Navigator.pushNamed(context, '/dashboard');
                  break;
                case 1: // Editais
                  Navigator.pushNamed(context, '/editais');
                  break;
                case 2: // Plano
                  Navigator.pushNamed(context, '/plano');
                  break;
                case 3: // Gamificação
                  Navigator.pushNamed(context, '/gamificacao');
                  break;
              }
            }
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          backgroundColor: AppTheme.darkSurface,
          elevation: 0,
          selectedLabelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          items: const [
            // Abas principais
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              activeIcon: Icon(Icons.description, color: AppTheme.primaryColor),
              label: 'Editais',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              activeIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              label: 'Plano',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              activeIcon: Icon(Icons.emoji_events, color: AppTheme.primaryColor),
              label: 'Progresso',
            ),
            // Ferramentas de IA
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              activeIcon: Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
              label: 'Ferramentas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'Recurso Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Os flashcards com IA estão disponíveis apenas para usuários premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Simulação de upgrade
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('FAZER UPGRADE'),
            ),
          ],
        ),
      ),
    );
  }
}
