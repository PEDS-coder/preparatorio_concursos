import 'package:flutter/material.dart';
import 'edital_upload_screen.dart';
import 'dart:io';

class ApiConfigScreen extends StatefulWidget {
  final void Function(String apiKey)? onApiKeyValidated;
  const ApiConfigScreen({super.key, this.onApiKeyValidated});

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  Future<void> _validateApiKey() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final apiKey = _controller.text.trim();
    // Simulação de validação (substitua por chamada real à API Gemini)
    await Future.delayed(const Duration(seconds: 1));
    if (apiKey.startsWith('AI') && apiKey.length > 10) {
      if (widget.onApiKeyValidated != null) {
        widget.onApiKeyValidated!(apiKey);
      } else {
        // Navega para a tela de upload de edital
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditalUploadScreen()),
        );
      }
    } else {
      setState(() {
        _errorText = 'Chave inválida. Verifique e tente novamente.';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showApiHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a2240),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Como obter sua chave Gemini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Acesse o Google AI Studio: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: () {
                  // Não abre link diretamente, apenas mostra para o usuário
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abra o link no navegador: https://aistudio.google.com/app/apikey'),
                    ),
                  );
                },
                child: const Text(
                  'https://aistudio.google.com/app/apikey',
                  style: TextStyle(color: Color(0xFFf43f7d), decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 12),
              const Text('2. Faça login com sua conta Google.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              const Text('3. Clique em "Create API Key" e copie a chave gerada.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              const Text('4. Cole a chave no campo acima para usar o app gratuitamente.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFf43f7d)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A chave Gemini do AI Studio é gratuita para uso pessoal e educacional.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFf43f7d)),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13192b),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf43f7d),
        elevation: 0,
        title: const Text('Configurar API Gemini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Configuração da API Gemini',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Insira sua chave de API Gemini para utilizar a análise inteligente de editais.',
                style: TextStyle(color: Color(0xFFf43f7d), fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFf43f7d)),
                onPressed: _showApiHelpDialog,
                icon: const Icon(Icons.help_outline),
                label: const Text('Como obter uma chave gratuita?'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Chave da API Gemini',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1a2240),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFf43f7d)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFf43f7d), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: _errorText,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
                obscureText: false,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf43f7d),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _validateApiKey,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Validar e Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
