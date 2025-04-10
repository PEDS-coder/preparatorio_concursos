import 'package:flutter/material.dart';
import '../../features/0_splash/presentation/screens/splash_screen.dart';
import '../../features/0_splash/presentation/screens/welcome_screen.dart';
import '../../features/1_auth/presentation/screens/login_screen.dart';
import '../../features/1_auth/presentation/screens/register_screen_new.dart' as new_register;
import '../../features/1_auth/presentation/screens/api_key_config_screen_new.dart' as new_api_config;
import '../../features/2_dashboard/presentation/screens/dashboard_screen.dart';

import '../../features/3_edital_management/presentation/screens/edital_add_screen.dart';
import '../../features/3_edital_management/presentation/screens/edital_details_screen.dart';
import '../../features/3_edital_management/presentation/screens/edital_edit_screen.dart';
import '../../features/3_edital_management/presentation/screens/edital_analyze_screen.dart';
import '../../features/3_edital_management/presentation/screens/cargo_select_screen.dart';
import '../../features/4_study_plan/presentation/screens/plano_add_screen.dart';
import '../../features/4_study_plan/presentation/screens/plano_details_screen.dart';
import '../../features/4_study_plan/presentation/screens/plano_calendario_screen.dart';
import '../../features/5_study_session/presentation/screens/sessao_screen.dart';
import '../../features/6_gamification/presentation/screens/trofeus_screen.dart';
import '../../features/7_ai_tools/presentation/screens/ia_tools_screen.dart';
import '../../features/7_ai_tools/presentation/screens/flashcards_screen.dart';
import '../../features/7_ai_tools/presentation/screens/resumos_screen.dart';
import '../../features/7_ai_tools/presentation/screens/questoes_screen.dart';
import '../../features/7_ai_tools/presentation/screens/mapas_mentais_screen.dart';
import '../../features/9_settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extrair argumentos da rota, se houver
    final args = settings.arguments;

    switch (settings.name) {
      // Rotas iniciais
      case '/':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case '/welcome':
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => new_register.RegisterScreen());
      case '/api_config':
        return MaterialPageRoute(builder: (_) => new_api_config.ApiKeyConfigScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => DashboardScreen());

      // Rotas de editais
      case '/editais':
        return MaterialPageRoute(builder: (_) => DashboardScreen(initialTabIndex: 1));
      case '/edital/add':
        return MaterialPageRoute(builder: (_) => EditalAddScreen());
      case '/edital/analyze':
        return MaterialPageRoute(builder: (_) => EditalAnalyzeScreen());
      case '/edital/detalhes':
        return MaterialPageRoute(builder: (_) => EditalDetailsScreen(editalId: args as String));
      case '/edital/edit':
        return MaterialPageRoute(builder: (_) => EditalEditScreen(editalId: args as String));
      case '/cargo/select':
        return MaterialPageRoute(builder: (_) => CargoSelectScreen(editalId: (args as Map<String, dynamic>)['editalId']));

      // Rotas de plano de estudo
      case '/plano':
        return MaterialPageRoute(builder: (_) => DashboardScreen(initialTabIndex: 2));
      case '/plano/add':
        Map<String, dynamic> planoArgs;
        if (args is String) {
          planoArgs = {'editalId': args, 'cargoIds': <String>[]};
        } else if (args is Map<String, dynamic>) {
          planoArgs = args;
        } else {
          planoArgs = {'editalId': null, 'cargoIds': <String>[]};
        }
        return MaterialPageRoute(builder: (_) => PlanoAddScreen(
          editalId: planoArgs['editalId'],
          cargoIds: planoArgs['cargoIds'],
        ));
      case '/plano/detalhes':
        return MaterialPageRoute(builder: (_) => PlanoDetailsScreen(planoId: args as String));
      case '/plano/calendario':
        return MaterialPageRoute(builder: (_) => PlanoCalendarioScreen(planoId: args as String));

      // Rotas de sessão de estudo
      case '/sessao':
        return MaterialPageRoute(builder: (_) => DashboardScreen(initialTabIndex: 0));
      case '/sessao/iniciar':
        return MaterialPageRoute(builder: (_) => SessaoScreen(itemId: args as String?));

      // Rotas de gamificação
      case '/gamificacao':
        return MaterialPageRoute(builder: (_) => DashboardScreen(initialTabIndex: 3));
      case '/trofeus':
        return MaterialPageRoute(builder: (_) => TrofeusScreen());

      // Rotas de ferramentas IA
      case '/ia':
        return MaterialPageRoute(builder: (_) => IAToolsScreen());
      case '/flashcards':
        return MaterialPageRoute(builder: (_) => FlashcardsScreen());
      case '/resumos':
        return MaterialPageRoute(builder: (_) => ResumosScreen());
      case '/questoes':
        return MaterialPageRoute(builder: (_) => QuestoesScreen());
      case '/mapas_mentais':
        return MaterialPageRoute(builder: (_) => MapasMentaisScreen());

      // Configurações
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());

      // Rota padrão para rotas não definidas
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Erro de Navegação')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Rota não encontrada',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('A rota "${settings.name}" não está definida.'),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(_, '/dashboard'),
                    child: Text('Voltar para o Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}