import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:preparatorio_concursos/core/data/services/gemini_service.dart';
import 'package:preparatorio_concursos/core/utils/logger_adapter.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final GeminiService _geminiService = GeminiService();
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _configureApiKey();
  }

  Future<void> _configureApiKey() async {
    await _geminiService.setApiKey('YOUR_API_KEY', 'gemini');
  }

  Future<void> _testProcessarPdf() async {
    setState(() {
      _isLoading = true;
      _result = 'Processando PDF...';
    });

    try {
      // Caminho para um arquivo PDF de teste
      final File file = File('test.pdf');
      if (!file.existsSync()) {
        setState(() {
          _isLoading = false;
          _result = 'Arquivo PDF não encontrado';
        });
        return;
      }

      final Uint8List pdfBytes = await file.readAsBytes();
      const String prompt = 'Extraia o conteúdo deste PDF';

      final String result = await _geminiService.processarPdf(prompt, pdfBytes);

      setState(() {
        _isLoading = false;
        _result = 'Resultado: $result';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isLoading ? null : _testProcessarPdf,
              child: const Text('Testar processarPdf'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _result,
                    style: const TextStyle(fontSize: 16),
                  ),
          ],
        ),
      ),
    );
  }
}
