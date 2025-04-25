import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';

/// Widget para exibir dados do Plano de Estudos gerados pela LLM
class PlanoEstudosSummaryWidget extends StatelessWidget {
  final PlanoEstudo plano;

  const PlanoEstudosSummaryWidget({Key? key, required this.plano}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metadados = plano.metadados;
    final planoEstudos = metadados['planoEstudos'] as Map<String, dynamic>?;
    if (planoEstudos == null) return const SizedBox.shrink();

    final ciclo = planoEstudos['cicloEstudos'] as List<dynamic>?;
    final duracao = metadados['duracao_total_ciclo'];
    final totalBlocos = metadados['total_blocos_ciclo'];
    final materiasPri = planoEstudos['materiasPrioritarias'] as List<dynamic>?;
    final recomendacoes = planoEstudos['recomendacoesGerais'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Plano de Estudos (LLM)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (duracao != null) Text('Duração total do ciclo: $duracao dias'),
                if (totalBlocos != null) Text('Total de blocos: $totalBlocos'),
                if (materiasPri != null && materiasPri.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Matérias Prioritárias:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...materiasPri.map((m) => Text('- ${m.toString()}')).toList(),
                ],
                if (recomendacoes != null && recomendacoes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Recomendações Gerais:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...recomendacoes.map((r) => Text('- ${r.toString()}')).toList(),
                ],
                if (ciclo != null && ciclo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Ciclo de Estudos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...ciclo.map((d) {
                    final dia = d['dia'];
                    final blocos = (d['blocos'] as List<dynamic>).map((b) => b['ordem']).join(', ');
                    return Text('• Dia $dia: blocos $blocos');
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
