import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../../domain/services/conteudo_programatico_service.dart';

/// Widget que exibe a aba de conteúdo programático do edital
class ConteudoTabWidget extends StatefulWidget {
  final Edital edital;
  final Function(String) onCargoSelected;

  const ConteudoTabWidget({
    Key? key,
    required this.edital,
    required this.onCargoSelected,
  }) : super(key: key);

  @override
  _ConteudoTabWidgetState createState() => _ConteudoTabWidgetState();
}

class _ConteudoTabWidgetState extends State<ConteudoTabWidget> {
  String? _cargoSelecionado;
  String? _categoriaSelecionada;
  String? _materiaSelecionada;

  @override
  Widget build(BuildContext context) {
    if (_cargoSelecionado == null) {
      return _buildCargosList();
    } else {
      // Encontrar o cargo selecionado
      Cargo? cargo;
      for (var c in widget.edital.dadosExtraidos.cargos) {
        if (c.nome == _cargoSelecionado) {
          cargo = c;
          break;
        }
      }

      if (cargo == null) {
        return const Center(
          child: Text('Cargo não encontrado'),
        );
      }

      // Agrupar matérias por categoria
      final materiasPorCategoria = ConteudoProgramaticoService.agruparMateriasPorCategoria(
        cargo.conteudoProgramatico,
      );

      if (_categoriaSelecionada == null) {
        return _buildCategoriasList(cargo, materiasPorCategoria);
      } else if (_materiaSelecionada == null) {
        return _buildMateriasList(cargo, materiasPorCategoria);
      } else {
        return _buildTopicosList(cargo);
      }
    }
  }

  Widget _buildCargosList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione um Cargo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Lista de cargos
          ...widget.edital.dadosExtraidos.cargos.map((cargo) => _buildCargoCard(cargo)).toList(),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Cargo cargo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _cargoSelecionado = cargo.nome;
            _categoriaSelecionada = null;
            _materiaSelecionada = null;
          });
          widget.onCargoSelected(cargo.nome);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.work,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cargo.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cargo.conteudoProgramatico.length} matérias',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriasList(
    Cargo cargo,
    Map<String, List<ConteudoProgramatico>> materiasPorCategoria,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materiasPorCategoria.length + 1, // +1 para o botão de voltar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Botão de voltar
          return _buildBackButton('Voltar para Cargos', () {
            setState(() {
              _cargoSelecionado = null;
            });
          });
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
            onTap: () {
              setState(() {
                _categoriaSelecionada = categoria;
              });
            },
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
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMateriasList(
    Cargo cargo,
    Map<String, List<ConteudoProgramatico>> materiasPorCategoria,
  ) {
    final materias = materiasPorCategoria[_categoriaSelecionada] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materias.length + 1, // +1 para o botão de voltar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Botão de voltar
          return _buildBackButton('Voltar para Categorias', () {
            setState(() {
              _categoriaSelecionada = null;
            });
          });
        }

        final materia = materias[index - 1];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _materiaSelecionada = materia.nome;
              });
            },
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
    ConteudoProgramatico? materiaSelecionada;
    for (var materia in cargo.conteudoProgramatico) {
      if (materia.nome == _materiaSelecionada) {
        materiaSelecionada = materia;
        break;
      }
    }

    if (materiaSelecionada == null) {
      return const Center(
        child: Text('Matéria não encontrada'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materiaSelecionada.topicos.length + 1, // +1 para o botão de voltar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Botão de voltar
          return _buildBackButton('Voltar para Matérias', () {
            setState(() {
              _materiaSelecionada = null;
            });
          });
        }

        final topico = materiaSelecionada!.topicos[index - 1];

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
