import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/api_response_logger.dart';

/// Tela para visualizar as respostas da API salvas
class ApiResponsesScreen extends StatefulWidget {
  const ApiResponsesScreen({Key? key}) : super(key: key);

  @override
  State<ApiResponsesScreen> createState() => _ApiResponsesScreenState();
}

class _ApiResponsesScreenState extends State<ApiResponsesScreen> with SingleTickerProviderStateMixin {
  final ApiResponseLogger _apiResponseLogger = ApiResponseLogger();
  List<FileSystemEntity> _respostas = [];
  String? _diretorioRespostas;
  bool _isLoading = true;
  String? _selectedResponsePath;
  String _selectedResponseContent = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarRespostas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega as respostas salvas
  Future<void> _carregarRespostas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obter o diretório de respostas
      _diretorioRespostas = await _apiResponseLogger.obterCaminhoDiretorioRespostas();
      
      // Carregar as respostas
      _respostas = await _apiResponseLogger.listarRespostas();
      
      // Ordenar as respostas por data (mais recentes primeiro)
      _respostas.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });
    } catch (e) {
      debugPrint('Erro ao carregar respostas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Carrega o conteúdo de uma resposta
  Future<void> _carregarConteudoResposta(String path) async {
    setState(() {
      _isLoading = true;
      _selectedResponsePath = path;
      _selectedResponseContent = '';
    });

    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _selectedResponseContent = content;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar conteúdo da resposta: $e');
      setState(() {
        _selectedResponseContent = 'Erro ao carregar conteúdo: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Formata o nome do arquivo para exibição
  String _formatarNomeArquivo(String path) {
    final fileName = path.split(Platform.isWindows ? '\\' : '/').last;
    return fileName;
  }

  /// Formata a data de modificação do arquivo
  String _formatarDataModificacao(FileSystemEntity file) {
    final stat = file.statSync();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    return dateFormat.format(stat.modified);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Respostas da API'),
        ),
        body: const Center(
          child: Text('Esta funcionalidade não está disponível na versão web.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Respostas da API'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Segunda Chamada'),
            Tab(text: 'Primeira Chamada'),
            Tab(text: 'Outras Respostas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRespostasTab('segunda_chamada'),
          _buildRespostasTab('primeira_chamada'),
          _buildRespostasTab('outras'),
        ],
      ),
    );
  }

  /// Constrói a tab de respostas
  Widget _buildRespostasTab(String tipo) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_respostas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhuma resposta encontrada.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarRespostas,
              child: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    // Filtrar as respostas pelo tipo
    final respostasFiltradas = _respostas.where((resposta) {
      final path = resposta.path;
      switch (tipo) {
        case 'segunda_chamada':
          return path.contains('segunda_chamada');
        case 'primeira_chamada':
          return path.contains('primeira_chamada');
        case 'outras':
          return !path.contains('segunda_chamada') && !path.contains('primeira_chamada');
        default:
          return true;
      }
    }).toList();

    if (respostasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Nenhuma resposta do tipo "$tipo" encontrada.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarRespostas,
              child: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Lista de respostas
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: respostasFiltradas.length,
            itemBuilder: (context, index) {
              final resposta = respostasFiltradas[index];
              final isSelected = _selectedResponsePath == resposta.path;
              
              return ListTile(
                title: Text(_formatarNomeArquivo(resposta.path)),
                subtitle: Text(_formatarDataModificacao(resposta)),
                selected: isSelected,
                onTap: () => _carregarConteudoResposta(resposta.path),
              );
            },
          ),
        ),
        
        // Conteúdo da resposta selecionada
        Expanded(
          flex: 2,
          child: _selectedResponsePath == null
              ? const Center(
                  child: Text('Selecione uma resposta para visualizar seu conteúdo.'),
                )
              : _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatarNomeArquivo(_selectedResponsePath!),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: SelectableText(_selectedResponseContent),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}
