import 'package:flutter/material.dart';

class ResumoPlanoCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;

  const ResumoPlanoCard({
    Key? key,
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class ResumoPlanoSection extends StatelessWidget {
  final String periodo;
  final int horasTotais;
  final int horasSemanais;
  final double horasPorDia;
  final Map<String, int> horasPorMateria;

  // Verificar se o total de horas é zero e exibir um valor mínimo
  int get totalHorasExibicao => horasTotais > 0 ? horasTotais : 1;

  const ResumoPlanoSection({
    Key? key,
    required this.periodo,
    required this.horasTotais,
    required this.horasSemanais,
    required this.horasPorDia,
    required this.horasPorMateria,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Plano de Estudos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63), // Rosa (mesma cor dos outros títulos)
              ),
            ),
            SizedBox(height: 16),
            ResumoPlanoCard(
              label: 'Período',
              value: periodo,
              emoji: '📅', // 📅 = 📅 (calendário)
              color: Colors.blue,
            ),
            ResumoPlanoCard(
              label: 'Total de Horas',
              value: '$totalHorasExibicao horas',
              emoji: '⏰', // ⏰ = ⏰ (despertador)
              color: Colors.green,
            ),
            ResumoPlanoCard(
              label: 'Horas por Semana',
              value: '$horasSemanais horas',
              emoji: '📆', // 📆 = 📆 (calendário de folha destacável)
              color: Colors.orange,
            ),
            ResumoPlanoCard(
              label: 'Horas por Dia (média)',
              value: '${horasPorDia.toStringAsFixed(1)} horas',
              emoji: '🗓', // 🗓 = 🗓 (calendário em espiral)
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Horas por Matéria',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63), // Rosa (mesma cor dos outros títulos)
              ),
            ),
            SizedBox(height: 8),
            ...horasPorMateria.entries.map((entry) {
              final Color materiaColor = _getColorForMateria(entry.key);
              final String materiaEmoji = _getEmojiForMateria(entry.key);

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: materiaColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: materiaColor),
                  boxShadow: [
                    BoxShadow(
                      color: materiaColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      materiaEmoji,
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${entry.value} horas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Método para obter cor baseada na matéria
  Color _getColorForMateria(String materia) {
    final lowerMateria = materia.toLowerCase();
    if (lowerMateria.contains('direito')) return Colors.purple;
    if (lowerMateria.contains('portugu')) return Colors.blue;
    if (lowerMateria.contains('matem')) return Colors.green;
    if (lowerMateria.contains('inform')) return Colors.teal;
    if (lowerMateria.contains('admin')) return Colors.orange;
    if (lowerMateria.contains('contab')) return Colors.amber;
    return Colors.blue;
  }

  // Método para obter emoji baseado na matéria
  String _getEmojiForMateria(String materia) {
    final lowerMateria = materia.toLowerCase();
    if (lowerMateria.contains('direito')) return '⚖️'; // ⚖️ = ⚖️ (balança)
    if (lowerMateria.contains('portugu')) return '📚'; // 📚 = 📚 (livros)
    if (lowerMateria.contains('matem')) return '📊'; // 📊 = 📊 (gráfico)
    if (lowerMateria.contains('inform')) return '💻'; // 💻 = 💻 (computador)
    if (lowerMateria.contains('admin')) return '💼'; // 💼 = 💼 (pasta de trabalho)
    if (lowerMateria.contains('contab')) return '💰'; // 💰 = 💰 (saco de dinheiro)
    return '🎓'; // 🎓 = 🎓 (chapéu de formatura)
  }
}
