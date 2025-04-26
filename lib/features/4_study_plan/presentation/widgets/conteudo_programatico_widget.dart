import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
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
  final SessaoEstudoService? sessaoEstudoService;

  const ConteudoProgramaticoWidget({
    Key? key,
    required this.plano,
    required this.edital,
    required this.cargo,
    required this.planoResumoService,
    required this.extratoService,
    this.sessaoEstudoService,
  }) : super(key: key);

  @override
  _ConteudoProgramaticoWidgetState createState() => _ConteudoProgramaticoWidgetState();
}

class _ConteudoProgramaticoWidgetState extends State<ConteudoProgramaticoWidget> {
  final Map<String, bool> _expandedMaterias = {};
  Map<String, int> _horasPorMateria = {};

  @override
  void initState() {
    super.initState();
    _carregarHorasPorMateria();
  }

  /// Carrega as horas de estudo por matéria
  void _carregarHorasPorMateria() {
    if (widget.sessaoEstudoService != null) {
      _horasPorMateria = widget.sessaoEstudoService!.calcularTempoEstudoPorMateria(widget.plano.id);
    } else {
      // Tentar obter horas dos metadados do plano
      if (widget.plano.metadados.containsKey('horasPorMateria') &&
          widget.plano.metadados['horasPorMateria'] is Map) {
        final Map<dynamic, dynamic> horasMap = widget.plano.metadados['horasPorMateria'];
        horasMap.forEach((key, value) {
          if (key is String && (value is int || value is double)) {
            _horasPorMateria[key] = (value is int) ? value : value.toInt();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cargo == null) {
      return const SizedBox.shrink();
    }

    // Selecionar lista de matérias: preferir dado da LLM se existir
    List<ConteudoProgramatico> listaMaterias;
    if (widget.plano.metadados.containsKey('conteudo_programatico') &&
        widget.plano.metadados['conteudo_programatico'] is List) {
      listaMaterias = (widget.plano.metadados['conteudo_programatico'] as List)
          .map((item) => ConteudoProgramatico.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } else {
      listaMaterias = widget.cargo!.conteudoProgramatico;
    }
    // Criar cargo temporário para agrupar usando as matérias corretas
    final cargoTemp = Cargo(
      nome: widget.cargo!.nome,
      id: widget.cargo!.id,
      vagas: widget.cargo!.vagas,
      salario: widget.cargo!.salario,
      taxaInscricao: widget.cargo!.taxaInscricao,
      nivel: widget.cargo!.nivel,
      escolaridade: widget.cargo!.escolaridade,
      requisitos: widget.cargo!.requisitos,
      conteudoProgramatico: listaMaterias,
      dataProva: widget.cargo!.dataProva,
      horarioProva: widget.cargo!.horarioProva,
    );
    // Agrupar matérias por grupo/módulo
    Map<String, List<ConteudoProgramatico>> materiasPorGrupo =
        widget.planoResumoService.agruparMateriasPorGrupo(cargoTemp);

    // Obter o nome do cargo para o título
    final String nomeCargo = widget.cargo?.nome ?? 'Não informado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título do conteúdo programático com o nome do cargo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.pink[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Conteúdo Programático - $nomeCargo',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Grupos de matérias
        ...materiasPorGrupo.entries.map((entry) {
          final grupo = entry.key;
          final materias = entry.value;

          // Calcular o total de questões do grupo
          int totalQuestoesGrupo = 0;
          for (var materia in materias) {
            if (materia.numeroQuestoes != null) {
              totalQuestoesGrupo += materia.numeroQuestoes!;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do grupo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E), // Azul escuro
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      grupo.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (totalQuestoesGrupo > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '≈ $totalQuestoesGrupo Questões',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Lista de matérias do grupo
              ...materias.map((materia) => _buildMateriaCard(materia)).toList(),
              const SizedBox(height: 16),
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

    // Obter número de questões
    final bool temQuestoes = materia.numeroQuestoes != null;
    final String questoesTexto = temQuestoes
        ? '${materia.numeroQuestoes} Questões${materia.questoesEstimadas == true ? " (estimadas)" : ""}'
        : 'Questões não informadas';

    // Obter horas de estudo para esta matéria
    final int horasEstudo = _horasPorMateria[materia.nome] ?? 0;
    final String horasTexto = horasEstudo > 0
        ? '${horasEstudo ~/ 60} Horas'
        : 'Horas não definidas';

    // Verificar se é critério de desempate
    final bool isDesempate = materia.criterioDesempate == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: materiaColor,
            width: 4,
          ),
        ),
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da matéria
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(8),
                bottomRight: Radius.circular(isExpanded ? 0 : 8),
              ),
            ),
            child: ListTile(
              title: Text(
                materia.nome.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Badges para questões, desempate e horas
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    // Badge de questões
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        questoesTexto,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge de horas de estudo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        horasTexto,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Badge de desempate (se aplicável)
                    if (isDesempate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Desempate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
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
            ),
          ),
          // Conteúdo expandido (tópicos)
          if (isExpanded && materia.topicos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tópicos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...materia.topicos.map((topico) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 8, color: materiaColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              topico,
                              style: const TextStyle(
                                fontSize: 14,
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
        ],
      ),
    );
  }
}
