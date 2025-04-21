import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/bottom_navigation_helper.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import 'cargo_select_screen.dart';

class EditalAnalysisViewScreen extends StatefulWidget {
  final String editalId;
  final List<String>? cargosSelecionados;
  final bool showBottomNavigationBar;

  EditalAnalysisViewScreen({
    required this.editalId,
    this.cargosSelecionados,
    this.showBottomNavigationBar = true,
  });

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

    // Verificar se há cargos disponíveis
    if (edital.dadosExtraidos.cargos.isEmpty) {
      debugPrint('Nenhum cargo encontrado no edital');
      setState(() {
        _gruposCargos = {};
      });
      return;
    }

    // Filtrar cargos selecionados se houver
    List<Cargo> cargosParaAgrupar = edital.dadosExtraidos.cargos;
    if (widget.cargosSelecionados != null && widget.cargosSelecionados!.isNotEmpty) {
      cargosParaAgrupar = edital.dadosExtraidos.cargos.where((cargo) {
        return widget.cargosSelecionados!.contains(cargo.nome) ||
               widget.cargosSelecionados!.contains(cargo.id);
      }).toList();

      // Se não encontrou nenhum cargo, usar todos os cargos
      if (cargosParaAgrupar.isEmpty) {
        cargosParaAgrupar = edital.dadosExtraidos.cargos;
      }
    }

    // Verificar se todos os cargos são de nível superior
    bool todosNivelSuperior = true;
    for (var cargo in cargosParaAgrupar) {
      final escolaridade = cargo.escolaridade.toLowerCase();
      if (!escolaridade.contains('superior') &&
          !escolaridade.contains('graduação') &&
          !escolaridade.contains('bacharel') &&
          !escolaridade.contains('licenciatura')) {
        todosNivelSuperior = false;
        break;
      }
    }

    // Verificar se o título do concurso contém MPU
    bool isMPU = edital.dadosExtraidos.titulo?.toLowerCase().contains('mpu') == true ||
                 edital.dadosExtraidos.orgao?.toLowerCase().contains('ministério público da união') == true;

    // Se todos os cargos são de nível superior ou se é um concurso do MPU
    if (todosNivelSuperior || isMPU) {
      // Agrupar por tipo de cargo em vez de nível de escolaridade
      for (var cargo in cargosParaAgrupar) {
        String grupo = 'Outros';
        final nomeCargo = cargo.nome.toLowerCase();

        // Para concursos do MPU
        if (isMPU) {
          if (nomeCargo.contains('analista')) {
            grupo = 'Analista do MPU';
          } else if (nomeCargo.contains('técnico')) {
            grupo = 'Técnico do MPU';
          }
        }
        // Para outros concursos onde todos os cargos são de nível superior
        else if (todosNivelSuperior) {
          // Extrair a área/especialidade do cargo
          if (nomeCargo.contains('analista')) {
            grupo = 'Analista';
          } else if (nomeCargo.contains('técnico')) {
            grupo = 'Técnico';
          } else if (nomeCargo.contains('auditor')) {
            grupo = 'Auditor';
          } else if (nomeCargo.contains('procurador')) {
            grupo = 'Procurador';
          } else if (nomeCargo.contains('advogado')) {
            grupo = 'Advogado';
          } else {
            // Tentar extrair a área principal do cargo
            List<String> partes = nomeCargo.split(' ');
            if (partes.length > 0) {
              grupo = partes[0].substring(0, 1).toUpperCase() + partes[0].substring(1);
            }
          }
        }

        if (!grupos.containsKey(grupo)) {
          grupos[grupo] = [];
        }

        grupos[grupo]!.add(cargo);
      }
    } else {
      // Comportamento padrão para outros editais com diferentes níveis de escolaridade
      for (var cargo in cargosParaAgrupar) {
        String grupo = 'Outros';
        final nomeCargo = cargo.nome.toLowerCase();
        final escolaridade = cargo.escolaridade.toLowerCase();

        // Determinar o nível pela escolaridade primeiro (mais preciso)
        if (escolaridade.contains('superior') ||
            escolaridade.contains('graduação') ||
            escolaridade.contains('bacharel') ||
            escolaridade.contains('licenciatura')) {
          grupo = 'Nível Superior';
        } else if (escolaridade.contains('médio') ||
                  escolaridade.contains('técnico') ||
                  escolaridade.contains('2º grau')) {
          grupo = 'Nível Médio';
        } else if (escolaridade.contains('fundamental') ||
                  escolaridade.contains('1º grau') ||
                  escolaridade.contains('elementar')) {
          grupo = 'Nível Fundamental';
        }
        // Se não encontrou pela escolaridade, tentar pelo nome do cargo
        else if (nomeCargo.contains('analista') ||
                nomeCargo.contains('auditor') ||
                nomeCargo.contains('procurador') ||
                nomeCargo.contains('advogado') ||
                nomeCargo.contains('contador') ||
                nomeCargo.contains('administrador')) {
          grupo = 'Nível Superior';
        } else if (nomeCargo.contains('técnico') ||
                  nomeCargo.contains('assistente') ||
                  nomeCargo.contains('agente')) {
          grupo = 'Nível Médio';
        } else if (nomeCargo.contains('auxiliar') ||
                  nomeCargo.contains('motorista') ||
                  nomeCargo.contains('operador')) {
          grupo = 'Nível Fundamental';
        }

        if (!grupos.containsKey(grupo)) {
          grupos[grupo] = [];
        }

        grupos[grupo]!.add(cargo);
      }
    }

    // Ordenar os cargos dentro de cada grupo por nome
    grupos.forEach((key, value) {
      value.sort((a, b) => a.nome.compareTo(b.nome));
    });

    setState(() {
      _gruposCargos = grupos;

      // Se houver apenas um cargo selecionado, expandir automaticamente
      if (cargosParaAgrupar.length == 1) {
        _cargoSelecionado = cargosParaAgrupar.first.nome;
      }
      // Se houver apenas um grupo, expandir automaticamente
      else if (grupos.length == 1) {
        _grupoExpandido = grupos.keys.first;
      }
    });

    // Log para depuração
    debugPrint('Grupos de cargos: ${_gruposCargos.keys.join(', ')}');
    _gruposCargos.forEach((grupo, cargos) {
      debugPrint('$grupo: ${cargos.length} cargos');
      for (var cargo in cargos) {
        debugPrint('  - ${cargo.nome}');
      }
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
      bottomNavigationBar: widget.showBottomNavigationBar
          ? BottomNavigationHelper.buildBottomNavigationBar(
              context,
              currentIndex: 1, // Índice do Meu Edital
            )
          : _buildBottomNavigation(),
    );
  }

  Widget _buildEditalHeader(Edital edital) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
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
          SizedBox(height: 12),
          // Órgão responsável
          if (edital.dadosExtraidos.orgao != null && edital.dadosExtraidos.orgao!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark ?
                           Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Órgão: ${edital.dadosExtraidos.orgao}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark ?
                               Colors.grey.shade300 : Colors.grey.shade700
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Banca organizadora
          if (edital.dadosExtraidos.banca != null && edital.dadosExtraidos.banca!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark ?
                           Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Banca: ${edital.dadosExtraidos.banca}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark ?
                               Colors.grey.shade300 : Colors.grey.shade700
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Inscrições
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark ?
                         Colors.grey.shade300 : Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Inscrições: ${_formatDate(edital.dadosExtraidos.inicioInscricao)} a ${_formatDate(edital.dadosExtraidos.fimInscricao)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark ?
                             Colors.grey.shade300 : Colors.grey.shade700
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Taxa
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark ?
                         Colors.grey.shade300 : Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: _buildTaxaInscricao(edital),
                ),
              ],
            ),
          ),
          // Local da prova
          if (edital.dadosExtraidos.localProva != null && edital.dadosExtraidos.localProva!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark ?
                           Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Local da Prova: ${edital.dadosExtraidos.localProva}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark ?
                               Colors.grey.shade300 : Colors.grey.shade700
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cotas
          _buildCotasInfo(edital),
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
                          color: Theme.of(context).brightness == Brightness.dark ?
                                 Colors.grey.shade300 : Colors.grey.shade700,
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
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            cargo.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ?
                                     Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ?
                                           Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Vagas: ${cargo.vagas}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ?
                                             Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ?
                                           Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Salário: R\$ ${cargo.salario.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ?
                                             Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ?
                                           Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Escolaridade: ${cargo.escolaridade}',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ?
                                               Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                          // Removido o ícone de seta para evitar confusão na navegação
                        ),
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
      // Verificar o tipo da matéria (comum ou específico/especifico)
      String categoria;
      if (materia.tipo == 'comum') {
        categoria = 'Conhecimentos Básicos';
      } else if (materia.tipo == 'específico' || materia.tipo == 'especifico') {
        categoria = 'Conhecimentos Específicos';
      } else {
        // Fallback para tipos desconhecidos
        categoria = 'Outros Conhecimentos';
      }

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
                    // Manter a seta para categorias e matérias, pois são navegações válidas
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
                    // Manter a seta para matérias, pois são navegações válidas
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

  Widget _buildTaxaInscricao(Edital edital) {
    // Verificar se há taxas por nível no dadosOriginais
    if (edital.dadosOriginais != null) {
      // Verificar diferentes formatos possíveis para taxas por nível
      Map<dynamic, dynamic>? taxasPorNivel;

      // Verificar diferentes chaves possíveis para taxas
      final possiveisChavesTaxas = [
        'taxas_por_nivel',
        'valor_taxa_inscricao',
        'taxa_inscricao',
        'taxas_inscricao',
        'taxas',
        'valores_taxa'
      ];

      // Buscar em todas as chaves possíveis
      for (final chave in possiveisChavesTaxas) {
        if (edital.dadosOriginais!.containsKey(chave) &&
            edital.dadosOriginais![chave] is Map) {
          taxasPorNivel = edital.dadosOriginais![chave] as Map<dynamic, dynamic>?;
          break;
        }
      }

      // Verificar se há um valor direto de taxa
      double valorTaxaDireta = 0.0;
      final possiveisChavesTaxaDireta = [
        'valorTaxa',
        'valor_taxa',
        'taxa',
        'taxa_inscricao_valor',
        'valor_inscricao'
      ];

      // Buscar em todas as chaves possíveis para taxa direta
      for (final chave in possiveisChavesTaxaDireta) {
        if (edital.dadosOriginais!.containsKey(chave)) {
          var valorTaxa = edital.dadosOriginais![chave];
          if (valorTaxa is num) {
            valorTaxaDireta = valorTaxa.toDouble();
            break;
          } else if (valorTaxa is String) {
            try {
              // Remover caracteres não numéricos, exceto ponto e vírgula
              final valorStr = valorTaxa.toString().replaceAll(RegExp(r'[^\d.,]'), '');
              if (valorStr.isNotEmpty) {
                valorTaxaDireta = double.parse(valorStr.replaceAll(',', '.'));
                break;
              }
            } catch (e) {
              print('Erro ao converter taxa direta ($chave): $e');
            }
          }
        }
      }

      // Verificar se há taxas por cargo
      Map<dynamic, dynamic>? taxasPorCargo;
      if (edital.dadosOriginais!.containsKey('cargos') &&
          edital.dadosOriginais!['cargos'] is List) {

        final cargos = edital.dadosOriginais!['cargos'] as List;
        if (cargos.isNotEmpty && cargos.first is Map) {
          // Verificar se os cargos têm taxas individuais
          bool temTaxasIndividuais = false;
          for (var cargo in cargos) {
            if (cargo is Map &&
                (cargo.containsKey('taxa_inscricao') ||
                 cargo.containsKey('taxa') ||
                 cargo.containsKey('valor_taxa'))) {
              temTaxasIndividuais = true;
              break;
            }
          }

          if (temTaxasIndividuais) {
            taxasPorCargo = {};
            for (var cargo in cargos) {
              if (cargo is Map) {
                String nomeCargo = '';
                if (cargo.containsKey('nome')) {
                  nomeCargo = cargo['nome'].toString();
                } else if (cargo.containsKey('nome_cargo')) {
                  nomeCargo = cargo['nome_cargo'].toString();
                }

                if (nomeCargo.isNotEmpty) {
                  double valorTaxa = 0.0;

                  // Buscar taxa em diferentes campos
                  for (final chaveTaxa in ['taxa_inscricao', 'taxa', 'valor_taxa']) {
                    if (cargo.containsKey(chaveTaxa)) {
                      var taxa = cargo[chaveTaxa];
                      if (taxa is num) {
                        valorTaxa = taxa.toDouble();
                        break;
                      } else if (taxa is String) {
                        try {
                          final valorStr = taxa.toString().replaceAll(RegExp(r'[^\d.,]'), '');
                          if (valorStr.isNotEmpty) {
                            valorTaxa = double.parse(valorStr.replaceAll(',', '.'));
                            break;
                          }
                        } catch (e) {
                          print('Erro ao converter taxa do cargo: $e');
                        }
                      }
                    }
                  }

                  if (valorTaxa > 0) {
                    taxasPorCargo[nomeCargo] = valorTaxa;
                  }
                }
              }
            }
          }
        }
      }

      // Prioridade de exibição: 1. Taxas por nível, 2. Taxas por cargo, 3. Taxa direta

      // Se temos taxas por nível, exibir todas
      if (taxasPorNivel != null && taxasPorNivel.isNotEmpty) {
        // Construir uma lista de taxas por nível
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxas de inscrição:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ?
                       Colors.grey.shade300 : Colors.grey.shade700
              ),
            ),
            ...taxasPorNivel.entries.map((entry) {
              final nivel = entry.key.toString();
              double valor = 0.0;

              // Extrair o valor numérico da taxa
              if (entry.value is num) {
                valor = (entry.value as num).toDouble();
              } else if (entry.value is String) {
                // Tentar extrair valor numérico da string
                try {
                  final valorStr = entry.value.toString().replaceAll(RegExp(r'[^\d.,]'), '');
                  if (valorStr.isNotEmpty) {
                    valor = double.parse(valorStr.replaceAll(',', '.'));
                  }
                } catch (e) {
                  print('Erro ao converter taxa: $e');
                }
              } else if (entry.value is Map) {
                // Alguns editais têm a taxa como um objeto com campo 'valor'
                final taxaMap = entry.value as Map;
                if (taxaMap.containsKey('valor')) {
                  var valorObj = taxaMap['valor'];
                  if (valorObj is num) {
                    valor = valorObj.toDouble();
                  } else if (valorObj is String) {
                    try {
                      final valorStr = valorObj.toString().replaceAll(RegExp(r'[^\d.,]'), '');
                      if (valorStr.isNotEmpty) {
                        valor = double.parse(valorStr.replaceAll(',', '.'));
                      }
                    } catch (e) {
                      print('Erro ao converter taxa do objeto: $e');
                    }
                  }
                }
              }

              // Só exibir se o valor for maior que zero
              if (valor > 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                  child: Text(
                    '${_formatarNivel(nivel)}: R\$ ${valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark ?
                             Colors.grey.shade300 : Colors.grey.shade700
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink(); // Não exibir se o valor for zero
              }
            }).toList(),
          ],
        );
      }

      // Se temos taxas por cargo, exibir
      else if (taxasPorCargo != null && taxasPorCargo.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxas de inscrição:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ?
                       Colors.grey.shade300 : Colors.grey.shade700
              ),
            ),
            ...taxasPorCargo.entries.map((entry) {
              final cargo = entry.key.toString();
              final valor = entry.value as double;

              // Só exibir se o valor for maior que zero
              if (valor > 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                  child: Text(
                    '${cargo}: R\$ ${valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark ?
                             Colors.grey.shade300 : Colors.grey.shade700
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink(); // Não exibir se o valor for zero
              }
            }).toList(),
          ],
        );
      }

      // Se temos um valor direto de taxa, exibir
      else if (valorTaxaDireta > 0) {
        return Text(
          'Taxa: R\$ ${valorTaxaDireta.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark ?
                   Colors.grey.shade300 : Colors.grey.shade700
          ),
        );
      }
    }

    // Verificar se o valor da taxa nos dados extraídos é válido
    if (edital.dadosExtraidos.valorTaxa > 0) {
      return Text(
        'Taxa: R\$ ${edital.dadosExtraidos.valorTaxa.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark ?
                 Colors.grey.shade300 : Colors.grey.shade700
        ),
      );
    }

    // Se chegou aqui, não encontrou nenhum valor válido
    return Text(
      'Taxa: Consulte o edital',
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).brightness == Brightness.dark ?
               Colors.grey.shade300 : Colors.grey.shade700
      ),
    );
  }

  Widget _buildCotasInfo(Edital edital) {
    // Verificar se há informações sobre cotas nos dados originais
    Map<dynamic, dynamic>? cotasInfo;
    String? cotasText;

    if (edital.dadosOriginais != null) {
      // Verificar diferentes formatos possíveis de cotas nos dados
      final possiveisChavesCotas = [
        'cotas',
        'percentual_cotas',
        'reserva_vagas',
        'vagas_reservadas',
        'reserva_de_vagas',
        'politica_cotas',
        'sistema_cotas'
      ];

      // Buscar em todas as chaves possíveis
      for (final chave in possiveisChavesCotas) {
        if (edital.dadosOriginais!.containsKey(chave)) {
          var cotasData = edital.dadosOriginais![chave];
          if (cotasData is Map) {
            cotasInfo = cotasData as Map<dynamic, dynamic>;
            break;
          } else if (cotasData is String && cotasData.isNotEmpty) {
            // Se for uma string, usar como texto de cotas
            cotasText = cotasData;
            break;
          }
        }
      }

      // Verificar se há informações de cotas nos cargos
      if (cotasInfo == null &&
          edital.dadosOriginais!.containsKey('cargos') &&
          edital.dadosOriginais!['cargos'] is List) {

        final cargos = edital.dadosOriginais!['cargos'] as List;
        if (cargos.isNotEmpty && cargos.first is Map) {
          // Verificar se os cargos têm informações de cotas
          for (var cargo in cargos) {
            if (cargo is Map) {
              for (final chaveCota in possiveisChavesCotas) {
                if (cargo.containsKey(chaveCota) && cargo[chaveCota] is Map) {
                  cotasInfo = cargo[chaveCota] as Map<dynamic, dynamic>;
                  break;
                }
              }
              if (cotasInfo != null) break;
            }
          }
        }
      }

      // Verificar se há informações de cotas no texto do edital
      if (edital.textoCompleto.isNotEmpty) {
        final texto = edital.textoCompleto.toLowerCase();

        // Padrões comuns de cotas em editais
        final padroes = [
          {'termo': 'negros', 'percentual': '20%', 'nome': 'Negros'},
          {'termo': 'afrodescendentes', 'percentual': '20%', 'nome': 'Afrodescendentes'},
          {'termo': 'pcd', 'percentual': '5%', 'nome': 'PCD'},
          {'termo': 'pessoa com deficiência', 'percentual': '5%', 'nome': 'PCD'},
          {'termo': 'indígena', 'percentual': '5%', 'nome': 'Indígenas'},
          {'termo': 'indigena', 'percentual': '5%', 'nome': 'Indígenas'},
          {'termo': 'minorias étnico-raciais', 'percentual': '10%', 'nome': 'Minorias étnico-raciais'},
          {'termo': 'minorias etnico-raciais', 'percentual': '10%', 'nome': 'Minorias étnico-raciais'},
          {'termo': 'quilombola', 'percentual': '5%', 'nome': 'Quilombolas'}
        ];

        // Verificar se o texto contém termos relacionados a cotas
        if (texto.contains('cota') ||
            texto.contains('reserva de vaga') ||
            texto.contains('vagas reservadas')) {

          List<String> cotasEncontradas = [];

          // Buscar padrões de cotas no texto
          for (var padrao in padroes) {
            final termo = padrao['termo']!;
            final percentualPadrao = padrao['percentual']!;
            final nome = padrao['nome']!;

            if (texto.contains(termo)) {
              // Tentar encontrar o percentual específico no texto próximo ao termo
              String percentual = '';

              // Buscar percentuais comuns (5%, 10%, 20%, 30%)
              for (var pct in ['5%', '10%', '15%', '20%', '25%', '30%']) {
                // Verificar se o percentual está próximo ao termo (dentro de 100 caracteres)
                final termoIndex = texto.indexOf(termo);
                if (termoIndex >= 0) {
                  final inicio = (termoIndex - 50).clamp(0, texto.length);
                  final fim = (termoIndex + 50).clamp(0, texto.length);
                  final trecho = texto.substring(inicio, fim);

                  if (trecho.contains(pct)) {
                    percentual = pct;
                    break;
                  }
                }
              }

              // Se não encontrou percentual específico, usar o padrão
              if (percentual.isEmpty) {
                percentual = percentualPadrao;
              }

              cotasEncontradas.add('$nome ($percentual)');
            }
          }

          // Se encontrou cotas no texto, montar a string
          if (cotasEncontradas.isNotEmpty) {
            cotasText = cotasEncontradas.join(' / ');
          }
        }
      }
    }

    // Se encontrou informações sobre cotas, exibir
    if (cotasInfo != null || cotasText != null) {
      String displayText = 'Cotas: ';

      // Usar informações estruturadas se disponíveis
      if (cotasInfo != null && cotasInfo.isNotEmpty) {
        List<String> cotasList = [];

        cotasInfo.forEach((key, value) {
          String cotaName = key.toString().toLowerCase();
          dynamic percentual = value;

          // Mapeamento de termos comuns para nomes padronizados
          final Map<String, String> mapeamentoCotas = {
            'negro': 'Negros',
            'afrodescendente': 'Afrodescendentes',
            'pcd': 'PCD',
            'deficiente': 'PCD',
            'deficiência': 'PCD',
            'indígena': 'Indígenas',
            'indigena': 'Indígenas',
            'minoria': 'Minorias étnico-raciais',
            'étnico': 'Minorias étnico-raciais',
            'etnico': 'Minorias étnico-raciais',
            'quilombola': 'Quilombolas'
          };

          // Encontrar o tipo de cota com base no nome
          String? tipoEncontrado;
          for (var tipo in mapeamentoCotas.keys) {
            if (cotaName.contains(tipo)) {
              tipoEncontrado = mapeamentoCotas[tipo];
              break;
            }
          }

          // Se não encontrou um tipo conhecido, usar o nome original formatado
          final nomeCota = tipoEncontrado ?? _formatarNivel(cotaName);

          // Extrair o percentual
          String percentualStr = '';
          if (percentual is num) {
            percentualStr = '(${percentual.toInt()}%)';
          } else if (percentual is String) {
            // Tentar extrair número da string
            final match = RegExp(r'(\d+)').firstMatch(percentual.toString());
            if (match != null) {
              percentualStr = '(${match.group(1)}%)';
            }
          } else if (percentual is Map && percentual.containsKey('valor')) {
            // Alguns editais têm o percentual como um objeto com campo 'valor'
            var valorObj = percentual['valor'];
            if (valorObj is num) {
              percentualStr = '(${valorObj.toInt()}%)';
            } else if (valorObj is String) {
              final match = RegExp(r'(\d+)').firstMatch(valorObj.toString());
              if (match != null) {
                percentualStr = '(${match.group(1)}%)';
              }
            }
          }

          // Adicionar à lista de cotas
          cotasList.add(percentualStr.isNotEmpty ? '$nomeCota $percentualStr' : nomeCota);
        });

        if (cotasList.isNotEmpty) {
          displayText += cotasList.join(' / ');
        } else {
          // Se não conseguiu extrair informações estruturadas, usar o texto
          displayText += cotasText ?? 'Informações disponíveis no edital';
        }
      } else if (cotasText != null) {
        displayText += cotasText;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.diversity_3,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark ?
                     Colors.grey.shade300 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ?
                         Colors.grey.shade300 : Colors.grey.shade700
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Se não encontrou informações sobre cotas, não exibir nada
    return SizedBox.shrink();
  }

  String _formatarNivel(String nivel) {
    // Formatar o nome do nível para exibição
    switch (nivel.toLowerCase()) {
      case 'nivel_superior':
        return 'Nível Superior';
      case 'nivel_medio':
        return 'Nível Médio';
      case 'nivel_fundamental':
        return 'Nível Fundamental';
      case 'analista':
        return 'Analista';
      case 'tecnico':
        return 'Técnico';
      default:
        // Capitalizar a primeira letra de cada palavra
        return nivel.split('_').map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
        ).join(' ');
    }
  }
}
