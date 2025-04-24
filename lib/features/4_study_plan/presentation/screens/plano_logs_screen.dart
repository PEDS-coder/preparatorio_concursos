import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/plano_data_logger.dart';

class PlanoLogsScreen extends StatefulWidget {
  final String planoId;

  const PlanoLogsScreen({Key? key, required this.planoId}) : super(key: key);

  @override
  _PlanoLogsScreenState createState() => _PlanoLogsScreenState();
}

class _PlanoLogsScreenState extends State<PlanoLogsScreen> {
  String _logs = '';
  bool _isLoading = true;
  final PlanoDataLogger _logger = PlanoDataLogger();

  @override
  void initState() {
    super.initState();
    _carregarLogs();
  }

  Future<void> _carregarLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _logger.getLogs();
      
      // Filtrar logs apenas para o plano atual
      final List<String> linhas = logs.split('\n');
      final List<String> logsFiltrados = linhas.where((linha) => 
        linha.contains(widget.planoId) || 
        !linha.contains('Plano:') // Incluir linhas que não são específicas de um plano
      ).toList();
      
      setState(() {
        _logs = logsFiltrados.join('\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logs = 'Erro ao carregar logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportarLogs() async {
    try {
      final path = await _logger.exportLogs();
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logs exportados para: $path')),
        );
        
        // Compartilhar o arquivo
        await Share.shareFiles([path], text: 'Logs do Plano de Estudos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar logs: $e')),
      );
    }
  }

  Future<void> _copiarLogs() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logs copiados para a área de transferência')),
    );
  }

  Future<void> _limparLogs() async {
    try {
      await _logger.clearLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logs limpos com sucesso')),
      );
      _carregarLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao limpar logs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs do Plano'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarLogs,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _copiarLogs,
            tooltip: 'Copiar',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _exportarLogs,
            tooltip: 'Exportar',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _limparLogs,
            tooltip: 'Limpar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logs do Plano ID: ${widget.planoId}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _logs.isEmpty ? 'Nenhum log encontrado' : _logs,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
