import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/widgets/modern_card.dart';
import '../screens/flashcards_screen.dart';
import '../screens/resumos_screen.dart';
import '../screens/questoes_screen.dart';
import '../screens/mapas_mentais_screen.dart';

class IAToolsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPremium = authService.isPremium;

    return !isPremium
        ? _buildPremiumRequired(context)
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ferramentas de IA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Utilize a inteligência artificial para potencializar seus estudos',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 24),
                _buildToolsGrid(context),
              ],
            ),
          );
  }

  Widget _buildToolsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildToolCard(
          context,
          'Flashcards',
          'Crie cartões de memorização para revisão rápida',
          Icons.flash_on,
          AppTheme.primaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FlashcardsScreen()),
          ),
        ),
        _buildToolCard(
          context,
          'Resumos',
          'Gere resumos concisos de textos longos',
          Icons.summarize,
          AppTheme.secondaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ResumosScreen()),
          ),
        ),
        _buildToolCard(
          context,
          'Questões',
          'Crie questões para testar seus conhecimentos',
          Icons.quiz,
          AppTheme.accentColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuestoesScreen()),
          ),
        ),
        _buildToolCard(
          context,
          'Mapas Mentais',
          'Visualize conceitos em mapas mentais interativos',
          Icons.account_tree,
          AppTheme.accentColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapasMentaisScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ModernCard(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.amber,
            ),
            SizedBox(height: 24),
            Text(
              'Recursos Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'As ferramentas de IA estão disponíveis apenas para usuários premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Simulação de upgrade
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.upgradeToPremium();

                // Mostrar confirmação
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Parabéns! Você agora é um usuário Premium.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('FAZER UPGRADE'),
            ),
          ],
        ),
      ),
    );
  }
}
