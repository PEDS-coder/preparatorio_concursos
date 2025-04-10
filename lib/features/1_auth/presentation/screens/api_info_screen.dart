import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';

class ApiInfoScreen extends StatelessWidget {
  final String title;
  final String content;

  const ApiInfoScreen({
    Key? key,
    required this.title,
    required this.content,
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
            title: Text('Abrir URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Por favor, copie e abra o seguinte URL no seu navegador:'),
                SizedBox(height: 12),
                SelectableText(url, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fechar'),
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
          decoration: BoxDecoration(
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
        padding: EdgeInsets.all(24),
        child: _buildMarkdownContent(context),
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context) {
    // Implementação simples de renderização de markdown
    // Em uma implementação real, usaríamos um pacote como flutter_markdown
    
    final lines = content.split('\n');
    List<Widget> widgets = [];
    
    for (var line in lines) {
      if (line.startsWith('# ')) {
        // Título principal
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Text(
              line.substring(2),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // Subtítulo
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
            child: Text(
              line.substring(3),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        // Sub-subtítulo
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
            child: Text(
              line.substring(4),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        // Item de lista
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('1. ') || line.startsWith('2. ') || line.startsWith('3. ') || 
                 line.startsWith('4. ') || line.startsWith('5. ') || line.startsWith('6. ') || 
                 line.startsWith('7. ') || line.startsWith('8. ') || line.startsWith('9. ')) {
        // Item de lista numerada
        final number = line.substring(0, line.indexOf('. ') + 2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    line.substring(number.length),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('```')) {
        // Código
        // Ignorar a primeira linha com ```
        continue;
      } else if (line.endsWith('```')) {
        // Fim do código
        // Ignorar a última linha com ```
        continue;
      } else if (line.contains('[') && line.contains('](')) {
        // Link
        final text = line.substring(line.indexOf('[') + 1, line.indexOf(']'));
        final url = line.substring(line.indexOf('](') + 2, line.indexOf(')', line.indexOf('](') + 2));
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: GestureDetector(
              onTap: () => _launchUrl(context, url),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        // Linha em branco
        widgets.add(SizedBox(height: 8));
      } else {
        // Texto normal
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              line,
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    }
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
