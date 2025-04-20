import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import 'api_info_screen.dart';

class ApiKeyConfigScreen extends StatefulWidget {
  @override
  _ApiKeyConfigScreenState createState() => _ApiKeyConfigScreenState();
}

class _ApiKeyConfigScreenState extends State<ApiKeyConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedApiType = 'gemini'; // Apenas Gemini

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Explicações em áudio foram removidas
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedApiKey() async {
    final iaService = Provider.of<IAServiceInterface>(context, listen: false);
    final apiKey = iaService.apiKey;
    final apiType = iaService.apiType;

    // Carregar chaves de API salvas
    if (apiKey != null && apiKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = apiKey;
        if (apiType != null && apiType.isNotEmpty) {
          _selectedApiType = apiType;
        }
      });
    }
  }

  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Mostrar SnackBar de validação
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Validando chave de API...'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          duration: Duration(seconds: 60), // Longo tempo para garantir que seja fechado manualmente
        ),
      );

      try {
        // Validar a chave do LLM (Gemini)
        final iaService = Provider.of<IAServiceInterface>(context, listen: false);

        // Usar o serviço Gemini Official
        iaService.setApiType('gemini_official');

        final llmResult = await iaService.setApiKey(
          _apiKeyController.text.trim(),
          'gemini_official',
        );

        // Fechar o SnackBar de validação
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (!llmResult['success']) {
          // Mostrar mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Erro na chave do LLM: ${llmResult['message']}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );

          setState(() {
            _isLoading = false;
            _errorMessage = 'Erro na chave do LLM: ${llmResult['message']}';
          });
          return;
        }

        // Chave validada com sucesso
        // Salvar que o usuário configurou a API
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('api_key_configured', true);

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Chave de API configurada com sucesso!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _isLoading = false;
        });

        // Navegar para a tela de análise de edital após um breve atraso para mostrar a mensagem
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/edital/analyze');
        });
      } catch (e) {
        // Fechar o SnackBar de validação
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Mostrar mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Erro ao configurar API: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );

        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao configurar API: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuração de API'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gradientStart,
                AppTheme.gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApiInfoScreen(
                    title: 'Como Gerar Uma Chave API',
                    content: 'Para gerar uma chave API gratuitamente, abra o navegador no site aistudio.google.com.\nFaça o login com sua conta google e siga as instruções abaixo:',
                    imageAssets: [
                      'assets/images/gemini_api_steps/step1.png',
                      'assets/images/gemini_api_steps/step2.png',
                      'assets/images/gemini_api_steps/step3.png',
                      'assets/images/gemini_api_steps/step4.png',
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuração da API de IA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Configure a API de IA para análise de editais e geração de conteúdo.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Tipo de API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          children: [
                            // Apenas Gemini é suportado
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Google Gemini',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'API oficial do Google com modelos avançados',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.check_circle, color: AppTheme.primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Opções de autenticação
                        Text(
                          'Método de Autenticação',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Opção de autenticação OAuth
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/oauth_config');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_circle, color: Colors.blue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Autenticação com Google (Recomendado)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Use sua conta Google para autenticar com a API Gemini',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'OU',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chave API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: 'Chave da API',
                            hintText: 'Insira sua chave da API Gemini (começa com AI...)',
                            prefixIcon: Icon(Icons.vpn_key),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a chave da API';
                            }
                            if (!value.startsWith('AI')) {
                              return 'Chave Gemini inválida. Deve começar com "AI"';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveApiKey,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Validar e Salvar'),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),
                // Card com informações sobre limites de uso gratuito
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limites de Uso Gratuito',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildLimitItem(
                          'gemini-2.5-pro-exp-03-25',
                          '10 requisições por minuto',
                          '65.536 tokens de saída (maxOutputTokens)',
                          'Modelo experimental gratuito',
                          Colors.purple,
                          isDarkMode,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nota: O modelo acima é experimental e oferece maior capacidade de saída. Você pode obter uma chave API gratuita no Google AI Studio.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Card com instruções para gerar chave API
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como Gerar Uma Chave API',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Para gerar uma chave API gratuitamente, abra o navegador no site aistudio.google.com.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Faça o login com sua conta Google e siga as instruções no botão abaixo.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Botão para configurações avançadas do MCP
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/mcp_config');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.settings_suggest, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Configurações Avançadas (MCP)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Botão de ajuda
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApiInfoScreen(
                                  title: 'Como Gerar Uma Chave API',
                                  content: 'Para gerar uma chave API gratuitamente, abra o navegador no site aistudio.google.com.\nFaça o login com sua conta google e siga as instruções abaixo:',
                                  imageAssets: [
                                    'assets/images/gemini_api_steps/step1.png',
                                    'assets/images/gemini_api_steps/step2.png',
                                    'assets/images/gemini_api_steps/step3.png',
                                    'assets/images/gemini_api_steps/step4.png',
                                  ],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Ver Instruções'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para exibir informações sobre limites de uso
  Widget _buildLimitItem(String modelName, String rpm, String tpm, String rpd, Color color, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modelName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                rpm,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.data_usage, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                tpm,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                rpd,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
