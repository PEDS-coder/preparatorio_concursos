import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:feedback/feedback.dart';

import 'core/auth/auth_service.dart';
import 'core/data/services/services.dart';
import 'core/data/services/document_storage_service.dart';
import 'core/data/services/mercado_service.dart';
import 'core/di/service_locator.dart';
import 'core/services/analytics_service.dart';
import 'core/services/document_classifier_service.dart';
import 'core/services/api_config_service.dart';
import 'core/services/audio_explanation_service.dart';
import 'core/services/calendar_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/error_handler_service.dart';
import 'core/services/feedback_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/share_service.dart';
import 'core/services/theme_service.dart';
import 'core/navigation/navigation_service.dart';
import 'core/providers/error_handler_provider.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar o Firebase
  await Firebase.initializeApp();

  // Configurar injeção de dependência
  configureDependencies();

  // Obter o logger do container de injeção de dependência
  final logger = getIt<Logger>();

  // Configurar o Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Capturar erros que ocorrem durante a inicialização do aplicativo
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Configurar o nível de log com base no modo de execução
  logger.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

  // Registrar início da aplicação
  logger.info('Iniciando aplicação', tag: 'App');

  // Inicializar o cache de análises de editais
  try {
    // Não limpar o cache automaticamente para preservar análises anteriores
    // await CacheManager.clearCache();
    logger.debug('Cache de análises de editais mantido', tag: 'Cache');
  } catch (e) {
    logger.error('Erro ao inicializar cache', tag: 'Cache', error: e);
    // Continuar mesmo com erro
  }

  // Carregar variáveis de ambiente do arquivo .env
  await dotenv.load(fileName: ".env");

  // Inicializar dados de localização para formatação de datas
  await initializeDateFormatting('pt_BR', null);

  // Criar instância do AuthService primeiro
  final authService = AuthService();
  await authService.checkAuthStatus();

  // Obter serviços do container de injeção de dependência
  final errorHandlerService = getIt<ErrorHandlerService>();
  final iaService = getIt<IAService>();
  final analyticsService = getIt<AnalyticsService>();
  final remoteConfigService = getIt<RemoteConfigService>();
  final feedbackService = getIt<FeedbackService>();
  final navigationService = getIt<NavigationService>();
  final themeService = getIt<ThemeService>();
  final calendarService = getIt<CalendarService>();
  final shareService = getIt<ShareService>();

  // Criar instâncias dos outros serviços (que ainda não foram migrados para DI)
  final editalService = EditalService();
  final planoEstudoService = PlanoEstudoService();
  final sessaoEstudoService = SessaoEstudoService();
  final gamificacaoService = GamificacaoService(authService);
  final apiConfigService = ApiConfigService();
  final audioExplanationService = AudioExplanationService();
  final documentStorageService = DocumentStorageService();
  final mercadoService = MercadoService(authService);

  // Conectar o serviço de sessão de estudo com o serviço de mercado
  sessaoEstudoService.setMercadoService(mercadoService);

  // Inicializar o serviço de áudio de explicação
  await audioExplanationService.init();

  // Inicializar o cache do serviço de IA
  await iaService.initCache();

  // Configurar o serviço de IA no ApiConfigService para verificação proativa
  apiConfigService.setIAService(iaService);

  // Verificar conectividade com a internet
  final bool isConnected = await ConnectivityService.isConnected();
  logger.info('Conectividade com a internet: ${isConnected ? "OK" : "Falha"}', tag: 'Conectividade');

  // Verificar proativamente a configuração da API LLM
  await apiConfigService.verificarConfiguracao();
  final documentClassifierService = DocumentClassifierService(iaService);

  // Carregar dados iniciais
  await editalService.loadEditais();
  await planoEstudoService.loadPlanos();
  await sessaoEstudoService.loadSessoes();
  await gamificacaoService.loadUsuarioTrofeus();
  // Resetar o bônus diário à meia-noite
  await mercadoService.resetarBonusDiario();

  // Inicializar o serviço de feedback
  final feedbackTheme = feedbackService.initFeedback();

  runApp(
    ErrorHandlerProvider(
      errorHandler: errorHandlerService,
      child: feedbackTheme.child = MultiProvider(
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
          Provider.value(value: documentClassifierService),
          Provider.value(value: logger),
          Provider.value(value: analyticsService),
          Provider.value(value: remoteConfigService),
          Provider.value(value: feedbackService),
          Provider.value(value: navigationService),
          ChangeNotifierProvider.value(value: themeService),
          Provider.value(value: calendarService),
          Provider.value(value: shareService),
        ],
        child: PreparatorioConcursosApp(),
      ),
    ),
  );

  // Registrar conclusão da inicialização
  logger.info('Aplicação inicializada com sucesso', tag: 'App');
}