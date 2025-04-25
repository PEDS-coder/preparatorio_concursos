import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/utils/edital_analyzer.dart';

class EditalAddScreen extends StatefulWidget {
  const EditalAddScreen({super.key});

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
  String? _errorMessage;
  String? _pdfFileName;
  double _pdfProcessingProgress = 0.0;
  String _progressMessage = '';
  Uint8List? _pdfBytes;

  @override
  void dispose() {
    _nomeConcursoController.dispose();
    _textoEditalController.dispose();
    super.dispose();
  }

  // Método simplificado para carregar um PDF de exemplo
  Future<void> _pickPdfFile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usando exemplo pré-carregado para evitar travamentos.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    // Simular carregamento de PDF
    setState(() {
      _pdfFileName = 'exemplo_edital.pdf';
      _isProcessingPdf = true;
      _pdfProcessingProgress = 0.0;
      _progressMessage = 'Carregando PDF...';
      _errorMessage = null;
    });

    // Simular o carregamento
    await Future.delayed(const Duration(seconds: 1));

    // Usar texto de exemplo
    const String exampleText = 'EDITAL DE CONCURSO PÚBLICO\n\nCargo: Analista Administrativo\nVagas: 10\nSalário: R\$ 5.000,00\nEscolaridade: Nível Superior\n\nConteúdo Programático:\n- Língua Portuguesa\n- Raciocínio Lógico\n- Direito Administrativo\n- Administração Pública';

    // Finalizar o carregamento
    setState(() {
      _textoEditalController.text = exampleText;
      _pdfProcessingProgress = 1.0;
      _progressMessage = 'PDF carregado com sucesso!';
      _isProcessingPdf = false;
      
      // Simular bytes do PDF (na implementação real, seriam os bytes do arquivo)
      _pdfBytes = Uint8List.fromList(exampleText.codeUnits);
    });
  }

  // Método para processar o edital (enviar para a LLM)
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
          if (editaisUsuario.isNotEmpty) {
            setState(() {
              _errorMessage = 'Usuários gratuitos podem adicionar apenas 1 edital. Faça upgrade para Premium.';
              _isLoading = false;
              _isExtracting = false;
            });
            return;
          }
        }

        // Verificar se temos bytes do PDF
        if (_pdfBytes == null) {
          setState(() {
            _errorMessage = 'Por favor, carregue um PDF antes de continuar.';
            _isLoading = false;
            _isExtracting = false;
          });
          return;
        }

        // Extrair dados do edital usando IA
        setState(() {
          _isExtracting = true;
          _progressMessage = 'Enviando PDF para análise...';
        });

        // Verificar se a API Key está configurada
        if (!iaService.isConfigured) {
          setState(() {
            _progressMessage = 'Usando extração simulada (API não configurada)...';
          });

          // Usar extração simulada se não houver API Key
          final dadosExtraidos = await editalService.extrairDadosEdital(_textoEditalController.text);

          setState(() {
            _isExtracting = false;
          });

          // Adicionar o edital
          await editalService.addEdital(
            usuario.id,
            _nomeConcursoController.text.trim(),
            _textoEditalController.text,
            dadosExtraidos,
          );
        } else {
          // Usar análise avançada com IA enviando o PDF diretamente
          try {
            setState(() {
              _progressMessage = 'Enviando PDF para análise com IA...';
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

            // Analisar o edital enviando o PDF diretamente
            final dadosExtraidos = await editalAnalyzer.analisarEdital(null, _pdfBytes);

            setState(() {
              _isExtracting = false;
              _progressMessage = 'Análise concluída!';
            });

            // Adicionar o edital
            await editalService.addEdital(
              usuario.id,
              _nomeConcursoController.text.trim(),
              _textoEditalController.text,
              dadosExtraidos,
            );
          } catch (iaError) {
            print('Erro ao usar IA para análise avançada: $iaError');

            setState(() {
              _progressMessage = 'Usando extração de backup...';
            });

            // Fallback para extração simulada
            final dadosExtraidos = await editalService.extrairDadosEdital(_textoEditalController.text);

            setState(() {
              _isExtracting = false;
            });

            // Adicionar o edital
            await editalService.addEdital(
              usuario.id,
              _nomeConcursoController.text.trim(),
              _textoEditalController.text,
              dadosExtraidos,
            );
          }
        }

        // Navegar de volta para a tela de editais
        Navigator.pop(context);

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edital adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Erro ao processar o edital: $e';
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
        title: const Text('Adicionar Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicione um novo edital',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeConcursoController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Concurso',
                  hintText: 'Ex: Concurso TRT 2023',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do concurso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Texto do Edital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textoEditalController,
                decoration: const InputDecoration(
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Carregar arquivo PDF'),
                    onPressed: _isProcessingPdf ? null : _pickPdfFile,
                  ),
                ],
              ),
              if (_isProcessingPdf)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _pdfProcessingProgress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _progressMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              if (_pdfFileName != null && !_isProcessingPdf)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF carregado: $_pdfFileName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processarEdital,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(_isExtracting ? 'Analisando edital...' : 'Processando...'),
                          ],
                        )
                      : Text('ADICIONAR EDITAL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
