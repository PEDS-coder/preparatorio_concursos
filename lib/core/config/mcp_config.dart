import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Configuração para o protocolo MCP (Model Context Protocol)
class McpConfig {
  static const String _tag = 'McpConfig';
  static const String _prefKey = 'use_mcp_protocol';

  /// Verifica se o protocolo MCP está ativado
  static Future<bool> isMcpEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao verificar configuração MCP', e);
      return false;
    }
  }

  /// Ativa ou desativa o protocolo MCP
  static Future<void> setMcpEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
      AppLogger.i(_tag, 'Protocolo MCP ${enabled ? 'ativado' : 'desativado'}');
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao configurar MCP', e);
    }
  }
}
