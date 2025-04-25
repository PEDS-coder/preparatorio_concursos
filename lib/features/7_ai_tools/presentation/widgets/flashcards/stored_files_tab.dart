import 'package:flutter/material.dart';
import '../../widgets/stored_files_widget.dart';
import '../../../../../core/data/services/document_storage_service.dart';

/// Widget para a aba de arquivos armazenados
class StoredFilesTab extends StatelessWidget {
  final String title;
  final String description;
  final bool showUploaded;
  final bool showGenerated;
  final Function(String) onFileSelected;

  const StoredFilesTab({
    Key? key,
    required this.title,
    required this.description,
    required this.showUploaded,
    required this.showGenerated,
    required this.onFileSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          StoredFilesWidget(
            toolType: DocumentStorageService.FLASHCARDS,
            title: showUploaded ? 'Seus Documentos' : 'Seus Flashcards',
            showUploaded: showUploaded,
            showGenerated: showGenerated,
            onFileSelected: onFileSelected,
          ),
        ],
      ),
    );
  }
}
