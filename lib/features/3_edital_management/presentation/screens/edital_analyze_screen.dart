import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/utils/logger_static.dart';
import '../widgets/edital_analyze/pdf_upload_widget.dart';
import '../widgets/edital_analyze/analysis_progress_widget.dart';
import '../widgets/edital_analyze/instructions_widget.dart';
import '../widgets/edital_analyze/analyze_button_widget.dart';
import '../../domain/services/edital_analysis_service.dart';

/// Tela para análise de editais com IA
class EditalAnalyzeScreen extends StatefulWidget {
  const EditalAnalyzeScreen({Key? key}) : super(key: key);

  @override
  _EditalAnalyzeScreenState createState() => _EditalAnalyzeScreenState();
}

class _EditalAnalyzeScreenState extends State<EditalAnalyzeScreen> {
  // Estado dos arquivos selecionados
  List<PlatformFile> _selectedFiles = [];

  // Estado do carregamento
  bool _isLoading = false;
  String _progressMessage = '';
  double _progressValue = 0.0;
  String? _errorMessage;

  // Lista de mensagens de status para a animação
  final List<String> _statusMessages = [
    'Extraindo texto do PDF...',
    'Identificando informações do concurso...',
    'Analisando cargos disponíveis...',
    'Processando conteúdo programático...',
    'Organizando dados do edital...',
    'Aplicando algoritmos de IA...',
  ];

  @override
  Widget build(BuildContext context) {
    // Verificar se o serviço de IA está configurado
    final iaService = Provider.of<IAServiceInterface>(context);
    final bool isIAConfigured = iaService.isConfigured;

    // Mostrar tela de carregamento durante o processamento
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisar Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            const Text(
              'Análise de Edital com IA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Faça upload do edital em PDF para análise automática',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Instruções
            const InstructionsWidget(),
            const SizedBox(height: 24),

            // Widget de upload de PDF
            PdfUploadWidget(
              selectedFiles: _selectedFiles,
              onFilesSelected: _handleFilesSelected,
              onRemoveAllFiles: _handleRemoveAllFiles,
              onRemoveFile: _handleRemoveFile,
            ),
            const SizedBox(height: 24),

            // Botão de análise
            AnalyzeButtonWidget(
              hasSelectedFiles: _selectedFiles.isNotEmpty,
              isLoading: _isLoading,
              onAnalyzePressed: _handleAnalyzePressed,
            ),

            // Mensagem de erro
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
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

            // Aviso de configuração da API
            if (!isIAConfigured)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API não configurada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure a API nas configurações para usar a análise de editais.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/settings');
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.orange.shade800,
                            ),
                            child: Text('Ir para Configurações'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisando Edital'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnalysisProgressWidget(
                progressMessage: _progressMessage,
                statusMessages: _statusMessages,
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _progressValue > 0 ? _progressValue : null,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                _progressMessage.isNotEmpty ? _progressMessage : 'Processando...',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_progressValue > 0)
                Text(
                  '${(_progressValue * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFilesSelected(List<PlatformFile> files) {
    setState(() {
      _selectedFiles = files;
      _errorMessage = null;
    });
  }

  void _handleRemoveAllFiles() {
    setState(() {
      _selectedFiles = [];
    });
  }

  void _handleRemoveFile(PlatformFile file) {
    setState(() {
      _selectedFiles.removeWhere((f) => f.name == file.name);
    });
  }

  // Método removido: _handleUseExamplePressed

  Future<void> _handleAnalyzePressed() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos um arquivo PDF para análise.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progressValue = 0.0;
      _progressMessage = 'Iniciando análise do edital...';
    });

    try {
      await EditalAnalysisService.analisarEdital(
        context: context,
        selectedFiles: _selectedFiles,
        onProgress: (message, progress) {
          setState(() {
            _progressMessage = message;
            _progressValue = progress;
          });
        },
      );
    } catch (e) {
      Logger.error('Erro ao analisar edital: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao analisar edital: ${e.toString()}';
      });
    }
  }
}
