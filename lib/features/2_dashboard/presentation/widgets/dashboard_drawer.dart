import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardDrawer extends StatelessWidget {
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
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            otherAccountsPictures: [
              if (isPremium)
                Tooltip(
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
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Meus Editais'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/editais');
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Plano de Estudo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/plano');
            },
          ),
          ListTile(
            leading: Icon(Icons.play_circle_filled),
            title: Text('Sessão de Estudo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sessao');
            },
          ),
          ListTile(
            leading: Icon(Icons.emoji_events),
            title: Text('Gamificação'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/gamificacao');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          Divider(),
          if (!isPremium)
            ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text(
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
            leading: Icon(Icons.exit_to_app),
            title: Text('Sair'),
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
        title: Row(
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
            Text(
              'Desbloqueie todos os recursos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildPremiumFeature('Análises ilimitadas de editais'),
            _buildPremiumFeature('Plano de estudo avançado'),
            _buildPremiumFeature('Ferramentas de IA para resumos'),
            _buildPremiumFeature('Flashcards ilimitados'),
            _buildPremiumFeature('Integração com Google Agenda'),
            _buildPremiumFeature('Gamificação completa'),
            SizedBox(height: 16),
            Text(
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
            child: Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Simulação de upgrade
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.upgradeToPremium();

              // Mostrar confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Parabéns! Você agora é um usuário Premium.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Fazer Upgrade'),
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
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(feature)),
        ],
      ),
    );
  }
}
