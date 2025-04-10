import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
// import 'package:file_picker/file_picker.dart'; // Comentado temporariamente
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/utils/pdf_processor.dart';
import '../../../../core/utils/edital_analyzer.dart';

class EditalAddScreen extends StatefulWidget {
  @override
  _EditalAddScreenState createState() => _EditalAddScreenState();
}

class _EditalAddScreenState extends State<EditalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeConcursoController = TextEditingController();
  final _textoEditalController = TextEditingController();
  bool _isLoading = false;
  bool _isExtracting = false;
  bool _isProcessingPdf = false;
  bool _isPdfScanned = false;
  String? _errorMessage;
  String? _pdfFilePath;
  String? _pdfFileName;
  double _pdfProcessingProgress = 0.0;
  String _progressMessage = '';
  Uint8List? _pdfBytes;
  String? _pdfText;

  // Processador de PDF
  late PdfProcessor _pdfProcessor;

  @override
  void initState() {
    super.initState();
    // Inicializar o processador de PDF
    _pdfProcessor = PdfProcessor(
      onProgress: (progress, message) {
        setState(() {
          _pdfProcessingProgress = progress;
          _progressMessage = message;
        });
      },
    );
  }

  @override
  void dispose() {
    _nomeConcursoController.dispose();
    _textoEditalController.dispose();
    // Limpar arquivos temporários
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    if (!kIsWeb && _pdfFilePath != null) {
      try {
        final file = File(_pdfFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Erro ao limpar arquivos temporários: $e');
      }
    }
  }

  Future<void> _processPdfBytes(Uint8List bytes, String fileName) async {
    try {
      // Verificar tamanho do arquivo (limite de 100MB para processamento direto)
      final fileSize = bytes.length;

      if (fileSize > 100 * 1024 * 1024) {
        await _processLargePdfBytes(bytes, fileSize);
      } else {
        await _processRegularPdfBytes(bytes);
      }

      setState(() {
        _isProcessingPdf = false;
        _pdfProcessingProgress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF processado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingPdf = false;
        _errorMessage = 'Erro ao processar o PDF: $e';
      });
    }
  }

  Future<void> _processRegularPdfBytes(Uint8List bytes) async {
    // Carregar o PDF usando Syncfusion
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      // Extrair texto do PDF
      String extractedText = '';

      // Processar cada página
      for (int i = 0; i < document.pages.count; i++) {
        // Atualizar progresso
        setState(() {
          _pdfProcessingProgress = (i + 1) / document.pages.count;
        });

        // Extrair texto da página
        final pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        extractedText += pageText + '\n\n';

        // Pausa para não bloquear a UI
        if (i % 10 == 0) {
          await Future.delayed(Duration(milliseconds: 10));
        }
      }

      // Atualizar o campo de texto
      setState(() {
        _textoEditalController.text = extractedText;
      });

      // Fechar o documento
      document.dispose();
    } finally {
      // Garantir que o documento seja fechado mesmo em caso de erro
      document.dispose();
    }
  }

  Future<void> _processLargePdfBytes(Uint8List bytes, int fileSize) async {
    // Para PDFs muito grandes, processar em partes
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final totalPages = document.pages.count;

    try {
      // Processar em lotes de 20 páginas
      const int batchSize = 20;
      final int totalBatches = (totalPages / batchSize).ceil();

      // Armazenar o texto extraído
      String extractedText = '';

      for (int batch = 0; batch < totalBatches; batch++) {
        final startPage = batch * batchSize;
        final endPage = (batch + 1) * batchSize - 1 < totalPages ? (batch + 1) * batchSize - 1 : totalPages - 1;

        // Extrair texto do lote de páginas
        final batchText = PdfTextExtractor(document).extractText(
          startPageIndex: startPage,
          endPageIndex: endPage,
        );

        // Adicionar ao texto extraído
        extractedText += batchText + '\n\n';

        // Atualizar progresso
        setState(() {
          _pdfProcessingProgress = (batch + 1) / totalBatches;
        });

        // Pausa para não bloquear a UI
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Ler as primeiras 10.000 caracteres para exibição
      final displayText = extractedText.length > 10000
          ? extractedText.substring(0, 10000) + '\n\n[Texto truncado devido ao tamanho do arquivo...]'
          : extractedText;

      setState(() {
        _textoEditalController.text = displayText;
      });

      // Mostrar aviso sobre o tamanho do arquivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('O PDF é muito grande (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Apenas uma prévia do texto foi carregada.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      // Fechar o documento
      document.dispose();
    }
  }

  Future<void> _pickPdfFile() async {
    // Funcionalidade temporariamente desabilitada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidade de upload temporariamente desabilitada. Use o exemplo pré-carregado.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );

    // Usar um exemplo pré-carregado para demonstração
    setState(() {
      _pdfFileName = 'exemplo_edital.pdf';
      _isProcessingPdf = true;
      _pdfProcessingProgress = 0.0;
      _progressMessage = 'Iniciando processamento do PDF...';
      _errorMessage = null;
    });

    // Simular o processamento de um PDF
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _pdfProcessingProgress = 0.5;
      _progressMessage = 'Extraindo texto do PDF...';
    });

    await Future.delayed(Duration(seconds: 1));

    // Usar texto de exemplo
    final String exampleText = 'EDITAL DE CONCURSO PÚBLICO\n\nCargo: Analista Administrativo\nVagas: 10\nSalário: R\$ 5.000,00\nEscolaridade: Nível Superior\n\nConteúdo Programático:\n- Língua Portuguesa\n- Raciocínio Lógico\n- Direito Administrativo\n- Administração Pública';

    // Simular o processamento do texto
    setState(() {
      _pdfProcessingProgress = 0.8;
      _progressMessage = 'Finalizando processamento...';
    });

    await Future.delayed(Duration(seconds: 1));

    // Finalizar o processamento
    setState(() {
      _pdfProcessingProgress = 1.0;
      _progressMessage = 'Processamento concluído!';
      _pdfText = exampleText;
      _isProcessingPdf = false;
    });
  }

  Future<void> _processarPdfAvancado(Uint8List bytes) async {
    try {
      setState(() {
        _progressMessage = 'Verificando tipo de PDF...';
      });

      // Verificar se o PDF é escaneado
      _isPdfScanned = await _pdfProcessor.isPdfScanned(bytes);

      setState(() {
        _progressMessage = _isPdfScanned
            ? 'PDF escaneado detectado. Iniciando OCR...'
            : 'Extraindo texto do PDF...';
      });

      // Extrair texto do PDF
      final String textoExtraido = await _pdfProcessor.extractTextFromPdf(
        bytes,
        useOcr: _isPdfScanned,
      );

      setState(() {
        _textoEditalController.text = textoExtraido;
        _isProcessingPdf = false;
        _pdfProcessingProgress = 1.0;
        _progressMessage = 'Processamento concluído!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPdfScanned
              ? 'PDF escaneado processado com OCR!'
              : 'PDF processado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingPdf = false;
        _errorMessage = 'Erro ao processar o PDF: $e';
      });
    }
  }

  Future<void> _processPdf(String filePath) async {
    try {
      // Carregar o PDF
      final File file = File(filePath);
      final fileSize = await file.length();

      // Verificar tamanho do arquivo (limite de 100MB para processamento direto)
      if (fileSize > 100 * 1024 * 1024) {
        await _processLargePdf(file, fileSize);
      } else {
        await _processRegularPdf(file);
      }

      setState(() {
        _isProcessingPdf = false;
        _pdfProcessingProgress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF processado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingPdf = false;
        _errorMessage = 'Erro ao processar o PDF: $e';
      });
    }
  }

  Future<void> _processRegularPdf(File file) async {
    // Carregar o PDF usando Syncfusion
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());

    try {
      // Extrair texto do PDF
      String extractedText = '';

      // Processar cada página
      for (int i = 0; i < document.pages.count; i++) {
        // Atualizar progresso
        setState(() {
          _pdfProcessingProgress = (i + 1) / document.pages.count;
        });

        // Extrair texto da página
        final page = document.pages[i];
        final pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        extractedText += pageText + '\n\n';

        // Pausa para não bloquear a UI
        if (i % 10 == 0) {
          await Future.delayed(Duration(milliseconds: 10));
        }
      }

      // Atualizar o campo de texto
      setState(() {
        _textoEditalController.text = extractedText;
      });

      // Fechar o documento
      document.dispose();
    } finally {
      // Garantir que o documento seja fechado mesmo em caso de erro
      document.dispose();
    }
  }

  Future<void> _processLargePdf(File file, int fileSize) async {
    // Para PDFs muito grandes, processar em partes
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/temp_edital_${DateTime.now().millisecondsSinceEpoch}.txt';
    final tempFile = File(tempFilePath);

    try {
      // Carregar o PDF usando Syncfusion
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      final totalPages = document.pages.count;

      // Processar em lotes de 20 páginas
      const int batchSize = 20;
      final int totalBatches = (totalPages / batchSize).ceil();

      // Criar arquivo temporário para armazenar o texto extraído
      await tempFile.create();
      final sink = tempFile.openWrite();

      try {
        for (int batch = 0; batch < totalBatches; batch++) {
          final startPage = batch * batchSize;
          final endPage = (batch + 1) * batchSize - 1 < totalPages ? (batch + 1) * batchSize - 1 : totalPages - 1;

          // Extrair texto do lote de páginas
          final batchText = PdfTextExtractor(document).extractText(
            startPageIndex: startPage,
            endPageIndex: endPage,
          );

          // Escrever no arquivo temporário
          sink.write(batchText + '\n\n');

          // Atualizar progresso
          setState(() {
            _pdfProcessingProgress = (batch + 1) / totalBatches;
          });

          // Pausa para não bloquear a UI
          await Future.delayed(Duration(milliseconds: 50));
        }
      } finally {
        // Fechar o sink e o documento
        await sink.close();
        document.dispose();
      }

      // Ler as primeiras 10.000 caracteres para exibição
      final previewText = await tempFile.readAsString();
      final displayText = previewText.length > 10000
          ? previewText.substring(0, 10000) + '\n\n[Texto truncado devido ao tamanho do arquivo...]'
          : previewText;

      setState(() {
        _textoEditalController.text = displayText;
        _pdfFilePath = tempFilePath; // Atualizar o caminho para o arquivo de texto
      });

      // Mostrar aviso sobre o tamanho do arquivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('O PDF é muito grande (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Apenas uma prévia do texto foi carregada.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Em caso de erro, tentar limpar o arquivo temporário
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Future<void> _processarEdital() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _isExtracting = true;
        _errorMessage = null;
        _progressMessage = 'Verificando permissões...';
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final editalService = Provider.of<EditalService>(context, listen: false);
        final iaService = Provider.of<IAService>(context, listen: false);

        // Verificar se o usuário está autenticado
        final usuario = authService.currentUser;
        if (usuario == null) {
          setState(() {
            _errorMessage = 'Você precisa estar autenticado para adicionar um edital.';
            _isLoading = false;
            _isExtracting = false;
          });
          return;
        }

        // Verificar limite de editais para usuários gratuitos
        if (!authService.isPremium) {
          final editaisUsuario = editalService.getEditaisByUserId(usuario.id);
          if (editaisUsuario.length >= 1) {
            setState(() {
              _errorMessage = 'Usuários gratuitos podem adicionar apenas 1 edital. Faça upgrade para Premium.';
              _isLoading = false;
              _isExtracting = false;
            });
            return;
          }
        }

        // Verificar se o texto do edital é muito grande
        final textoEdital = _textoEditalController.text;
        if (textoEdital.length > 100000 && !authService.isPremium) {
          setState(() {
            _errorMessage = 'O texto do edital é muito grande. Usuários gratuitos podem processar até 100.000 caracteres. Faça upgrade para Premium.';
            _isLoading = false;
            _isExtracting = false;
          });
          return;
        }

        // Extrair dados do edital usando IA
        setState(() {
          _isExtracting = true;
          _progressMessage = 'Analisando edital...';
        });

        // Verificar se a API Key está configurada
        if (!iaService.isConfigured) {
          setState(() {
            _progressMessage = 'Usando extração simulada (API não configurada)...';
          });

          // Usar extração simulada se não houver API Key
          final dadosExtraidos = await editalService.extrairDadosEdital(textoEdital);

          setState(() {
            _isExtracting = false;
          });

          // Adicionar o edital
          await editalService.addEdital(
            usuario.id,
            _nomeConcursoController.text.trim(),
            textoEdital,
            dadosExtraidos,
          );
        } else {
          // Usar análise avançada com IA
          try {
            setState(() {
              _progressMessage = 'Iniciando análise avançada com IA...';
            });

            // Criar analisador de edital
            final editalAnalyzer = EditalAnalyzer(
              iaService: iaService,
              onProgress: (progress, message) {
                setState(() {
                  _pdfProcessingProgress = progress;
                  _progressMessage = message;
                });
              },
            );

            // Analisar o edital
            final dadosExtraidos = await editalAnalyzer.analisarEdital(textoEdital);

            setState(() {
              _isExtracting = false;
              _progressMessage = 'Análise concluída!';
            });

            // Adicionar o edital
            await editalService.addEdital(
              usuario.id,
              _nomeConcursoController.text.trim(),
              textoEdital,
              dadosExtraidos,
            );
          } catch (iaError) {
            print('Erro ao usar IA para análise avançada: $iaError');

            setState(() {
              _progressMessage = 'Usando extração de backup...';
            });

            // Fallback para extração simulada
            final dadosExtraidos = await editalService.extrairDadosEdital(textoEdital);

            setState(() {
              _isExtracting = false;
            });

            // Adicionar o edital
            await editalService.addEdital(
              usuario.id,
              _nomeConcursoController.text.trim(),
              textoEdital,
              dadosExtraidos,
            );
          }
        }

        // Limpar arquivos temporários
        await _cleanupTempFiles();

        // Navegar de volta para a tela de editais
        Navigator.pop(context);

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edital adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Ocorreu um erro ao processar o edital: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
          _isExtracting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Text(
                'Adicionar Novo Edital',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Preencha as informações abaixo para adicionar um novo edital',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),

              // Nome do concurso
              TextFormField(
                controller: _nomeConcursoController,
                decoration: InputDecoration(
                  labelText: 'Nome do Concurso',
                  hintText: 'Ex: Concurso TRT 10ª Região',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do concurso';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Texto do edital
              Text(
                'Texto do Edital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cole o texto completo do edital ou as partes mais importantes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _textoEditalController,
                decoration: InputDecoration(
                  hintText: 'Cole o texto do edital aqui...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o texto do edital';
                  }
                  if (value.length < 100) {
                    return 'O texto é muito curto. Insira um texto mais completo';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text('Carregar arquivo PDF'),
                    onPressed: _isProcessingPdf ? null : _pickPdfFile,
                  ),
                  if (_isProcessingPdf) ...[
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Processando: $_pdfFileName',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(value: _pdfProcessingProgress),
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(_pdfProcessingProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                _progressMessage,
                                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Mensagem de erro
              if (_errorMessage != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
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

              // Botões de ação
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processarEdital,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(_isExtracting ? 'Extraindo dados...' : 'Processando...'),
                              ],
                            )
                          : Text('Processar Edital'),
                    ),
                  ),
                ],
              ),

              // Informações sobre o processamento
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que acontece ao processar o edital?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Extraímos automaticamente as informações importantes do edital\n'
                      '• Identificamos datas, cargos, requisitos e conteúdo programático\n'
                      '• Organizamos tudo para facilitar seu planejamento de estudos',
                      style: TextStyle(fontSize: 14),
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
}
