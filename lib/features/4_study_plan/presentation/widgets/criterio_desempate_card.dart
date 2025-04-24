import 'package:flutter/material.dart';

class CriterioDesempateCard extends StatelessWidget {
  final int index;
  final String criterio;
  final Color color;
  final String emoji;

  const CriterioDesempateCard({
    Key? key,
    required this.index,
    required this.criterio,
    required this.color,
    required this.emoji,
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
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                criterio,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class CriteriosDesempateSection extends StatelessWidget {
  final List<String> criterios;

  const CriteriosDesempateSection({
    Key? key,
    required this.criterios,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (criterios.isEmpty) {
      return SizedBox.shrink();
    }

    // Usar a cor rosa para o título (mesma cor do título "Informações da Prova")
    final Color tituloColor = Color(0xFFE91E63); // Rosa

    // Lista de cores para os cards
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.amber,
      Colors.indigo,
    ];

    // Lista de emojis para os critérios
    final List<String> emojis = [
      '👴', // 👴 = 👴 (pessoa idosa)
      '🎓', // 🎓 = 🎓 (chapéu de formatura)
      '📝', // 📝 = 📝 (memorando)
      '📊', // 📊 = 📊 (gráfico)
      '⚖️', // ⚖️ = ⚖️ (balança)
      '🗳️', // 🗳️ = 🗳️ (urna de votação)
      '👤', // 👤 = 👤 (silhueta de busto)
      '📅', // 📅 = 📅 (calendário)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Critérios de Desempate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tituloColor,
            ),
          ),
        ),
        ...criterios.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final criterio = entry.value;
          final color = colors[index % colors.length];
          final emoji = _getEmojiForCriterio(criterio, emojis[index % emojis.length]);

          return CriterioDesempateCard(
            index: index,
            criterio: criterio,
            color: color,
            emoji: emoji,
          );
        }).toList(),
      ],
    );
  }

  // Método para obter emoji baseado no texto do critério
  String _getEmojiForCriterio(String criterio, String defaultEmoji) {
    final criterioLower = criterio.toLowerCase();

    if (criterioLower.contains('idade') || criterioLower.contains('anos')) {
      return '👴'; // 👴 = 👴 (pessoa idosa)
    }
    if (criterioLower.contains('nota') || criterioLower.contains('pontuação')) {
      return '🌟'; // 🌟 = 🌟 (estrela brilhante)
    }
    if (criterioLower.contains('prova objetiva')) {
      return '✅'; // ✅ = ✅ (marca de verificação)
    }
    if (criterioLower.contains('discursiva') || criterioLower.contains('redação')) {
      return '📝'; // 📝 = 📝 (memorando)
    }
    if (criterioLower.contains('jurado')) {
      return '⚖️'; // ⚖️ = ⚖️ (balança)
    }
    if (criterioLower.contains('exercício') || criterioLower.contains('função')) {
      return '💼'; // 💼 = 💼 (pasta de trabalho)
    }
    if (criterioLower.contains('nascimento') || criterioLower.contains('velho')) {
      return '🎂'; // 🎂 = 🎂 (bolo de aniversário)
    }

    return defaultEmoji;
  }
}
