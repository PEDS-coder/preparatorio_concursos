import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/gamificacao_service.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/gradient_button.dart';

class MeuProgressoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final gamificacaoService = Provider.of<GamificacaoService>(context);
    final sessaoService = Provider.of<SessaoEstudoService>(context);

    final usuario = authService.currentUser;
    final isPremium = authService.isPremium;

    // Obter troféus do usuário
    final trofeus = usuario != null
        ? gamificacaoService.getTrofeusByUserId(usuario.id)
        : [];

    // Calcular estatísticas
    final horasEstudadas = usuario != null
        ? sessaoService.calcularTempoTotalEstudo(usuario.id) / 60
        : 0.0;

    final nivel = usuario?.nivelGamificacao ?? 1;
    final pontos = usuario?.pontosGamificacao ?? 0;
    final pontosProximoNivel = nivel * 500;
    final progresso = pontos / pontosProximoNivel;

    // Dados simulados para gráficos
    final List<Map<String, dynamic>> dadosEstudoSemanal = [
      {'dia': 'Seg', 'horas': 2.5},
      {'dia': 'Ter', 'horas': 1.8},
      {'dia': 'Qua', 'horas': 3.0},
      {'dia': 'Qui', 'horas': 2.2},
      {'dia': 'Sex', 'horas': 1.5},
      {'dia': 'Sáb', 'horas': 4.0},
      {'dia': 'Dom', 'horas': 1.0},
    ];

    final List<Map<String, dynamic>> dadosMateriasEstudadas = [
      {'materia': 'Português', 'horas': 8.5, 'cor': Colors.blue},
      {'materia': 'Matemática', 'horas': 6.2, 'cor': Colors.red},
      {'materia': 'Direito Constitucional', 'horas': 10.0, 'cor': Colors.green},
      {'materia': 'Direito Administrativo', 'horas': 7.5, 'cor': Colors.purple},
      {'materia': 'Informática', 'horas': 3.0, 'cor': Colors.orange},
    ];

    // Calcular total de horas estudadas por matéria
    final totalHorasMateria = dadosMateriasEstudadas.fold<double>(0.0, (sum, item) => sum + (item['horas'] as double));

    // Calcular progresso total do plano de estudos (simulado)
    final progressoPlano = 0.65; // 65% concluído
    final diasRestantes = 45; // 45 dias restantes

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            'Meu Progresso',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Acompanhe sua evolução nos estudos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),

          // Conteúdo principal
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de progresso geral
                  ModernCard(
                    gradient: LinearGradient(
                      colors: [AppTheme.darkCardColor, Color(0xFF1E3A6E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppTheme.primaryColor, Color(0xFF9C1AFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${(progressoPlano * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progresso do Plano',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Faltam $diasRestantes dias para a prova',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progressoPlano,
                                      backgroundColor: Colors.grey.shade800,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 24),

                          // Estatísticas rápidas
                          Row(
                            children: [
                              _buildStatItem(
                                '${horasEstudadas.toStringAsFixed(1)}h',
                                'Estudadas',
                                Icons.access_time,
                                AppTheme.secondaryColor,
                              ),
                              _buildStatItem(
                                '${trofeus.length}',
                                'Conquistas',
                                Icons.emoji_events,
                                Colors.amber,
                              ),
                              _buildStatItem(
                                '$pontos',
                                'Pontos',
                                Icons.star,
                                AppTheme.accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Gráfico de horas estudadas por dia
                  Text(
                    'Horas Estudadas na Semana',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),

                  ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 200,
                            child: _buildBarChart(dadosEstudoSemanal),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total: ${dadosEstudoSemanal.fold<double>(0.0, (sum, item) => sum + (item['horas'] as double)).toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                ' esta semana',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Gráfico de distribuição por matéria
                  Text(
                    'Distribuição por Matéria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),

                  ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildPieChart(dadosMateriasEstudadas),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: _buildMateriasList(dadosMateriasEstudadas),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Conquistas recentes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Conquistas Recentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (trofeus.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/trofeus');
                          },
                          child: Text(
                            'Ver Todas',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Lista de conquistas
                  trofeus.isEmpty
                      ? ModernCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Nenhuma conquista ainda',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Continue estudando para desbloquear conquistas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: math.min(3, trofeus.length),
                            itemBuilder: (context, index) {
                              final trofeu = trofeus[index];
                              return Container(
                                width: 200,
                                margin: EdgeInsets.only(right: 12),
                                child: ModernCard(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber.shade700.withOpacity(0.7), Colors.amber.shade300.withOpacity(0.7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          trofeu.nomeTrofeu,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          trofeu.descricaoTrofeu,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> dados) {
    // Encontrar o valor máximo para escala
    final maxHoras = dados.fold<double>(0.0, (maxVal, item) => math.max(maxVal, item['horas'] as double));

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dados.map((item) {
          final altura = (item['horas'] as double) / (maxHoras > 0 ? maxHoras : 1) * 150;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${item['horas']}h',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Container(
                width: 30,
                height: altura,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondaryColor, Color(0xFF2E7BFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                item['dia'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> dados) {
    // Calcular total para percentuais
    final total = dados.fold<double>(0.0, (sum, item) => sum + (item['horas'] as double));

    return CustomPaint(
      painter: PieChartPainter(dados, total),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${total.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Total',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriasList(List<Map<String, dynamic>> dados) {
    // Calcular total para percentuais
    final total = dados.fold<double>(0.0, (sum, item) => sum + (item['horas'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: dados.map((item) {
        final percentual = (item['horas'] as double) / total * 100;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['cor'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['materia'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '${percentual.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Painter para o gráfico de pizza
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> dados;
  final double total;

  PieChartPainter(this.dados, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;

    double startAngle = -math.pi / 2; // Começar do topo

    for (var item in dados) {
      final sweepAngle = (item['horas'] as double) / total * 2 * math.pi;

      final paint = Paint()
        ..color = (item['cor'] as Color)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Adicionar borda
      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Adicionar círculo central
    final centerPaint = Paint()
      ..color = AppTheme.darkCardColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
