import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/ia_service.dart';

class IAToolsScreen extends StatefulWidget {
  @override
  _IAToolsScreenState createState() => _IAToolsScreenState();
}

class _IAToolsScreenState extends State<IAToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _materiaController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isLoading = false;
  String? _resultado;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _materiaController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _processarTexto(String tipo) async {
    // Validar entrada
    if (_textController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, insira um texto para processar.';
      });
      return;
    }

    if (tipo == 'flashcards' && _materiaController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, informe a matéria para os flashcards.';
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
      final authService = Provider.of<AuthService>(context, listen: false);

      // Verificar se a API Key está configurada
      if (!iaService.isConfigured) {
        if (_apiKeyController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Por favor, configure sua API Key do Gemini.';
            _isLoading = false;
          });
          return;
        }

        // Configurar API Key
        final bool isValid = await iaService.configurarApiKey(_apiKeyController.text);
        if (!isValid) {
          setState(() {
            _errorMessage = 'A API Key fornecida é inválida ou o serviço está indisponível.';
            _isLoading = false;
          });
          return;
        }
      }

      // Verificar se o usuário é premium
      if (!authService.isPremium) {
        setState(() {
          _errorMessage = 'Esta funcionalidade está disponível apenas para usuários Premium.';
          _isLoading = false;
        });
        return;
      }

      // Processar o texto de acordo com o tipo
      String resultado = '';

      switch (tipo) {
        case 'flashcards':
          final usuario = authService.currentUser;
          if (usuario == null) {
            setState(() {
              _errorMessage = 'Você precisa estar autenticado para usar esta funcionalidade.';
              _isLoading = false;
            });
            return;
          }

          final flashcards = await iaService.gerarFlashcards(
            usuario.id,
            null, // editalId opcional
            _materiaController.text,
            _textController.text,
          );

          resultado = 'Foram gerados ${flashcards.length} flashcards:\n\n';
          for (int i = 0; i < flashcards.length; i++) {
            final flashcard = flashcards[i];
            resultado += 'Flashcard ${i + 1}:\n';
            resultado += 'Pergunta: ${flashcard.pergunta}\n';
            resultado += 'Resposta: ${flashcard.resposta}\n\n';
          }
          break;

        case 'resumo':
          resultado = await iaService.gerarResumo(_textController.text);
          break;

        case 'esquema':
          resultado = await iaService.gerarEsquema(_textController.text);
          break;
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
      appBar: AppBar(
        title: Text('Ferramentas de IA'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Flashcards'),
            Tab(text: 'Resumos'),
            Tab(text: 'Esquemas'),
          ],
        ),
      ),
      body: !isPremium
          ? _buildPremiumRequired()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFlashcardsTab(),
                _buildResumoTab(),
                _buildEsquemaTab(),
              ],
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
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'As ferramentas de IA estão disponíveis apenas para usuários Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.upgradeToPremium();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Parabéns! Você agora é um usuário Premium.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: Icon(Icons.star),
            label: Text('Fazer Upgrade para Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Gerador de Flashcards',
            'Crie flashcards automaticamente a partir de textos de estudo',
          ),
          SizedBox(height: 24),

          // Campo de matéria
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
          SizedBox(height: 16),

          // Campo de texto
          Text(
            'Texto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Cole aqui o texto para gerar flashcards...',
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
          ),
          SizedBox(height: 16),

          // Botão de processar
          _buildProcessButton('Gerar Flashcards', () => _processarTexto('flashcards')),

          // Mensagem de erro
          if (_errorMessage != null)
            _buildErrorMessage(),

          // Resultado
          if (_resultado != null)
            _buildResultado(),

          // Configuração da API Key
          SizedBox(height: 32),
          _buildApiKeyConfig(),
        ],
      ),
    );
  }

  Widget _buildResumoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Gerador de Resumos',
            'Crie resumos concisos a partir de textos longos',
          ),
          SizedBox(height: 24),

          // Campo de texto
          Text(
            'Texto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Cole aqui o texto para resumir...',
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
          ),
          SizedBox(height: 16),

          // Botão de processar
          _buildProcessButton('Gerar Resumo', () => _processarTexto('resumo')),

          // Mensagem de erro
          if (_errorMessage != null)
            _buildErrorMessage(),

          // Resultado
          if (_resultado != null)
            _buildResultado(),

          // Configuração da API Key
          SizedBox(height: 32),
          _buildApiKeyConfig(),
        ],
      ),
    );
  }

  Widget _buildEsquemaTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Gerador de Esquemas',
            'Crie esquemas e mapas mentais a partir de textos de estudo',
          ),
          SizedBox(height: 24),

          // Campo de texto
          Text(
            'Texto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Cole aqui o texto para gerar um esquema...',
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
          ),
          SizedBox(height: 16),

          // Botão de processar
          _buildProcessButton('Gerar Esquema', () => _processarTexto('esquema')),

          // Mensagem de erro
          if (_errorMessage != null)
            _buildErrorMessage(),

          // Resultado
          if (_resultado != null)
            _buildResultado(),

          // Configuração da API Key
          SizedBox(height: 32),
          _buildApiKeyConfig(),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.psychology),
        label: Text(_isLoading ? 'Processando...' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.only(top: 16),
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
    );
  }

  Widget _buildResultado() {
    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Resultado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(_resultado!.replaceAll('\\n', '\n')),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // Implementar cópia para a área de transferência
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Texto copiado para a área de transferência!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: Icon(Icons.copy),
            label: Text('Copiar Resultado'),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyConfig() {
    final iaService = Provider.of<IAService>(context);

    return ExpansionTile(
      title: Text('Configuração da API Key'),
      subtitle: Text(
        iaService.isConfigured
            ? 'API Key configurada'
            : 'Configure sua API Key do Gemini',
      ),
      leading: Icon(
        iaService.isConfigured ? Icons.check_circle : Icons.settings,
        color: iaService.isConfigured ? Colors.green : Colors.grey,
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para usar as ferramentas de IA, é necessário configurar uma API Key do Gemini ou OpenAI.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key (Gemini ou OpenAI)',
                  hintText: 'Cole sua API Key aqui (começa com AI... ou sk-...)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_apiKeyController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor, insira uma API Key válida.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final iaService = Provider.of<IAService>(context, listen: false);
                    final bool isValid = await iaService.configurarApiKey(_apiKeyController.text);

                    if (isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('API Key configurada com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('API Key inválida ou serviço indisponível.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao configurar API Key: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: Text('Salvar API Key'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
