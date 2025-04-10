import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import 'cargo_select_screen.dart';

class EditalAnalysisViewScreen extends StatefulWidget {
  final String editalId;

  EditalAnalysisViewScreen({required this.editalId});

  @override
  _EditalAnalysisViewScreenState createState() => _EditalAnalysisViewScreenState();
}

class _EditalAnalysisViewScreenState extends State<EditalAnalysisViewScreen> {
  // Controle de expansão
  String? _grupoExpandido;
  String? _cargoSelecionado;
  String? _categoriaSelecionada;
  String? _materiaSelecionada;

  // Mapa para agrupar cargos
  Map<String, List<Cargo>> _gruposCargos = {};

  @override
  void initState() {
    super.initState();
    _agruparCargos();
  }

  void _agruparCargos() {
    final editalService = Provider.of<EditalService>(context, listen: false);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) return;

    // Agrupar cargos por nível de escolaridade
    Map<String, List<Cargo>> grupos = {};

    for (var cargo in edital.dadosExtraidos.cargos) {
      String grupo = 'Outros';

      // Tentar identificar o grupo pelo nome do cargo
      if (cargo.nome.toLowerCase().contains('analista')) {
        grupo = 'Nível Superior';
      } else if (cargo.nome.toLowerCase().contains('técnico')) {
        grupo = 'Nível Médio';
      } else if (cargo.nome.toLowerCase().contains('auxiliar')) {
        grupo = 'Nível Fundamental';
      }

      // Ou pela escolaridade
      else if (cargo.escolaridade.toLowerCase().contains('superior')) {
        grupo = 'Nível Superior';
      } else if (cargo.escolaridade.toLowerCase().contains('médio')) {
        grupo = 'Nível Médio';
      } else if (cargo.escolaridade.toLowerCase().contains('fundamental')) {
        grupo = 'Nível Fundamental';
      }

      if (!grupos.containsKey(grupo)) {
        grupos[grupo] = [];
      }

      grupos[grupo]!.add(cargo);
    }

    setState(() {
      _gruposCargos = grupos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final editalService = Provider.of<EditalService>(context);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Análise do Edital'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Text('Edital não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Análise do Edital'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gradientStart,
                AppTheme.gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle),
            onPressed: () {
              // Navegar para a tela de seleção de cargo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CargoSelectScreen(editalId: widget.editalId),
                ),
              );
            },
            tooltip: 'Selecionar Cargo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com informações do edital
          _buildEditalHeader(edital),

          // Conteúdo principal
          Expanded(
            child: _cargoSelecionado == null
                ? _buildGruposCargos()
                : _buildConteudoProgramatico(edital),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEditalHeader(Edital edital) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edital.nomeConcurso,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Inscrições: ${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Taxa: R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGruposCargos() {
    if (_gruposCargos.isEmpty) {
      return Center(
        child: Text('Nenhum cargo encontrado'),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _gruposCargos.length,
      itemBuilder: (context, index) {
        final grupo = _gruposCargos.keys.elementAt(index);
        final cargos = _gruposCargos[grupo]!;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (_grupoExpandido == grupo) {
                  _grupoExpandido = null;
                } else {
                  _grupoExpandido = grupo;
                }
                _cargoSelecionado = null;
                _categoriaSelecionada = null;
                _materiaSelecionada = null;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // Cabeçalho do grupo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: _grupoExpandido == grupo ? Radius.zero : Radius.circular(12),
                      bottomRight: _grupoExpandido == grupo ? Radius.zero : Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForGrupo(grupo),
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          grupo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '${cargos.length} cargos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        _grupoExpandido == grupo
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),

                // Lista de cargos (se expandido)
                if (_grupoExpandido == grupo)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: cargos.length,
                    itemBuilder: (context, index) {
                      final cargo = cargos[index];
                      return ListTile(
                        title: Text(cargo.nome),
                        subtitle: Text('Vagas: ${cargo.vagas} | Salário: R\$ ${cargo.salario.toStringAsFixed(2)}'),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                          child: Icon(Icons.work, color: AppTheme.secondaryColor),
                        ),
                        onTap: () {
                          setState(() {
                            _cargoSelecionado = cargo.nome;
                            _categoriaSelecionada = null;
                            _materiaSelecionada = null;
                          });
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConteudoProgramatico(Edital edital) {
    // Encontrar o cargo selecionado
    Cargo? cargoSelecionado;
    for (var grupo in _gruposCargos.values) {
      for (var cargo in grupo) {
        if (cargo.nome == _cargoSelecionado) {
          cargoSelecionado = cargo;
          break;
        }
      }
      if (cargoSelecionado != null) break;
    }

    if (cargoSelecionado == null) {
      return Center(
        child: Text('Cargo não encontrado'),
      );
    }

    // Agrupar matérias por tipo (comum/específico)
    Map<String, List<ConteudoProgramatico>> materiasPorCategoria = {};

    for (var materia in cargoSelecionado.conteudoProgramatico) {
      String categoria = materia.tipo == 'comum' ? 'Conhecimentos Básicos' : 'Conhecimentos Específicos';

      if (!materiasPorCategoria.containsKey(categoria)) {
        materiasPorCategoria[categoria] = [];
      }

      materiasPorCategoria[categoria]!.add(materia);
    }

    if (_categoriaSelecionada == null) {
      // Mostrar categorias
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: materiasPorCategoria.length + 1, // +1 para o botão de voltar
        itemBuilder: (context, index) {
          if (index == 0) {
            // Botão de voltar
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _cargoSelecionado = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Text(
                        'Voltar para Grupos de Cargos',
                        style: TextStyle(
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

          final categoria = materiasPorCategoria.keys.elementAt(index - 1);
          final materias = materiasPorCategoria[categoria]!;

          return Card(
            margin: EdgeInsets.only(bottom: 16),
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
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      categoria == 'Conhecimentos Básicos' ? Icons.school : Icons.psychology,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
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
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else if (_materiaSelecionada == null) {
      // Mostrar matérias da categoria selecionada
      final materias = materiasPorCategoria[_categoriaSelecionada] ?? [];

      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: materias.length + 1, // +1 para o botão de voltar
        itemBuilder: (context, index) {
          if (index == 0) {
            // Botão de voltar
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _categoriaSelecionada = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Text(
                        'Voltar para Categorias',
                        style: TextStyle(
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

          final materia = materias[index - 1];

          return Card(
            margin: EdgeInsets.only(bottom: 16),
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
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.book,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            materia.nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
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
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Mostrar tópicos da matéria selecionada
      ConteudoProgramatico? materiaSelecionada;
      for (var materia in cargoSelecionado.conteudoProgramatico) {
        if (materia.nome == _materiaSelecionada) {
          materiaSelecionada = materia;
          break;
        }
      }

      if (materiaSelecionada == null) {
        return Center(
          child: Text('Matéria não encontrada'),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: materiaSelecionada.topicos.length + 1, // +1 para o botão de voltar
        itemBuilder: (context, index) {
          if (index == 0) {
            // Botão de voltar
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _materiaSelecionada = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Text(
                        'Voltar para Matérias',
                        style: TextStyle(
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

          final topico = materiaSelecionada!.topicos[index - 1];

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topico,
                      style: TextStyle(
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
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Voltar'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar para a tela de seleção de cargo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CargoSelectScreen(editalId: widget.editalId),
                  ),
                );
              },
              icon: Icon(Icons.check_circle),
              label: Text('Selecionar Cargo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForGrupo(String grupo) {
    if (grupo.contains('Superior')) {
      return Icons.school;
    } else if (grupo.contains('Médio')) {
      return Icons.work;
    } else if (grupo.contains('Fundamental')) {
      return Icons.engineering;
    } else {
      return Icons.group;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Não informado';
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }
}
