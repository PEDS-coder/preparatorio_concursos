import 'dart:io';
import 'package:http/http.dart' as http;

/// Serviço para verificar a conectividade com a internet e serviços externos
class ConnectivityService {
  /// Verifica se o dispositivo tem conexão com a internet
  static Future<bool> isConnected() async {
    try {
      print('[ConnectivityService] Verificando conexão com a internet...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('[ConnectivityService] Conexão com a internet OK');
        return true;
      }
      print('[ConnectivityService] Sem conexão com a internet');
      return false;
    } on SocketException catch (e) {
      print('[ConnectivityService] Erro de socket ao verificar conexão: $e');
      return false;
    } catch (e) {
      print('[ConnectivityService] Erro ao verificar conexão: $e');
      return false;
    }
  }

  /// Verifica se um serviço específico está acessível
  static Future<bool> canReachService(String url) async {
    try {
      print('[ConnectivityService] Verificando acesso ao serviço: $url');
      
      // Primeiro, verificar se há conexão com a internet
      if (!await isConnected()) {
        print('[ConnectivityService] Sem conexão com a internet para acessar o serviço');
        return false;
      }
      
      // Tentar fazer uma requisição HEAD para o serviço
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[ConnectivityService] Timeout ao verificar serviço: $url');
          return http.Response('', 408); // Request Timeout
        },
      );
      
      print('[ConnectivityService] Resposta do serviço $url: ${response.statusCode}');
      
      // Considerar como acessível se o status code for 2xx, 3xx ou 4xx (mas não 408)
      // 5xx indica problema no servidor, 408 indica timeout
      final isReachable = response.statusCode >= 200 && 
                         response.statusCode < 500 && 
                         response.statusCode != 408;
      
      print('[ConnectivityService] Serviço $url ${isReachable ? 'está acessível' : 'não está acessível'}');
      return isReachable;
    } catch (e) {
      print('[ConnectivityService] Erro ao verificar acesso ao serviço $url: $e');
      return false;
    }
  }
}
