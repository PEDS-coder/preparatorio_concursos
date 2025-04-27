import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/interfaces/secure_storage_service_interface.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/api_quota_service.dart';
import '../../../../core/data/models/api_quota.dart';
import '../../../../core/widgets/api_quota_indicator.dart';
import '../../../../core/services/audio_explanation_service.dart';
import 'api_info_screen.dart';

class ApiKeyConfigScreen extends StatefulWidget {
  const ApiKeyConfigScreen({super.key});

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

    // Inicializar o serviço de cotas
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final apiQuotaService = ApiQuotaService();
      await apiQuotaService.init();

      // Limpar o status de validação ao iniciar a tela
      final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);
      if (apiConfigService.validationStatus.isNotEmpty) {
        apiConfigService.resetValidationStatus();
      }
    });
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
        if (apiType.isNotEmpty) {
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
          content: const Row(
            children: [
              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Validando chave de API...'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 60), // Longo tempo para garantir que seja fechado manualmente
        ),
      );

      try {
        // Obter o serviço de configuração da API
        final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);

        // Validar a chave do LLM (Gemini)
        final iaService = Provider.of<IAServiceInterface>(context, listen: false);

        // Usar o serviço Gemini Official
        iaService.setApiType('gemini_official');

        // Salvar a chave API no armazenamento seguro
        final secureStorage = Provider.of<ISecureStorageService>(context, listen: false);
        await secureStorage.saveSecure('api_key', _apiKeyController.text.trim());
        await secureStorage.saveSecure('api_type', 'gemini_official');

        // Verificar a configuração usando o serviço de configuração da API
        final bool isConfigValid = await apiConfigService.verificarConfiguracao();

        // Fechar o SnackBar de validação
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (!isConfigValid) {
          // Mostrar mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Erro na chave do LLM: ${apiConfigService.configErrorMessage ?? "Chave inválida"}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );

          setState(() {
            _isLoading = false;
            _errorMessage = 'Erro na chave do LLM: ${apiConfigService.configErrorMessage ?? "Chave inválida"}';
          });
          return;
        }

        // Chave validada com sucesso
        // Salvar que o usuário configurou a API
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('api_key_configured', true);

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
        Future.delayed(const Duration(seconds: 2), () {
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
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao configurar API: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao configurar API: $e';
        });
      }
    }
  }

  /// Método para forçar a validação da chave API no Windows
  Future<void> _forcarValidacao() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma chave API válida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_apiKeyController.text.trim().startsWith('AI')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave Gemini inválida. Deve começar com "AI"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Mostrar SnackBar de validação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Forçando validação para Windows...'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      // Obter o serviço de configuração da API
      final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);

      // Validar a chave do LLM (Gemini)
      final iaService = Provider.of<IAServiceInterface>(context, listen: false);

      // Usar o serviço Gemini Official
      iaService.setApiType('gemini_official');

      // Salvar a chave API no armazenamento seguro
      final secureStorage = Provider.of<ISecureStorageService>(context, listen: false);
      await secureStorage.saveSecure('api_key', _apiKeyController.text.trim());
      await secureStorage.saveSecure('api_type', 'gemini_official');

      // Configurar o serviço de IA com a chave API
      await iaService.configurarApiKey(_apiKeyController.text.trim());

      // Fechar o SnackBar de validação
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Salvar que o usuário configurou a API
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('api_key_configured', true);

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Validação forçada com sucesso! A chave API foi salva.')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _isLoading = false;
      });

      // Iniciar verificação assíncrona
      _verificarApiAssincronamente();

      // Navegar para a tela de análise de edital após um breve atraso para mostrar a mensagem
      Future.delayed(const Duration(seconds: 2), () {
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
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao forçar validação: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao forçar validação: $e';
      });
    }
  }

  /// Método para verificar a API assincronamente
  void _verificarApiAssincronamente() {
    // Executar em um isolate separado para não bloquear a UI
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);
        final bool isValid = await apiConfigService.verificarConfiguracao();

        if (isValid) {
          print('Verificação assíncrona da API: Sucesso');
        } else {
          print('Verificação assíncrona da API: Falha');
        }
      } catch (e) {
        print('Erro na verificação assíncrona da API: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de API'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
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
          // Indicador de uso de cotas
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: ApiQuotaIndicator(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiInfoScreen(
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
                        const SizedBox(height: 8),
                        Text(
                          'Configure a API de IA para análise de editais e geração de conteúdo.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tipo de API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            // Apenas Gemini é suportado
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                                  const SizedBox(width: 12),
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
                                        const SizedBox(height: 4),
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
                                  const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Opções de autenticação
                        Text(
                          'Método de Autenticação',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Opção de autenticação OAuth
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/oauth_config');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_circle, color: Colors.blue),
                                const SizedBox(width: 12),
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
                                      const SizedBox(height: 4),
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
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'OU',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chave API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: 'Chave da API',
                            hintText: 'Insira sua chave da API Gemini (começa com AI...)',
                            prefixIcon: const Icon(Icons.vpn_key),
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
                        // Status da validação
                        Consumer<ApiConfigService>(
                          builder: (context, apiConfigService, child) {
                            if (apiConfigService.isVerifyingConfig || apiConfigService.validationStatus.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(apiConfigService.validationStatus).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getStatusColor(apiConfigService.validationStatus).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getStatusIcon(apiConfigService.validationStatus),
                                            size: 16,
                                            color: _getStatusColor(apiConfigService.validationStatus),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Status: ${_getStatusMessage(apiConfigService.validationStatus)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(apiConfigService.validationStatus),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (apiConfigService.isVerifyingConfig)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: LinearProgressIndicator(
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _getStatusColor(apiConfigService.validationStatus),
                                            ),
                                          ),
                                        ),
                                      if (apiConfigService.configErrorMessage != null && apiConfigService.configErrorMessage!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            apiConfigService.configErrorMessage!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      if (apiConfigService.lastValidationTime != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Última verificação: ${_formatDateTime(apiConfigService.lastValidationTime!)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (_errorMessage != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Container(
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
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Consumer<ApiConfigService>(
                          builder: (context, apiConfigService, child) {
                            // No ambiente web, não mostrar o botão de forçar validação
                            // No Windows, mostrar botão adicional para forçar validação
                            if (!kIsWeb && Platform.isWindows) {
                              return Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: _isLoading || apiConfigService.isVerifyingConfig ? null : _saveApiKey,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      disabledBackgroundColor: Colors.grey.shade400,
                                    ),
                                    child: _isLoading || apiConfigService.isVerifyingConfig
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                apiConfigService.isVerifyingConfig ? 'Verificando...' : 'Validando...',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          )
                                        : const Text('Validar e Salvar'),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _isLoading || apiConfigService.isVerifyingConfig ? null : _forcarValidacao,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      disabledBackgroundColor: Colors.grey.shade400,
                                    ),
                                    child: _isLoading || apiConfigService.isVerifyingConfig
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Aguarde...',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          )
                                        : const Text('Forçar Validação (Windows)'),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Use "Forçar Validação" apenas se a validação normal falhar no Windows.',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            } else {
                              // Para outras plataformas, mostrar apenas o botão normal
                              return ElevatedButton(
                                onPressed: _isLoading || apiConfigService.isVerifyingConfig ? null : _saveApiKey,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade400,
                                ),
                                child: _isLoading || apiConfigService.isVerifyingConfig
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            apiConfigService.isVerifyingConfig ? 'Verificando...' : 'Validando...',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      )
                                    : const Text('Validar e Salvar'),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
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
                        const SizedBox(height: 12),
                        _buildLimitItem(
                          'Limites da API Gemini (gratuita)',
                          '5 Requisições por minuto',
                          '250.000 Tokens por minuto',
                          '25 Requisições por dia / 1.000.000 de Tokens por dia',
                          Colors.purple,
                          isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nota: O aplicativo tentará usar o modelo experimental gemini-2.5-pro-exp-03-25. Se este modelo não estiver disponível, o sistema tentará os modelos gemini-2.5-pro-preview-03-25 ou gemini-2.5-flash-preview-04-17. Você pode obter uma chave API gratuita no Google AI Studio (aistudio.google.com).',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Importante: Certifique-se de que sua chave API tenha permissão para acessar os modelos da família Gemini 2.5.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.orange[300] : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                        const SizedBox(height: 8),
                        Text(
                          'Para gerar uma chave API gratuitamente, abra o navegador no site aistudio.google.com.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Faça o login com sua conta Google e siga as instruções no botão abaixo.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botão para configurações avançadas do MCP
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/mcp_config');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
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
                        const SizedBox(height: 16),
                        // Botão de ajuda
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApiInfoScreen(
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Ver Instruções'),
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
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                rpm,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.data_usage, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                tpm,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: color),
              const SizedBox(width: 4),
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

  // Retorna a cor apropriada com base no status
  Color _getStatusColor(String status) {
    if (status.isEmpty) {
      return Colors.grey;
    } else if (status.startsWith('Sucesso')) {
      return Colors.green;
    } else if (status.startsWith('Falha')) {
      return Colors.red;
    } else if (status.startsWith('Erro')) {
      return Colors.red.shade700;
    } else if (status.startsWith('Aguardando')) {
      return Colors.orange;
    } else if (status.startsWith('Tentativa')) {
      return Colors.blue;
    } else {
      return Colors.blue;
    }
  }

  // Retorna o ícone apropriado com base no status
  IconData _getStatusIcon(String status) {
    if (status.isEmpty) {
      return Icons.info_outline;
    } else if (status.startsWith('Sucesso')) {
      return Icons.check_circle_outline;
    } else if (status.startsWith('Falha') || status.startsWith('Erro')) {
      return Icons.error_outline;
    } else if (status.startsWith('Aguardando')) {
      return Icons.hourglass_empty;
    } else if (status.startsWith('Tentativa')) {
      return Icons.refresh;
    } else {
      return Icons.sync;
    }
  }

  // Retorna uma mensagem amigável com base no status
  String _getStatusMessage(String status) {
    if (status.isEmpty) {
      return 'Aguardando verificação';
    } else if (status.startsWith('Sucesso')) {
      return 'Verificação bem-sucedida';
    } else if (status.startsWith('Falha') || status.startsWith('Erro')) {
      return 'Falha na verificação';
    } else if (status.startsWith('Aguardando')) {
      return 'Aguardando...';
    } else if (status.startsWith('Tentativa')) {
      return 'Verificando...';
    } else {
      return 'Em andamento...';
    }
  }

  // Formata a data e hora
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours} horas';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
