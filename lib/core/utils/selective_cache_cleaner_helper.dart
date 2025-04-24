import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../data/services/edital_service.dart';
import '../data/services/progresso_estudo_service.dart';
import '../data/services/sessao_estudo_service.dart';
import 'selective_cache_cleaner.dart';

/// Classe auxiliar para limpar o cache de áreas específicas da aplicação
class SelectiveCacheCleanerHelper {
  /// Limpa o cache das áreas solicitadas (Meu Edital, Progresso e Sessão de Estudo)
  static Future<bool> limparCacheAreas(BuildContext context) async {
    try {
      // Limpar cache da aba Meu Edital
      await SelectiveCacheCleaner.clearMeuEditalCache();
      
      // Limpar cache da aba Progresso
      await SelectiveCacheCleaner.clearProgressoCache();
      
      // Limpar cache da função de iniciar sessão
      await SelectiveCacheCleaner.clearSessaoEstudoCache();
      
      // Limpar cache dos serviços relacionados
      final editalService = Provider.of<EditalService>(context, listen: false);
      final progressoService = Provider.of<ProgressoEstudoService>(context, listen: false);
      final sessaoService = Provider.of<SessaoEstudoService>(context, listen: false);
      
      await editalService.limparCacheEditais();
      await progressoService.limparCacheProgresso();
      await sessaoService.limparCacheSessoes();
      
      debugPrint('Cache das áreas solicitadas limpo com sucesso!');
      return true;
    } catch (e) {
      debugPrint('Erro ao limpar cache das áreas solicitadas: $e');
      return false;
    }
  }
}
