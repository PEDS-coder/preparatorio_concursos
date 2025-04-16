import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/google_oauth_service.dart';
import 'core/di/service_locator.dart';
import 'core/data/services/services.dart';
import 'core/data/services/interfaces/ia_service_interface.dart';
import 'core/data/services/interfaces/analytics_service_interface.dart';
import 'core/data/services/interfaces/secure_storage_service_interface.dart';
import 'core/services/temp_secure_storage_service.dart';
import 'core/data/services/document_storage_service.dart';
import 'core/data/services/mercado_service.dart';
import 'core/services/document_classifier_service.dart';
import 'core/services/api_config_service.dart';
import 'core/services/audio_explanation_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/utils/cache_manager.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  try {
    print('Inicializando aplicação...');
    WidgetsFlutterBinding.ensureInitialized();
    print('WidgetsFlutterBinding inicializado com sucesso');

    // Inicializar injeção de dependência
    print('Configurando injeção de dependência...');
    configureDependencies();
    print('Injeção de dependência configurada com sucesso');

  // Limpar o cache de análises de editais ao iniciar
  try {
    await CacheManager.clearCache();
    print('Cache de análises de editais limpo com sucesso!');
  } catch (e) {
    print('Erro ao limpar cache: $e');
    // Continuar mesmo com erro
  }

  // Carregar variáveis de ambiente do arquivo .env
  try {
    print('Carregando variáveis de ambiente...');
    await dotenv.load(fileName: ".env");
    print('Variáveis de ambiente carregadas com sucesso');
  } catch (e) {
    print('ERRO ao carregar variáveis de ambiente: $e');
    // Continuar mesmo com erro
  }

  // Inicializar dados de localização para formatação de datas
  await initializeDateFormatting('pt_BR', null);

  // Criar instância do AuthService primeiro
  print('Inicializando AuthService...');
  final authService = AuthService();
  try {
    await authService.checkAuthStatus();
    print('Status de autenticação verificado com sucesso');
  } catch (e) {
    print('ERRO ao verificar status de autenticação: $e');
    // Continuar mesmo com erro
  }

  // Criar instâncias dos outros serviços
  // Tentar usar o service locator quando possível
  final editalService = EditalService();
  final planoEstudoService = PlanoEstudoService();
  final sessaoEstudoService = SessaoEstudoService();
  final gamificacaoService = GamificacaoService(authService);
  // Tentar obter do service locator primeiro
  final iaService = getIt.isRegistered<IAService>() ? getIt.get<IAService>() : IAService();
  final apiConfigService = getIt.isRegistered<ApiConfigService>()
      ? getIt.get<ApiConfigService>()
      : ApiConfigService(
          getIt.isRegistered<ISecureStorageService>() ? getIt.get<ISecureStorageService>() : TempSecureStorageService(Logger()),
          getIt.isRegistered<Logger>() ? getIt.get<Logger>() : Logger(),
        );
  final audioExplanationService = AudioExplanationService();
  final documentStorageService = DocumentStorageService();
  final mercadoService = MercadoService(authService);

  // Criar instância do GoogleOAuthService
  // Nota: As credenciais serão carregadas na tela de configuração OAuth

  // Criar instância do ThemeService
  final themeService = getIt.isRegistered<ThemeService>()
      ? getIt.get<ThemeService>()
      : ThemeService(
          getIt.isRegistered<Logger>() ? getIt.get<Logger>() : Logger(),
          getIt.isRegistered<IAnalyticsService>() ? getIt.get<IAnalyticsService>() : AnalyticsService(Logger()),
        );

  // Criar instância do RemoteConfigService
  final remoteConfigService = getIt.isRegistered<RemoteConfigService>()
      ? getIt.get<RemoteConfigService>()
      : RemoteConfigService(
          getIt.isRegistered<Logger>() ? getIt.get<Logger>() : Logger(),
          getIt.isRegistered<IAnalyticsService>() ? getIt.get<IAnalyticsService>() : AnalyticsService(Logger()),
        );

  // Conectar o serviço de sessão de estudo com o serviço de mercado
  sessaoEstudoService.setMercadoService(mercadoService);

  // Desabilitar o serviço de áudio de explicação
  await audioExplanationService.setExplanationsEnabled(false);

  // Inicializar o cache do serviço de IA
  print('Inicializando cache do serviço de IA...');
  try {
    await iaService.initCache();
    print('Cache do serviço de IA inicializado com sucesso');
  } catch (e) {
    print('ERRO ao inicializar cache do serviço de IA: $e');
    // Continuar mesmo com erro
  }

  // Configurar o serviço de IA no ApiConfigService para verificação proativa
  apiConfigService.setIAService(iaService);

  // Verificar conectividade com a internet
  final bool isConnected = await ConnectivityService.isConnected();
  print('Conectividade com a internet: ${isConnected ? "OK" : "Falha"}');

  // Verificar proativamente a configuração da API LLM
  print('Verificando configuração da API LLM...');
  try {
    await apiConfigService.verificarConfiguracao();
    print('Configuração da API LLM verificada com sucesso');
  } catch (e) {
    print('ERRO ao verificar configuração da API LLM: $e');
    // Continuar mesmo com erro
  }
  final documentClassifierService = DocumentClassifierService(iaService);

  // Carregar dados iniciais
  print('Carregando dados iniciais...');
  try {
    await editalService.loadEditais();
    await planoEstudoService.loadPlanos();
    await sessaoEstudoService.loadSessoes();
    await gamificacaoService.loadUsuarioTrofeus();
    // Resetar o bônus diário à meia-noite
    await mercadoService.resetarBonusDiario();
    print('Dados iniciais carregados com sucesso');
  } catch (e) {
    print('ERRO ao carregar dados iniciais: $e');
    // Continuar mesmo com erro
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: editalService),
        ChangeNotifierProvider.value(value: planoEstudoService),
        ChangeNotifierProvider.value(value: sessaoEstudoService),
        ChangeNotifierProvider.value(value: gamificacaoService),
        ChangeNotifierProvider.value(value: iaService),
        ChangeNotifierProvider.value(value: apiConfigService),
        ChangeNotifierProvider.value(value: audioExplanationService),
        ChangeNotifierProvider.value(value: documentStorageService),
        ChangeNotifierProvider.value(value: mercadoService),
        ChangeNotifierProvider.value(value: themeService),
        Provider.value(value: remoteConfigService),
        Provider.value(value: documentClassifierService),
      ],
      child: PreparatorioConcursosApp(),
    ),
  );
  } catch (e) {
    print('ERRO FATAL ao inicializar aplicação: $e');
    rethrow; // Relançar o erro para que o Flutter mostre a tela de erro
  }
}