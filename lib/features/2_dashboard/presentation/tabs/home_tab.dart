import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final sessaoService = Provider.of<SessaoEstudoService>(context);
    final planoService = Provider.of<PlanoEstudoService>(context);

    // Obter dados do usuário
    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;

    // Obter próximos itens do cronograma (simulação)
    final hoje = DateTime.now();
    final proximosItens = planoService.getCronogramaByDate(hoje);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação
          Text(
            'Olá, ${usuario?.nome.split(' ')[0] ?? 'Concurseiro'}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vamos estudar hoje?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Próxima sessão de estudo
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Próxima Sessão de Estudo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.notifications,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        proximosItens.isNotEmpty
                            ? '${_formatHora(proximosItens.first.dataHoraInicio)} - ${_formatHora(proximosItens.first.dataHoraFim)}'
                            : 'Hoje, 19:00 - 20:00',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.subject, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        proximosItens.isNotEmpty
                            ? proximosItens.first.nomeMateria
                            : 'Direito Constitucional',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.book, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        proximosItens.isNotEmpty
                            ? proximosItens.first.atividadeSugerida
                            : 'Leitura de material',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/sessao/iniciar');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text('Iniciar Sessão'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Seu progresso
          const Text(
            'Seu Progresso',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProgressItem(
                        'Horas Estudadas',
                        (sessaoService.calcularTempoTotalEstudo(usuario?.id ?? '') / 60).toStringAsFixed(1),
                        Icons.access_time,
                      ),
                      _buildProgressItem(
                        'Questões Resolvidas',
                        '145',
                        Icons.check_circle,
                      ),
                      _buildProgressItem(
                        'Dias Seguidos',
                        '7',
                        Icons.local_fire_department,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/gamificacao');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text('Ver Detalhes'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recomendações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recomendações para Você',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Direito Administrativo',
            'Princípios da Administração Pública',
            '15 questões novas',
            Colors.orange.shade100,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            'Português',
            'Concordância Verbal',
            'Conteúdo atualizado',
            Colors.green.shade100,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            'Raciocínio Lógico',
            'Proposições e Conectivos',
            'Recomendado para você',
            Colors.purple.shade100,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    String subject,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.book, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          trailing: Text(
            subject,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            // Navegar para o conteúdo recomendado
          },
        ),
      ),
    );
  }

  String _formatHora(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
