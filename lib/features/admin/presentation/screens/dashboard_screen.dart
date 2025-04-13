import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/services/analytics_service.dart';
import 'package:preparatorio_concursos/core/services/remote_config_service.dart';
import 'package:preparatorio_concursos/core/services/advanced_cache_service.dart';
import 'package:preparatorio_concursos/core/services/background_processor_service.dart';
import 'package:preparatorio_concursos/core/services/data_loader_service.dart';
import 'package:preparatorio_concursos/core/services/image_loader_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Tela de dashboard para monitoramento
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Estatísticas
  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _backgroundProcessorStats = {};
  Map<String, dynamic> _dataLoaderStats = {};
  Map<String, dynamic> _imageLoaderStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  /// Carrega as estatísticas
  Future<void> _loadStats() async {
    final advancedCacheService = Provider.of<AdvancedCacheService>(context, listen: false);
    final backgroundProcessorService = Provider.of<BackgroundProcessorService>(context, listen: false);
    final dataLoaderService = Provider.of<DataLoaderService>(context, listen: false);
    final imageLoaderService = Provider.of<ImageLoaderService>(context, listen: false);
    
    setState(() {
      _cacheStats = advancedCacheService.getCacheStats();
      _backgroundProcessorStats = backgroundProcessorService.getStats();
      _dataLoaderStats = dataLoaderService.getCacheStats();
      _imageLoaderStats = imageLoaderService.getCacheStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    final remoteConfigService = Provider.of<RemoteConfigService>(context, listen: false);
    final logger = Provider.of<Logger>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Monitoramento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Atualizar Estatísticas',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Configurações Remotas
            _buildSection(
              title: 'Configurações Remotas',
              children: [
                _buildConfigItem('Modo de Manutenção', remoteConfigService.isInMaintenanceMode ? 'Ativado' : 'Desativado'),
                _buildConfigItem('Atualização Necessária', remoteConfigService.needsUpdate ? 'Sim' : 'Não'),
                _buildConfigItem('Atualização Forçada', remoteConfigService.isForceUpdate ? 'Sim' : 'Não'),
                _buildConfigItem('Tamanho Máximo do Cache (MB)', remoteConfigService.getInt('max_cache_size_mb').toString()),
                _buildConfigItem('Gamificação', remoteConfigService.isFeatureEnabled('gamification') ? 'Ativada' : 'Desativada'),
                _buildConfigItem('Mercado', remoteConfigService.isFeatureEnabled('mercado') ? 'Ativado' : 'Desativado'),
                _buildConfigItem('Sincronização de Calendário', remoteConfigService.isFeatureEnabled('calendar_sync') ? 'Ativada' : 'Desativada'),
                _buildConfigItem('Compartilhamento Social', remoteConfigService.isFeatureEnabled('social_sharing') ? 'Ativado' : 'Desativado'),
                _buildConfigItem('Backup na Nuvem', remoteConfigService.isFeatureEnabled('cloud_backup') ? 'Ativado' : 'Desativado'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Cache
            _buildSection(
              title: 'Estatísticas de Cache',
              children: [
                _buildConfigItem('Itens no Cache', _cacheStats['itemCount']?.toString() ?? '0'),
                _buildConfigItem('Tamanho Atual (KB)', (_cacheStats['currentSize'] != null ? (_cacheStats['currentSize'] / 1024).toStringAsFixed(2) : '0')),
                _buildConfigItem('Tamanho Máximo (KB)', (_cacheStats['maxSize'] != null ? (_cacheStats['maxSize'] / 1024).toStringAsFixed(2) : '0')),
                _buildConfigItem('Uso (%)', _cacheStats['usagePercentage']?.toString() ?? '0'),
                _buildConfigItem('Itens Expirados', _cacheStats['expiredItems']?.toString() ?? '0'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Processamento em Segundo Plano
            _buildSection(
              title: 'Processamento em Segundo Plano',
              children: [
                _buildConfigItem('Isolates', _backgroundProcessorStats['isolates']?.toString() ?? '0'),
                _buildConfigItem('Tarefas em Execução', _backgroundProcessorStats['runningTasks']?.toString() ?? '0'),
                _buildConfigItem('Tarefas Pendentes', _backgroundProcessorStats['pendingTasks']?.toString() ?? '0'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Carregamento de Dados
            _buildSection(
              title: 'Carregamento de Dados',
              children: [
                _buildConfigItem('Chaves no Cache', _dataLoaderStats['keys']?.length.toString() ?? '0'),
                _buildConfigItem('Total de Páginas', _dataLoaderStats['totalPages']?.toString() ?? '0'),
                _buildConfigItem('Total de Itens', _dataLoaderStats['totalItems']?.toString() ?? '0'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Carregamento de Imagens
            _buildSection(
              title: 'Carregamento de Imagens',
              children: [
                _buildConfigItem('Imagens no Cache', _imageLoaderStats['imageCount']?.toString() ?? '0'),
                _buildConfigItem('Tamanho Atual (KB)', (_imageLoaderStats['currentSize'] != null ? (_imageLoaderStats['currentSize'] / 1024).toStringAsFixed(2) : '0')),
                _buildConfigItem('Tamanho Máximo (KB)', (_imageLoaderStats['maxSize'] != null ? (_imageLoaderStats['maxSize'] / 1024).toStringAsFixed(2) : '0')),
                _buildConfigItem('Uso (%)', _imageLoaderStats['usagePercentage']?.toString() ?? '0'),
                _buildConfigItem('Imagens Expiradas', _imageLoaderStats['expiredImages']?.toString() ?? '0'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Seção de Ações
            _buildSection(
              title: 'Ações',
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Buscar configurações remotas
                    final success = await remoteConfigService.fetchAndActivate();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Configurações remotas atualizadas com sucesso'
                            : 'Erro ao atualizar configurações remotas'),
                      ),
                    );
                    _loadStats();
                  },
                  child: const Text('Atualizar Configurações Remotas'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Registrar evento de teste
                    analyticsService.logEvent(
                      name: 'test_event',
                      parameters: {'source': 'dashboard'},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Evento de teste registrado'),
                      ),
                    );
                  },
                  child: const Text('Registrar Evento de Teste'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Registrar erro de teste
                    try {
                      throw Exception('Erro de teste');
                    } catch (e) {
                      analyticsService.recordError(e, StackTrace.current, reason: 'Erro de teste do dashboard');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro de teste registrado'),
                        ),
                      );
                    }
                  },
                  child: const Text('Registrar Erro de Teste'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Limpar logs
                    logger.clearLogs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs limpos com sucesso'),
                      ),
                    );
                  },
                  child: const Text('Limpar Logs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Constrói uma seção do dashboard
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
  
  /// Constrói um item de configuração
  Widget _buildConfigItem(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
