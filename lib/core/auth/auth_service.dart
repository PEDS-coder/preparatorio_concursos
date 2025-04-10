import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/usuario.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  Usuario? _currentUser;
  String _assinaturaAtual = 'free'; // 'free' ou 'premium'

  bool get isAuthenticated => _isAuthenticated;
  Usuario? get currentUser => _currentUser;
  String get assinaturaAtual => _assinaturaAtual;
  bool get isPremium => _assinaturaAtual == 'premium';

  // Método para verificar se o usuário está autenticado ao iniciar o app
  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      try {
        final userMap = json.decode(userJson);
        _currentUser = Usuario.fromMap(userMap);
        _assinaturaAtual = _currentUser?.nivelAssinatura ?? 'free';
      } catch (e) {
        _isAuthenticated = false;
        _currentUser = null;
      }
    }

    notifyListeners();
    return _isAuthenticated;
  }

  // Método para fazer login
  Future<bool> login(String email, String password) async {
    // Simulação de autenticação - em produção, isso seria uma chamada de API
    if (email.isNotEmpty && password.isNotEmpty) {
      // Simular um atraso de rede
      await Future.delayed(Duration(seconds: 1));

      // Verificação básica - em produção, isso seria validado pelo backend
      if (email.contains('@') && password.length >= 6) {
        // Criar um usuário simulado
        _currentUser = Usuario(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nome: email.split('@')[0], // Usar parte do email como nome
          email: email,
          senha: password, // Em produção, seria apenas o hash
          nivelAssinatura: 'free',
        );

        _isAuthenticated = true;
        _assinaturaAtual = _currentUser!.nivelAssinatura;

        // Salvar estado de autenticação
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('currentUser', json.encode(_currentUser!.toMap()));

        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Método para fazer cadastro
  Future<bool> register(String nome, String email, String password, {bool isPremium = false}) async {
    // Simulação de cadastro - em produção, isso seria uma chamada de API
    if (nome.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      // Simular um atraso de rede
      await Future.delayed(Duration(seconds: 1));

      // Verificação básica - em produção, isso seria validado pelo backend
      if (email.contains('@') && password.length >= 6) {
        // Criar um novo usuário
        _currentUser = Usuario(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nome: nome,
          email: email,
          senha: password, // Em produção, seria apenas o hash
          nivelAssinatura: isPremium ? 'premium' : 'free',
        );

        _isAuthenticated = true;
        _assinaturaAtual = _currentUser!.nivelAssinatura;

        // Salvar estado de autenticação
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('currentUser', json.encode(_currentUser!.toMap()));

        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Método para fazer logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    _assinaturaAtual = 'free';

    // Limpar estado de autenticação
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('currentUser');

    notifyListeners();
  }

  // Método para atualizar para premium
  Future<bool> upgradeToPremium() async {
    // Simulação de upgrade - em produção, isso seria uma chamada de API após pagamento
    if (_currentUser != null) {
      // Simular um atraso de rede
      await Future.delayed(Duration(seconds: 1));

      // Atualizar o usuário para premium
      _currentUser = _currentUser!.copyWith(nivelAssinatura: 'premium');
      _assinaturaAtual = 'premium';

      // Salvar estado atualizado
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', json.encode(_currentUser!.toMap()));

      notifyListeners();
      return true;
    }
    return false;
  }

  // Método para verificar se uma funcionalidade premium está disponível
  bool isPremiumFeatureAvailable(String feature) {
    // Lista de features premium
    final premiumFeatures = [
      'flashcards_ilimitados',
      'resumos_ia',
      'mapas_mentais',
      'editais_ilimitados',
      'google_calendar',
      'plano_avancado',
    ];

    // Se o usuário é premium, todas as features estão disponíveis
    if (isPremium) return true;

    // Se a feature não é premium, está disponível para todos
    if (!premiumFeatures.contains(feature)) return true;

    // Caso contrário, não está disponível
    return false;
  }
}