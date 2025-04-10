import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/auth/auth_service.dart';
import 'core/data/services/services.dart';
import 'core/services/document_classifier_service.dart';
import 'core/services/api_config_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        Provider.value(value: documentClassifierService),
      ],
      child: PreparatorioConcursosApp(),
    ),
  );
}