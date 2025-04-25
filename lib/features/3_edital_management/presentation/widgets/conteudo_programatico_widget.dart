import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/edital_data_formatter_service.dart';

/// Widget que representa o conteúdo programático de um cargo
class ConteudoProgramaticoWidget extends StatelessWidget {
  final Edital edital;
  final String cargoSelecionado;
  final String? categoriaSelecionada;
  final String? materiaSelecionada;
  final Map<String, List<Cargo>> gruposCargos;
  final Function() onVoltarParaGrupos;
  final Function(String?) onCategoriaSelecionadaChanged;
  final Function(String?) onMateriaSelecionadaChanged;

  const ConteudoProgramaticoWidget({
    Key? key,
    required this.edital,
    required this.cargoSelecionado,
    required this.categoriaSelecionada,
    required this.materiaSelecionada,
    required this.gruposCargos,
    required this.onVoltarParaGrupos,
    required this.onCategoriaSelecionadaChanged,
    required this.onMateriaSelecionadaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Encontrar o cargo selecionado
    Cargo? cargo;
    for (var grupo in gruposCargos.values) {
      for (var c in grupo) {
        if (c.nome == cargoSelecionado) {
          cargo = c;
          break;
        }
      }
      if (cargo != null) break;
    }

    if (cargo == null) {
      return const Center(
        child: Text('Cargo não encontrado'),
      );
    }

    // Agrupar matérias por tipo (comum/específico)
    final materiasPorCategoria = EditalDataFormatterService.agruparMateriasPorCategoria(cargo);

    if (categoriaSelecionada == null) {
      // Mostrar categorias
      return _buildCategoriasList(materiasPorCategoria);
    } else if (materiaSelecionada == null) {
      // Mostrar matérias da categoria selecionada
      return _buildMateriasList(materiasPorCategoria);
    } else {
      // Mostrar tópicos da matéria selecionada
      return _buildTopicosList(cargo);
    }
  }

  Widget _buildCategoriasList(Map<String, List<ConteudoProgramatico>> materiasPorCategoria) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materiasPorCategoria.length + 1, // +1 para o botão de voltar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Botão de voltar
          return _buildBackButton('Voltar para Grupos de Cargos', onVoltarParaGrupos);
        }

        final categoria = materiasPorCategoria.keys.elementAt(index - 1);
        final materias = materiasPorCategoria[categoria]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => onCategoriaSelecionadaChanged(categoria),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    categoria == 'Conhecimentos Básicos' ? Icons.school : Icons.psychology,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${materias.length} matérias',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Manter a seta para categorias e matérias, pois são navegações válidas
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMateriasList(Map<String, List<ConteudoProgramatico>> materiasPorCategoria) {
    final materias = materiasPorCategoria[categoriaSelecionada] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materias.length + 1, // +1 para o botão de voltar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Botão de voltar
          return _buildBackButton('Voltar para Categorias', () => onCategoriaSelecionadaChanged(null));
        }

        final materia = materias[index - 1];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => onMateriaSelecionadaChanged(materia.nome),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.book,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          materia.nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${materia.topicos.length} tópicos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Manter a seta para matérias, pois são navegações válidas
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicosList(Cargo cargo) {
    // Encontrar a matéria selecionada
    ConteudoProgramatico? materia;
    for (var m in cargo.conteudoProgramatico) {
      if (m.nome == materiaSelecionado) {
        materia = m;
        break;
      }
    }

    if (materia == null) {
      return const Center(
        child: Text('Matéria não encontrada'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materia.topicos.length + 1, // +1 para o botão de voltar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Botão de voltar
          return _buildBackButton('Voltar para Matérias', () => onMateriaSelecionadaChanged(null));
        }

        final topico = materia!.topicos[index - 1];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topico,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(String text, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
