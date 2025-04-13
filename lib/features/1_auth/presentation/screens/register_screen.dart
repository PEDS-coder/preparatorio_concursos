import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPremium = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.register(
          _nomeController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          isPremium: _isPremium,
        );

        if (success) {
          // Navegar para a tela de configuração da API
          Navigator.pushReplacementNamed(context, '/api_config');
        } else {
          setState(() {
            _errorMessage = 'Erro ao criar conta. Tente novamente.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Ocorreu um erro. Tente novamente mais tarde.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Botão de voltar
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Logo
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person_add,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),

                      // Título
                      Text(
                        'Criar Conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: 10),

                      // Subtítulo
                      Text(
                        'Preencha os campos para começar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      SizedBox(height: 40),

                      // Campo de nome
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Nome Completo',
                          hintText: 'Seu nome e sobrenome',
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        controller: _nomeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu nome';
                          }
                          if (value.trim().split(' ').length < 2) {
                            return 'Por favor, insira nome e sobrenome';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Campo de email
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Seu endereço de email',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu email';
                          }
                          if (!value.contains('@')) {
                            return 'Por favor, insira um email válido';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Campo de senha
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Crie uma senha segura',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Campo de confirmação de senha
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          hintText: 'Repita sua senha',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua senha';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 30),

                      // Opções de plano
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESCOLHA SEU PLANO',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildPlanOptions(),
                          ],
                        ),
                      ),

                      // Mensagem de erro
                      if (_errorMessage != null)
                        Container(
                          margin: EdgeInsets.only(top: 24),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Botão de cadastro
                      SizedBox(height: 30),
                      _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                minimumSize: Size(double.infinity, 48),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('CRIAR CONTA'),
                            ),

                      SizedBox(height: 30),

                      // Link para login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem uma conta?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Entrar',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOptions() {
    return Column(
      children: [
        _buildPlanOption(
          title: 'Plano Gratuito',
          description: 'Acesso básico com recursos limitados',
          isSelected: !_isPremium,
          onTap: () {
            setState(() {
              _isPremium = false;
            });
          },
        ),
        SizedBox(height: 12),
        _buildPlanOption(
          title: 'Plano Premium',
          description: 'Acesso completo a todos os recursos',
          isSelected: _isPremium,
          isPremium: true,
          onTap: () {
            setState(() {
              _isPremium = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String description,
    required bool isSelected,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isPremium ? Colors.amber : AppTheme.secondaryColor)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          color: isSelected
              ? (isPremium
                  ? Colors.amber.withOpacity(0.1)
                  : AppTheme.secondaryColor.withOpacity(0.1))
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isPremium ? Colors.amber : AppTheme.secondaryColor)
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: isSelected
                    ? (isPremium ? Colors.amber : AppTheme.secondaryColor)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (isPremium) ...[
                        SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
