import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget que representa a área de upload de arquivos PDF
class EditalUploadAreaWidget extends StatelessWidget {
  final List<String> pdfFileNames;
  final bool isProcessingPdf;
  final bool isAnalyzingEdital;
  final double pdfProcessingProgress;
  final String progressMessage;
  final VoidCallback onSelectFiles;
  final VoidCallback onAnalyzeWithAI;

  const EditalUploadAreaWidget({
    Key? key,
    required this.pdfFileNames,
    required this.isProcessingPdf,
    required this.isAnalyzingEdital,
    required this.pdfProcessingProgress,
    required this.progressMessage,
    required this.onSelectFiles,
    required this.onAnalyzeWithAI,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildFilesList(),
          SizedBox(height: 24),
          _buildSelectFilesButton(),
          SizedBox(height: 24),
          _buildAnalyzeButton(),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    if (pdfFileNames.isEmpty) {
      return Text(
        'Selecione os arquivos PDF do edital',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        Text(
          '${pdfFileNames.length} arquivo(s) selecionado(s):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Container(
          height: pdfFileNames.length > 3 ? 100 : null,
          decoration: pdfFileNames.length > 3 ? BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ) : null,
          child: pdfFileNames.length > 3
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: pdfFileNames.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(pdfFileNames[index], style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  );
                },
              )
            : Column(
                children: pdfFileNames.map((fileName) => Padding(
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
    );
  }

  Widget _buildSelectFilesButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.file_upload),
      label: Text('Selecionar Arquivos'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: isProcessingPdf || isAnalyzingEdital ? null : onSelectFiles,
    );
  }

  Widget _buildAnalyzeButton() {
    if (pdfFileNames.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
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
            onPressed: isProcessingPdf || isAnalyzingEdital ? null : onAnalyzeWithAI,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (!isProcessingPdf) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: 24),
        LinearProgressIndicator(value: pdfProcessingProgress),
        SizedBox(height: 8),
        Text(
          '${(pdfProcessingProgress * 100).toStringAsFixed(0)}% - $progressMessage',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
