import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/mercado_service.dart';
import '../../../../core/data/models/recompensa_mercado.dart';

class HistoricoMoedasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final mercadoService = Provider.of<MercadoService>(context);

    final usuario = authService.currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Histórico de Moedas'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Text(
            'Você precisa estar autenticado para ver o histórico',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Obter histórico de moedas do usuário
    final historico = mercadoService.getHistoricoMoedasByUserId(usuario.id);

    // Ordenar por data (mais recente primeiro)
    historico.sort((a, b) => b.data.compareTo(a.data));

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Moedas'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: historico.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: historico.length,
              itemBuilder: (context, index) {
                final item = historico[index];
                return _buildHistoricoItem(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma transação de moedas registrada',
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

  Widget _buildHistoricoItem(HistoricoMoedas item) {
    final bool isGanho = item.tipo == 'ganho';
    final Color cor = isGanho ? Colors.green : Colors.red;
    final IconData icone = isGanho ? Icons.arrow_upward : Icons.arrow_downward;
    final String sinal = isGanho ? '+' : '-';

    // Determinar o ícone baseado na origem
    IconData origemIcone;
    String origemTexto;

    switch (item.origem) {
      case 'sessao_estudo':
        origemIcone = Icons.book;
        origemTexto = 'Sessão de Estudo';
        break;
      case 'bonus_diario':
        origemIcone = Icons.wb_sunny;
        origemTexto = 'Bônus Diário';
        break;
      case 'streak_3_dias':
      case 'streak_7_dias':
      case 'streak_14_dias':
      case 'streak_30_dias':
        origemIcone = Icons.local_fire_department;
        origemTexto = 'Streak de Dias';
        break;
      case 'meta_semanal':
        origemIcone = Icons.calendar_today;
        origemTexto = 'Meta Semanal';
        break;
      case 'marco_10_horas':
      case 'marco_50_horas':
      case 'marco_100_horas':
        origemIcone = Icons.access_time;
        origemTexto = 'Marco de Horas';
        break;
      case 'primeira_recompensa':
        origemIcone = Icons.emoji_events;
        origemTexto = 'Primeira Recompensa';
        break;
      case 'resgate':
        origemIcone = Icons.redeem;
        origemTexto = 'Resgate de Recompensa';
        break;
      default:
        origemIcone = Icons.monetization_on;
        origemTexto = 'Transação';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                color: cor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        origemIcone,
                        size: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        origemTexto,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.descricao ?? 'Sem descrição',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sinal${item.quantidade} Moedas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd-MM-yyyy HH:mm').format(item.data),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
