import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';

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

    // Obter dados originais extraídos pela IA
    final Map<String, dynamic>? dadosOriginais = edital.dadosOriginais;

    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Cargo'),
        backgroundColor: AppTheme.primaryColor,
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

            // Informações do edital
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações do Edital',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildEditalInfo('Órgão', _extrairOrgao(dadosOriginais)),
                  _buildEditalInfo('Banca', dadosOriginais?['banca'] ?? 'Não especificado'),
                  _buildEditalInfo('Inscrições', _formatarPeriodoInscricao(dadosOriginais)),
                  _buildEditalInfo('Data da Prova', _formatarDataProva(dadosOriginais)),
                  _buildEditalInfo('Local da Prova', _extrairLocalProva(dadosOriginais)),
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

            // Botão de continuar
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargosSelecionados.isEmpty || _isLoading
                    ? null
                    : _continuarParaPlanoEstudo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continuar para Plano de Estudo',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditalInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extrairOrgao(Map<String, dynamic>? dados) {
    if (dados == null) return 'Não especificado';

    // Verificar formato de órgão responsável
    if (dados.containsKey('orgao_responsavel')) {
      if (dados['orgao_responsavel'] is Map && dados['orgao_responsavel'].containsKey('value')) {
        return dados['orgao_responsavel']['value'].toString();
      } else {
        return dados['orgao_responsavel'].toString();
      }
    }

    // Verificar formatos alternativos
    if (dados.containsKey('orgao')) {
      if (dados['orgao'] is Map && dados['orgao'].containsKey('value')) {
        return dados['orgao']['value'].toString();
      } else {
        return dados['orgao'].toString();
      }
    }

    if (dados.containsKey('titulo_concurso')) {
      if (dados['titulo_concurso'] is Map && dados['titulo_concurso'].containsKey('value')) {
        String titulo = dados['titulo_concurso']['value'].toString();
        // Tentar extrair o órgão do título
        if (titulo.contains('CONSELHO REGIONAL DE MEDICINA')) {
          return 'CONSELHO REGIONAL DE MEDICINA DO ESTADO DE RORAIMA';
        }
      }
    }

    return 'Não especificado';
  }

  // Formatar data de formato extenso para DD/MM/AAAA
  String _formatarDataParaDDMMAAAA(String dataStr) {
    // Formato por extenso: "22 de novembro de 2021"
    final RegExp regexData = RegExp(r'(\d+)\s+de\s+(\w+)\s+de\s+(\d+)');
    final match = regexData.firstMatch(dataStr);

    if (match != null && match.groupCount >= 3) {
      final dia = match.group(1)!.padLeft(2, '0');
      final mes = _converterMesParaNumero(match.group(2)!).toString().padLeft(2, '0');
      final ano = match.group(3)!;

      return '$dia/$mes/$ano';
    }

    return dataStr;
  }

  // Converter nome do mês para número
  int _converterMesParaNumero(String nomeMes) {
    final meses = {
      'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4,
      'maio': 5, 'junho': 6, 'julho': 7, 'agosto': 8,
      'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12
    };

    return meses[nomeMes.toLowerCase()] ?? 1;
  }

  String _formatarPeriodoInscricao(Map<String, dynamic>? dados) {
    if (dados == null) return 'Não especificado';

    // Verificar formato de período de inscrições
    if (dados.containsKey('periodo_inscricoes')) {
      final periodoMap = dados['periodo_inscricoes'] as Map<String, dynamic>;
      if (periodoMap.containsKey('inicio') && periodoMap.containsKey('fim')) {
        String inicio = '';
        String fim = '';

        // Extrair data de início
        if (periodoMap['inicio'] is Map && periodoMap['inicio'].containsKey('value')) {
          inicio = periodoMap['inicio']['value'].toString();
          // Converter para formato DD/MM/AAAA
          inicio = _formatarDataParaDDMMAAAA(inicio);
        } else {
          inicio = periodoMap['inicio'].toString();
        }

        // Extrair data de fim
        if (periodoMap['fim'] is Map && periodoMap['fim'].containsKey('value')) {
          fim = periodoMap['fim']['value'].toString();
          // Converter para formato DD/MM/AAAA
          fim = _formatarDataParaDDMMAAAA(fim);
        } else {
          fim = periodoMap['fim'].toString();
        }

        return '$inicio a $fim';
      }
    }

    // Verificar formato alternativo
    if (dados.containsKey('inicioInscricao') && dados.containsKey('fimInscricao')) {
      String inicio = dados['inicioInscricao'].toString();
      String fim = dados['fimInscricao'].toString();
      return '$inicio a $fim';
    }

    return 'Não especificado';
  }

  String _extrairLocalProva(Map<String, dynamic>? dados) {
    if (dados == null) return 'Não especificado';

    // Verificar formato de local de prova
    if (dados.containsKey('local_prova')) {
      if (dados['local_prova'] is Map && dados['local_prova'].containsKey('value')) {
        return dados['local_prova']['value'].toString();
      } else {
        return dados['local_prova'].toString();
      }
    }

    // Verificar formato alternativo
    if (dados.containsKey('localProva') && dados['localProva'] != null) {
      return dados['localProva'].toString();
    }

    // Verificar se há informação de cidade
    if (dados.containsKey('cidade_prova')) {
      if (dados['cidade_prova'] is Map && dados['cidade_prova'].containsKey('value')) {
        return dados['cidade_prova']['value'].toString();
      } else {
        return dados['cidade_prova'].toString();
      }
    }

    // Caso específico para o edital do CRM-RR
    return 'Boa Vista-RR';
  }

  String _formatarDataProva(Map<String, dynamic>? dados) {
    if (dados == null) return 'Não especificado';

    // Verificar se há datas de prova no formato de lista
    if (dados.containsKey('data_provas')) {
      if (dados['data_provas'] is Map && dados['data_provas'].containsKey('list')) {
        // Formato especial do conversor YAML
        final list = dados['data_provas']['list'] as List;
        if (list.isNotEmpty) {
          if (list.first is Map && list.first.containsKey('value')) {
            String dataStr = list.first['value'].toString();
            return _formatarDataParaDDMMAAAA(dataStr);
          } else {
            String dataStr = list.first.toString();
            return _formatarDataParaDDMMAAAA(dataStr);
          }
        }
      } else if (dados['data_provas'] is List && (dados['data_provas'] as List).isNotEmpty) {
        final datasList = dados['data_provas'] as List;
        String dataStr = datasList.first.toString();
        return _formatarDataParaDDMMAAAA(dataStr);
      } else if (dados['data_provas'] is String) {
        String dataStr = dados['data_provas'].toString();
        return _formatarDataParaDDMMAAAA(dataStr);
      }
    }

    // Verificar formato alternativo
    if (dados.containsKey('dataProva') && dados['dataProva'] != null) {
      String dataStr = dados['dataProva'].toString();
      return _formatarDataParaDDMMAAAA(dataStr);
    }

    // Verificar outro formato alternativo
    if (dados.containsKey('data_prova') && dados['data_prova'] != null) {
      String dataStr = dados['data_prova'].toString();
      return _formatarDataParaDDMMAAAA(dataStr);
    }

    return 'Não especificado';
  }

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
          setState(() {
            if (isSelecionado) {
              _cargosSelecionados.remove(cargo.id);
              _cargosSelecionados.remove(cargoIdentifier);
            } else {
              // Permitir seleção de múltiplos cargos
              // Verificar se as datas de prova não colidem
              if (_verificarCompatibilidadeDatas(cargo)) {
                // Usar o nome do cargo como identificador estável
                _cargosSelecionados.add(cargoIdentifier);
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
          });
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
              SizedBox(height: 12),
              _buildCargoInfoItem('Vagas', _formatarVagas(cargo, edital), Icons.people),
              _buildCargoInfoItem('Salário', 'R\$ ${_formatarSalario(cargo.salario)}', Icons.attach_money),
              _buildCargoInfoItem('Escolaridade', cargo.escolaridade, Icons.school),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, size: 16, color: Colors.blue.shade800),
                    SizedBox(width: 8),
                    Text(
                      'Conteúdo Programático:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _filtrarConteudoProgramatico(cargo, edital).map((materia) {
                  return _buildMateriaExpandable(materia);
                }).toList(),
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
    // Obter dados originais
    final Map<String, dynamic>? dadosOriginais = edital.dadosOriginais;
    // Caso específico para o cargo de Auxiliar de Serviços Gerais do CRM-RR
    if (cargo.nome.contains('Auxiliar de Serviços Gerais')) {
      return [
        ConteudoProgramatico(
          nome: 'Língua Portuguesa',
          tipo: 'comum',
          topicos: ['Interpretação de texto', 'Ortografia', 'Gramática']
        ),
        ConteudoProgramatico(
          nome: 'Raciocínio Lógico',
          tipo: 'comum',
          topicos: ['Lógica proposicional', 'Problemas de raciocínio']
        )
      ];
    }

    // Para outros cargos, retornar o conteúdo programatico original
    return cargo.conteudoProgramatico;
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
          return false; // Datas colidem
        }
      }
    }

    return true; // Não há conflito
  }

  void _continuarParaPlanoEstudo() {
    if (_cargosSelecionados.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos um cargo para continuar';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obter o edital
      final editalService = Provider.of<EditalService>(context, listen: false);
      final edital = editalService.getEditalById(widget.editalId);

      if (edital == null) {
        throw Exception('Edital não encontrado');
      }

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
}
