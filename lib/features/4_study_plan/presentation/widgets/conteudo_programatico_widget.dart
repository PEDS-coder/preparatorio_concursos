import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/sessao_estudo_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/extrator_dados_service.dart';
import '../../domain/services/plano_resumo_service.dart';
import '../../domain/services/plano_dados_service.dart';

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
    // Primeiro tentar obter do serviço de sessões
    if (widget.sessaoEstudoService != null) {
      _horasPorMateria = widget.sessaoEstudoService!.calcularTempoEstudoPorMateria(widget.plano.id);
    }

    // Se não houver dados do serviço ou se estiver vazio, tentar obter dos metadados
    if (_horasPorMateria.isEmpty &&
        widget.plano.metadados.containsKey('horasPorMateria') &&
        widget.plano.metadados['horasPorMateria'] is Map) {
      final Map<dynamic, dynamic> horasMap = widget.plano.metadados['horasPorMateria'];
      horasMap.forEach((key, value) {
        if (key is String && (value is int || value is double)) {
          // Converter para minutos (60 minutos por hora)
          int minutos = (value is int) ? value * 60 : (value * 60).toInt();
          _horasPorMateria[key] = minutos;
        }
      });
    }

    // Se ainda estiver vazio, atribuir valores padrão com base nas matérias disponíveis
    if (_horasPorMateria.isEmpty && widget.cargo != null) {
      for (var materia in widget.cargo!.conteudoProgramatico) {
        // Atribuir 60 minutos (1 hora) por padrão para cada matéria
        _horasPorMateria[materia.nome] = 60;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cargo == null) {
      debugPrint('ERRO: Cargo é nulo, não é possível exibir conteúdo programático');
      return const SizedBox.shrink();
    }

    // Criar serviço para extrair dados do plano
    final planoDadosService = PlanoDadosService();

    // Extrair conteúdo programático usando o serviço
    List<ConteudoProgramatico> listaMaterias = planoDadosService.extrairConteudoProgramatico(widget.plano);

    // Se não encontrou conteúdo programático, usar uma lista vazia
    if (listaMaterias.isEmpty) {
      debugPrint('AVISO: Conteúdo programático não encontrado. Usando lista vazia.');

      // Verificar se há metadados no plano para diagnóstico
      if (widget.plano.metadados.isNotEmpty) {
        debugPrint('Metadados disponíveis: ${widget.plano.metadados.keys.join(', ')}');

        if (widget.plano.metadados.containsKey('concurso')) {
          debugPrint('Chaves em concurso: ${(widget.plano.metadados['concurso'] as Map?)?.keys.join(', ') ?? 'nenhuma'}');
        }
      }
    } else {
      debugPrint('Usando conteúdo programático: ${listaMaterias.length} matérias');
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

          // Definir uma cor para o grupo
          final Color grupoColor = _getColorForGrupo(grupo);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do grupo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: grupoColor, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIconForGrupo(grupo),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          grupo.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (totalQuestoesGrupo > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: grupoColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: grupoColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.quiz,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalQuestoesGrupo Questões',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
        ? '${materia.numeroQuestoes} Questões'
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
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: materiaColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da matéria
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(6),
                topRight: const Radius.circular(6),
                bottomLeft: Radius.circular(isExpanded ? 0 : 6),
                bottomRight: Radius.circular(isExpanded ? 0 : 6),
              ),
            ),
            child: ListTile(
              title: Text(
                materia.nome.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: materiaColor,
                  fontSize: 16,
                ),
              ),
              // Badges para questões, desempate e horas
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Badge de questões
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.quiz,
                            color: Colors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            questoesTexto,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de horas de estudo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.blue,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            horasTexto,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de desempate (se aplicável)
                    if (isDesempate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Desempate',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// Retorna uma cor para o grupo de matérias
  Color _getColorForGrupo(String grupo) {
    final grupoNormalizado = grupo.toLowerCase();

    // Mapeamento fixo de cores para garantir que grupos diferentes tenham cores diferentes
    if (grupoNormalizado.contains('módulo i') || grupoNormalizado.contains('modulo i')) {
      return Colors.blue.shade700; // Azul para Módulo I
    } else if (grupoNormalizado.contains('módulo ii') || grupoNormalizado.contains('modulo ii')) {
      return Colors.deepOrange.shade700; // Laranja para Módulo II
    } else if (grupoNormalizado.contains('módulo iii') || grupoNormalizado.contains('modulo iii')) {
      return Colors.purple.shade700; // Roxo para Módulo III
    } else if (grupoNormalizado.contains('módulo iv') || grupoNormalizado.contains('modulo iv')) {
      return Colors.teal.shade700; // Verde-azulado para Módulo IV
    } else if (grupoNormalizado.contains('conhecimentos básicos') || grupoNormalizado.contains('basicos')) {
      return Colors.indigo.shade700; // Índigo para Conhecimentos Básicos
    } else if (grupoNormalizado.contains('conhecimentos específicos') || grupoNormalizado.contains('especificos')) {
      return Colors.pink.shade700; // Rosa para Conhecimentos Específicos
    } else if (grupoNormalizado.contains('comum')) {
      return Colors.green.shade700; // Verde para Comum
    } else if (grupoNormalizado.contains('direito constitucional')) {
      return Colors.red.shade700; // Vermelho para Direito Constitucional
    } else if (grupoNormalizado.contains('direito administrativo')) {
      return Colors.amber.shade800; // Âmbar para Direito Administrativo
    } else if (grupoNormalizado.contains('direito civil')) {
      return Colors.cyan.shade700; // Ciano para Direito Civil
    } else if (grupoNormalizado.contains('direito processual')) {
      return Colors.deepPurple.shade700; // Roxo escuro para Direito Processual
    } else if (grupoNormalizado.contains('direito penal')) {
      return Colors.lightGreen.shade700; // Verde claro para Direito Penal
    } else if (grupoNormalizado.contains('português') || grupoNormalizado.contains('lingua portuguesa')) {
      return Colors.blue.shade800; // Azul escuro para Português
    } else if (grupoNormalizado.contains('raciocínio lógico') || grupoNormalizado.contains('matematica')) {
      return Colors.green.shade800; // Verde escuro para Raciocínio Lógico
    } else {
      // Cores para outros grupos - garantindo que sejam distintas e vibrantes
      final int hashCode = grupo.hashCode;
      final List<Color> cores = [
        Colors.blue.shade700,      // Azul
        Colors.deepOrange.shade700, // Laranja
        Colors.purple.shade700,     // Roxo
        Colors.teal.shade700,       // Verde-azulado
        Colors.pink.shade700,       // Rosa
        Colors.indigo.shade700,     // Índigo
        Colors.green.shade700,      // Verde
        Colors.amber.shade800,      // Âmbar
        Colors.cyan.shade700,       // Ciano
        Colors.red.shade700,        // Vermelho
        Colors.deepPurple.shade700, // Roxo escuro
        Colors.lightGreen.shade700, // Verde claro
      ];

      return cores[hashCode.abs() % cores.length];
    }
  }

  /// Retorna um ícone para o grupo de matérias
  IconData _getIconForGrupo(String grupo) {
    final grupoNormalizado = grupo.toLowerCase();

    if (grupoNormalizado.contains('módulo') || grupoNormalizado.contains('modulo')) {
      return Icons.book;
    } else if (grupoNormalizado.contains('conhecimentos básicos') || grupoNormalizado.contains('basicos')) {
      return Icons.school;
    } else if (grupoNormalizado.contains('conhecimentos específicos') || grupoNormalizado.contains('especificos')) {
      return Icons.architecture;
    } else if (grupoNormalizado.contains('comum')) {
      return Icons.people;
    } else {
      return Icons.subject;
    }
  }
}
