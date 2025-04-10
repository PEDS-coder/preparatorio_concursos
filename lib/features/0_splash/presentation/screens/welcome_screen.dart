import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Fundo com efeito de brilho
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.darkBackground.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Efeito de brilho secundário
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondaryColor.withOpacity(0.15),
                    AppTheme.darkBackground.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 60),

                    // Logo e título
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.school,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),

                    // Título principal
                    Text(
                      'Sua Aprovação Inteligente',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),

                    // Subtítulo
                    Text(
                      'Começa Aqui',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.secondaryColor,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 60),

                    // Botões de ação
                    GradientButton(
                      child: Text('ENTRAR'),
                      icon: Icon(Icons.login, color: Colors.white),
                      gradient: AppTheme.secondaryGradient,
                      fullWidth: true,
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    ),
                    SizedBox(height: 20),

                    GradientButton(
                      child: Text('CADASTRAR'),
                      icon: Icon(Icons.person_add, color: Colors.white),
                      fullWidth: true,
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                    ),
                    SizedBox(height: 20),

                    OutlineGradientButton(
                      child: Text('CONTINUAR SEM CONTA'),
                      icon: Icon(Icons.public, color: Colors.white),
                      fullWidth: true,
                      onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                    ),

                    // Informações sobre o modelo freemium
                    SizedBox(height: 60),
                    _buildFreemiumInfo(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreemiumInfo() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'MODELO FREEMIUM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildFeatureRow('Análise de 1 edital', true),
          _buildFeatureRow('Plano de estudo básico', true),
          _buildFeatureRow('Gamificação limitada', true),
          Divider(color: Colors.white.withOpacity(0.1), height: 30),
          _buildFeatureRow('Análises ilimitadas', false),
          _buildFeatureRow('Ferramentas de IA', false),
          _buildFeatureRow('Integração Google Agenda', false),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable
                  ? AppTheme.successColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.2),
            ),
            child: Center(
              child: Icon(
                isAvailable ? Icons.check : Icons.lock,
                color: isAvailable ? AppTheme.successColor : AppTheme.primaryColor,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isAvailable ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (!isAvailable)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
