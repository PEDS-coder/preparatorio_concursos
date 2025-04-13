import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serviço para verificar a conectividade com a internet
class ConnectivityService {
  static const String _googleDnsUrl = 'https://8.8.8.8';
  static const String _googleUrl = 'https://www.google.com';
  static const Duration _timeout = Duration(seconds: 5);

  /// Verifica se o dispositivo está conectado à internet
  static Future<bool> isConnected() async {
    try {
      if (kIsWeb) {
        // No ambiente web, assumimos que há conexão para evitar problemas de CORS
        debugPrint('Ambiente web detectado, assumindo conectividade');
        return true;
      } else {
        // Em dispositivos móveis, primeiro tentamos o ping do Google DNS
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(_timeout);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (e) {
          debugPrint('Erro ao verificar conectividade via DNS: $e');
          // Se falhar, tentamos uma requisição HTTP
          try {
            final response = await http.get(Uri.parse(_googleUrl))
                .timeout(_timeout);
            return response.statusCode == 200;
          } catch (e) {
            debugPrint('Erro ao verificar conectividade via HTTP: $e');
            return false;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Verifica se um serviço específico está acessível
  static Future<bool> canReachService(String url) async {
    try {
      if (kIsWeb) {
        // No ambiente web, assumimos que o serviço está acessível para evitar problemas de CORS
        debugPrint('Ambiente web detectado, assumindo que o serviço $url está acessível');
        return true;
      }

      final response = await http.get(Uri.parse(url))
          .timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      debugPrint('Erro ao verificar acesso ao serviço $url: $e');
      return false;
    }
  }
}
