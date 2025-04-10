import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_service.dart';

class PreparatorioConcursosApp extends StatelessWidget {
  const PreparatorioConcursosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return MaterialApp(
          title: 'Preparatório Concursos',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Usando tema escuro por padrão para o design moderno
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: '/',
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}