import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Aguardar 2 segundos para mostrar a splash screen
    await Future.delayed(Duration(seconds: 2));

    // Verificar se o usuário está autenticado
    final authService = Provider.of<AuthService>(context, listen: false);
    final iaService = Provider.of<IAService>(context, listen: false);
    final isAuthenticated = authService.isAuthenticated;

    // Verificar se a API Key já foi configurada
    final prefs = await SharedPreferences.getInstance();
    final apiKeySkipped = prefs.getBool('api_key_skipped') ?? false;
    final apiKey = prefs.getString('api_key');
    final apiType = prefs.getString('api_type');

    // Configurar API Key se já estiver salva
    if (apiKey != null && apiKey.isNotEmpty) {
      iaService.configurarApiKey(apiKey);
      if (apiType != null) {
        iaService.setApiType(apiType);
      }
    }

    // Sempre começar pela tela de boas-vindas para garantir o fluxo completo
    // Isso força o usuário a passar pelo login e configuração da API
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Fundo com gradiente sutil
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
            ),
          ),

          // Efeito de brilho no topo
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.darkBackground.withOpacity(0.0),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Conteúdo principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado com brilho
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 1000),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5 * value,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Título com animação de fade
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: Text(
                    'CONCURSEIRO PRO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Linha pulsante
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, double value, child) {
                    return Container(
                      width: 180 * value,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: AppTheme.secondaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Subtítulo com animação de fade
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: Text(
                    'Sua Aprovação Inteligente',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 60),

                // Indicador de carregamento personalizado
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}