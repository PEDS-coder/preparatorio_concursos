import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serviço para verificar a conectividade com a internet
class ConnectivityService {
  static const String _googleDnsUrl = 'https://8.8.8.8';
  static const String _googleUrl = 'https://www.google.com';

  /// Verifica se o dispositivo está conectado à internet
  static Future<bool> isConnected() async {
    try {
      if (kIsWeb) {
        // No ambiente web, assumimos que há conexão para evitar problemas de CORS
        debugPrint('Ambiente web detectado, assumindo conectividade');
        return true;
      } else if (Platform.isWindows) {
        // No Windows, usar uma abordagem mais robusta
        return await _isConnectedWindows();
      } else {
        // Em outros dispositivos, usar a abordagem padrão
        return await _isConnectedStandard();
      }
    } catch (e) {
      debugPrint('Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Verifica conectividade em dispositivos padrão
  static Future<bool> _isConnectedStandard() async {
    try {
      // Primeiro tentamos o ping do Google DNS
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('Conectividade confirmada via DNS (google.com)');
        return true;
      }
    } catch (e) {
      debugPrint('Erro ao verificar conectividade via DNS: $e');
      // Se falhar, tentamos uma requisição HTTP
      try {
        final response = await http.get(Uri.parse(_googleUrl));
        if (response.statusCode == 200) {
          debugPrint('Conectividade confirmada via HTTP (Google)');
          return true;
        }
      } catch (e) {
        debugPrint('Erro ao verificar conectividade via HTTP: $e');
        return false;
      }
    }
    return false;
  }

  /// Verifica conectividade no Windows usando múltiplas abordagens
  static Future<bool> _isConnectedWindows() async {
    debugPrint('Verificando conectividade no Windows...');

    // Tentar múltiplas abordagens
    try {
      // 1. Tentar ping do Google DNS
      final result = await InternetAddress.lookup('8.8.8.8');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('Conectividade confirmada via DNS (8.8.8.8)');
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao verificar DNS (8.8.8.8): $e');
    }

    try {
      // 2. Tentar ping do Cloudflare DNS
      final result = await InternetAddress.lookup('1.1.1.1');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('Conectividade confirmada via DNS (1.1.1.1)');
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao verificar DNS (1.1.1.1): $e');
    }

    try {
      // 3. Tentar HTTP para Google
      final response = await http.get(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        debugPrint('Conectividade confirmada via HTTP (Google)');
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao verificar HTTP (Google): $e');
    }

    try {
      // 4. Tentar HTTP para Cloudflare
      final response = await http.get(Uri.parse('https://www.cloudflare.com'));
      if (response.statusCode == 200) {
        debugPrint('Conectividade confirmada via HTTP (Cloudflare)');
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao verificar HTTP (Cloudflare): $e');
    }

    // Se todas as tentativas falharem, assumir que não há conexão
    debugPrint('Todas as verificações de conectividade falharam no Windows');
    return false;
  }

  /// Verifica se um serviço específico está acessível
  static Future<bool> canReachService(String url) async {
    try {
      if (kIsWeb) {
        // No ambiente web, assumimos que o serviço está acessível para evitar problemas de CORS
        debugPrint('Ambiente web detectado, assumindo que o serviço $url está acessível');
        return true;
      } else if (Platform.isWindows) {
        // No Windows, usar uma abordagem mais robusta
        return await _canReachServiceWindows(url);
      }

      // Abordagem padrão para outros dispositivos
      final response = await http.get(Uri.parse(url));
      final bool isReachable = response.statusCode >= 200 && response.statusCode < 400;
      debugPrint('Serviço $url ${isReachable ? "acessível" : "inacessível"}: ${response.statusCode}');
      return isReachable;
    } catch (e) {
      debugPrint('Erro ao verificar acesso ao serviço $url: $e');
      return false;
    }
  }

  /// Verifica se um serviço específico está acessível no Windows
  static Future<bool> _canReachServiceWindows(String url) async {
    debugPrint('Verificando acesso ao serviço no Windows: $url');

    // Primeiro, verificar se há conexão com a internet
    if (!await _isConnectedWindows()) {
      debugPrint('Sem conexão com a internet no Windows');
      return false;
    }

    // Tentar múltiplas abordagens
    try {
      // 1. Tentar HTTP GET
      final response = await http.get(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        debugPrint('Serviço acessível via HTTP GET: $url (${response.statusCode})');
        return true;
      } else {
        debugPrint('Serviço inacessível via HTTP GET: $url (${response.statusCode})');
        // Mesmo com status code de erro, se conseguimos uma resposta, o serviço está acessível
        // Isso é importante para APIs que podem retornar 401/403 para chaves inválidas
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao verificar serviço via HTTP GET: $e');
    }

    try {
      // 2. Tentar HTTP HEAD
      final response = await http.head(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        debugPrint('Serviço acessível via HTTP HEAD: $url (${response.statusCode})');
        return true;
      } else {
        debugPrint('Serviço inacessível via HTTP HEAD: $url (${response.statusCode})');
        // Mesmo com status code de erro, se conseguimos uma resposta, o serviço está acessível
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao verificar serviço via HTTP HEAD: $e');
    }

    // Se todas as tentativas falharem, tentar uma abordagem alternativa
    try {
      // 3. Verificar se o domínio é resolvível
      final uri = Uri.parse(url);
      final result = await InternetAddress.lookup(uri.host);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('Domínio do serviço resolvível: ${uri.host}');
        // Se o domínio é resolvível, assumir que o serviço está acessível
        // Isso é um fallback para contornar possíveis problemas de firewall
        return true;
      }
    } catch (e) {
      debugPrint('Falha ao resolver domínio do serviço: $e');
    }

    // Se todas as tentativas falharem, assumir que o serviço não está acessível
    debugPrint('Todas as verificações de acesso ao serviço falharam no Windows: $url');
    return false;
  }
}
