import 'package:flutter/material.dart';
import '../data/models/api_quota.dart';
import '../services/api_quota_service.dart';
import '../theme/app_theme.dart';

/// Widget para exibir o uso de cotas da API Gemini
class ApiQuotaIndicator extends StatefulWidget {
  final bool showDetailed;
  
  const ApiQuotaIndicator({
    Key? key,
    this.showDetailed = false,
  }) : super(key: key);

  @override
  _ApiQuotaIndicatorState createState() => _ApiQuotaIndicatorState();
}

class _ApiQuotaIndicatorState extends State<ApiQuotaIndicator> {
  final ApiQuotaService _quotaService = ApiQuotaService();
  bool _showDetails = false;
  
  @override
  void initState() {
    super.initState();
    _showDetails = widget.showDetailed;
  }
  
  @override
  Widget build(BuildContext context) {
    final ApiQuota quota = _quotaService.quota;
    
    return InkWell(
      onTap: () {
        setState(() {
          _showDetails = !_showDetails;
        });
        
        if (_showDetails) {
          _showQuotaDetailsDialog(context, quota);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.data_usage,
              size: 16,
              color: _getColorForUsage(quota.requestsPerMinutePercentage),
            ),
            const SizedBox(width: 4),
            Text(
              '${quota.requestsPerMinute}/${ApiQuota.MAX_REQUESTS_PER_MINUTE}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getColorForUsage(quota.requestsPerMinutePercentage),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Exibe um diálogo com detalhes do uso de cotas
  void _showQuotaDetailsDialog(BuildContext context, ApiQuota quota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_usage, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Uso de Cotas do Gemini'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Limites da API Gemini (gratuita):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLimitItem('5 Requisições por minuto'),
            _buildLimitItem('25 Requisições por dia'),
            _buildLimitItem('250.000 Tokens por minuto'),
            _buildLimitItem('1.000.000 de Tokens por dia'),
            const SizedBox(height: 16),
            const Text(
              'Uso atual:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUsageRow('Requisições/min:', quota.requestsPerMinute, ApiQuota.MAX_REQUESTS_PER_MINUTE),
            _buildUsageRow('Requisições/dia:', quota.requestsPerDay, ApiQuota.MAX_REQUESTS_PER_DAY),
            _buildUsageRow('Tokens/min:', quota.tokensPerMinute, ApiQuota.MAX_TOKENS_PER_MINUTE),
            _buildUsageRow('Tokens/dia:', quota.tokensPerDay, ApiQuota.MAX_TOKENS_PER_DAY),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  /// Constrói um item da lista de limites
  Widget _buildLimitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
  
  /// Constrói uma linha de uso de cota
  Widget _buildUsageRow(String label, int current, int max) {
    final double percentage = current / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$current/$max',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getColorForUsage(percentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_getColorForUsage(percentage)),
          ),
        ],
      ),
    );
  }
  
  /// Retorna uma cor baseada no percentual de uso
  Color _getColorForUsage(double percentage) {
    if (percentage < 0.5) {
      return Colors.green;
    } else if (percentage < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
