import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/auth/auth_service.dart';
import 'core/data/services/services.dart';
import 'core/services/document_classifier_service.dart';
import 'core/services/api_config_service.dart';
import 'core/services/audio_explanation_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/utils/cache_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar o cache de análises de editais
  try {
    // Não limpar o cache automaticamente para preservar análises anteriores
    // await CacheManager.clearCache();
    // print('Cache de análises de editais limpo com sucesso!');
  } catch (e) {
    print('Erro ao inicializar cache: $e');
    // Continuar mesmo com erro
  }

  // Carregar variáveis de ambiente do arquivo .env
  await dotenv.load(fileName: ".env");

  // Inicializar dados de localização para formatação de datas
  await initializeDateFormatting('pt_BR', null);

  // Criar instância do AuthService primeiro
  final authService = AuthService();
  await authService.checkAuthStatus();

  // Criar instâncias dos outros serviços
  final editalService = EditalService();
  final planoEstudoService = PlanoEstudoService();
  final sessaoEstudoService = SessaoEstudoService();
  final gamificacaoService = GamificacaoService(authService);
  final iaService = IAService();
  final apiConfigService = ApiConfigService();
  final audioExplanationService = AudioExplanationService();

  // Inicializar o serviço de áudio de explicação
  await audioExplanationService.init();

  // Inicializar o cache do serviço de IA
  await iaService.initCache();

  // Configurar o serviço de IA no ApiConfigService para verificação proativa
  apiConfigService.setIAService(iaService);

  // Verificar conectividade com a internet
  final bool isConnected = await ConnectivityService.isConnected();
  print('Conectividade com a internet: ${isConnected ? "OK" : "Falha"}');

  // Verificar proativamente a configuração da API LLM
  await apiConfigService.verificarConfiguracao();
  final documentClassifierService = DocumentClassifierService(iaService);

  // Carregar dados iniciais
  await editalService.loadEditais();
  await planoEstudoService.loadPlanos();
  await sessaoEstudoService.loadSessoes();
  await gamificacaoService.loadUsuarioTrofeus();

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
        Provider.value(value: documentClassifierService),
      ],
      child: PreparatorioConcursosApp(),
    ),
  );
}