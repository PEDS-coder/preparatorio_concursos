import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../../core/services/document_classifier_service.dart';

class FlashcardsScreen extends StatefulWidget {
  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  bool _isLoading = false;
  String? _resultado;
  String? _errorMessage;

  // Modo de entrada (upload ou texto)
  String _modoEntrada = 'upload'; // 'upload' ou 'texto'

  // Controladores para modo texto
  final _textController = TextEditingController();
  final _materiaController = TextEditingController();

  // Dados para modo upload
  String? _textoUpload;
  String? _materiaId;
  String? _assuntoId;

  @override
  void dispose() {
    _textController.dispose();
    _materiaController.dispose();
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
          _errorMessage = 'Por favor, informe a matéria para os flashcards.';
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
      final iaService = Provider.of<IAService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!iaService.isConfigured) {
        setState(() {
          _errorMessage = 'Você precisa configurar sua chave de API primeiro.';
          _isLoading = false;
        });
        return;
      }

      final usuario = authService.currentUser;
      if (usuario == null) {
        setState(() {
          _errorMessage = 'Você precisa estar autenticado para usar esta funcionalidade.';
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

      final flashcards = await iaService.gerarFlashcards(
        usuario.id,
        null, // editalId opcional
        materia,
        texto,
      );

      String resultado = 'Foram gerados ${flashcards.length} flashcards:\n\n';
      for (int i = 0; i < flashcards.length; i++) {
        final flashcard = flashcards[i];
        resultado += 'Flashcard ${i + 1}:\n';
        resultado += 'Pergunta: ${flashcard.pergunta}\n';
        resultado += 'Resposta: ${flashcard.resposta}\n\n';
      }

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
        title: Text('Flashcards'),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: !isPremium
          ? _buildPremiumRequired()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criar Flashcards com IA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Faça upload de um documento ou insira um texto para gerar flashcards automaticamente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Seleção de modo
                  _buildModeSelector(),
                  SizedBox(height: 24),

                  // Conteúdo com base no modo selecionado
                  _modoEntrada == 'upload'
                      ? _buildUploadMode()
                      : _buildTextMode(),

                  // Botão de gerar (apenas para modo texto)
                  if (_modoEntrada == 'texto')
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          : ElevatedButton.icon(
                              icon: Icon(Icons.auto_awesome),
                              label: Text('GERAR FLASHCARDS'),
                              onPressed: _gerarFlashcards,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  'Flashcards Gerados',
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
                                  icon: Icon(Icons.save),
                                  label: Text('SALVAR'),
                                  onPressed: () {
                                    // Implementar salvamento
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Flashcards salvos com sucesso!'),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  },
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

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 4, // Índice do Flashcards
          onTap: (index) {
            if (index != 4) { // Se não for o índice atual (Flashcards)
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
                case 5: // Resumos
                  Navigator.pushNamed(context, '/resumos');
                  break;
                case 6: // Questões
                  Navigator.pushNamed(context, '/questoes');
                  break;
                case 7: // Mapas Mentais
                  Navigator.pushNamed(context, '/mapas_mentais');
                  break;
              }
            }
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          backgroundColor: AppTheme.darkSurface,
          elevation: 0,
          selectedLabelStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          items: [
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
              label: 'Gamificação',
            ),
            // Ferramentas de IA
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on),
              activeIcon: Icon(Icons.flash_on, color: AppTheme.primaryColor),
              label: 'Flashcards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize),
              activeIcon: Icon(Icons.summarize, color: AppTheme.primaryColor),
              label: 'Resumos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz),
              activeIcon: Icon(Icons.quiz, color: AppTheme.primaryColor),
              label: 'Questões',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree),
              activeIcon: Icon(Icons.account_tree, color: AppTheme.primaryColor),
              label: 'Mapas',
            ),
          ],
        ),
      ),
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
            SizedBox(width: 16),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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

  // Modo de inserção de texto
  Widget _buildTextMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de matéria
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Matéria',
            hintText: 'Ex: Direito Constitucional',
            prefixIcon: Icon(Icons.category, color: AppTheme.secondaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          controller: _materiaController,
        ),
        SizedBox(height: 24),

        // Campo de texto
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Texto para Processamento',
            hintText: 'Cole aqui o texto que deseja transformar em flashcards...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          controller: _textController,
          maxLines: 6,
          minLines: 3,
        ),
      ],
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
