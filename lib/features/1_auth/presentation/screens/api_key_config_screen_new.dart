import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/services/api_config_service.dart';
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
  String _selectedApiType = 'gemini'; // 'gemini', 'openrouter' ou 'requestry'

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedApiKey() async {
    final iaService = Provider.of<IAService>(context, listen: false);
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
        // Validar a chave do LLM (Gemini ou OpenAI)
        final iaService = Provider.of<IAService>(context, listen: false);
        final llmResult = await iaService.setApiKey(
          _apiKeyController.text.trim(),
          _selectedApiType,
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
                    title: 'Sobre as APIs',
                    content: '''
# APIs de Inteligência Artificial

Este aplicativo utiliza APIs de IA para análise de editais e geração de conteúdo personalizado.

## Google Gemini API

A API Gemini é a mais recomendada por oferecer excelente qualidade e custo-benefício.

### Como obter uma chave:
1. Visite [ai.google.dev](https://ai.google.dev)
2. Crie uma conta Google (se ainda não tiver)
3. Obtenha uma chave API gratuita (crédito inicial de \$10)
4. Copie a chave API para o campo "Chave da API"

## OpenRouter API

A API OpenRouter oferece acesso unificado a centenas de modelos de IA.

### Como obter uma chave:
1. Visite [openrouter.ai](https://openrouter.ai)
2. Crie uma conta
3. Compre créditos para usar com qualquer modelo
4. Gere uma chave API (começa com "sk-")
5. Copie a chave API para o campo "Chave da API"

## Requestry API

A API Requestry oferece roteamento inteligente para modelos de IA.

### Como obter uma chave:
1. Visite [requesty.ai](https://app.requesty.ai/sign-up)
2. Crie uma conta
3. Obtenha \$6 em créditos gratuitos
4. Gere uma chave API (começa com "sk-")
5. Copie a chave API para o campo "Chave da API"

## Configuração:

1. Escolha o tipo de API (Gemini, OpenRouter ou Requestry)
2. Insira sua chave API no campo "Chave da API"
3. Clique em "Validar e Salvar" para testar e salvar sua chave
                    ''',
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
                            RadioListTile<String>(
                              title: Text('Google Gemini'),
                              subtitle: Text('API oficial do Google (recomendada)'),
                              value: 'gemini',
                              groupValue: _selectedApiType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedApiType = value!;
                                });
                              },
                              activeColor: AppTheme.accentColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              dense: true,
                            ),
                            RadioListTile<String>(
                              title: Text('OpenRouter AI'),
                              subtitle: Text('API unificada com acesso a vários modelos'),
                              value: 'openrouter',
                              groupValue: _selectedApiType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedApiType = value!;
                                });
                              },
                              activeColor: AppTheme.accentColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              dense: true,
                            ),
                            RadioListTile<String>(
                              title: Text('Requestry'),
                              subtitle: Text('API com suporte a vários modelos'),
                              value: 'requestry',
                              groupValue: _selectedApiType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedApiType = value!;
                                });
                              },
                              activeColor: AppTheme.accentColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              dense: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: 'Chave da API',
                            hintText: _selectedApiType == 'gemini'
                                ? 'Insira sua chave da API Gemini (começa com AI...)'
                                : _selectedApiType == 'openrouter'
                                    ? 'Insira sua chave da API OpenRouter (começa com sk...)'
                                    : 'Insira sua chave da API Requestry (começa com sk...)',
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
                            if (_selectedApiType == 'gemini' && !value.startsWith('AI')) {
                              return 'Chave Gemini inválida. Deve começar com "AI"';
                            }
                            if (_selectedApiType == 'openrouter' && !value.startsWith('sk-')) {
                              return 'Chave OpenRouter inválida. Deve começar com "sk-"';
                            }
                            if (_selectedApiType == 'requestry' && !value.startsWith('sk-')) {
                              return 'Chave Requestry inválida. Deve começar com "sk-"';
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
                          'Sobre as APIs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Este aplicativo utiliza APIs de IA para análise de editais e geração de conteúdo personalizado.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'A API Gemini é a mais recomendada por oferecer excelente qualidade e custo-benefício.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApiInfoScreen(
                                  title: 'Sobre as APIs',
                                  content: '''
# APIs de Inteligência Artificial

Este aplicativo utiliza APIs de IA para análise de editais e geração de conteúdo personalizado.

## Google Gemini API

A API Gemini é a mais recomendada por oferecer excelente qualidade e custo-benefício.

### Como obter uma chave:
1. Visite [ai.google.dev](https://ai.google.dev)
2. Crie uma conta Google (se ainda não tiver)
3. Obtenha uma chave API gratuita (crédito inicial de \$10)
4. Copie a chave API para o campo "Chave da API"

## OpenAI API

A API da OpenAI (GPT-4) também é suportada, mas tem um custo mais elevado.

### Como obter uma chave:
1. Visite [platform.openai.com](https://platform.openai.com)
2. Crie uma conta OpenAI
3. Adicione um método de pagamento
4. Gere uma chave API
5. Copie a chave API para o campo "Chave da API"

## Configuração:

1. Escolha o tipo de API (Gemini ou OpenAI)
2. Insira sua chave API no campo "Chave da API"
3. Clique em "Validar e Salvar" para testar e salvar sua chave
                                ''',
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
                          child: Text('Mais Informações'),
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
}
