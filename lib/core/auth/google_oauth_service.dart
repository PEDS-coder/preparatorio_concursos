import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_logger.dart';

/// Serviço para gerenciar a autenticação OAuth com o Google
class GoogleOAuthService extends ChangeNotifier {
  static const String _tag = 'GoogleOAuthService';

  // Credenciais do cliente OAuth
  final String _clientId;
  final String _clientSecret;

  // Token de acesso
  AccessToken? _accessToken;

  // Cliente HTTP autenticado
  http.Client? _authenticatedClient;

  // Estado da autenticação
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;
  http.Client? get authenticatedClient => _authenticatedClient;

  // Construtor
  GoogleOAuthService({
    required String clientId,
    required String clientSecret,
  }) : _clientId = clientId,
       _clientSecret = clientSecret {
    _loadTokenFromStorage();
  }

  // Carregar token salvo
  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString('google_oauth_token');

      if (tokenJson != null) {
        final tokenData = json.decode(tokenJson);
        _accessToken = AccessToken(
          tokenData['type'],
          tokenData['data'],
          DateTime.parse(tokenData['expiry']),
        );

        // Verificar se o token ainda é válido
        if (_accessToken!.expiry.isAfter(DateTime.now())) {
          _isAuthenticated = true;
          _createAuthenticatedClient();
          notifyListeners();
          AppLogger.i(_tag, 'Token OAuth carregado com sucesso');
        } else {
          AppLogger.w(_tag, 'Token OAuth expirado');
          _accessToken = null;
        }
      }
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao carregar token OAuth', e);
    }
  }

  // Salvar token
  Future<void> _saveTokenToStorage(AccessToken token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenData = {
        'type': token.type,
        'data': token.data,
        'expiry': token.expiry.toIso8601String(),
      };
      await prefs.setString('google_oauth_token', json.encode(tokenData));
      // AppLogger.i(_tag, 'Token OAuth salvo com sucesso'); // Comentado para evitar log massivo de token
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao salvar token OAuth', e);
    }
  }

  // Criar cliente autenticado
  void _createAuthenticatedClient() {
    if (_accessToken != null) {
      final credentials = AccessCredentials(
        _accessToken!,
        null,
        ['https://www.googleapis.com/auth/generative-language.retriever'],
      );
      _authenticatedClient = autoRefreshingClient(ClientId('', ''), credentials, http.Client());
    }
  }

  // Autenticar com o Google
  Future<bool> authenticate() async {
    try {
      _isAuthenticating = true;
      _errorMessage = null;
      notifyListeners();

      // Configurar cliente OAuth
      final clientId = ClientId(_clientId, _clientSecret);

      // Escopos necessários para a API Gemini
      const scopes = ['https://www.googleapis.com/auth/generative-language.retriever'];

      // Função para abrir a URL de autenticação
      void openUrl(String url) {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }

      // Autenticar com o Google
      final client = await clientViaUserConsent(
        clientId,
        scopes,
        openUrl,
      );

      // Obter credenciais
      final credentials = client.credentials;
      _accessToken = credentials.accessToken;

      // Salvar token
      await _saveTokenToStorage(_accessToken!);

      // Atualizar estado
      _isAuthenticated = true;
      _authenticatedClient = client;

      _isAuthenticating = false;
      notifyListeners();

      AppLogger.i(_tag, 'Autenticado com o Google com sucesso');
      return true;
    } catch (e) {
      _isAuthenticating = false;
      _errorMessage = 'Erro ao autenticar com o Google: $e';
      notifyListeners();

      AppLogger.e(_tag, 'Erro ao autenticar com o Google', e);
      return false;
    }
  }

  // Desautenticar
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_oauth_token');

      _accessToken = null;
      _authenticatedClient?.close();
      _authenticatedClient = null;
      _isAuthenticated = false;

      notifyListeners();
      AppLogger.i(_tag, 'Logout realizado com sucesso');
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao fazer logout', e);
    }
  }

  // Verificar se o token ainda é válido
  bool isTokenValid() {
    if (_accessToken == null) return false;
    return _accessToken!.expiry.isAfter(DateTime.now());
  }

  // Obter cliente HTTP autenticado
  Future<http.Client?> getAuthenticatedClient() async {
    if (!isTokenValid()) {
      // Tentar renovar o token
      final success = await authenticate();
      if (!success) return null;
    }
    return _authenticatedClient;
  }
}
