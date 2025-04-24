import 'package:flutter/material.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/navigation/app_router.dart';
import 'core/data/services/interfaces/navigation_service_interface.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_service.dart';
import 'core/data/services/interfaces/analytics_service_interface.dart';
import 'core/services/analytics_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/theme_service.dart';
import 'core/widgets/maintenance_banner.dart';
import 'core/di/service_locator.dart';

class PreparatorioConcursosApp extends StatelessWidget {
  // Construtor
  PreparatorioConcursosApp({Key? key}) : super(key: key);

  // Não precisamos mais de uma chave global aqui, vamos usar a do NavigationService

  @override
  Widget build(BuildContext context) {
    // Obter serviços do service locator quando disponíveis
    // Se não estiverem disponíveis, usar Provider
    final analyticsService = getIt.isRegistered<IAnalyticsService>()
        ? getIt<IAnalyticsService>()
        : null;

    final remoteConfigService = getIt.isRegistered<RemoteConfigService>()
        ? getIt<RemoteConfigService>()
        : null;

    final navigationService = getIt.isRegistered<INavigationService>()
        ? getIt<INavigationService>()
        : null;

    // Usar o ThemeService do Provider
    final themeService = Provider.of<ThemeService>(context, listen: false);

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return MaintenanceBanner(
          child: MaterialApp(
            title: 'Preparatório Concursos',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.flutterThemeMode,
            navigatorKey: navigationService?.navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: '/',
            debugShowCheckedModeBanner: false,
            // Adicionar suporte para localização em português
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'), // Português do Brasil
              Locale('en', 'US'), // Inglês (fallback)
            ],
            locale: const Locale('pt', 'BR'), // Definir português como padrão
          ),
        );
      },
    );
  }
}