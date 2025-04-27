import 'package:flutter/material.dart';
import '../../../../../core/data/models/models.dart';
import '../../../../../core/utils/plano_data_logger.dart';
import '../../../domain/services/plano_data_service.dart';

class MateriasSection extends StatefulWidget {
  final PlanoEstudo plano;
  final Edital? edital;
  final PlanoDataLogger logger;

  const MateriasSection({
    Key? key,
    required this.plano,
    this.edital,
    required this.logger,
  }) : super(key: key);

  @override
  State<MateriasSection> createState() => _MateriasSectionState();
}

class _MateriasSectionState extends State<MateriasSection> {
  final Map<String, bool> _expandedMaterias = {};

  @override
  void initState() {
    super.initState();
    _initExpandedState();
  }

  void _initExpandedState() {
    final planoDataService = PlanoDataService(
      plano: widget.plano,
      edital: widget.edital,
      logger: widget.logger,
    );

    final materias = planoDataService.obterMaterias();
    for (var materia in materias) {
      _expandedMaterias[materia.nome] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planoDataService = PlanoDataService(
      plano: widget.plano,
      edital: widget.edital,
      logger: widget.logger,
    );

    final materias = planoDataService.obterMaterias();

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: const Color(0xFF1a2240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conteúdo Programático',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (materias.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nenhuma matéria encontrada para este cargo.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Tentar recarregar as matérias
                      setState(() {
                        // Forçar reconstrução do widget
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            else
              ...materias.map((materia) => _buildMateriaItem(context, materia)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaItem(BuildContext context, ConteudoProgramatico materia) {
    final isExpanded = _expandedMaterias[materia.nome] ?? false;
    final tipoLabel = materia.tipo == 'comum' ? 'Conhecimento Comum' : 'Conhecimento Específico';
    final questoesLabel = materia.numeroQuestoes != null ? '${materia.numeroQuestoes} questões' : '';
    final pesoLabel = materia.pesoMaior == true ? 'Peso maior' : '';
    final desempateLabel = materia.criterioDesempate == true ? 'Critério de desempate' : '';

    // Combinar labels não vazios com vírgulas
    final List<String> labels = [tipoLabel, questoesLabel, pesoLabel, desempateLabel]
        .where((label) => label.isNotEmpty)
        .toList();
    final String subtitleText = labels.join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: const Color(0xFF13192b),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          materia.nome,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.white70,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedMaterias[materia.nome] = expanded;
          });
        },
        initiallyExpanded: isExpanded,
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tópicos:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...materia.topicos.map((topico) => _buildTopicoItem(topico)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicoItem(String topico) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              topico,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
