import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

class ApiInfoScreen extends StatelessWidget {
  final String title;
  final String content;
  final List<String>? imageAssets;

  const ApiInfoScreen({
    Key? key,
    required this.title,
    required this.content,
    this.imageAssets,
  }) : super(key: key);

  void _launchUrl(BuildContext context, String url) {
    try {
      // Usar abordagem alternativa sem o plugin url_launcher
      if (url.startsWith('http')) {
        // Mostrar mensagem para o usuário
        print('Por favor, abra o seguinte URL no seu navegador: $url');

        // Mostrar diálogo com o URL
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Abrir URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Por favor, copie e abra o seguinte URL no seu navegador:'),
                const SizedBox(height: 12),
                SelectableText(url, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Erro ao tentar abrir URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gradientStart,
                AppTheme.gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarkdownContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context) {
    // Implementação simples de renderização de markdown
    // Em uma implementação real, usaríamos um pacote como flutter_markdown

    final lines = content.split('\n');
    List<Widget> widgets = [];

    // Primeiro, processar o texto
    for (var line in lines) {
      if (line.trim().isEmpty) {
        // Linha em branco
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Texto normal
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            line,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Adicionar espaço entre o texto e as imagens
    widgets.add(const SizedBox(height: 16));

    // Depois, adicionar imagens se fornecidas
    if (imageAssets != null && imageAssets!.isNotEmpty) {
      for (var i = 0; i < imageAssets!.length; i++) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i > 0) const SizedBox(height: 8),
                Text(
                  'Passo ${i + 1}:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageAssets![i],
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
