import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/logger_static.dart';
import '../../../../core/widgets/matrix_rain_animation.dart';
import '../../../4_study_plan/presentation/screens/plano_questionario_screen.dart';
import '../widgets/cargo_select/cargo_card_widget.dart';
import '../widgets/cargo_select/error_message_widget.dart';
import '../widgets/cargo_select/no_cargos_message_widget.dart';
import '../widgets/cargo_select/progress_indicator_widget.dart';
import '../../domain/services/cargo_selection_service.dart';

/// Tela de seleção de cargo para criação de plano de estudos
class CargoSelectScreen extends StatefulWidget {
  final String editalId;

  const CargoSelectScreen({
    Key? key,
    required this.editalId,
  }) : super(key: key);

  @override
  _CargoSelectScreenState createState() => _CargoSelectScreenState();
}

class _CargoSelectScreenState extends State<CargoSelectScreen> {
  // Estado da seleção de cargos
  final List<String> _cargosSelecionados = [];
  String? _lastSelectedCargo;
  bool _showPopupButtons = false;

  // Estado do carregamento
  bool _isLoading = false;
  double _progressValue = 0.0;
  String _progressMessage = '';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final editalService = Provider.of<EditalService>(context);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) {
      return _buildEditalNotFoundScreen();
    }

    // Mostrar tela de carregamento durante o processamento
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Cargo'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_cargosSelecionados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _navegarParaVisualizacaoEdital(edital),
              tooltip: 'Visualizar Edital',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            const Text(
              'Selecione seu Cargo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Escolha o cargo para o qual deseja se preparar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Instruções para seleção de cargo
            _buildInstructionsCard(),
            const SizedBox(height: 32),

            // Lista de cargos
            const Text(
              'Cargos Disponíveis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Verificar se há cargos disponíveis
            edital.dadosExtraidos.cargos.isEmpty
                ? const NoCargosMessageWidget()
                : Column(
                    children: [
                      // Construir lista de cargos
                      ...edital.dadosExtraidos.cargos.map((cargo) => _buildCargoCard(cargo, edital)).toList(),
                    ],
                  ),

            // Mensagem de erro
            if (_errorMessage != null)
              ErrorMessageWidget(errorMessage: _errorMessage!),

            // Indicador de progresso quando estiver carregando
            if (_isLoading)
              ProgressIndicatorWidget(
                progressValue: _progressValue,
                progressMessage: _progressMessage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditalNotFoundScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Cargo'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Edital não encontrado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('O edital solicitado não foi encontrado ou foi removido.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processando'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 8,
                color: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: MatrixRainAnimation(
                    width: 350,
                    height: 300,
                    primaryColor: AppTheme.primaryColor,
                    secondaryColor: AppTheme.accentColor,
                    message: 'Preparando Plano de Estudo',
                    statusMessages: [
                      'Verificando compatibilidade de datas...',
                      'Extraindo conteúdo programático do cargo...',
                      'Analisando matérias específicas do cargo...',
                      'Organizando assuntos por disciplina...',
                      'Preparando dados para o questionário...',
                      'Segunda chamada à API em andamento...',
                      _progressMessage,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selecione um ou mais cargos para os quais deseja se preparar. Após a seleção, você poderá ver o conteúdo programático detalhado e criar seu plano de estudos personalizado.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Cargo cargo, Edital edital) {
    // Usar o nome do cargo como identificador único para evitar problemas com IDs gerados dinamicamente
    final cargoIdentifier = cargo.nome;
    final isSelecionado = _cargosSelecionados.contains(cargo.id) || _cargosSelecionados.contains(cargoIdentifier);

    return CargoCardWidget(
      cargo: cargo,
      isSelecionado: isSelecionado,
      showPopupButtons: _showPopupButtons && _lastSelectedCargo == cargoIdentifier,
      isLoading: _isLoading,
      onTap: () => _handleCargoTap(cargo, cargoIdentifier),
      onCriarPlanoPressed: _continuarParaPlanoEstudo,
    );
  }

  void _handleCargoTap(Cargo cargo, String cargoIdentifier) {
    if (_cargosSelecionados.contains(cargo.id) || _cargosSelecionados.contains(cargoIdentifier)) {
      setState(() {
        _cargosSelecionados.remove(cargo.id);
        _cargosSelecionados.remove(cargoIdentifier);
        _showPopupButtons = false;
        _lastSelectedCargo = null;
      });
    } else {
      // Permitir apenas um cargo por vez
      setState(() {
        // Limpar seleções anteriores
        _cargosSelecionados.clear();
        // Adicionar apenas o cargo atual
        _cargosSelecionados.add(cargoIdentifier);
        _showPopupButtons = true;
        _lastSelectedCargo = cargoIdentifier;
      });
    }
  }

  void _navegarParaVisualizacaoEdital(Edital edital) {
    Navigator.pushNamed(
      context,
      '/edital/details',
      arguments: {
        'editalId': widget.editalId,
        'cargosSelecionados': _cargosSelecionados,
      },
    );
  }

  Future<void> _continuarParaPlanoEstudo() async {
    if (_cargosSelecionados.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos um cargo para continuar.';
      });
      return;
    }

    final editalService = Provider.of<EditalService>(context, listen: false);
    final edital = editalService.getEditalById(widget.editalId);

    if (edital == null) {
      setState(() {
        _errorMessage = 'Edital não encontrado.';
      });
      return;
    }

    // Encontrar o cargo selecionado
    Cargo? cargoSelecionado;
    for (var cargo in edital.dadosExtraidos.cargos) {
      if (cargo.nome == _cargosSelecionados.first || cargo.id == _cargosSelecionados.first) {
        cargoSelecionado = cargo;
        break;
      }
    }

    if (cargoSelecionado == null) {
      setState(() {
        _errorMessage = 'Cargo selecionado não encontrado.';
      });
      return;
    }

    // Iniciar o processo de carregamento
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progressValue = 0.1;
      _progressMessage = 'Iniciando análise do cargo...';
    });

    try {
      // Realizar a segunda chamada à API para obter informações detalhadas do cargo
      final bool sucesso = await CargoSelectionService.realizarSegundaChamadaAPI(
        context: context,
        edital: edital,
        cargo: cargoSelecionado,
        onProgress: (message, progress) {
          setState(() {
            _progressMessage = message;
            _progressValue = progress;
          });
        },
      );

      if (!sucesso) {
        throw Exception('Falha ao processar os dados do cargo');
      }

      // Preparar dados para a tela de questionário
      final Map<String, dynamic> dadosEdital = {
        'id': edital.id,
        'titulo': edital.nomeConcurso,
        'orgao': edital.dadosExtraidos.orgao ?? 'Não informado',
        'banca': edital.dadosExtraidos.banca ?? 'Não informado',
      };

      // Obter o cargo atualizado
      final editalAtualizado = editalService.getEditalById(widget.editalId);
      if (editalAtualizado == null) {
        throw Exception('Edital não encontrado após atualização');
      }

      // Encontrar o cargo atualizado
      Cargo? cargoAtualizado;
      for (var cargo in editalAtualizado.dadosExtraidos.cargos) {
        if (cargo.nome == _cargosSelecionados.first || cargo.id == _cargosSelecionados.first) {
          cargoAtualizado = cargo;
          break;
        }
      }

      if (cargoAtualizado == null) {
        throw Exception('Cargo não encontrado após atualização');
      }

      // Preparar dados do cargo
      final Map<String, dynamic> dadosCargo = {
        'cargo': cargoAtualizado.nome,
        'materias': cargoAtualizado.conteudoProgramatico.map((m) => m.nome).toList(),
      };

      // Navegar para a tela de questionário
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanoQuestionarioScreen(
            dadosEdital: dadosEdital,
            dadosCargo: dadosCargo,
          ),
        ),
      );
    } catch (e) {
      Logger.error('Erro ao continuar para plano de estudo: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao processar o cargo: ${e.toString()}';
      });
    }
  }
}
