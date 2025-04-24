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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload do Edital',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Selecione o arquivo PDF do edital para análise',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 16),
            _buildUploadButton(context),
            SizedBox(height: 16),
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
        icon: Icon(Icons.upload_file),
        label: Text('Selecionar Arquivo PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            Text(
              'Arquivos Selecionados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: onRemoveAllFiles,
              icon: Icon(Icons.delete, size: 16, color: Colors.red),
              label: Text(
                'Remover Todos',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...selectedFiles.map((file) => _buildFileItem(file)).toList(),
      ],
    );
  }

  Widget _buildFileItem(PlatformFile file) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade100,
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(
          file.name,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${(file.size / 1024).toStringAsFixed(2)} KB',
          style: TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.grey),
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
