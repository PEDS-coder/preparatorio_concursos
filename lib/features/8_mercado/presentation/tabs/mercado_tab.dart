import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/mercado_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/data/models/recompensa_mercado.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../screens/adicionar_recompensa_screen.dart';
import '../screens/historico_moedas_screen.dart';

class MercadoTab extends StatefulWidget {
  @override
  _MercadoTabState createState() => _MercadoTabState();
}

class _MercadoTabState extends State<MercadoTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final mercadoService = Provider.of<MercadoService>(context);
    final sessaoService = Provider.of<SessaoEstudoService>(context);

    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;

    if (usuario == null) {
      return Center(
        child: Text(
          'Você precisa estar autenticado para acessar o Mercado Aprovação',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Obter recompensas do usuário
    final recompensasNaoResgatadas = mercadoService.getRecompensasNaoResgatadas(usuario.id);
    final recompensasResgatadas = mercadoService.getRecompensasResgatadas(usuario.id);

    // Obter estatísticas
    final horasEstudadas = sessaoService.calcularTempoTotalEstudo(usuario.id) / 60;
    final streakAtual = mercadoService.getStreakAtual(usuario.id);
    final horasSemanais = mercadoService.getHorasEstudoSemanais(usuario.id);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            'Mercado Aprovação',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Troque suas moedas por recompensas personalizadas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24),

          // Saldo de moedas
          _buildSaldoCard(usuario.pontosGamificacao),
          SizedBox(height: 24),

          // Estatísticas
          _buildEstatisticasRow(horasEstudadas, streakAtual, horasSemanais),
          SizedBox(height: 24),

          // Botão para adicionar recompensa
          GradientButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdicionarRecompensaScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('ADICIONAR RECOMPENSA'),
              ],
            ),
            fullWidth: true,
          ),
          SizedBox(height: 24),

          // Abas de recompensas
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: 'Disponíveis'),
                    Tab(text: 'Resgatadas'),
                  ],
                ),
                SizedBox(
                  height: 400, // Altura fixa para o conteúdo das abas
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Aba de recompensas disponíveis
                      recompensasNaoResgatadas.isEmpty
                          ? _buildEmptyState('Você ainda não tem recompensas disponíveis')
                          : _buildRecompensasList(recompensasNaoResgatadas, mercadoService, true),

                      // Aba de recompensas resgatadas
                      recompensasResgatadas.isEmpty
                          ? _buildEmptyState('Você ainda não resgatou nenhuma recompensa')
                          : _buildRecompensasList(recompensasResgatadas, mercadoService, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoCard(int saldo) {
    return ModernCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                color: Colors.amber,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu Saldo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$saldo Moedas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.history),
              label: Text('Histórico'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoricoMoedasScreen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticasRow(double horasEstudadas, int streakAtual, double horasSemanais) {
    return Row(
      children: [
        Expanded(
          child: _buildEstatisticaCard(
            'Horas Estudadas',
            horasEstudadas.toStringAsFixed(1),
            Icons.access_time,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildEstatisticaCard(
            'Streak Atual',
            streakAtual.toString(),
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildEstatisticaCard(
            'Horas Semanais',
            horasSemanais.toStringAsFixed(1),
            Icons.calendar_today,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildEstatisticaCard(String titulo, String valor, IconData icone, Color cor) {
    return ModernCard(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              color: cor,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String mensagem) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              mensagem,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecompensasList(List<RecompensaMercado> recompensas, MercadoService mercadoService, bool podeResgatar) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: recompensas.length,
      itemBuilder: (context, index) {
        final recompensa = recompensas[index];
        return _buildRecompensaCard(recompensa, mercadoService, podeResgatar);
      },
    );
  }

  Widget _buildRecompensaCard(RecompensaMercado recompensa, MercadoService mercadoService, bool podeResgatar) {
    final usuario = Provider.of<AuthService>(context).currentUser;
    final saldoSuficiente = usuario != null && usuario.pontosGamificacao >= recompensa.custoMoedas;

    Color categoriaColor;
    IconData categoriaIcon;

    switch (recompensa.categoria) {
      case 'pequena':
        categoriaColor = Colors.green;
        categoriaIcon = Icons.coffee;
        break;
      case 'media':
        categoriaColor = Colors.orange;
        categoriaIcon = Icons.movie;
        break;
      case 'grande':
        categoriaColor = Colors.purple;
        categoriaIcon = Icons.celebration;
        break;
      default:
        categoriaColor = Colors.blue;
        categoriaIcon = Icons.emoji_events;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: recompensa.resgatada ? Colors.green.withOpacity(0.5) : Colors.transparent,
          width: recompensa.resgatada ? 1 : 0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoriaColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoriaIcon,
                    color: categoriaColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recompensa.titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        recompensa.descricao,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${recompensa.custoMoedas} Moedas',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (recompensa.resgatada)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Resgatado em ${DateFormat('dd-MM-yyyy').format(recompensa.dataResgate!)}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else if (podeResgatar)
                  Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.delete, size: 16),
                        label: Text('Excluir'),
                        onPressed: () async {
                          final confirmacao = await _confirmarExclusao(context);
                          if (confirmacao) {
                            await mercadoService.excluirRecompensa(recompensa.id);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.redeem, size: 16),
                        label: Text('Resgatar'),
                        onPressed: saldoSuficiente
                            ? () async {
                                final confirmacao = await _confirmarResgate(context, recompensa);
                                if (confirmacao) {
                                  await mercadoService.resgatarRecompensa(recompensa.id);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarResgate(BuildContext context, RecompensaMercado recompensa) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmar Resgate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Você deseja resgatar a seguinte recompensa?'),
                SizedBox(height: 16),
                Text(
                  recompensa.titulo,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(recompensa.descricao),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${recompensa.custoMoedas} Moedas',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('RESGATAR'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmarExclusao(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmar Exclusão'),
            content: Text('Tem certeza que deseja excluir esta recompensa?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('EXCLUIR'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
