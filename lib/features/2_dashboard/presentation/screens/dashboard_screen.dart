import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/dashboard_drawer.dart';
import '../tabs/home_tab.dart';
import '../tabs/meu_edital_tab.dart';
import '../tabs/plano_estudo_tab.dart';
import '../tabs/meu_progresso_tab.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  DashboardScreen({this.initialTabIndex = 0});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  final List<Widget> _tabs = [
    HomeTab(),
    MeuEditalTab(),
    PlanoEstudoTab(),
    MeuProgressoTab(),
    // Novas abas para ferramentas de IA
    Scaffold(body: Center(child: Text('Flashcards'))),
    Scaffold(body: Center(child: Text('Resumos'))),
    Scaffold(body: Center(child: Text('Questões'))),
    Scaffold(body: Center(child: Text('Mapas Mentais'))),
  ];

  final List<String> _tabTitles = [
    'Dashboard',
    'Meu Edital',
    'Plano de Estudo',
    'Meu Progresso',
    'Flashcards',
    'Resumos',
    'Questões',
    'Mapas Mentais',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPremium = authService.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (!isPremium)
            TextButton.icon(
              icon: Icon(Icons.star, color: Colors.amber),
              label: Text(
                'Premium',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _showPremiumDialog(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Implementar notificações
            },
          ),
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: DashboardDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Função auxiliar para determinar a cor do ícone com base no fundo
  Color _getIconColor(int index) {
    // Se o item estiver selecionado, usar a cor primária
    if (_selectedIndex == index) {
      return AppTheme.primaryColor;
    }

    // Verificar o tema atual para escolher uma cor com bom contraste
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Em tema escuro, usar cinza claro; em tema claro, usar cinza escuro
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
  }

  // Função auxiliar para determinar a cor do texto com base no fundo
  Color _getTextColor() {
    // Verificar o tema atual para escolher uma cor com bom contraste
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Em tema escuro, usar cinza claro; em tema claro, usar cinza escuro
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex < 4 ? _selectedIndex : 0, // Manter selecionado apenas as 4 primeiras abas
          onTap: (index) {
            if (index < 4) {
              // Abas principais
              _onItemTapped(index);
            } else {
              // Abas de ferramentas de IA
              switch (index) {
                case 4: // Flashcards
                  Navigator.pushNamed(context, '/flashcards');
                  break;
                case 5: // Resumos
                  Navigator.pushNamed(context, '/resumos');
                  break;
                case 6: // Questões
                  Navigator.pushNamed(context, '/questoes');
                  break;
                case 7: // Mapas Mentais
                  Navigator.pushNamed(context, '/mapas_mentais');
                  break;
              }
            }
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: _getTextColor(),
          backgroundColor: Colors.white,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          elevation: 0,
          selectedLabelStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(color: _getTextColor(), fontSize: 12),
          items: [
            // Abas principais
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, color: _getIconColor(0)),
              activeIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article, color: _getIconColor(1)),
              activeIcon: Icon(Icons.article, color: AppTheme.primaryColor),
              label: 'Meu Edital',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, color: _getIconColor(2)),
              activeIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              label: 'Plano',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights, color: _getIconColor(3)),
              activeIcon: Icon(Icons.insights, color: AppTheme.primaryColor),
              label: 'Progresso',
            ),
            // Ferramentas de IA
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on, color: _getIconColor(4)),
              activeIcon: Icon(Icons.flash_on, color: AppTheme.primaryColor),
              label: 'Flashcards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize, color: _getIconColor(5)),
              activeIcon: Icon(Icons.summarize, color: AppTheme.primaryColor),
              label: 'Resumos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz, color: _getIconColor(6)),
              activeIcon: Icon(Icons.quiz, color: AppTheme.primaryColor),
              label: 'Questões',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree, color: _getIconColor(7)),
              activeIcon: Icon(Icons.account_tree, color: AppTheme.primaryColor),
              label: 'Mapas',
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 0: // Home
        return null;
      case 1: // Meu Edital
        return FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/edital/add');
          },
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.add),
          tooltip: 'Adicionar Edital',
        );
      case 2: // Plano de Estudo
        return FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/plano/add');
          },
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.add),
          tooltip: 'Criar Plano',
        );
      case 3: // Meu Progresso
        return null;
      default:
        return null;
    }
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
