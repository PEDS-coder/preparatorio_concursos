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
  const MercadoTab({super.key});

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
      return const Center(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          const Text(
            'Mercado Aprovação',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Troque suas moedas por recompensas personalizadas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Saldo de moedas
          _buildSaldoCard(usuario.pontosGamificacao),
          const SizedBox(height: 24),

          // Estatísticas
          _buildEstatisticasRow(horasEstudadas, streakAtual, horasSemanais),
          const SizedBox(height: 24),

          // Botão para adicionar recompensa
          GradientButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdicionarRecompensaScreen()),
              );
            },
            fullWidth: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('ADICIONAR RECOMPENSA'),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  tabs: const [
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    '$saldo Moedas',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Histórico'),
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
        const SizedBox(width: 12),
        Expanded(
          child: _buildEstatisticaCard(
            'Streak Atual',
            streakAtual.toString(),
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              color: cor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              style: const TextStyle(
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
      padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: recompensa.resgatada ? Colors.green.withOpacity(0.5) : Colors.transparent,
          width: recompensa.resgatada ? 1 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recompensa.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recompensa.custoMoedas} Moedas',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (recompensa.resgatada)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resgatado em ${DateFormat('dd/MM/yyyy').format(recompensa.dataResgate!)}',
                        style: const TextStyle(
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
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Excluir'),
                        onPressed: () async {
                          final confirmacao = await _confirmarExclusao(context);
                          if (confirmacao) {
                            await mercadoService.excluirRecompensa(recompensa.id);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.redeem, size: 16),
                        label: const Text('Resgatar'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
            title: const Text('Confirmar Resgate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Você deseja resgatar a seguinte recompensa?'),
                const SizedBox(height: 16),
                Text(
                  recompensa.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(recompensa.descricao),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${recompensa.custoMoedas} Moedas',
                      style: const TextStyle(
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
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: Text('RESGATAR'),
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
            title: const Text('Confirmar Exclusão'),
            content: const Text('Tem certeza que deseja excluir esta recompensa?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('EXCLUIR'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
