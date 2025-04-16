import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/document_storage_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/widgets/modern_card.dart';

class StoredFilesWidget extends StatelessWidget {
  final String toolType;
  final String title;
  final bool showUploaded;
  final bool showGenerated;
  final Function(String content)? onFileSelected;

  const StoredFilesWidget({
    Key? key,
    required this.toolType,
    required this.title,
    this.showUploaded = true,
    this.showGenerated = true,
    this.onFileSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storageService = Provider.of<DocumentStorageService>(context);
    final userId = authService.currentUser?.id ?? '';

    final uploadedDocs = showUploaded
        ? storageService.getUploadedDocumentsByTool(userId, toolType)
        : [];
    final generatedFiles = showGenerated
        ? storageService.getGeneratedFilesByTool(userId, toolType)
        : [];

    return ModernCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            if (showUploaded && uploadedDocs.isNotEmpty) ...[
              Text(
                'Documentos Enviados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: uploadedDocs.length,
                itemBuilder: (context, index) {
                  final doc = uploadedDocs[index];
                  return _buildFileItem(
                    context,
                    doc.fileName,
                    _formatDate(doc.uploadDate),
                    doc.fileType,
                    () async {
                      // Carregar conteúdo do documento
                      final content = await storageService.getUploadedDocumentContent(doc.id);
                      if (content != null && onFileSelected != null) {
                        onFileSelected!(content);
                      }
                    },
                    () async {
                      // Download do documento
                      final bytes = await storageService.getUploadedDocumentBytes(doc.id);
                      if (bytes != null) {
                        _downloadFile(context, doc.fileName, bytes);
                      }
                    },
                    () async {
                      // Excluir documento
                      final confirmed = await _confirmDelete(context, 'documento');
                      if (confirmed) {
                        await storageService.deleteUploadedDocument(doc.id);
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 16),
            ],
            if (showGenerated && generatedFiles.isNotEmpty) ...[
              Text(
                'Arquivos Gerados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: generatedFiles.length,
                itemBuilder: (context, index) {
                  final file = generatedFiles[index];
                  return _buildFileItem(
                    context,
                    file.fileName,
                    _formatDate(file.generationDate),
                    file.fileType,
                    () {
                      // Visualizar conteúdo
                      if (onFileSelected != null) {
                        onFileSelected!(file.content);
                      }
                    },
                    () async {
                      // Download do arquivo
                      final bytes = await storageService.getGeneratedFileBytes(file.id);
                      if (bytes != null) {
                        _downloadFile(context, file.fileName, bytes);
                      }
                    },
                    () async {
                      // Excluir arquivo
                      final confirmed = await _confirmDelete(context, 'arquivo');
                      if (confirmed) {
                        await storageService.deleteGeneratedFile(file.id);
                      }
                    },
                  );
                },
              ),
            ],
            if ((showUploaded && uploadedDocs.isEmpty) &&
                (showGenerated && generatedFiles.isEmpty))
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Nenhum arquivo encontrado',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    String name,
    String date,
    String type,
    VoidCallback onTap,
    VoidCallback onDownload,
    VoidCallback onDelete,
  ) {
    IconData typeIcon;
    switch (type.toLowerCase()) {
      case 'pdf':
        typeIcon = Icons.picture_as_pdf;
        break;
      case 'docx':
        typeIcon = Icons.description;
        break;
      case 'txt':
        typeIcon = Icons.text_snippet;
        break;
      case 'html':
        typeIcon = Icons.code;
        break;
      case 'md':
        typeIcon = Icons.article;
        break;
      default:
        typeIcon = Icons.insert_drive_file;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: AppTheme.darkSurface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(typeIcon, color: Colors.white70),
        title: Text(
          name,
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          date,
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download, color: Colors.white70),
              tooltip: 'Download',
              onPressed: onDownload,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white70),
              tooltip: 'Excluir',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(date);
  }

  Future<bool> _confirmDelete(BuildContext context, String itemType) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmar exclusão'),
            content: Text('Tem certeza que deseja excluir este $itemType?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('EXCLUIR'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _downloadFile(BuildContext context, String fileName, List<int> bytes) {
    // Implementação de download específica para cada plataforma
    // No web, isso pode ser feito com o pacote universal_html
    // Em plataformas nativas, pode ser feito com o pacote path_provider e share_plus

    // Por enquanto, apenas mostrar um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download de "$fileName" iniciado'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
