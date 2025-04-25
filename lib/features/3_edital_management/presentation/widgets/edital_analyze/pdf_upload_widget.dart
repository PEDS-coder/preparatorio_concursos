import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para upload de arquivos PDF
class PdfUploadWidget extends StatelessWidget {
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
            const SizedBox(height: 16),
            _buildUploadButton(context),
            const SizedBox(height: 16),
            if (selectedFiles.isNotEmpty) _buildSelectedFilesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _pickPdfFile(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Selecionar Arquivo PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              onPressed: onRemoveAllFiles,
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              label: const Text(
                'Remover Todos',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...selectedFiles.map((file) => _buildFileItem(file)).toList(),
      ],
    );
  }

  Widget _buildFileItem(PlatformFile file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade100,
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${(file.size / 1024).toStringAsFixed(2)} KB',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => onRemoveFile(file),
        ),
      ),
    );
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        onFilesSelected(result.files);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
