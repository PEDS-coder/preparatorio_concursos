import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/plano_resumo_service.dart';

/// Widget para exibir o conteúdo programático
class ConteudoProgramaticoWidget extends StatefulWidget {
  final PlanoEstudo plano;
  final Edital? edital;
  final Cargo? cargo;
  final PlanoResumoService planoResumoService;
  final ExtratorDadosService extratoService;

  const ConteudoProgramaticoWidget({
    Key? key,
    required this.plano,
    required this.edital,
    required this.cargo,
    required this.planoResumoService,
    required this.extratoService,
  }) : super(key: key);

  @override
  _ConteudoProgramaticoWidgetState createState() => _ConteudoProgramaticoWidgetState();
}

class _ConteudoProgramaticoWidgetState extends State<ConteudoProgramaticoWidget> {
  Map<String, bool> _expandedMaterias = {};

  @override
  Widget build(BuildContext context) {
    if (widget.edital == null || widget.cargo == null) {
      return SizedBox.shrink();
    }

    // Agrupar matérias por grupo/módulo
    Map<String, List<ConteudoProgramatico>> materiasPorGrupo =
        widget.planoResumoService.agruparMateriasPorGrupo(widget.cargo!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Conteúdo Programático',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        ...materiasPorGrupo.entries.map((entry) {
          final grupo = entry.key;
          final materias = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                  grupo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              ...materias.map((materia) => _buildMateriaCard(materia)).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMateriaCard(ConteudoProgramatico materia) {
    // Gerar um ID único baseado no nome da matéria
    final String materiaId = materia.nome.hashCode.toString();
    final isExpanded = _expandedMaterias[materiaId] ?? false;
    final materiaColor = widget.extratoService.getColorForMateria(materia.nome);

    // Obter número de questões e peso
    final String questoes = materia.numeroQuestoes != null ? materia.numeroQuestoes.toString() : 'Não informado';
    final String peso = materia.pesoMaior == true ? 'Maior' : 'Normal';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: materiaColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              materia.nome,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Peso: $peso | Questões: $questoes ${materia.questoesEstimadas == true ? "(estimadas)" : ""}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: materiaColor,
              ),
              onPressed: () {
                setState(() {
                  _expandedMaterias[materiaId] = !isExpanded;
                });
              },
            ),
            onTap: () {
              setState(() {
                _expandedMaterias[materiaId] = !isExpanded;
              });
            },
            tileColor: materiaColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: isExpanded ? Radius.zero : Radius.circular(8),
              ),
            ),
          ),
          if (isExpanded && materia.topicos.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tópicos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...materia.topicos.map((topico) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 8, color: materiaColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              topico,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
