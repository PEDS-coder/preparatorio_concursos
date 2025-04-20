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
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/audio_explanation_service.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/utils/edital_analyzer.dart';
import '../../../../core/utils/pdf_processor.dart';
import '../../../../core/utils/cargo_converter.dart';
import '../../../../core/utils/cache_manager.dart';
import '../../../../core/utils/cache_cleaner.dart';
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
  List<String> _pdfFileNames = [];
  List<String?> _pdfFilePaths = [];
  List<Uint8List> _pdfBytesList = [];
  double _pdfProcessingProgress = 0.0;
  String _progressMessage = '';
  String? _errorMessage;
  bool _isCacheClearing = false;

  // Variáveis para compatibilidade com código existente
  String? _pdfFileName;
  Uint8List? _pdfBytes;

  // Dados extraídos do edital
  Map<String, dynamic>? _dadosExtraidos;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true, // Permitir seleção de múltiplos arquivos
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isProcessingPdf = true;
          _pdfProcessingProgress = 0.1;
          _progressMessage = 'Carregando PDFs...';
          _errorMessage = null;
          _dadosExtraidos = null;
        });

        // Limpar listas anteriores se houver
        _pdfFileNames.clear();
        _pdfFilePaths.clear();
        _pdfBytesList.clear();

        // Processar cada arquivo selecionado
        for (var i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          _pdfFileNames.add(file.name);

          // Obter os bytes do arquivo
          if (kIsWeb) {
            // Web
            if (file.bytes != null) {
              _pdfBytesList.add(file.bytes!);
              _pdfFilePaths.add(null);
            }
          } else {
            // Desktop/Mobile
            if (file.path != null) {
              final fileObj = File(file.path!);
              final bytes = await fileObj.readAsBytes();
              _pdfBytesList.add(bytes);
              _pdfFilePaths.add(file.path);
            }
          }

          // Atualizar progresso
          setState(() {
            _pdfProcessingProgress = 0.1 + (0.1 * (i + 1) / result.files.length);
            _progressMessage = 'Carregando PDF ${i + 1} de ${result.files.length}...';
          });
        }

        if (_pdfBytesList.isEmpty) {
          throw Exception('Não foi possível ler os arquivos PDF');
        }

        setState(() {
          _pdfProcessingProgress = 0.2;
          _progressMessage = '${_pdfBytesList.length} PDFs carregados com sucesso';
          _isProcessingPdf = false; // Arquivos carregados, aguardando análise
        });

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pdfBytesList.length} PDFs carregados com sucesso. Clique em "Analisar com IA" para continuar.'),
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
        _errorMessage = 'Erro ao carregar os PDFs: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar os PDFs: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Iniciar análise com IA
  Future<void> _iniciarAnaliseComIA() async {
    if (_pdfBytesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione pelo menos um arquivo PDF primeiro.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final apiConfigService = Provider.of<ApiConfigService>(context, listen: false);
    final iaService = Provider.of<IAServiceInterface>(context, listen: false);

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
        // Processar arquivos PDF reais
        if (_pdfBytesList.isNotEmpty) {
          await _analisarEdital(_pdfBytesList.first);
        } else {
          throw Exception('Nenhum arquivo PDF carregado corretamente');
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
  }

  Future<void> _analisarEdital(Uint8List pdfBytes) async {
    try {
      final iaService = Provider.of<IAServiceInterface>(context, listen: false);
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
        _progressMessage = 'Verificando texto do edital...';
        _pdfProcessingProgress = 0.05;
      });

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

        setState(() {
          _dadosExtraidos = dadosMap;
          _isProcessingPdf = false;
          _isAnalyzingEdital = false;
          _pdfProcessingProgress = 1.0;
          _progressMessage = 'Análise concluída!';
          _errorMessage = null; // Limpar mensagens de erro anteriores
        });
      } catch (e) {
        setState(() {
          _isProcessingPdf = false;
          _isAnalyzingEdital = false;
          _pdfProcessingProgress = 0.0;
          _errorMessage = e.toString();
        });
      }
    } catch (e) {
      setState(() {
        _isProcessingPdf = false;
        _isAnalyzingEdital = false;
        _pdfProcessingProgress = 0.0;
        _errorMessage = e.toString();
      });
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
                      _pdfFileNames.isEmpty
                        ? Text(
                            'Selecione os arquivos PDF do edital',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Column(
                            children: [
                              Text(
                                '${_pdfFileNames.length} arquivo(s) selecionado(s):',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: _pdfFileNames.length > 3 ? 100 : null,
                                decoration: _pdfFileNames.length > 3 ? BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ) : null,
                                child: _pdfFileNames.length > 3
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _pdfFileNames.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                          child: Row(
                                            children: [
                                              Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(_pdfFileNames[index], style: TextStyle(fontSize: 14)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : Column(
                                      children: _pdfFileNames.map((fileName) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(fileName, style: TextStyle(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                    ),
                              ),
                            ],
                          ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(Icons.file_upload),
                        label: Text('Selecionar Arquivos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _isProcessingPdf || _isAnalyzingEdital ? null : _pickPdfFile,
                      ),

                      SizedBox(height: 24),

                      // Botões de análise com IA (só aparecem quando pelo menos um arquivo foi selecionado)
                      if (_pdfFileNames.isNotEmpty)
                        Column(
                          children: [
                            // Botão principal de análise
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.psychology),
                                label: Text('Analisar com IA'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _isProcessingPdf || _isAnalyzingEdital ? null : _iniciarAnaliseComIA,
                              ),
                            ),
                          ],
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
                Text(
                  '1. Upload do Edital',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Envie os arquivos PDF do edital do concurso',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '2. Análise com IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'A API LLM (Gemini ou OpenAI) analisa o edital e extrai as informações importantes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '3. Seleção de Cargo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Escolha o cargo para o qual deseja se preparar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '4. Plano Personalizado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Receba um plano de estudos personalizado para o cargo escolhido',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
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
                                    _pdfBytesList.clear();
                                    _pdfFileNames.clear();
                                    _pdfFilePaths.clear();
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
                          'Processando PDF do edital...',
                          'Identificando cargos disponíveis...',
                          'Identificando requisitos dos cargos...',
                          'Identificando nível de escolaridade...',
                          'Identificando número de vagas...',
                          'Organizando informações dos cargos...',
                          'Estruturando dados para seleção...',
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
}
