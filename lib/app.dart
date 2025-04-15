import 'package:flutter/material.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/theme_service.dart';
import 'core/widgets/maintenance_banner.dart';

class PreparatorioConcursosApp extends StatelessWidget {
  // Construtor
  PreparatorioConcursosApp({Key? key}) : super(key: key);

  // Chave global para o navegador
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Comentar temporariamente os serviços que estão causando problemas
    // final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    // final remoteConfigService = Provider.of<RemoteConfigService>(context, listen: false);
    // final navigationService = Provider.of<NavigationService>(context, listen: false);
    // final themeService = Provider.of<ThemeService>(context);

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return MaintenanceBanner(
          child: MaterialApp(
            title: 'Preparatório Concursos',
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light().copyWith(
                primary: Colors.blue,
                secondary: Colors.cyan,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark().copyWith(
                primary: Colors.blue,
                secondary: Colors.cyan,
              ),
            ),
            themeMode: ThemeMode.dark,
            navigatorKey: _navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: '/',
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}