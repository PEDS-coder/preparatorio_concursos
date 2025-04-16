import 'package:flutter/material.dart';
import '../../../core/config/mcp_config.dart';
import '../../../core/utils/app_logger.dart';

/// Tela de configurações do protocolo MCP
class McpSettingsScreen extends StatefulWidget {
  const McpSettingsScreen({Key? key}) : super(key: key);

  @override
  _McpSettingsScreenState createState() => _McpSettingsScreenState();
}

class _McpSettingsScreenState extends State<McpSettingsScreen> {
  static const String _tag = 'McpSettingsScreen';
  bool _isMcpEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Carrega as configurações do MCP
  Future<void> _loadSettings() async {
    try {
      final enabled = await McpConfig.isMcpEnabled();
      setState(() {
        _isMcpEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao carregar configurações', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Salva as configurações do MCP
  Future<void> _saveSettings(bool value) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await McpConfig.setMcpEnabled(value);

      setState(() {
        _isMcpEnabled = value;
        _isLoading = false;
      });

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Protocolo MCP ${value ? 'ativado' : 'desativado'} com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e(_tag, 'Erro ao salvar configurações', e);
      setState(() {
        _isLoading = false;
      });

      // Mostrar mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações do Protocolo MCP'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações sobre o MCP
                  const Card(
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'O que é o Protocolo MCP?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'O Model Context Protocol (MCP) é um protocolo aberto que melhora a comunicação entre aplicativos e modelos de linguagem (LLMs). Ele permite que o aplicativo forneça contexto estruturado, ferramentas e recursos para o modelo, resultando em respostas mais precisas e úteis.',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Benefícios:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Melhor compreensão do contexto\n'
                            '• Respostas mais precisas\n'
                            '• Menor uso de tokens\n'
                            '• Comunicação mais eficiente\n'
                            '• Redução de erros de conexão',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Switch para ativar/desativar o MCP
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ativar Protocolo MCP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isMcpEnabled,
                            onChanged: (value) => _saveSettings(value),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Nota sobre reinicialização
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nota: A alteração desta configuração será aplicada na próxima vez que você usar o serviço de IA.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
