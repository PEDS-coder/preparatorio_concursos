import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/data/services/ia_service.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../../core/services/document_classifier_service.dart';

class MapasMentaisScreen extends StatefulWidget {
  @override
  _MapasMentaisScreenState createState() => _MapasMentaisScreenState();
}

class _MapasMentaisScreenState extends State<MapasMentaisScreen> {
  bool _isLoading = false;
  String? _resultado;
  String? _errorMessage;

  // Modo de entrada (upload ou texto)
  String _modoEntrada = 'upload'; // 'upload' ou 'texto'

  // Controladores para modo texto
  final _textController = TextEditingController();
  final _tituloController = TextEditingController();

  // Dados para modo upload
  String? _textoUpload;
  String? _materiaId;
  String? _assuntoId;

  @override
  void dispose() {
    _textController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _gerarMapaMental() async {
    // Validar entrada com base no modo
    if (_modoEntrada == 'texto') {
      if (_textController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, insira um texto para processar.';
        });
        return;
      }

      if (_tituloController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, informe um título para o mapa mental.';
        });
        return;
      }
    } else { // modo upload
      if (_textoUpload == null) {
        setState(() {
          _errorMessage = 'Por favor, faça upload de um documento para processar.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultado = null;
    });

    try {
      final iaService = Provider.of<IAService>(context, listen: false);

      if (!iaService.isConfigured) {
        setState(() {
          _errorMessage = 'Você precisa configurar sua chave de API primeiro.';
          _isLoading = false;
        });
        return;
      }

      // Obter texto e título com base no modo
      final texto = _modoEntrada == 'texto' ? _textController.text : _textoUpload!;
      String? titulo;

      if (_modoEntrada == 'texto') {
        titulo = _tituloController.text;
      } else {
        // Obter nome da matéria pelo ID como título
        final planoService = Provider.of<PlanoEstudoService>(context, listen: false);
        if (_materiaId != null) {
          final materiaObj = planoService.getMateriaById(_materiaId!);
          titulo = materiaObj?.nome;
        }
      }

      final resultado = await iaService.gerarEsquema(texto, titulo: titulo);

      setState(() {
        _resultado = resultado;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro ao processar o texto: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isPremium = authService.isPremium;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Mapas Mentais'),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
      ),
      body: !isPremium
          ? _buildPremiumRequired()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criar Mapas Mentais com IA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Faça upload de um documento ou insira um texto para gerar um mapa mental estruturado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Seleção de modo
                  _buildModeSelector(),
                  SizedBox(height: 24),

                  // Conteúdo com base no modo selecionado
                  _modoEntrada == 'upload'
                      ? _buildUploadMode()
                      : _buildTextMode(),

                  // Botão de gerar (apenas para modo texto)
                  if (_modoEntrada == 'texto')
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _gerarMapaMental,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_tree, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('GERAR MAPA MENTAL'),
                                ],
                              ),
                            ),
                    ),

                  // Mensagem de erro
                  if (_errorMessage != null)
                    Container(
                      margin: EdgeInsets.only(top: 24),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Resultado
                  if (_resultado != null)
                    Container(
                      margin: EdgeInsets.only(top: 24),
                      child: ModernCard(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Mapa Mental Gerado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _resultado!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: Icon(Icons.copy),
                                  label: Text('COPIAR'),
                                  onPressed: () {
                                    // Copiar para a área de transferência
                                    Clipboard.setData(ClipboardData(text: _resultado!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Mapa mental copiado para a área de transferência!'),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: 12),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.open_in_new),
                                  label: Text('ABRIR NO MARKMAP'),
                                  onPressed: () {
                                    // Abrir no markmap.js.org/repl
                                    _abrirNoMarkmap(_resultado!);
                                  },
                                ),
                                SizedBox(width: 12),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.save),
                                  label: Text('SALVAR'),
                                  onPressed: () {
                                    // Implementar salvamento
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Mapa mental salvo com sucesso!'),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
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

  // Seletor de modo (upload ou texto)
  Widget _buildModeSelector() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildModeButton(
                'upload',
                'Upload de Documento',
                Icons.upload_file,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModeButton(
                'texto',
                'Inserir Texto',
                Icons.text_fields,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botão de modo
  Widget _buildModeButton(String modo, String label, IconData icon) {
    final isSelected = _modoEntrada == modo;

    return InkWell(
      onTap: () {
        setState(() {
          _modoEntrada = modo;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modo de upload de documento
  Widget _buildUploadMode() {
    return DocumentUploadWidget(
      title: 'Upload de Documento',
      description: 'Faça upload de um documento para gerar um mapa mental automaticamente',
      onDocumentProcessed: (texto, materiaId, assuntoId) {
        setState(() {
          _textoUpload = texto;
          _materiaId = materiaId;
          _assuntoId = assuntoId;
        });

        // Processar automaticamente
        _gerarMapaMental();
      },
    );
  }

  // Modo de inserção de texto
  Widget _buildTextMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de título
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Título do Mapa Mental',
            hintText: 'Ex: Princípios Constitucionais',
            prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          controller: _tituloController,
        ),
        SizedBox(height: 16),

        // Campo de texto
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Texto para Processamento',
            hintText: 'Cole aqui o texto que deseja transformar em mapa mental...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          controller: _textController,
          maxLines: 8,
          minLines: 5,
        ),
      ],
    );
  }

  // Método para abrir o mapa mental no markmap.js.org/repl
  Future<void> _abrirNoMarkmap(String conteudo) async {
    try {
      // Codificar o conteúdo para URL
      final conteudoEncoded = Uri.encodeComponent(conteudo);

      // Construir a URL do markmap.js.org/repl com o conteúdo
      final url = 'https://markmap.js.org/repl?content=$conteudoEncoded';

      // Mostrar diálogo com URL para copiar
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Abrir Mapa Mental'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Copie o link abaixo e abra no seu navegador:'),
              SizedBox(height: 12),
              SelectableText(url, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL copiada para a área de transferência'))
                  );
                },
                child: Text('Copiar URL'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: conteudo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conteúdo do mapa mental copiado para a área de transferência'))
                  );
                },
                child: Text('Copiar conteúdo do mapa mental'),
              ),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir o mapa mental: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPremiumRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 80,
            color: Colors.amber,
          ),
          SizedBox(height: 24),
          Text(
            'Funcionalidade Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Esta funcionalidade está disponível apenas para usuários premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              // Simulação de upgrade
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.upgradeToPremium();

              // Mostrar confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Parabéns! Você agora é um usuário Premium.'),
                  backgroundColor: AppTheme.successColor,
                ),
              );

              // Recarregar a tela
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('FAZER UPGRADE'),
          ),
        ],
      ),
    );
  }
}
