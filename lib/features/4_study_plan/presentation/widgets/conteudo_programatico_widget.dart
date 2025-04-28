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

    // Verificar se estamos lidando com o MPU para pré-expandir matérias relevantes
    if (widget.cargo != null &&
        (widget.cargo!.nome.toLowerCase().contains('mpu') ||
         widget.cargo!.nome.toLowerCase().contains('ministério público'))) {
      debugPrint('Cargo do MPU detectado, pré-expandindo matérias relevantes');

      // Pré-expandir matérias de Direito importantes para o MPU
      Future.delayed(Duration.zero, () {
        setState(() {
          for (var materia in widget.cargo!.conteudoProgramatico) {
            final nome = materia.nome.toLowerCase();
            if (nome.contains('direito constitucional') ||
                nome.contains('direito administrativo') ||
                nome.contains('direito civil') ||
                nome.contains('direito processual') ||
                nome.contains('direito penal')) {
              final materiaId = materia.nome.hashCode.toString();
              _expandedMaterias[materiaId] = true;
            }
          }
        });
      });
    }
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

    // Agrupar matérias por grupo/módulo, usando a chave "grupo_materia" (ou similar)
    Map<String, List<ConteudoProgramatico>> materiasPorGrupo = {};
    for (final materia in listaMaterias) {
      // Prioriza o campo "grupo_materia" (ou variações), senão agrupa em "SEM GRUPO"
      String grupo = '';
      if (materia.grupoMateria != null && materia.grupoMateria!.trim().isNotEmpty) {
        grupo = materia.grupoMateria!;
      } else if (materia.grupo != null && materia.grupo!.trim().isNotEmpty) {
        grupo = materia.grupo!;
      } else {
        grupo = 'SEM GRUPO';
      }
      if (!materiasPorGrupo.containsKey(grupo)) {
        materiasPorGrupo[grupo] = [];
      }
      materiasPorGrupo[grupo]!.add(materia);
    }

    // Ordena grupos pelo nome
    final gruposOrdenados = materiasPorGrupo.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...gruposOrdenados.map((grupo) {
          final materias = materiasPorGrupo[grupo]!;
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
                child: Text(
                  grupo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ...materias.map((materia) => _buildMateriaCardPersonalizado(materia, grupoColor)).toList(),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMateriaCardPersonalizado(ConteudoProgramatico materia, Color grupoColor) {
    final String materiaId = materia.nome.hashCode.toString();
    final isExpanded = _expandedMaterias[materiaId] ?? false;
    // Nome da matéria caixa alta, cor do grupo
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: grupoColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              materia.nome.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: grupoColor,
                fontSize: 16,
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
                  ...materia.topicos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final topico = entry.value;
                    // Nome do tópico: só a primeira letra maiúscula
                    final topicoFormatado = topico.isNotEmpty
                        ? topico[0].toUpperCase() + topico.substring(1).toLowerCase()
                        : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: grupoColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              topicoFormatado,
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
