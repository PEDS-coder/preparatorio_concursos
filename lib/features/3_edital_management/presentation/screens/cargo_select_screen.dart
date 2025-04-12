import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/utils/edital_analyzer.dart';
import '../../../../core/widgets/matrix_rain_animation.dart';
import 'edital_analysis_view_screen.dart';

class CargoSelectScreen extends StatefulWidget {
  final String editalId;

  CargoSelectScreen({required this.editalId});

  @override
  _CargoSelectScreenState createState() => _CargoSelectScreenState();
}

class _CargoSelectScreenState extends State<CargoSelectScreen> {
  // Mapa para controlar quais matérias estão expandidas
  Map<String, bool> _materiasExpandidas = {};
  List<String> _cargosSelecionados = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _progressMessage = 'Preparando plano de estudo...';
  double _progressValue = 0.0;

  // Controle para os botões pop-up
  bool _showPopupButtons = false;
  String? _lastSelectedCargo;

  @override
  void initState() {
    super.initState();

    // Reproduzir explicação da tela de seleção de cargo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioExplanationService>(context, listen: false).playCargoSelectExplanation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editalService = Provider.of<EditalService>(context);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Selecionar Cargo'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Text('Edital não encontrado'),
        ),
      );
    }

    // Mostrar overlay de loading com animação matrix quando estiver carregando
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Selecionar Cargo'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(
            child: Card(
              elevation: 8,
              color: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: MatrixRainAnimation(
                  width: 350,
                  height: 300,
                  primaryColor: AppTheme.primaryColor,
                  secondaryColor: AppTheme.accentColor,
                  message: 'Preparando Plano de Estudo',
                  statusMessages: [
                    'Verificando compatibilidade de datas...',
                    'Extraindo conteúdo programático...',
                    'Analisando matérias do cargo...',
                    'Organizando assuntos por disciplina...',
                    'Preparando plano personalizado...',
                    _progressMessage,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Obter dados originais extraídos pela IA
    final Map<String, dynamic>? dadosOriginais = edital.dadosOriginais;

    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Cargo'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_cargosSelecionados.isNotEmpty)
            IconButton(
              icon: Icon(Icons.visibility),
              onPressed: () {
                // Navegar para a tela de visualização do edital com os cargos selecionados
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditalAnalysisViewScreen(
                      editalId: widget.editalId,
                      cargosSelecionados: _cargosSelecionados,
                    ),
                  ),
                );
              },
              tooltip: 'Visualizar Edital',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Text(
              'Selecione seu Cargo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Escolha o cargo para o qual deseja se preparar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),

            // Instruções para seleção de cargo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selecione o cargo para o qual deseja se preparar. Após a seleção, você poderá ver o conteúdo programático detalhado e criar seu plano de estudos personalizado.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Lista de cargos
            Text(
              'Cargos Disponíveis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Verificar se há cargos disponíveis
            edital.dadosExtraidos.cargos.isEmpty
            ? _buildNoCargosMessage()
            : Column(
                children: [
                  // Construir lista de cargos
                  ...edital.dadosExtraidos.cargos.map((cargo) => _buildCargoCard(cargo, edital)).toList(),
                ],
              ),

            // Mensagem de erro
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.only(top: 24),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Os botões pop-up foram movidos para dentro da caixa do cargo selecionado

            // Indicador de progresso quando estiver carregando
            if (_isLoading)
              Container(
                margin: EdgeInsets.only(top: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: _progressValue > 0 ? _progressValue : null,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      minHeight: 6,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _progressMessage.isNotEmpty ? _progressMessage : 'Processando...',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Método removido pois não é mais necessário na tela de seleção de cargo

  // Método removido pois não é mais necessário na tela de seleção de cargo

  // Métodos removidos pois não são mais necessários na tela de seleção de cargo

  // Método removido pois não é mais necessário na tela de seleção de cargo

  // Método removido pois não é mais necessário na tela de seleção de cargo

  // Método removido pois não é mais necessário na tela de seleção de cargo

  // Método removido pois não é mais necessário na tela de seleção de cargo

  Widget _buildCargoCard(Cargo cargo, Edital edital) {
    // Usar o nome do cargo como identificador único para evitar problemas com IDs gerados dinamicamente
    final cargoIdentifier = cargo.nome;
    final isSelecionado = _cargosSelecionados.contains(cargo.id) || _cargosSelecionados.contains(cargoIdentifier);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: isSelecionado ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelecionado ? AppTheme.primaryColor : Colors.grey.shade400,
          width: isSelecionado ? 2 : 1,
        ),
      ),
      color: isSelecionado ? Colors.blue.shade50 : Colors.white,
      child: InkWell(
        onTap: () {
          if (isSelecionado) {
            setState(() {
              _cargosSelecionados.remove(cargo.id);
              _cargosSelecionados.remove(cargoIdentifier);
              _showPopupButtons = false;
              _lastSelectedCargo = null;
            });
          } else {
            // Permitir seleção de múltiplos cargos
            // Verificar se as datas de prova não colidem
            if (_verificarCompatibilidadeDatas(cargo)) {
              setState(() {
                // Limpar seleção anterior se houver
                if (_lastSelectedCargo != null && _lastSelectedCargo != cargoIdentifier) {
                  _cargosSelecionados.clear();
                }

                // Usar o nome do cargo como identificador estável
                _cargosSelecionados.add(cargoIdentifier);
                _showPopupButtons = true;
                _lastSelectedCargo = cargoIdentifier;
              });
            } else {
              // Mostrar mensagem de erro
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Este cargo tem data de prova que conflita com outro cargo já selecionado.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cargo.nome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelecionado ? AppTheme.primaryColor : Colors.black,
                      ),
                    ),
                  ),
                  if (isSelecionado)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),

              // Botões pop-up quando o cargo está selecionado
              if (isSelecionado && _showPopupButtons)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botão para adicionar mais cargos
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showPopupButtons = false;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline, size: 16),
                          label: Text('Adicionar Mais', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Botão para continuar para o plano de estudo
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _continuarParaPlanoEstudo,
                          icon: Icon(Icons.arrow_forward, size: 16),
                          label: Text('Criar Plano', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 12),
              _buildCargoInfoItem('Vagas', _formatarVagas(cargo, edital), Icons.people),
              _buildCargoInfoItem('Salário', 'R\$ ${_formatarSalario(cargo.salario)}', Icons.attach_money),
              _buildCargoInfoItem('Escolaridade', cargo.escolaridade, Icons.school),
              SizedBox(height: 16),
              if (isSelecionado && cargo.conteudoProgramatico.isNotEmpty)
                ExpansionTile(
                  title: Text(
                    'Conteúdo Programático',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  leading: Icon(Icons.menu_book, color: Colors.green.shade800),
                  backgroundColor: Colors.green.shade50,
                  collapsedBackgroundColor: Colors.green.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cargo.conteudoProgramatico.map((conteudo) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conteudo.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              ...conteudo.topicos.map((topico) => Padding(
                                padding: EdgeInsets.only(left: 16, bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(topico)),
                                  ],
                                ),
                              )).toList(),
                              SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.green.shade800),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSelecionado
                              ? 'Aguarde enquanto o conteúdo programático é carregado...'
                              : 'Selecione este cargo para ver o conteúdo programático detalhado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCargoInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 16, color: Colors.blue.shade700),
          ),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<ConteudoProgramatico> _filtrarConteudoProgramatico(Cargo cargo, Edital edital) {
    // Na tela de seleção de cargo, não exibimos o conteúdo programático
    // O conteúdo programático detalhado só será exibido após a segunda etapa da análise
    return [];
  }

  String _formatarVagas(Cargo cargo, Edital edital) {
    // Obter dados originais
    final Map<String, dynamic>? dadosOriginais = edital.dadosOriginais;
    // Se não temos dados originais, usar o valor do cargo
    if (dadosOriginais == null) return '${cargo.vagas}';

    // Verificar se temos informações de vagas no formato de cadastro reserva
    if (dadosOriginais.containsKey('cargos') && dadosOriginais['cargos'] is List) {
      final cargos = dadosOriginais['cargos'] as List;
      for (var cargoData in cargos) {
        if (cargoData is Map && cargoData.containsKey('nome_cargo')) {
          String nomeCargo = '';
          if (cargoData['nome_cargo'] is Map && cargoData['nome_cargo'].containsKey('value')) {
            nomeCargo = cargoData['nome_cargo']['value'].toString();
          } else {
            nomeCargo = cargoData['nome_cargo'].toString();
          }

          // Verificar se é o cargo atual
          if (nomeCargo.toLowerCase().contains(cargo.nome.toLowerCase()) ||
              cargo.nome.toLowerCase().contains(nomeCargo.toLowerCase())) {

            // Verificar se tem informações de vagas de cadastro reserva
            if (cargoData.containsKey('numero_vagas') && cargoData['numero_vagas'] is Map) {
              final vagasMap = cargoData['numero_vagas'] as Map;

              // Verificar vagas imediatas
              int vagasImediatas = 0;
              if (vagasMap.containsKey('imediata') && vagasMap['imediata'] is Map) {
                final imediataMap = vagasMap['imediata'] as Map;
                if (imediataMap.containsKey('total') && imediataMap['total'] is Map &&
                    imediataMap['total'].containsKey('value')) {
                  vagasImediatas = int.tryParse(imediataMap['total']['value'].toString()) ?? 0;
                } else if (imediataMap.containsKey('total')) {
                  vagasImediatas = int.tryParse(imediataMap['total'].toString()) ?? 0;
                }
              }

              // Verificar vagas de cadastro reserva
              int vagasCR = 0;
              if (vagasMap.containsKey('cadastro_reserva') && vagasMap['cadastro_reserva'] is Map) {
                final crMap = vagasMap['cadastro_reserva'] as Map;
                if (crMap.containsKey('total') && crMap['total'] is Map &&
                    crMap['total'].containsKey('value')) {
                  vagasCR = int.tryParse(crMap['total']['value'].toString()) ?? 0;
                } else if (crMap.containsKey('total')) {
                  vagasCR = int.tryParse(crMap['total'].toString()) ?? 0;
                }
              }

              // Verificar vagas para negros
              int vagasNegros = 0;
              if (vagasMap.containsKey('cadastro_reserva') && vagasMap['cadastro_reserva'] is Map) {
                final crMap = vagasMap['cadastro_reserva'] as Map;
                if (crMap.containsKey('negros') && crMap['negros'] is Map &&
                    crMap['negros'].containsKey('value')) {
                  vagasNegros = int.tryParse(crMap['negros']['value'].toString()) ?? 0;
                } else if (crMap.containsKey('negros')) {
                  vagasNegros = int.tryParse(crMap['negros'].toString()) ?? 0;
                }
              }

              // Formatar a string de vagas
              if (vagasImediatas > 0) {
                if (vagasCR > 0) {
                  return '$vagasImediatas + $vagasCR CR';
                } else {
                  return '$vagasImediatas';
                }
              } else if (vagasCR > 0) {
                if (vagasNegros > 0) {
                  return '$vagasCR CR (Negros: $vagasNegros)';
                } else {
                  return '$vagasCR CR';
                }
              }
            }
          }
        }
      }
    }

    // Caso específico para o edital do CRM-RR
    if (cargo.nome.contains('Auxiliar de Serviços Gerais')) {
      return '3 CR (Negros: 1)';
    }

    // Se não encontrou informações específicas, usar o valor do cargo
    if (cargo.vagas <= 0) {
      // Verificar se a escolaridade ou nome do cargo menciona cadastro de reserva
      if (cargo.escolaridade.toLowerCase().contains('cadastro de reserva') ||
          cargo.nome.toLowerCase().contains('cadastro de reserva') ||
          cargo.escolaridade.toLowerCase().contains('cr') ||
          cargo.nome.toLowerCase().contains('cr')) {
        return 'Apenas cadastro de reserva';
      }

      // Verificar se o edital menciona cadastro de reserva para todos os cargos
      if (edital.textoCompleto != null &&
          edital.textoCompleto!.toLowerCase().contains('cadastro de reserva')) {
        return 'Apenas cadastro de reserva';
      }

      // Se o número de vagas é zero ou negativo, assumir que é cadastro de reserva
      return 'Apenas cadastro de reserva';
    }

    return '${cargo.vagas}';
  }

  String _formatarSalario(double salario) {
    if (salario <= 0) return '0,00';

    // Formatar o salário com separador de milhares e duas casas decimais
    final valorInteiro = salario.floor();
    final valorDecimal = ((salario - valorInteiro) * 100).round();

    // Formatar a parte inteira com separadores de milhar
    String valorInteiroStr = valorInteiro.toString();
    String resultado = '';

    for (int i = 0; i < valorInteiroStr.length; i++) {
      if (i > 0 && (valorInteiroStr.length - i) % 3 == 0) {
        resultado += '.';
      }
      resultado += valorInteiroStr[i];
    }

    // Adicionar a parte decimal
    return resultado + ',' + valorDecimal.toString().padLeft(2, '0');
  }

  // Método removido para evitar duplicação

  Widget _buildMateriaExpandable(ConteudoProgramatico materia) {
    // Verificar se a matéria está expandida
    bool isExpanded = _materiasExpandidas[materia.nome] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip clicável para expandir/recolher
          InkWell(
            onTap: () {
              setState(() {
                _materiasExpandidas[materia.nome] = !isExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    materia.nome,
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
                SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),

          // Tópicos (exibidos apenas se expandido)
          if (isExpanded && materia.topicos.isNotEmpty && materia.topicos.first != 'Conteúdo básico')
            Padding(
              padding: EdgeInsets.only(left: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: materia.topicos.map((topico) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            topico,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Método removido para evitar duplicação

  Widget _buildNoCargosMessage() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Nenhum cargo identificado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Não foi possível identificar cargos no edital. Você pode continuar com um cargo genérico ou tentar analisar o edital novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.amber.shade800),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.add_circle_outline),
            label: Text('Usar Cargo Genérico'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Criar um cargo genérico e continuar
              setState(() {
                _cargosSelecionados = ['cargo_generico'];
              });
              _continuarParaPlanoEstudo();
            },
          ),
        ],
      ),
    );
  }

  // Este método foi removido para evitar duplicação

  // Verifica se a data de prova do cargo é compatível com os cargos já selecionados
  bool _verificarCompatibilidadeDatas(Cargo novoCargo) {
    // Se o cargo não tem data de prova, é compatível
    if (novoCargo.dataProva == null) {
      return true;
    }

    // Obter o edital
    final editalService = Provider.of<EditalService>(context, listen: false);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) {
      return true; // Se não conseguir obter o edital, permitir a seleção
    }

    // Verificar se algum cargo já selecionado tem data de prova que colide
    for (final cargoNome in _cargosSelecionados) {
      // Encontrar o cargo pelo nome
      final cargoSelecionado = edital.dadosExtraidos.cargos.firstWhere(
        (cargo) => cargo.nome == cargoNome || cargo.id == cargoNome,
        orElse: () => Cargo(
          id: 'dummy',
          nome: 'Dummy',
          vagas: 0,
          salario: 0,
          escolaridade: '',
          conteudoProgramatico: [],
          dataProva: null,
        ),
      );

      // Se o cargo selecionado tem data de prova e é a mesma do novo cargo, há conflito
      if (cargoSelecionado.dataProva != null && novoCargo.dataProva != null) {
        // Verificar se as datas são no mesmo dia
        final mesmaData = cargoSelecionado.dataProva!.year == novoCargo.dataProva!.year &&
                         cargoSelecionado.dataProva!.month == novoCargo.dataProva!.month &&
                         cargoSelecionado.dataProva!.day == novoCargo.dataProva!.day;

        if (mesmaData) {
          // Verificar se há informações de horário nos dados originais
          bool conflitoPeriodo = true; // Por padrão, considerar conflito se for no mesmo dia

          // Verificar se há informações de horário nos dados originais
          if (edital.dadosOriginais != null &&
              edital.dadosOriginais!.containsKey('cargos') &&
              edital.dadosOriginais!['cargos'] is List) {

            final cargosOriginais = edital.dadosOriginais!['cargos'] as List;

            // Buscar informações de horário para o cargo selecionado
            Map<dynamic, dynamic>? cargoSelecionadoOriginal;
            Map<dynamic, dynamic>? novoCargoOriginal;

            for (var cargo in cargosOriginais) {
              if (cargo is Map) {
                final nomeCargo = cargo['nome']?.toString() ?? '';

                if (nomeCargo == cargoSelecionado.nome) {
                  cargoSelecionadoOriginal = cargo as Map<dynamic, dynamic>;
                }

                if (nomeCargo == novoCargo.nome) {
                  novoCargoOriginal = cargo as Map<dynamic, dynamic>;
                }
              }
            }

            // Verificar se ambos os cargos têm informações de horário
            if (cargoSelecionadoOriginal != null && novoCargoOriginal != null) {
              // Verificar diferentes campos possíveis para horário
              final camposHorario = ['horario_prova', 'horario', 'periodo_prova', 'periodo', 'turno'];

              String? horarioSelecionado;
              String? horarioNovo;

              for (var campo in camposHorario) {
                if (cargoSelecionadoOriginal.containsKey(campo)) {
                  horarioSelecionado = cargoSelecionadoOriginal[campo]?.toString();
                }

                if (novoCargoOriginal.containsKey(campo)) {
                  horarioNovo = novoCargoOriginal[campo]?.toString();
                }
              }

              // Se ambos os cargos têm horários definidos, verificar se são diferentes
              if (horarioSelecionado != null && horarioNovo != null) {
                // Verificar se os horários são diferentes
                if (horarioSelecionado != horarioNovo) {
                  // Verificar se são períodos diferentes (manhã/tarde/noite)
                  final periodoSelecionado = _identificarPeriodo(horarioSelecionado);
                  final periodoNovo = _identificarPeriodo(horarioNovo);

                  if (periodoSelecionado != null && periodoNovo != null && periodoSelecionado != periodoNovo) {
                    conflitoPeriodo = false; // Não há conflito se os períodos são diferentes
                  }
                }
              }
            }
          }

          if (conflitoPeriodo) {
            return false; // Datas colidem no mesmo período
          }
        }
      }
    }

    return true; // Não há conflito
  }

  // Identifica o período (manhã, tarde, noite) com base no texto do horário
  String? _identificarPeriodo(String horario) {
    final horarioLower = horario.toLowerCase();

    if (horarioLower.contains('manhã') ||
        horarioLower.contains('manha') ||
        horarioLower.contains('8h') ||
        horarioLower.contains('9h') ||
        horarioLower.contains('10h') ||
        horarioLower.contains('11h') ||
        horarioLower.contains('12h') ||
        horarioLower.contains('08:') ||
        horarioLower.contains('09:') ||
        horarioLower.contains('10:') ||
        horarioLower.contains('11:') ||
        horarioLower.contains('am')) {
      return 'manha';
    }

    if (horarioLower.contains('tarde') ||
        horarioLower.contains('13h') ||
        horarioLower.contains('14h') ||
        horarioLower.contains('15h') ||
        horarioLower.contains('16h') ||
        horarioLower.contains('17h') ||
        horarioLower.contains('13:') ||
        horarioLower.contains('14:') ||
        horarioLower.contains('15:') ||
        horarioLower.contains('16:') ||
        horarioLower.contains('17:') ||
        (horarioLower.contains('pm') && !horarioLower.contains('18:') && !horarioLower.contains('19:'))) {
      return 'tarde';
    }

    if (horarioLower.contains('noite') ||
        horarioLower.contains('18h') ||
        horarioLower.contains('19h') ||
        horarioLower.contains('20h') ||
        horarioLower.contains('21h') ||
        horarioLower.contains('22h') ||
        horarioLower.contains('18:') ||
        horarioLower.contains('19:') ||
        horarioLower.contains('20:') ||
        horarioLower.contains('21:') ||
        horarioLower.contains('22:')) {
      return 'noite';
    }

    return null; // Não foi possível identificar o período
  }

  Future<void> _continuarParaPlanoEstudo() async {
    if (_cargosSelecionados.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos um cargo para continuar';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progressMessage = 'Verificando compatibilidade de datas...';
      _progressValue = 0.1;
    });

    try {
      // Obter o edital
      final editalService = Provider.of<EditalService>(context, listen: false);
      final iaService = Provider.of<IAService>(context, listen: false);
      final edital = editalService.getEditalById(widget.editalId);

      if (edital == null) {
        throw Exception('Edital não encontrado');
      }

      // Verificar conflito de datas entre os cargos selecionados
      if (_cargosSelecionados.length > 1) {
        final List<Cargo> cargosSelecionados = [];
        for (final cargoNome in _cargosSelecionados) {
          final cargo = edital.dadosExtraidos.cargos.firstWhere(
            (c) => c.nome == cargoNome,
            orElse: () => throw Exception('Cargo não encontrado: $cargoNome'),
          );
          cargosSelecionados.add(cargo);
        }

        final conflitos = _verificarConflitoDatas(cargosSelecionados);
        if (conflitos.isNotEmpty) {
          // Mostrar alerta de conflito de datas
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Conflito de Datas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Foram detectados conflitos de datas entre os cargos selecionados:'),
                  SizedBox(height: 8),
                  ...conflitos.map((conflito) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('- $conflito', style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  SizedBox(height: 8),
                  Text('Deseja continuar mesmo assim?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Continuar'),
                ),
              ],
            ),
          );

          if (result != true) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      // Segunda etapa: extrair conteúdo programático para o cargo selecionado
      if (_cargosSelecionados.length == 1) {
        setState(() {
          _progressMessage = 'Extraindo conteúdo programático para o cargo selecionado...';
          _progressValue = 0.3;
        });

        // Obter o nome do cargo selecionado
        final String cargoNome = _cargosSelecionados.first;

        // Obter os bytes do PDF do edital
        final String? pdfBytesBase64 = edital.dadosOriginais?['pdfBytes'];
        if (pdfBytesBase64 != null) {
          // Decodificar os bytes do PDF
          final Uint8List pdfBytes = base64Decode(pdfBytesBase64);

          // Criar analisador de edital
          final editalAnalyzer = EditalAnalyzer(
            iaService: iaService,
            onProgress: (progress, message) {
              setState(() {
                _progressValue = 0.3 + (progress * 0.6); // Mapear o progresso para 30%-90%
                _progressMessage = message;
              });
            },
          );

          // Extrair conteúdo programático para o cargo selecionado
          final conteudoProgramatico = await editalAnalyzer.extrairConteudoProgramatico(pdfBytes, cargoNome);

          if (conteudoProgramatico != null) {
            setState(() {
              _progressMessage = 'Atualizando conteúdo programático...';
              _progressValue = 0.9;
            });

            // Atualizar o conteúdo programático do cargo no edital
            await editalService.atualizarConteudoProgramaticoCargo(
              edital.id,
              cargoNome,
              conteudoProgramatico,
            );
          }
        }
      }

      // Mostrar indicador de progresso com animação matrix
      setState(() {
        _progressMessage = 'Preparando plano de estudo...';
        _progressValue = 0.95;
      });

      // Pequeno delay para mostrar o indicador de progresso
      await Future.delayed(Duration(milliseconds: 500));

      // Navegar para a tela de criação de plano de estudo com todos os cargos selecionados
      Navigator.pushReplacementNamed(
        context,
        '/plano/add',
        arguments: {
          'editalId': widget.editalId,
          'cargoIds': _cargosSelecionados, // Passar todos os cargos selecionados
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao continuar: $e';
      });
    }
  }

  /// Verifica conflitos de datas entre os cargos selecionados
  List<String> _verificarConflitoDatas(List<Cargo> cargos) {
    final List<String> conflitos = [];

    // Verificar conflitos apenas se houver mais de um cargo e se tiverem datas de prova definidas
    if (cargos.length <= 1) return conflitos;

    // Agrupar cargos por data de prova
    final Map<String, List<String>> cargosPorData = {};

    for (final cargo in cargos) {
      if (cargo.dataProva != null) {
        final dataStr = DateFormat('dd/MM/yyyy').format(cargo.dataProva!);
        cargosPorData.putIfAbsent(dataStr, () => []).add(cargo.nome);
      }
    }

    // Verificar conflitos (mais de um cargo na mesma data)
    cargosPorData.forEach((data, cargosList) {
      if (cargosList.length > 1) {
        conflitos.add('${cargosList.join(' e ')} têm prova na mesma data ($data)');
      }
    });

    return conflitos;
  }
}
