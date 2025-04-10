import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente para o Protocolo Multi-Contexto (MCP)
/// 
/// Esta classe implementa um cliente básico para o Protocolo Multi-Contexto (MCP),
/// que permite que aplicativos forneçam contexto aos LLMs de forma padronizada.
class MCPClient {
  final String _baseUrl;
  final String _apiKey;
  final Map<String, String> _headers;

  MCPClient({
    required String baseUrl,
    required String apiKey,
    Map<String, String>? additionalHeaders,
  }) : _baseUrl = baseUrl,
       _apiKey = apiKey,
       _headers = {
         'Content-Type': 'application/json',
         'Authorization': 'Bearer $apiKey',
         ...?additionalHeaders,
       };

  /// Lista os recursos disponíveis no servidor MCP
  Future<List<Map<String, dynamic>>> listResources() async {
    final url = '$_baseUrl/resources';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['resources']);
      } else {
        throw Exception('Falha ao listar recursos: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor MCP: $e');
    }
  }

  /// Lista as ferramentas disponíveis no servidor MCP
  Future<List<Map<String, dynamic>>> listTools() async {
    final url = '$_baseUrl/tools';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['tools']);
      } else {
        throw Exception('Falha ao listar ferramentas: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor MCP: $e');
    }
  }

  /// Chama uma ferramenta no servidor MCP
  Future<Map<String, dynamic>> callTool(String toolName, Map<String, dynamic> args) async {
    final url = '$_baseUrl/tools/$toolName/call';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({'args': args}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao chamar ferramenta: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor MCP: $e');
    }
  }

  /// Obtém um recurso do servidor MCP
  Future<Map<String, dynamic>> getResource(String resourceId) async {
    final url = '$_baseUrl/resources/$resourceId';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao obter recurso: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor MCP: $e');
    }
  }

  /// Converte definições de ferramentas MCP para definições de ferramentas compatíveis com OpenAI
  Map<String, dynamic> convertToolToOpenAIFormat(Map<String, dynamic> tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool['name'],
        'description': tool['description'],
        'parameters': {
          'type': 'object',
          'properties': tool['inputSchema']['properties'],
          'required': tool['inputSchema']['required'],
        },
      },
    };
  }
}
