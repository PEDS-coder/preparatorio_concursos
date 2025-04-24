import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'features/4_study_plan/presentation/screens/plano_questionario_screen.dart';

class EditalUploadScreen extends StatefulWidget {
  const EditalUploadScreen({super.key});

  @override
  State<EditalUploadScreen> createState() => _EditalUploadScreenState();
}

class _EditalUploadScreenState extends State<EditalUploadScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  List<Map<String, String>> _resultados = [];
  int? _cargoSelecionado;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  Future<void> _analisarEditais() async {
    setState(() {
      _isLoading = true;
      _resultados.clear();
      _cargoSelecionado = null;
    });
    // Simulação: normalmente aqui você enviaria os arquivos para a LLM
    await Future.delayed(const Duration(seconds: 2));
    // Exemplo de resultado simulado
    setState(() {
      _resultados = [
        {
          'cargo': 'Analista Administrativo',
          'escolaridade': 'Nível Superior',
          'vagas': '10',
          'salario': 'R\$ 6.000,00',
          'materias': 'Português, Matemática, Informática, Direito Administrativo',
        },
        {
          'cargo': 'Técnico em TI',
          'escolaridade': 'Nível Médio',
          'vagas': '5',
          'salario': 'R\$ 3.200,00',
          'materias': 'Português, Informática, Redes de Computadores',
        },
      ];
      _isLoading = false;
    });
  }

  void _iniciarPreparacao(int idx) async {
    setState(() {
      _cargoSelecionado = idx;
    });
    // Simulação de extração avançada (normalmente aqui você faria a chamada à LLM)
    await Future.delayed(const Duration(seconds: 1));
    final cargo = _resultados[idx];
    // Converter as matérias para uma lista de strings
    final String materiasStr = cargo['materias'] ?? '';
    final List<String> materiasList = materiasStr.split(',').map((s) => s.trim()).toList();
    print('Matérias extraídas: $materiasList'); // Debug

    final dadosCargo = {
      ...cargo,
      'materias': materiasList,
    };
    final dadosEdital = {
      'nomeConcurso': 'Concurso Público Federal',
      'orgao': 'Órgão Exemplo',
      'banca': 'Banca Exemplo',
      'periodoInscricoes': '01/05/2025 a 25/05/2025',
      'dataProvas': '30/06/2025',
      'cotas': 'Ampla concorrência, PCD, Negros',
      'desempate': 'Idade, Maior nota em Português',
      'taxa': 'R\$ 120,00',
      'eliminacao': 'Nota mínima 50%',
      // ... outros campos simulados
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanoQuestionarioScreen(
          dadosCargo: dadosCargo,
          dadosEdital: dadosEdital,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13192b),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf43f7d),
        elevation: 0,
        title: const Text('Upload de Edital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Envie os editais em PDF para análise automática dos cargos e matérias',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22c55e),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                onPressed: _pickFiles,
                icon: const Icon(Icons.upload_file),
                label: const Text('Selecionar arquivos PDF'),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Selecionados: ${_selectedFiles.map((f) => f.name).join(", ")}',
                  style: const TextStyle(color: Color(0xFFf43f7d), fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf43f7d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _analisarEditais,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Analisar Editais'),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (_resultados.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cargos encontrados:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_resultados.length, (idx) {
                      final cargo = _resultados[idx];
                      return Card(
                        color: _cargoSelecionado == idx ? const Color(0xFFf43f7d).withOpacity(0.1) : const Color(0xFF1a2240),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(Icons.work, color: _cargoSelecionado == idx ? const Color(0xFFf43f7d) : Colors.white),
                          title: Text(
                            cargo['cargo'] ?? '',
                            style: TextStyle(
                              color: _cargoSelecionado == idx ? const Color(0xFFf43f7d) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Escolaridade: ${cargo['escolaridade']}', style: const TextStyle(color: Colors.white70)),
                              Text('Vagas: ${cargo['vagas']}', style: const TextStyle(color: Colors.white70)),
                              Text('Salário: ${cargo['salario']}', style: const TextStyle(color: Colors.white70)),
                              Text('Matérias: ${cargo['materias']}', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22c55e),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _iniciarPreparacao(idx),
                            child: const Text('Preparar'),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
