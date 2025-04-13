import 'package:flutter/material.dart';
import 'animated_route.dart';
import '../../features/0_splash/presentation/screens/splash_screen.dart';
import '../../features/0_splash/presentation/screens/welcome_screen.dart';
import '../../features/1_auth/presentation/screens/login_screen.dart';
import '../../features/1_auth/presentation/screens/register_screen.dart';
import '../../features/1_auth/presentation/screens/api_key_config_screen.dart';
import '../../features/2_dashboard/presentation/screens/dashboard_screen.dart';

import '../../features/3_edital_management/presentation/screens/edital_add_screen.dart';
import '../../features/3_edital_management/presentation/screens/edital_details_screen.dart';
import '../../features/3_edital_management/presentation/screens/edital_edit_screen.dart';
import '../../features/3_edital_management/presentation/screens/edital_analyze_screen.dart';
import '../../features/3_edital_management/presentation/screens/cargo_select_screen.dart';
import '../../features/4_study_plan/presentation/screens/plano_add_screen.dart';
import '../../features/4_study_plan/presentation/screens/plano_details_screen.dart';
import '../../features/4_study_plan/presentation/screens/plano_resumo_screen.dart';
import '../../features/5_study_session/presentation/screens/sessao_screen.dart';
import '../../features/6_gamification/presentation/screens/trofeus_screen.dart';
import '../../features/7_ai_tools/presentation/screens/ia_tools_screen.dart';
import '../../features/7_ai_tools/presentation/screens/flashcards_screen.dart';
import '../../features/7_ai_tools/presentation/screens/resumos_screen.dart';
import '../../features/7_ai_tools/presentation/screens/questoes_screen.dart';
import '../../features/7_ai_tools/presentation/screens/mapas_mentais_screen.dart';
import '../../features/9_settings/presentation/screens/settings_screen.dart';
import '../../features/9_settings/presentation/screens/audio_explanation_settings_screen.dart';
import '../../features/9_settings/presentation/screens/theme_settings_screen.dart';
import '../../features/8_mercado/presentation/screens/adicionar_recompensa_screen.dart';
import '../../features/8_mercado/presentation/screens/historico_moedas_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extrair argumentos da rota, se houver
    final args = settings.arguments;

    switch (settings.name) {
      // Rotas iniciais
      case '/':
        return AnimatedRoute(page: SplashScreen(), animationType: AnimationType.fade);
      case '/welcome':
        return AnimatedRoute(page: WelcomeScreen(), animationType: AnimationType.fadeScale);
      case '/login':
        return AnimatedRoute(page: LoginScreen(), animationType: AnimationType.fadeSlide);
      case '/register':
        return AnimatedRoute(page: RegisterScreen(), animationType: AnimationType.fadeSlide);
      case '/api_config':
        return AnimatedRoute(page: ApiKeyConfigScreen(), animationType: AnimationType.slideRight);
      case '/dashboard':
        return AnimatedRoute(page: DashboardScreen(), animationType: AnimationType.fadeScale);

      // Rotas de editais
      case '/editais':
        return AnimatedRoute(page: DashboardScreen(initialTabIndex: 1), animationType: AnimationType.fadeScale);
      case '/edital/add':
        return AnimatedRoute(page: EditalAddScreen(), animationType: AnimationType.slideRight);
      case '/edital/analyze':
        return AnimatedRoute(page: EditalAnalyzeScreen(), animationType: AnimationType.slideUp);
      case '/edital/detalhes':
        return AnimatedRoute(page: EditalDetailsScreen(editalId: args as String), animationType: AnimationType.fadeSlide);
      case '/edital/edit':
        return AnimatedRoute(page: EditalEditScreen(editalId: args as String), animationType: AnimationType.slideRight);
      case '/cargo/select':
        return AnimatedRoute(page: CargoSelectScreen(editalId: (args as Map<String, dynamic>)['editalId']), animationType: AnimationType.slideRight);

      // Rotas de plano de estudo
      case '/plano':
        return AnimatedRoute(page: DashboardScreen(initialTabIndex: 2), animationType: AnimationType.fadeScale);
      case '/plano/add':
        Map<String, dynamic> planoArgs;
        if (args is String) {
          planoArgs = {'editalId': args, 'cargoIds': <String>[]};
        } else if (args is Map<String, dynamic>) {
          planoArgs = args;
        } else {
          planoArgs = {'editalId': null, 'cargoIds': <String>[]};
        }
        return AnimatedRoute(
          page: PlanoAddScreen(
            editalId: planoArgs['editalId'],
            cargoIds: planoArgs['cargoIds'],
          ),
          animationType: AnimationType.slideRight,
        );
      case '/plano/detalhes':
        return AnimatedRoute(page: PlanoDetailsScreen(planoId: args as String), animationType: AnimationType.fadeSlide);
      case '/plano/resumo':
        return AnimatedRoute(page: PlanoResumoScreen(planoId: args as String), animationType: AnimationType.fadeScale);

      // Rotas de sessão de estudo
      case '/sessao':
        return AnimatedRoute(page: DashboardScreen(initialTabIndex: 0), animationType: AnimationType.fadeScale);
      case '/sessao/iniciar':
        return AnimatedRoute(page: SessaoScreen(itemId: args as String?), animationType: AnimationType.fadeScale);

      // Rotas de gamificação
      case '/gamificacao':
        return AnimatedRoute(page: DashboardScreen(initialTabIndex: 3), animationType: AnimationType.fadeScale);
      case '/trofeus':
        return AnimatedRoute(page: TrofeusScreen(), animationType: AnimationType.fadeSlide);

      // Rotas de ferramentas IA
      case '/ferramentas':
        return AnimatedRoute(page: DashboardScreen(initialTabIndex: 4), animationType: AnimationType.fadeScale);
      case '/flashcards':
        return AnimatedRoute(page: FlashcardsScreen(), animationType: AnimationType.slideRight);
      case '/resumos':
        return AnimatedRoute(page: ResumosScreen(), animationType: AnimationType.slideRight);
      case '/questoes':
        return AnimatedRoute(page: QuestoesScreen(), animationType: AnimationType.slideRight);
      case '/mapas_mentais':
        return AnimatedRoute(page: MapasMentaisScreen(), animationType: AnimationType.slideRight);

      // Rotas do Mercado Aprovação
      case '/mercado':
        return AnimatedRoute(page: DashboardScreen(initialTabIndex: 5), animationType: AnimationType.fadeScale);
      case '/mercado/adicionar':
        return AnimatedRoute(page: AdicionarRecompensaScreen(), animationType: AnimationType.slideUp);
      case '/mercado/historico':
        return AnimatedRoute(page: HistoricoMoedasScreen(), animationType: AnimationType.fadeSlide);

      // Configurações
      case '/settings':
        return AnimatedRoute(page: SettingsScreen(), animationType: AnimationType.slideLeft);
      case '/settings/audio_explanations':
        return AnimatedRoute(page: AudioExplanationSettingsScreen(), animationType: AnimationType.slideRight);
      case '/settings/theme':
        return AnimatedRoute(page: ThemeSettingsScreen(), animationType: AnimationType.slideRight);

      // Rota padrão para rotas não definidas
      default:
        return AnimatedRoute(
          page: Scaffold(
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
          animationType: AnimationType.fade,
        );
    }
  }
}