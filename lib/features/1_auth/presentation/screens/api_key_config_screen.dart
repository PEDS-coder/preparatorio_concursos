import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';
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
  String _selectedApiType = 'gemini'; // 'gemini' ou 'openai'

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
    final prefs = await SharedPreferences.getInstance();
    final savedApiKey = prefs.getString('api_key');
    final savedApiType = prefs.getString('api_type');

    if (savedApiKey != null && savedApiKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = savedApiKey;
        if (savedApiType != null) {
          _selectedApiType = savedApiType;
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

      try {
        final iaService = Provider.of<IAService>(context, listen: false);

        // Mostrar mensagem de validação
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Validando sua chave API...'),
              ],
            ),
            duration: Duration(seconds: 60), // Longa duração, será fechado manualmente
            backgroundColor: Colors.blue,
          ),
        );

        // Configurar o tipo de API
        iaService.setApiType(_selectedApiType);

        try {
          // Configurar e validar a API Key no serviço
          final bool isValid = await iaService.setApiKey(_apiKeyController.text, _selectedApiType);

          // Fechar o SnackBar de validação
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Se chegou aqui, a validação foi bem-sucedida

          // Salvar a API Key nas preferências
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('api_key', _apiKeyController.text);
          await prefs.setString('api_type', _selectedApiType);

          // Atualizar o status da API LLM no ApiConfigService
          final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);
          await apiConfigService.setLlmConfigured(true);

          // API LLM configurada com sucesso

          // Mostrar mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('API Key configurada com sucesso!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Atualizar o status da API LLM no ApiConfigService
          final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);
          await apiConfigService.setLlmConfigured(true);

          // Mostrar mensagem de sucesso e navegar para a tela de análise de edital
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('API configurada com sucesso! Você já pode analisar editais.')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navegar para a tela de análise de edital
          Navigator.pushReplacementNamed(context, '/edital/analyze');
        } catch (e) {
          // Fechar o SnackBar de validação
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          setState(() {
            _errorMessage = 'Erro ao validar a API Key: ${e.toString()}';
            _isLoading = false;
          });

          // Mostrar mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Chave API inválida: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        // Fechar o SnackBar de validação
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        setState(() {
          _errorMessage = 'Ocorreu um erro ao salvar a API Key: $e';
        });

        // Mostrar mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Erro ao validar a chave: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipConfiguration() async {
    // Marcar que o usuário viu a tela de configuração
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('api_key_skipped', true);

    // Navegar para a tela de análise de edital
    Navigator.pushReplacementNamed(context, '/edital/analyze');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuração de API'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Text(
                'Configuração de API',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Configure sua chave de API para utilizar os recursos de inteligência artificial',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 32),

              // Seleção do tipo de API
              Text(
                'Selecione o tipo de API:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildApiTypeCard(
                      'gemini',
                      'Gemini AI',
                      'API do Google para modelos de linguagem avançados',
                      'assets/images/gemini_logo.png',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildApiTypeCard(
                      'openai',
                      'OpenAI',
                      'API para modelos como GPT-4 e GPT-3.5',
                      'assets/images/openai_logo.png',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Campo de API Key
              Text(
                'Chave de API:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  hintText: _selectedApiType == 'gemini'
                      ? 'Ex: AI...'
                      : 'Ex: sk-...',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.vpn_key),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua chave de API';
                  }
                  if (_selectedApiType == 'gemini' && !value.startsWith('AI')) {
                    return 'Chave Gemini inválida. Deve começar com "AI"';
                  }
                  if (_selectedApiType == 'openai' && !value.startsWith('sk-')) {
                    return 'Chave OpenAI inválida. Deve começar com "sk-"';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Instruções
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como obter sua chave de API:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_selectedApiType == 'gemini')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInstructionStep('1', 'Acesse o Google AI Studio (aistudio.google.com)'),
                          _buildInstructionStep('2', 'Faça login com sua conta Google'),
                          _buildInstructionStep('3', 'Clique em "Get API key" no menu lateral'),
                          _buildInstructionStep('4', 'Clique em "Criar chave de API" e copie a chave gerada'),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInstructionStep('1', 'Acesse o site da OpenAI (platform.openai.com)'),
                          _buildInstructionStep('2', 'Faça login em sua conta'),
                          _buildInstructionStep('3', 'Vá para "API Keys" nas configurações'),
                          _buildInstructionStep('4', 'Clique em "Create new secret key" e copie a chave gerada'),
                        ],
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
                ),

              // Botões de ação
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _skipConfiguration,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text('Pular por Enquanto'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Salvando...'),
                              ],
                            )
                          : Text('Salvar e Continuar'),
                    ),
                  ),
                ],
              ),

              // Botão de ajuda
              SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApiInfoScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.help_outline, color: AppTheme.primaryColor),
                  label: Text(
                    'Precisa de ajuda para obter uma API Key?',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),

              // Nota de privacidade
              SizedBox(height: 24),
              Text(
                'Nota: Sua chave de API é armazenada apenas localmente no seu dispositivo e nunca é compartilhada com nossos servidores.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiTypeCard(String type, String title, String description, String imagePath) {
    final isSelected = _selectedApiType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedApiType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Placeholder para o logo (em um app real, usaria a imagem)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == 'gemini' ? Icons.auto_awesome : Icons.psychology,
                color: type == 'gemini' ? Colors.blue : Colors.green,
                size: 30,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
