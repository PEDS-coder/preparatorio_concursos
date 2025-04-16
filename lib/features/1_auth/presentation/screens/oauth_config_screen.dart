import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/services/gemini_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/theme/app_theme.dart';

class OAuthConfigScreen extends StatefulWidget {
  @override
  _OAuthConfigScreenState createState() => _OAuthConfigScreenState();
}

class _OAuthConfigScreenState extends State<OAuthConfigScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Carregar as credenciais do arquivo client.json
  Map<String, dynamic>? _clientCredentials;

  @override
  void initState() {
    super.initState();
    _loadClientCredentials();
  }

  Future<void> _loadClientCredentials() async {
    try {
      // Carregar o arquivo client.json
      final jsonString = await DefaultAssetBundle.of(context).loadString('assets/data/client.json');
      final jsonData = json.decode(jsonString);

      setState(() {
        _clientCredentials = jsonData['installed'];
      });

      debugPrint('Credenciais carregadas com sucesso: ${_clientCredentials!['client_id']}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar credenciais: $e';
      });
      debugPrint('Erro ao carregar credenciais: $e');
    }
  }

  Future<void> _authenticateWithGoogle() async {
    if (_clientCredentials == null) {
      setState(() {
        _errorMessage = 'Credenciais não carregadas. Tente novamente.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Obter o serviço Gemini
      final geminiService = Provider.of<IAService>(context, listen: false) as GeminiService;

      // Configurar as credenciais OAuth
      final configResult = await geminiService.configureOAuth(
        _clientCredentials!['client_id'],
        _clientCredentials!['client_secret'],
      );

      if (!configResult['success']) {
        setState(() {
          _errorMessage = configResult['message'];
        });
        return;
      }

      // Autenticar com o Google
      final authResult = await geminiService.authenticateWithGoogle();

      if (authResult['success']) {
        // Testar conexão com a API
        final apiConnected = await geminiService.testApiConnection();

        if (apiConnected) {
          setState(() {
            _successMessage = 'Autenticação com Google realizada com sucesso!';
          });

          // Navegar para a tela principal após um breve delay
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          setState(() {
            _errorMessage = 'Conexão com a API Gemini falhou. Verifique suas permissões.';
          });
        }
      } else {
        setState(() {
          _errorMessage = authResult['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro durante a autenticação: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuração OAuth'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autenticação com Google',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use sua conta Google para autenticar com a API Gemini. Isso permite que o aplicativo acesse a API sem precisar de uma chave API.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Status das credenciais
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
                      'Status das Credenciais',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _clientCredentials != null ? Icons.check_circle : Icons.error,
                          color: _clientCredentials != null ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _clientCredentials != null
                              ? 'Credenciais carregadas com sucesso'
                              : 'Credenciais não carregadas',
                          style: TextStyle(
                            color: _clientCredentials != null ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (_clientCredentials != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Project ID: ${_clientCredentials!['project_id']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Botão de autenticação
            ElevatedButton.icon(
              onPressed: _isLoading || _clientCredentials == null
                  ? null
                  : _authenticateWithGoogle,
              icon: Icon(Icons.login),
              label: Text('Autenticar com Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Indicador de carregamento
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Autenticando com Google...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

            // Mensagem de erro
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),

            // Mensagem de sucesso
            if (_successMessage != null)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),

            SizedBox(height: 24),

            // Instruções
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
                      'Instruções',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Clique no botão "Autenticar com Google"\n'
                      '2. Você será redirecionado para a página de login do Google\n'
                      '3. Faça login com sua conta Google\n'
                      '4. Autorize o aplicativo a acessar a API Gemini\n'
                      '5. Você será redirecionado de volta para o aplicativo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Botão para voltar para a tela de configuração de API
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/api_config');
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Voltar para configuração de API'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
