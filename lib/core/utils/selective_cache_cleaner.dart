import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/edital_service.dart';
import '../data/services/progresso_estudo_service.dart';
import '../data/services/sessao_estudo_service.dart';

/// Utilitário para limpar seletivamente o cache de áreas específicas da aplicação
class SelectiveCacheCleaner {
  static const String _tag = 'SelectiveCacheCleaner';

  /// Limpa o cache da aba Meu Edital
  static Future<bool> clearMeuEditalCache(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remover apenas as chaves relacionadas à visualização do edital
      // mas preservar os dados do edital em si
      final keys = prefs.getKeys().where((key) =>
        key.startsWith('meu_edital_expanded_') ||
        key.startsWith('meu_edital_view_state_') ||
        key.startsWith('edital_view_')
      ).toList();

      for (var key in keys) {
        await prefs.remove(key);
      }

      // Recarregar dados do serviço
      final editalService = Provider.of<EditalService>(context, listen: false);
      await editalService.loadEditais();

      debugPrint('[$_tag] Cache da aba Meu Edital limpo com sucesso!');
      return true;
    } catch (e) {
      debugPrint('[$_tag] Erro ao limpar cache da aba Meu Edital: $e');
      return false;
    }
  }

  /// Limpa o cache da aba Progresso
  static Future<bool> clearProgressoCache(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remover apenas as chaves relacionadas à visualização do progresso
      // mas preservar os dados de progresso em si
      final keys = prefs.getKeys().where((key) =>
        key.startsWith('progresso_view_') ||
        key.startsWith('progresso_chart_')
      ).toList();

      for (var key in keys) {
        await prefs.remove(key);
      }

      // Recarregar dados do serviço
      final progressoService = Provider.of<ProgressoEstudoService>(context, listen: false);
      await progressoService.loadProgressos();

      debugPrint('[$_tag] Cache da aba Progresso limpo com sucesso!');
      return true;
    } catch (e) {
      debugPrint('[$_tag] Erro ao limpar cache da aba Progresso: $e');
      return false;
    }
  }

  /// Limpa o cache da função de iniciar sessão
  static Future<bool> clearSessaoEstudoCache(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remover apenas as chaves relacionadas à visualização da sessão de estudo
      // mas preservar os dados de sessões anteriores
      final keys = prefs.getKeys().where((key) =>
        key.startsWith('sessao_estudo_temp_') ||
        key.startsWith('sessao_estudo_view_')
      ).toList();

      for (var key in keys) {
        await prefs.remove(key);
      }

      // Recarregar dados do serviço
      final sessaoService = Provider.of<SessaoEstudoService>(context, listen: false);
      await sessaoService.loadSessoes();

      debugPrint('[$_tag] Cache da função de iniciar sessão limpo com sucesso!');
      return true;
    } catch (e) {
      debugPrint('[$_tag] Erro ao limpar cache da função de iniciar sessão: $e');
      return false;
    }
  }

  /// Limpa o cache de todas as áreas solicitadas
  static Future<bool> clearAllRequestedCaches(BuildContext context) async {
    bool success = true;

    if (!await clearMeuEditalCache(context)) {
      success = false;
    }

    if (!await clearProgressoCache(context)) {
      success = false;
    }

    if (!await clearSessaoEstudoCache(context)) {
      success = false;
    }

    return success;
  }
}
