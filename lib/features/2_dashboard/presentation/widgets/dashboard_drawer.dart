import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(usuario?.nome ?? 'Usuário'),
            accountEmail: Text(usuario?.email ?? 'Não autenticado'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            otherAccountsPictures: [
              if (isPremium)
                const Tooltip(
                  message: 'Usuário Premium',
                  child: CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Meus Editais'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/editais');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Plano de Estudo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/plano');
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_filled),
            title: const Text('Sessão de Estudo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sessao');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Gamificação'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/gamificacao');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Ferramentas de IA'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ferramentas');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Mercado Aprovação'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard', arguments: 5);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          if (!isPremium)
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text(
                'Upgrade para Premium',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showPremiumDialog(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade para Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desbloqueie todos os recursos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPremiumFeature('Análises ilimitadas de editais'),
            _buildPremiumFeature('Plano de estudo avançado'),
            _buildPremiumFeature('Ferramentas de IA para resumos'),
            _buildPremiumFeature('Flashcards ilimitados'),
            _buildPremiumFeature('Integração com Google Agenda'),
            _buildPremiumFeature('Gamificação completa'),
            const SizedBox(height: 16),
            const Text(
              'Por apenas R\$ 19,90/mês',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Simulação de upgrade
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.upgradeToPremium();

              // Mostrar confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Parabéns! Você agora é um usuário Premium.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Fazer Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(feature)),
        ],
      ),
    );
  }
}
