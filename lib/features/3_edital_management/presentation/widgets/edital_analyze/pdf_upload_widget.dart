import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/services/pdf_upload_service.dart';

/// Widget para upload de arquivos PDF
class PdfUploadWidget extends StatefulWidget {
  final List<PlatformFile> selectedFiles;
  final Function(List<PlatformFile>) onFilesSelected;
  final VoidCallback onRemoveAllFiles;
  final Function(PlatformFile) onRemoveFile;

  const PdfUploadWidget({
    Key? key,
    required this.selectedFiles,
    required this.onFilesSelected,
    required this.onRemoveAllFiles,
    required this.onRemoveFile,
  }) : super(key: key);

  @override
  _PdfUploadWidgetState createState() => _PdfUploadWidgetState();
}

class _PdfUploadWidgetState extends State<PdfUploadWidget> {
  final PdfUploadService _pdfUploadService = PdfUploadService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload do Edital',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione o arquivo PDF do edital para análise',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tamanho máximo recomendado: ${_pdfUploadService.formatFileSize(PdfUploadService.maxPdfSizeBytes)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            _buildUploadButton(context),
            const SizedBox(height: 16),
            if (_isUploading) _buildUploadingIndicator(),
            if (widget.selectedFiles.isNotEmpty) _buildSelectedFilesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processando arquivo...',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : () => _pickPdfFile(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Selecionar Arquivo PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSelectedFilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Arquivos Selecionados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _isUploading ? null : widget.onRemoveAllFiles,
              icon: Icon(
                Icons.delete,
                size: 16,
                color: _isUploading ? Colors.grey : Colors.red
              ),
              label: Text(
                'Remover Todos',
                style: TextStyle(
                  color: _isUploading ? Colors.grey : Colors.red
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.selectedFiles.map((file) => _buildFileItem(file)).toList(),
      ],
    );
  }

  Widget _buildFileItem(PlatformFile file) {
    // Verificar se o arquivo está dentro do limite de tamanho
    final bool isFileTooLarge = file.size > PdfUploadService.maxPdfSizeBytes;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isFileTooLarge ? Colors.red.shade50 : Colors.grey.shade100,
      child: ListTile(
        leading: Icon(
          Icons.picture_as_pdf,
          color: isFileTooLarge ? Colors.red.shade700 : Colors.red,
        ),
        title: Text(
          file.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isFileTooLarge ? Colors.red.shade700 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pdfUploadService.formatFileSize(file.size),
              style: const TextStyle(fontSize: 12),
            ),
            if (isFileTooLarge)
              Text(
                'Arquivo muito grande! Recomendado: ${_pdfUploadService.formatFileSize(PdfUploadService.maxPdfSizeBytes)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close,
            color: _isUploading ? Colors.grey.shade400 : Colors.grey,
          ),
          onPressed: _isUploading ? null : () => widget.onRemoveFile(file),
        ),
      ),
    );
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    // Evitar múltiplos cliques
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await _pdfUploadService.pickPdfFiles(
        allowMultiple: true,
        onError: (errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );

          setState(() {
            _isUploading = false;
          });
        },
        onCancel: () {
          setState(() {
            _isUploading = false;
          });
        },
      );

      if (result != null) {
        // Converter PdfUploadResult para List<PlatformFile>
        final List<PlatformFile> platformFiles = [];

        for (int i = 0; i < result.fileNames.length; i++) {
          platformFiles.add(
            PlatformFile(
              name: result.fileNames[i],
              size: result.bytesList[i].length,
              path: result.filePaths[i],
              bytes: kIsWeb ? result.bytesList[i] : null,
            ),
          );
        }

        widget.onFilesSelected(platformFiles);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
