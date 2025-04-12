import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/utils/edital_analyzer.dart';
import '../../../../core/utils/pdf_processor.dart';
import '../../../../core/utils/cargo_converter.dart';
import '../../../../core/utils/cache_manager.dart';
import '../../../../core/widgets/matrix_rain_animation.dart';
import 'cargo_select_screen.dart';
import 'edital_analysis_view_screen.dart';

class EditalAnalyzeScreen extends StatefulWidget {
  @override
  _EditalAnalyzeScreenState createState() => _EditalAnalyzeScreenState();
}

class _EditalAnalyzeScreenState extends State<EditalAnalyzeScreen> {
  bool _isProcessingPdf = false;
  bool _isAnalyzingEdital = false;
  String? _pdfFileName;
  String? _pdfFilePath;
  Uint8List? _pdfBytes;
  double _pdfProcessingProgress = 0.0;
  String _progressMessage = '';
  String? _errorMessage;

  // Dados extraídos do edital
  Map<String, dynamic>? _dadosExtraidos;

  @override
  void initState() {
    super.initState();

    // Reproduzir explicação da tela de análise de edital
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioExplanationService>(context, listen: false).playEditalAnalyzeExplanation();
    });
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _pdfFileName = result.files.single.name;
          _isProcessingPdf = true;
          _pdfProcessingProgress = 0.1;
          _progressMessage = 'Carregando PDF...';
          _errorMessage = null;
          _dadosExtraidos = null;
        });

        // Obter os bytes do arquivo
        if (kIsWeb) {
          // Web
          _pdfBytes = result.files.single.bytes;
        } else {
          // Desktop/Mobile
          if (result.files.single.path != null) {
            final file = File(result.files.single.path!);
            _pdfBytes = await file.readAsBytes();
            _pdfFilePath = result.files.single.path;
          }
        }

        if (_pdfBytes == null) {
          throw Exception('Não foi possível ler o arquivo PDF');
        }

        setState(() {
          _pdfProcessingProgress = 0.2;
          _progressMessage = 'PDF carregado com sucesso';
          _isProcessingPdf = false; // Arquivo carregado, aguardando análise
        });

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF carregado com sucesso. Clique em "Analisar com IA" para continuar.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // Usuário cancelou a seleção
        setState(() {
          _isProcessingPdf = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessingPdf = false;
        _errorMessage = 'Erro ao carregar o PDF: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar o PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Método removido: _usarExemploPdf

  // Iniciar análise com IA
  Future<void> _iniciarAnaliseComIA() async {
    if (_pdfFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione um arquivo PDF primeiro.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);
    final iaService = Provider.of<IAService>(context, listen: false);

    // Verificar se o IAService está configurado
    if (!iaService.isConfigured) {
      // Tentar verificar a configuração novamente
      final bool isConfigured = await apiConfigService.verificarConfiguracao();

      if (!isConfigured) {
        setState(() {
          _errorMessage = 'É necessário configurar a API LLM (Gemini, OpenRouter ou Requestry) para analisar editais.';
        });

        // Mostrar mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Configurar',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/api_config');
              },
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isAnalyzingEdital = true;
      _pdfProcessingProgress = 0.2;
      _progressMessage = 'Preparando texto para análise...';
    });

    try {
      // Se estiver usando o exemplo
      if (_pdfFileName == 'exemplo_edital.pdf') {
        final String exampleText = 'EDITAL DE CONCURSO PÚBLICO\n\nCargo: Analista Administrativo\nVagas: 10\nSalário: R\$ 5.000,00\nEscolaridade: Nível Superior\n\nConteúdo Programático:\n- Língua Portuguesa\n- Raciocínio Lógico\n- Direito Administrativo\n- Administração Pública';

        // Simular o processamento do texto com atualizações incrementais reais
        await Future.delayed(Duration(milliseconds: 800));

        setState(() {
          _pdfProcessingProgress = 0.3;
          _progressMessage = 'Extraindo informações básicas...';
        });

        await Future.delayed(Duration(milliseconds: 800));

        setState(() {
          _pdfProcessingProgress = 0.5;
          _progressMessage = 'Identificando cargos e requisitos...';
        });

        await Future.delayed(Duration(milliseconds: 800));

        setState(() {
          _pdfProcessingProgress = 0.7;
          _progressMessage = 'Analisando conteúdo programático...';
        });

        await Future.delayed(Duration(milliseconds: 800));

        setState(() {
          _pdfProcessingProgress = 0.9;
          _progressMessage = 'Finalizando análise...';
        });

        await Future.delayed(Duration(milliseconds: 800));

        // Criar dados de exemplo
        _processarDadosExemplo();
      } else {
        // Processar arquivo PDF real
        if (_pdfBytes != null) {
          await _analisarEdital(_pdfBytes!);
        } else {
          throw Exception('Arquivo PDF não carregado corretamente');
        }
      }
    } catch (e) {
      setState(() {
        _isAnalyzingEdital = false;
        _errorMessage = 'Erro ao analisar o edital: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao analisar o edital: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _processarDadosExemplo() {
    // Criar dados de exemplo com informações mais completas
    final Map<String, dynamic> dadosExemplo = {
      'titulo': 'Concurso Público para Analista do Tribunal Regional do Trabalho da 10ª Região',
      'banca': 'CESPE',
      'inicioInscricao': '2023-05-01',
      'fimInscricao': '2023-05-30',
      'valorTaxa': 120.0,
      'localProva': 'Brasília/DF',
      'dataProva': '2023-07-15',
      'cargos': [
        {
          'nome': 'Analista Judiciário - Área Administrativa',
          'vagas': 10,
          'salario': 13994.78,
          'escolaridade': 'Nível Superior em Contabilidade',
          'materias': ['Contabilidade Pública', 'Administração Financeira e Orçamentária', 'Legislação Tributária Aplicada às Contratações Públicas', 'Auditoria Governamental']
        },
        {
          'nome': 'Analista Judiciário - Área Arquitetura',
          'vagas': 5,
          'salario': 13994.78,
          'escolaridade': 'Nível Superior em Arquitetura',
          'materias': ['Conceitos fundamentais sobre arquitetura, urbanismo e paisagismo', 'Elaboração de projeto de arquitetura', 'Zoneamento das atividades', 'Materiais, técnicas, processos e sistemas inovadores de construção', 'Conforto ambiental', 'Noções básicas de acústica', 'Ergonomia nas edificações e mobiliários', 'Acessibilidade a edificações', 'Compatibilização de projeto arquitetônico e instalações prediais', 'Projeto de reforma', 'Manutenção predial', 'Projetos complementares', 'Projeto de áreas livres', 'Administração de projetos e obras', 'Informática aplicada a arquitetura', 'Gestão ambiental em edificações', 'Legislação urbanística aplicável a edificações', 'Legislação do exercício profissional do arquiteto', 'Legislação ambiental aplicada à construção civil', 'Normas de segurança do trabalho aplicadas à construção civil', 'Legislação aplicada a economia de recursos naturais e sustentabilidade nas edificações', 'Normas do Judiciário aplicadas a serviços de engenharia e arquitetura', 'Gestão de Contratos']
        },
        {
          'nome': 'Analista Judiciário - Área Arquivologia',
          'vagas': 3,
          'salario': 13994.78,
          'escolaridade': 'Nível Superior em Arquivologia',
          'materias': ['Arquivologia', 'Gestão de Contratos']
        }
      ]
    };

    // Finalizar o processamento
    setState(() {
      _pdfProcessingProgress = 1.0;
      _progressMessage = 'Análise concluída!';
      _dadosExtraidos = dadosExemplo;
      _isAnalyzingEdital = false;
    });

    // Mostrar diálogo de sucesso
    _mostrarDialogoSucesso();
  }

  Future<void> _analisarEdital(Uint8List pdfBytes) async {
    try {
      final iaService = Provider.of<IAService>(context, listen: false);
      final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);

      // Verificar se o IAService está configurado
      if (!iaService.isConfigured) {
        // Tentar verificar a configuração novamente
        final bool isConfigured = await apiConfigService.verificarConfiguracao();

        if (!isConfigured) {
          setState(() {
            _isProcessingPdf = false;
            _isAnalyzingEdital = false;
            _errorMessage = 'É necessário configurar a API LLM (Gemini, OpenRouter ou Requestry) para analisar editais.';
          });

          // Mostrar mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Erro ao analisar edital'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Configurar',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/api_config');
                },
              ),
            ),
          );

          return;
        }
      }

      setState(() {
        _isAnalyzingEdital = true;
        _progressMessage = 'Verificando cache...';
        _pdfProcessingProgress = 0.05;
      });

      // Verificar se há cache para este PDF
      final bool hasCache = await CacheManager.hasCache(_pdfBytes!);

      if (hasCache) {
        // Este bloco não será executado durante os testes
        setState(() {
          _progressMessage = 'Recuperando análise do cache...';
          _pdfProcessingProgress = 0.1;
        });

        // Recuperar dados do cache
        final Map<String, dynamic>? cachedData = await CacheManager.getFromCache(pdfBytes);

        if (cachedData != null) {
          setState(() {
            _progressMessage = 'Processando dados do cache...';
            _pdfProcessingProgress = 0.8;
          });

          // Remover o timestamp do resultado
          cachedData.remove('timestamp');

          setState(() {
            _dadosExtraidos = cachedData;
            _isProcessingPdf = false;
            _isAnalyzingEdital = false;
            _pdfProcessingProgress = 1.0;
            _progressMessage = 'Análise recuperada do cache!';
            _errorMessage = null; // Limpar mensagens de erro anteriores
          });

          // Mostrar diálogo de sucesso
          _mostrarDialogoSucesso();
          return;
        }
      }

      // Criar o analisador de edital
      final editalAnalyzer = EditalAnalyzer(
        iaService: iaService,
        onProgress: (progress, message) {
          setState(() {
            _pdfProcessingProgress = progress;
            _progressMessage = message;
          });
        },
      );

      setState(() {
        _progressMessage = 'Preparando PDF para análise...';
        _pdfProcessingProgress = 0.2;
      });

      try {
        // Analisar o edital enviando o PDF diretamente para a LLM (primeira etapa: informações básicas)
        final DadosExtraidos dadosExtraidos = await editalAnalyzer.analisarEdital(null, pdfBytes);

        // Converter para Map para manter compatibilidade com o restante do código
        final Map<String, dynamic> dadosMap = {
          'titulo': dadosExtraidos.titulo ?? 'Edital Analisado',
          'banca': dadosExtraidos.banca ?? 'Não especificado',
          'inicioInscricao': dadosExtraidos.inicioInscricao?.toIso8601String().split('T')[0] ?? 'Não especificado',
          'fimInscricao': dadosExtraidos.fimInscricao?.toIso8601String().split('T')[0] ?? 'Não especificado',
          'valorTaxa': dadosExtraidos.valorTaxa,
          'localProva': dadosExtraidos.localProva,
          'cargos': dadosExtraidos.cargos.map((cargo) => {
            'nome': cargo.nome,
            'vagas': cargo.vagas,
            'salario': cargo.salario,
            'escolaridade': cargo.escolaridade,
            'dataProva': cargo.dataProva?.toIso8601String().split('T')[0],
            // Não incluir conteúdo programático na primeira etapa
            'conteudoProgramatico': [],
          }).toList(),
          // Preservar os bytes do PDF para a segunda etapa
          'pdfBytes': base64Encode(pdfBytes),
        };

        // Salvar no cache para uso futuro
        setState(() {
          _progressMessage = 'Finalizando análise e salvando no cache...';
          _pdfProcessingProgress = 0.9;
        });

        // Salvar no cache para uso futuro
        await CacheManager.saveToCache(pdfBytes, dadosMap);

        setState(() {
          _dadosExtraidos = dadosMap;
          _isProcessingPdf = false;
          _isAnalyzingEdital = false;
          _pdfProcessingProgress = 1.0;
          _progressMessage = 'Análise concluída!';
          _errorMessage = null; // Limpar mensagens de erro anteriores
        });

        // Mostrar diálogo de sucesso
        _mostrarDialogoSucesso();
      } catch (e) {
        setState(() {
          _isProcessingPdf = false;
          _isAnalyzingEdital = false;
          _pdfProcessingProgress = 0.0;
          _errorMessage = _formatarMensagemErro(e.toString());
        });
      }

    } catch (e) {
      setState(() {
        _isProcessingPdf = false;
        _isAnalyzingEdital = false;
        _errorMessage = 'Erro ao analisar o edital: $e';
      });
    }
  }

  void _mostrarDialogoSucesso() {
    // Obter o número de cargos identificados
    final int numCargos = _dadosExtraidos?['cargos_disponiveis']?.length ??
                         _dadosExtraidos?['cargos']?.length ?? 0;

    // Verificar se os dados foram recuperados do cache
    final bool fromCache = _progressMessage.contains('cache');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado de sucesso
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        fromCache ? Icons.cached : Icons.check_circle_outline,
                        color: Colors.green,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              // Título com animação
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Text(
                        fromCache ? 'Análise Recuperada!' : 'Análise Concluída!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              // Mensagem principal
              Text(
                fromCache
                    ? 'O edital foi recuperado do cache. Você já analisou este edital anteriormente.'
                    : 'O edital foi analisado com sucesso. Agora você pode selecionar o cargo para o qual deseja se preparar.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87, // Cor escura para garantir legibilidade
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              // Informações sobre cargos
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cargos Identificados',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87, // Cor escura para garantir legibilidade
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Foram encontrados $numCargos cargos neste edital.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87, // Cor escura para garantir legibilidade
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Botões de ação
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navegarParaSelecaoCargo();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.check_circle),
                      label: Text(
                        'Selecionar Cargo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Botão para forçar nova análise (apenas se for do cache)
                  if (fromCache)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _forcarNovaAnalise();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(Icons.refresh),
                          label: Text(
                            'Forçar Nova Análise',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navegarParaSelecaoCargo() async {
    if (_dadosExtraidos != null && _pdfBytes != null) {
      // Salvar o edital no serviço
      final authService = Provider.of<AuthService>(context, listen: false);
      final editalService = Provider.of<EditalService>(context, listen: false);

      if (authService.currentUser != null) {
        try {
          // Criar objeto DadosExtraidos a partir do JSON
          final dadosExtraidos = DadosExtraidos(
            titulo: _dadosExtraidos?['titulo'] ?? 'Edital Analisado',
            banca: _dadosExtraidos?['banca'] ?? 'Não especificado',
            inicioInscricao: _parseData(_dadosExtraidos?['inicioInscricao']),
            fimInscricao: _parseData(_dadosExtraidos?['fimInscricao']),
            valorTaxa: _extrairValorTaxa(_dadosExtraidos),
            localProva: _dadosExtraidos?['localProva'] ?? 'Não especificado',
            cargos: _converterCargos(_dadosExtraidos?['cargos'] ?? []),
          );

          // Adicionar o edital
          final edital = await editalService.addEdital(
            authService.currentUser!.id,
            _dadosExtraidos?['titulo'] ?? 'Edital Analisado',
            _dadosExtraidos?['textoCompleto'] ?? '',
            dadosExtraidos,
            dadosOriginais: _dadosExtraidos,
          );

          print('Edital salvo com ID: ${edital.id}');
          print('Navegando para tela de seleção de cargo...');

          // Navegar para a tela de seleção de cargo
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CargoSelectScreen(editalId: edital.id),
            ),
          );
        } catch (e) {
          print('Erro ao navegar para seleção de cargo: $e');
          setState(() {
            _errorMessage = 'Erro ao processar o edital: $e';
          });
        }
      }
    }
  }

  List<Cargo> _converterCargos(List<dynamic> cargosJson) {
    // Usar a classe utilitária para converter os cargos
    return CargoConverter.converterCargos(cargosJson);
  }

  // Método antigo de conversão de cargos (mantido para referência)
  List<Cargo> _converterCargosAntigo(List<dynamic> cargosJson) {
    try {
      // Verificar se a lista de cargos é válida
      if (cargosJson.isEmpty) {
        print('Lista de cargos vazia, criando cargo genérico');
        return [
          Cargo(
            id: 'cargo_generico_${DateTime.now().millisecondsSinceEpoch}',
            nome: 'Cargo Genérico',
            vagas: 1,
            salario: 0.0,
            escolaridade: 'Não especificado',
            dataProva: null,
            conteudoProgramatico: [
              ConteudoProgramatico(nome: 'Língua Portuguesa', tipo: 'comum', topicos: ['Conteúdo básico']),
              ConteudoProgramatico(nome: 'Matemática', tipo: 'comum', topicos: ['Conteúdo básico']),
              ConteudoProgramatico(nome: 'Conhecimentos Gerais', tipo: 'comum', topicos: ['Conteúdo básico']),
            ],
          )
        ];
      }

      return cargosJson.map<Cargo>((cargoJson) {
        try {
          // Verificar se o cargoJson é um Map
          if (cargoJson is! Map<String, dynamic>) {
            print('Cargo não é um Map: $cargoJson');
            throw FormatException('Formato de cargo inválido');
          }

          // Garantir que vagas seja um int
          int vagas = 0;
          if (cargoJson['vagas'] is int) {
            vagas = cargoJson['vagas'];
          } else if (cargoJson['vagas'] is String) {
            vagas = int.tryParse(cargoJson['vagas']) ?? 0;
          }

          // Garantir que salário seja um double
          double salario = 0.0;
          if (cargoJson['salario'] is double) {
            salario = cargoJson['salario'];
          } else if (cargoJson['salario'] is int) {
            salario = cargoJson['salario'].toDouble();
          } else if (cargoJson['salario'] is String) {
            // Extrair valor numérico da string de remuneração (ex: "R$ 1.185,13" ou "1.621,93")
            String salarioStr = cargoJson['salario'].toString();

            // Remover caracteres não numéricos, exceto pontos e vírgulas
            salarioStr = salarioStr.replaceAll(RegExp(r'[^0-9\.,]'), '');

            // Tratar formato brasileiro (1.234,56)
            if (salarioStr.contains(',')) {
              // Se tem vírgula, assume formato brasileiro
              // Primeiro remove pontos (separadores de milhar) e depois substitui vírgula por ponto
              salarioStr = salarioStr.replaceAll('.', '').replaceAll(',', '.');
              try {
                salario = double.parse(salarioStr);
              } catch (e) {
                print('Erro ao converter salário: $e');
                salario = 0.0;
              }
            } else {
              // Formato sem vírgula, tenta converter diretamente
              try {
                salario = double.parse(salarioStr);
              } catch (e) {
                print('Erro ao converter salário: $e');
                salario = 0.0;
              }
            }
          }

          // Garantir que conteudoProgramatico seja uma lista de ConteudoProgramatico
          List<ConteudoProgramatico> conteudoProgramatico = [];

          // Verificar se há conteúdo programático no formato de objeto aninhado
          if (cargoJson['conteudoProgramatico'] is Map<String, dynamic>) {
            final Map<String, dynamic> conteudoMap = cargoJson['conteudoProgramatico'] as Map<String, dynamic>;

            // Processar conteúdo comum
            if (conteudoMap.containsKey('Língua Portuguesa')) {
              var topicos = _extrairTopicos(conteudoMap['Língua Portuguesa']);
              conteudoProgramatico.add(ConteudoProgramatico(
                nome: 'Língua Portuguesa',
                tipo: 'comum',
                topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
              ));
            }

            if (conteudoMap.containsKey('Raciocínio Lógico')) {
              var topicos = _extrairTopicos(conteudoMap['Raciocínio Lógico']);
              conteudoProgramatico.add(ConteudoProgramatico(
                nome: 'Raciocínio Lógico',
                tipo: 'comum',
                topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
              ));
            }

            if (conteudoMap.containsKey('Matemática')) {
              var topicos = _extrairTopicos(conteudoMap['Matemática']);
              conteudoProgramatico.add(ConteudoProgramatico(
                nome: 'Matemática',
                tipo: 'comum',
                topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
              ));
            }

            // Verificar se há conhecimentos específicos
            if (conteudoMap.containsKey('conhecimentos_especificos')) {
              final especificosMap = conteudoMap['conhecimentos_especificos'];
              if (especificosMap is Map<String, dynamic>) {
                // Extrair cada matéria específica
                especificosMap.forEach((materia, topicosData) {
                  var topicos = _extrairTopicos(topicosData);
                  conteudoProgramatico.add(ConteudoProgramatico(
                    nome: materia,
                    tipo: 'específico',
                    topicos: topicos.isEmpty ? ['Conteúdo específico'] : topicos,
                  ));
                });
              }
            }

            // Verificar se há conhecimentos gerais
            if (conteudoMap.containsKey('conhecimentos_gerais')) {
              final geraisMap = conteudoMap['conhecimentos_gerais'];
              if (geraisMap is Map<String, dynamic>) {
                // Extrair cada matéria de conhecimentos gerais
                geraisMap.forEach((materia, topicosData) {
                  var topicos = _extrairTopicos(topicosData);
                  conteudoProgramatico.add(ConteudoProgramatico(
                    nome: materia,
                    tipo: 'comum',
                    topicos: topicos.isEmpty ? ['Conteúdo geral'] : topicos,
                  ));
                });
              }
            }
          }
          // Formato de lista (formato antigo)
          else if (cargoJson['conteudoProgramatico'] is List) {
            conteudoProgramatico = (cargoJson['conteudoProgramatico'] as List).map((item) {
              if (item is Map<String, dynamic>) {
                // Extrair tópicos
                List<String> topicos = [];
                if (item['topicos'] is List) {
                  topicos = List<String>.from(item['topicos']);
                } else if (item['topicos'] is String) {
                  // Se for uma string, dividir por quebras de linha ou vírgulas
                  final String topicosStr = item['topicos'].toString();
                  if (topicosStr.contains('\n')) {
                    topicos = topicosStr.split('\n')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  } else if (topicosStr.contains(',')) {
                    topicos = topicosStr.split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  } else {
                    topicos = [topicosStr];
                  }
                }

                return ConteudoProgramatico(
                  nome: item['nome'] ?? 'Conteúdo não especificado',
                  tipo: item['tipo'] ?? 'comum',
                  topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos,
                );
              } else if (item is String) {
                // Se for uma string, verificar se é uma matéria comum
                final String nomeMateria = item.toString().trim();
                List<String> topicos = [];

                // Tentar identificar tópicos comuns para matérias padrão
                if (nomeMateria.toLowerCase().contains('português')) {
                  topicos = ['Interpretação de texto', 'Gramática', 'Ortografia', 'Pontuação'];
                } else if (nomeMateria.toLowerCase().contains('matemática')) {
                  topicos = ['Raciocínio lógico', 'Operações básicas', 'Porcentagem', 'Equações'];
                } else if (nomeMateria.toLowerCase().contains('conhecimentos gerais')) {
                  topicos = ['Atualidades', 'História', 'Geografia', 'Política'];
                }

                return ConteudoProgramatico(
                  nome: nomeMateria,
                  tipo: 'comum',
                  topicos: topicos.isEmpty ? ['Conteúdo básico'] : topicos
                );
              } else {
                return ConteudoProgramatico(
                  nome: item.toString(),
                  tipo: 'comum',
                  topicos: ['Conteúdo básico']
                );
              }
            }).toList();
          }

          // Se não houver conteúdo programático, adicionar matérias padrão
          if (conteudoProgramatico.isEmpty) {
            conteudoProgramatico = [
              ConteudoProgramatico(nome: 'Língua Portuguesa', tipo: 'comum', topicos: ['Interpretação de texto', 'Gramática', 'Ortografia']),
              ConteudoProgramatico(nome: 'Matemática', tipo: 'comum', topicos: ['Raciocínio lógico', 'Operações básicas']),
              ConteudoProgramatico(nome: 'Conhecimentos Gerais', tipo: 'comum', topicos: ['Atualidades', 'História', 'Geografia']),
            ];
          }

          // Garantir que o nome do cargo seja válido
          String nomeCargo = 'Cargo não identificado';
          if (cargoJson['nome'] != null && cargoJson['nome'].toString().trim().isNotEmpty) {
            nomeCargo = cargoJson['nome'].toString().trim();
            // Se o nome do cargo for muito genérico, tentar encontrar um nome mais específico
            if (nomeCargo == 'Cargo sem nome' || nomeCargo == 'Cargo não especificado') {
              // Verificar se há informações adicionais que possam ajudar a identificar o cargo
              if (cargoJson['escolaridade'] != null) {
                String escolaridade = cargoJson['escolaridade'].toString();
                if (escolaridade.toLowerCase().contains('policial') ||
                    escolaridade.toLowerCase().contains('militar')) {
                  nomeCargo = 'Policial Militar';
                } else if (escolaridade.toLowerCase().contains('superior')) {
                  nomeCargo = 'Analista';
                } else if (escolaridade.toLowerCase().contains('médio')) {
                  nomeCargo = 'Técnico';
                }
              }
            }
          }

          return Cargo(
            id: DateTime.now().millisecondsSinceEpoch.toString() + nomeCargo,
            nome: nomeCargo,
            vagas: vagas,
            salario: salario,
            escolaridade: cargoJson['escolaridade'] ?? 'Não especificado',
            dataProva: null, // Será preenchido depois
            conteudoProgramatico: conteudoProgramatico.isEmpty ?
                [
                  ConteudoProgramatico(nome: 'Língua Portuguesa', tipo: 'comum', topicos: ['Conteúdo básico']),
                  ConteudoProgramatico(nome: 'Matemática', tipo: 'comum', topicos: ['Conteúdo básico']),
                  ConteudoProgramatico(nome: 'Conhecimentos Gerais', tipo: 'comum', topicos: ['Conteúdo básico']),
                ] : conteudoProgramatico,
          );
        } catch (e) {
          print('Erro ao converter cargo individual: $e');
          // Retornar um cargo padrão em caso de erro
          return Cargo(
            id: 'cargo_erro_${DateTime.now().millisecondsSinceEpoch}',
            nome: 'Cargo Não Identificado',
            vagas: 1,
            salario: 0.0,
            escolaridade: 'Não especificado',
            dataProva: null,
            conteudoProgramatico: [
              ConteudoProgramatico(nome: 'Língua Portuguesa', tipo: 'comum', topicos: ['Conteúdo básico']),
              ConteudoProgramatico(nome: 'Matemática', tipo: 'comum', topicos: ['Conteúdo básico']),
              ConteudoProgramatico(nome: 'Conhecimentos Gerais', tipo: 'comum', topicos: ['Conteúdo básico']),
            ],
          );
        }
      }).toList();
    } catch (e) {
      print('Erro ao converter lista de cargos: $e');
      // Retornar uma lista com um cargo padrão em caso de erro
      return [
        Cargo(
          id: 'cargo_fallback_${DateTime.now().millisecondsSinceEpoch}',
          nome: 'Cargo Padrão',
          vagas: 1,
          salario: 0.0,
          escolaridade: 'Não especificado',
          dataProva: null,
          conteudoProgramatico: [
            ConteudoProgramatico(nome: 'Língua Portuguesa', tipo: 'comum', topicos: ['Conteúdo básico']),
            ConteudoProgramatico(nome: 'Matemática', tipo: 'comum', topicos: ['Conteúdo básico']),
            ConteudoProgramatico(nome: 'Conhecimentos Gerais', tipo: 'comum', topicos: ['Conteúdo básico']),
          ],
        )
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise de Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          // Conteúdo principal
          SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Text(
                  'Análise de Edital',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Envie o PDF do edital para análise automática com IA',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32),

                // Área de upload
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _pdfFileName ?? 'Selecione o arquivo PDF do edital',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _pdfFileName != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(Icons.file_upload),
                        label: Text('Selecionar Arquivo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _isProcessingPdf || _isAnalyzingEdital ? null : _pickPdfFile,
                      ),

                      SizedBox(height: 24),

                      // Botão de análise com IA (só aparece quando um arquivo foi selecionado)
                      if (_pdfFileName != null)
                        ElevatedButton.icon(
                          icon: Icon(Icons.psychology),
                          label: Text('Analisar com IA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isProcessingPdf || _isAnalyzingEdital ? null : _iniciarAnaliseComIA,
                        ),

                      // Progresso de processamento
                      if (_isProcessingPdf) ...[
                        SizedBox(height: 24),
                        LinearProgressIndicator(value: _pdfProcessingProgress),
                        SizedBox(height: 8),
                        Text(
                          '${(_pdfProcessingProgress * 100).toStringAsFixed(0)}% - $_progressMessage',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Informações sobre o processo
                SizedBox(height: 32),
                Text(
                  'Como funciona:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildProcessStep(
                  '1',
                  'Upload do Edital',
                  'Envie o arquivo PDF do edital do concurso',
                  Icons.upload_file,
                ),
                _buildProcessStep(
                  '2',
                  'Análise com IA',
                  'A API LLM (Gemini ou OpenAI) analisa o edital e extrai as informações importantes',
                  Icons.psychology,
                ),
                _buildProcessStep(
                  '3',
                  'Seleção de Cargo',
                  'Escolha o cargo para o qual deseja se preparar',
                  Icons.work,
                ),
                _buildProcessStep(
                  '4',
                  'Plano Personalizado',
                  'Receba um plano de estudos personalizado para o cargo escolhido',
                  Icons.calendar_today,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Erro ao analisar o edital',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                    _pdfBytes = null;
                                    _isProcessingPdf = false;
                                    _isAnalyzingEdital = false;
                                  });
                                },
                                icon: Icon(Icons.refresh, size: 18),
                                label: Text('Tentar Novamente'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Direcionar para a configuração da API LLM
                                  Navigator.pushNamed(context, '/api_config');
                                },
                                icon: Icon(Icons.settings, size: 18),
                                label: Text('Configurar API'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 32),
              ],
            ),
          ),

          // Overlay de análise com animação Matrix
          if (_isAnalyzingEdital)
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: Container(
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
                        message: 'Analisando Edital',
                        statusMessages: [
                          'Identificando nome do concurso...',
                          'Identificando órgão responsável...',
                          'Identificando banca organizadora...',
                          'Identificando datas de inscrição...',
                          'Identificando taxas de inscrição...',
                          'Identificando cotas e vagas...',
                          'Identificando cargos disponíveis...',
                          'Identificando requisitos dos cargos...',
                          'Identificando conteúdo programático...',
                          'Organizando informações...',
                          'Estruturando dados para análise...',
                          'Finalizando processamento...',
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Métodos removidos pois foram substituídos pela animação Matrix

  Widget _buildProcessStep(String number, String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formata a mensagem de erro para exibição ao usuário
  String _formatarMensagemErro(String mensagemOriginal) {
    // Remover detalhes técnicos e formatar a mensagem para o usuário
    if (mensagemOriginal.contains('token limit')) {
      return 'O texto do edital excede o limite de tokens da API LLM.\n\n' +
             'Sugestões:\n' +
             '1. Tente com um arquivo menor (menos páginas)\n' +
             '2. Verifique se o PDF está correto e legível\n' +
             '3. Considere usar uma API com maior limite de contexto';
    } else if (mensagemOriginal.contains('Não foi possível extrair JSON')) {
      return 'Ocorreu um erro ao analisar o edital. O sistema não conseguiu extrair as informações necessárias.\n\n' +
             'Sugestões:\n' +
             '1. Verifique se o PDF está correto e legível\n' +
             '2. Tente novamente com um arquivo menor\n' +
             '3. Verifique sua conexão com a internet\n' +
             '4. Certifique-se de que sua chave de API está configurada corretamente';
    } else if (mensagemOriginal.contains('ConteudoProgramatico')) {
      return 'Erro ao processar o conteúdo programático do edital. Tente novamente.\n\n' +
             'Sugestões:\n' +
             '1. Verifique se o PDF está correto e legível\n' +
             '2. Tente novamente com um arquivo menor\n' +
             '3. Verifique sua conexão com a internet';
    } else if (mensagemOriginal.contains('API') || mensagemOriginal.contains('comunicação com o serviço de IA')) {
      return 'Erro na comunicação com o serviço de IA. Verifique sua chave de API e conexão com a internet.\n\n' +
             'Sugestões:\n' +
             '1. Verifique se você está conectado à internet\n' +
             '2. Verifique se sua chave API está configurada corretamente\n' +
             '3. Tente novamente em alguns instantes';
    } else if (mensagemOriginal.contains('timeout') || mensagemOriginal.contains('tempo esgotado')) {
      return 'O tempo de processamento excedeu o limite. Tente novamente com um arquivo menor ou em partes.';
    } else {
      // Mensagem genérica para outros erros
      return 'Ocorreu um erro ao analisar o edital. Por favor, tente novamente.\n\n' +
             'Detalhes técnicos (para suporte): ' + mensagemOriginal.substring(0, mensagemOriginal.length > 100 ? 100 : mensagemOriginal.length);
    }
  }

  // Removido o método de extração de texto do PDF pois agora enviamos o PDF diretamente para a LLM

  /// Converte uma string de data para DateTime
  DateTime _parseData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) {
      return DateTime.now();
    }

    try {
      // Tentar converter diretamente
      return DateTime.parse(dataStr);
    } catch (e) {
      // Se falhar, tentar extrair dia, mês e ano da string
      final RegExp regexData = RegExp(r'(\d{1,2})\s*(?:de)?\s*([a-zA-Z]+|\d{1,2})\s*(?:de)?\s*(\d{2,4})');
      final match = regexData.firstMatch(dataStr);

      if (match != null) {
        int? dia = int.tryParse(match.group(1) ?? '');
        String mesStr = match.group(2) ?? '';
        int? ano = int.tryParse(match.group(3) ?? '');

        // Converter nome do mês para número
        int? mes;
        if (int.tryParse(mesStr) != null) {
          mes = int.parse(mesStr);
        } else {
          final meses = {
            'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4, 'maio': 5, 'junho': 6,
            'julho': 7, 'agosto': 8, 'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12,
            'jan': 1, 'fev': 2, 'mar': 3, 'abr': 4, 'mai': 5, 'jun': 6,
            'jul': 7, 'ago': 8, 'set': 9, 'out': 10, 'nov': 11, 'dez': 12,
          };
          mes = meses[mesStr.toLowerCase()];
        }

        // Ajustar ano se necessário (20 -> 2020)
        if (ano != null && ano < 100) {
          ano += 2000;
        }

        // Formatar data se todos os componentes forem válidos
        if (dia != null && mes != null && ano != null) {
          return DateTime(ano, mes, dia);
        }
      }

      // Se não conseguir extrair, retornar a data atual
      return DateTime.now();
    }
  }

  /// Extrai o valor da taxa de inscrição dos dados do edital
  double _extrairValorTaxa(Map<String, dynamic>? dados) {
    if (dados == null) return 100.0; // Valor padrão

    // Verificar se há um valor direto de taxa
    if (dados.containsKey('valorTaxa')) {
      var valorTaxa = dados['valorTaxa'];
      if (valorTaxa is num) {
        return valorTaxa.toDouble();
      } else if (valorTaxa is String) {
        // Tentar converter string para double
        try {
          return double.parse(valorTaxa.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
        } catch (e) {
          print('Erro ao converter taxa: $e');
        }
      }
    }

    // Verificar se há taxas por nível
    if (dados.containsKey('taxas_por_nivel')) {
      var taxasPorNivel = dados['taxas_por_nivel'];
      if (taxasPorNivel is Map) {
        // Verificar se há valores para analista ou técnico
        if (taxasPorNivel.containsKey('analista')) {
          var taxa = taxasPorNivel['analista'];
          if (taxa is num) return taxa.toDouble();
          if (taxa is String) {
            try {
              return double.parse(taxa.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
            } catch (e) {}
          }
        }
        if (taxasPorNivel.containsKey('tecnico')) {
          var taxa = taxasPorNivel['tecnico'];
          if (taxa is num) return taxa.toDouble();
          if (taxa is String) {
            try {
              return double.parse(taxa.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
            } catch (e) {}
          }
        }
        if (taxasPorNivel.containsKey('nivel_superior')) {
          var taxa = taxasPorNivel['nivel_superior'];
          if (taxa is num) return taxa.toDouble();
          if (taxa is String) {
            try {
              return double.parse(taxa.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
            } catch (e) {}
          }
        }

        // Se não encontrou valores específicos, pegar o primeiro valor
        if (taxasPorNivel.isNotEmpty) {
          var primeiroValor = taxasPorNivel.values.first;
          if (primeiroValor is num) return primeiroValor.toDouble();
          if (primeiroValor is String) {
            try {
              return double.parse(primeiroValor.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
            } catch (e) {}
          }
        }
      }
    }

    // Verificar se há informações no texto completo
    if (dados.containsKey('textoCompleto')) {
      String texto = dados['textoCompleto'].toString().toLowerCase();
      RegExp regexTaxa = RegExp(r'taxa\s+de\s+inscri[çc][ãa]o\s*[:-]?\s*R\$\s*(\d+[.,]\d+)');
      var match = regexTaxa.firstMatch(texto);
      if (match != null && match.groupCount >= 1) {
        try {
          return double.parse(match.group(1)!.replaceAll(',', '.'));
        } catch (e) {}
      }
    }

    // Valor padrão se nada for encontrado
    return 100.0;
  }

  /// Extrai tópicos de diferentes formatos de dados
  List<String> _extrairTopicos(dynamic topicosData) {
    List<String> topicos = [];

    if (topicosData is List) {
      // Se for uma lista, converter cada item para string
      topicos = List<String>.from(topicosData.map((item) => item.toString()));
    } else if (topicosData is String) {
      // Se for uma string, dividir por quebras de linha ou vírgulas
      final String topicosStr = topicosData.toString();
      if (topicosStr.contains('\n')) {
        topicos = topicosStr.split('\n')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      } else if (topicosStr.contains(',')) {
        topicos = topicosStr.split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      } else {
        topicos = [topicosStr];
      }
    } else if (topicosData is Map<String, dynamic>) {
      // Se for um mapa, extrair valores como tópicos
      topicosData.forEach((key, value) {
        if (value is List) {
          // Adicionar cada item da lista como um tópico
          topicos.addAll(List<String>.from(value.map((item) => item.toString())));
        } else if (value is String) {
          topicos.add(value);
        }
      });
    }

    // Limpar tópicos vazios e remover duplicatas
    return topicos
      .where((t) => t.trim().isNotEmpty)
      .toSet()
      .toList();
  }

  /// Força uma nova análise do edital, ignorando o cache
  Future<void> _forcarNovaAnalise() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arquivo PDF não disponível. Selecione o arquivo novamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Limpar o cache para este PDF
    await CacheManager.removeFromCache(_pdfBytes!);

    // Iniciar nova análise
    setState(() {
      _isAnalyzingEdital = true;
      _progressMessage = 'Iniciando nova análise...';
      _pdfProcessingProgress = 0.05;
      _errorMessage = null;
    });

    // Analisar o edital novamente
    await _analisarEdital(_pdfBytes!);
  }

  // O método _formatarMensagemErro já está definido em outra parte do código
}
