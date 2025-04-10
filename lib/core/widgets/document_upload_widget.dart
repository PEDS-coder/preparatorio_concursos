import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/services/plano_estudo_service.dart';
import '../services/document_classifier_service.dart';
import '../data/models/materia.dart';
import '../data/models/assunto.dart';
import 'modern_card.dart';
import 'gradient_button.dart';

class DocumentUploadWidget extends StatefulWidget {
  final Function(String texto, String? materiaId, String? assuntoId) onDocumentProcessed;
  final bool showClassification;
  final String title;
  final String description;

  const DocumentUploadWidget({
    Key? key,
    required this.onDocumentProcessed,
    this.showClassification = true,
    this.title = 'Upload de Documento',
    this.description = 'Faça upload de um documento para processamento',
  }) : super(key: key);

  @override
  _DocumentUploadWidgetState createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  // Arquivo selecionado (File para desktop, bytes para web)
  File? _selectedFile;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isLoading = false;
  String? _fileContent;
  String? _materiaId;
  String? _assuntoId;

  // Classificação automática
  Map<String, dynamic>? _classificacao;
  List<Map<String, dynamic>>? _sugestoes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(height: 16),

        // Área de upload
        ModernCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Área de arrastar e soltar ou selecionar arquivo
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: (_selectedFile == null && _fileBytes == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Clique para selecionar um arquivo',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'PDF, DOCX, TXT, HTML',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedFile != null
                                      ? _getFileIcon(_selectedFile!.path)
                                      : Icons.description,
                                  size: 48,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _fileName ?? (_selectedFile?.path.split('/').last ?? 'Arquivo selecionado'),
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Clique para alterar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Botão de processar
                ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('PROCESSAR DOCUMENTO'),
                  onPressed: (_selectedFile == null && _fileBytes == null) || _isLoading
                      ? null
                      : _processDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Indicador de carregamento
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade800,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Processando documento...',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Classificação automática (se habilitada)
        if (widget.showClassification && _classificacao != null)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classificação Automática',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),

                ModernCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Matéria identificada
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: AppTheme.secondaryColor,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Matéria: ${_classificacao!['materia']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Assunto identificado
                        Row(
                          children: [
                            Icon(
                              Icons.book,
                              color: AppTheme.secondaryColor,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Assunto: ${_classificacao!['assunto']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Nível de confiança
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppTheme.secondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Confiança: ${(_classificacao!['confianca'] * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Seleção manual de matéria e assunto
                        _buildMateriaAssuntoSelector(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Botão de confirmar (após classificação)
        if (widget.showClassification && _classificacao != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.check),
              label: Text('CONFIRMAR E CONTINUAR'),
              onPressed: _confirmarProcessamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Seletor de matéria e assunto
  Widget _buildMateriaAssuntoSelector() {
    return Consumer<PlanoEstudoService>(
      builder: (context, planoService, _) {
        // Obter matérias disponíveis
        final materias = planoService.materias;

        // Obter assuntos da matéria selecionada
        final assuntos = _materiaId != null
            ? planoService.getAssuntosByMateria(_materiaId!)
            : <Assunto>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajustar Classificação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),

            // Seletor de matéria
            DropdownButtonFormField<String>(
              value: _materiaId,
              decoration: InputDecoration(
                labelText: 'Matéria',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.darkCardColor,
              ),
              dropdownColor: AppTheme.darkCardColor,
              items: materias.map((materia) {
                return DropdownMenuItem<String>(
                  value: materia.id,
                  child: Text(
                    materia.nome,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _materiaId = value;
                  _assuntoId = null; // Limpar assunto ao mudar de matéria
                });
              },
            ),
            SizedBox(height: 16),

            // Seletor de assunto
            DropdownButtonFormField<String>(
              value: _assuntoId,
              decoration: InputDecoration(
                labelText: 'Assunto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.darkCardColor,
              ),
              dropdownColor: AppTheme.darkCardColor,
              items: assuntos.map((assunto) {
                return DropdownMenuItem<String>(
                  value: assunto.id,
                  child: Text(
                    assunto.nome,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _assuntoId = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Selecionar arquivo
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'html'],
        withData: true, // Importante para web
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            // No web, usamos os bytes do arquivo
            _fileBytes = result.files.single.bytes;
            _fileName = result.files.single.name;
            _selectedFile = null;
          } else {
            // Em plataformas nativas, usamos o caminho do arquivo
            if (result.files.single.path != null) {
              _selectedFile = File(result.files.single.path!);
              _fileName = result.files.single.name;
              _fileBytes = null;
            }
          }
          _fileContent = null;
          _classificacao = null;
          _sugestoes = null;
        });
      }
    } catch (e) {
      print('Erro ao selecionar arquivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  // Processar documento
  Future<void> _processDocument() async {
    if (_selectedFile == null && _fileBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Extrair texto do documento
      String texto;
      if (kIsWeb && _fileBytes != null) {
        // No web, extraímos o texto dos bytes
        texto = String.fromCharCodes(_fileBytes!);
      } else if (_selectedFile != null) {
        // Em plataformas nativas, extraímos o texto do arquivo
        texto = await _extractTextFromFile(_selectedFile!);
      } else {
        throw Exception('Nenhum arquivo selecionado');
      }

      // Classificar o documento
      if (widget.showClassification) {
        // Usar o serviço já injetado
        final classifier = Provider.of<DocumentClassifierService>(context, listen: false);

        final classificacao = await classifier.identificarMateriaAssunto(texto);
        final sugestoes = await classifier.sugerirMateriasAssuntos(texto);

        // Encontrar matéria correspondente
        final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
        final materias = planoService.materias;

        String? materiaId;
        String? assuntoId;

        // Tentar encontrar uma matéria com nome similar
        for (final materia in materias) {
          if (materia.nome.toLowerCase().contains(
                classificacao['materia'].toString().toLowerCase()) ||
              classificacao['materia'].toString().toLowerCase().contains(
                materia.nome.toLowerCase())) {
            materiaId = materia.id;

            // Tentar encontrar um assunto com nome similar
            final assuntos = planoService.getAssuntosByMateria(materia.id);
            for (final assunto in assuntos) {
              if (assunto.nome.toLowerCase().contains(
                    classificacao['assunto'].toString().toLowerCase()) ||
                  classificacao['assunto'].toString().toLowerCase().contains(
                    assunto.nome.toLowerCase())) {
                assuntoId = assunto.id;
                break;
              }
            }

            break;
          }
        }

        setState(() {
          _fileContent = texto;
          _classificacao = classificacao;
          _sugestoes = sugestoes;
          _materiaId = materiaId;
          _assuntoId = assuntoId;
        });
      } else {
        // Se não mostrar classificação, processar diretamente
        widget.onDocumentProcessed(texto, null, null);
      }
    } catch (e) {
      print('Erro ao processar documento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar documento: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Confirmar processamento
  void _confirmarProcessamento() {
    if (_fileContent != null) {
      widget.onDocumentProcessed(_fileContent!, _materiaId, _assuntoId);
    }
  }

  // Extrair texto do arquivo
  Future<String> _extractTextFromFile(File file) async {
    // Implementação simplificada - em um app real, você usaria bibliotecas
    // específicas para cada tipo de arquivo

    final extension = file.path.split('.').last.toLowerCase();

    switch (extension) {
      case 'txt':
        return await file.readAsString();
      case 'pdf':
      case 'docx':
      case 'html':
        // Simulação - em um app real, você usaria bibliotecas específicas
        return 'Conteúdo extraído do arquivo ${file.path.split('/').last}';
      default:
        throw Exception('Formato de arquivo não suportado');
    }
  }

  // Obter ícone com base na extensão do arquivo
  IconData _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'html':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }
}
