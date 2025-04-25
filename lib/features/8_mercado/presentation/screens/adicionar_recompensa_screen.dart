import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/mercado_service.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/styled_text_field.dart';

class AdicionarRecompensaScreen extends StatefulWidget {
  const AdicionarRecompensaScreen({super.key});

  @override
  _AdicionarRecompensaScreenState createState() => _AdicionarRecompensaScreenState();
}

class _AdicionarRecompensaScreenState extends State<AdicionarRecompensaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _custoController = TextEditingController();

  String _categoriaSelected = 'pequena';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _atualizarCustoSugerido();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _custoController.dispose();
    super.dispose();
  }

  void _atualizarCustoSugerido() {
    final custoSugerido = _getCustoSugerido(_categoriaSelected);
    _custoController.text = custoSugerido.toString();
  }

  int _getCustoSugerido(String categoria) {
    switch (categoria) {
      case 'pequena':
        return 250; // Média entre 150 e 400
      case 'media':
        return 1000; // Média entre 500 e 1500
      case 'grande':
        return 3000; // Média entre 2000 e 5000
      default:
        return 500;
    }
  }

  Future<void> _salvarRecompensa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mercadoService = Provider.of<MercadoService>(context, listen: false);

      await mercadoService.adicionarRecompensa(
        _tituloController.text,
        _descricaoController.text,
        _categoriaSelected,
        int.tryParse(_custoController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recompensa adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao adicionar recompensa: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Recompensa'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nova Recompensa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie uma recompensa personalizada para trocar por moedas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Título',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              StyledTextField(
                controller: _tituloController,
                hintText: 'Ex: Assistir um episódio de série',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              const Text(
                'Descrição (opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              StyledTextField(
                controller: _descricaoController,
                hintText: 'Ex: 30 minutos de pausa para assistir minha série favorita',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Categoria
              const Text(
                'Categoria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoriaSelector(),
              const SizedBox(height: 24),

              // Custo em moedas
              const Text(
                'Custo em Moedas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              StyledTextField(
                controller: _custoController,
                hintText: 'Ex: 250',
                prefixIcon: Icons.monetization_on,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um custo';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor, insira um número válido';
                  }
                  if (int.parse(value) <= 0) {
                    return 'O custo deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Dica: O custo sugerido é baseado na categoria selecionada',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Mensagem de erro
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botão de salvar
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GradientButton(
                      onPressed: _salvarRecompensa,
                      fullWidth: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text('SALVAR RECOMPENSA'),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCategoriaOption(
              'pequena',
              'Pequena',
              'Pausas curtas, lanches, música (150-400 moedas)',
              Icons.coffee,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildCategoriaOption(
              'media',
              'Média',
              'Filmes, jogos, compras pequenas (500-1500 moedas)',
              Icons.movie,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildCategoriaOption(
              'grande',
              'Grande',
              'Dia de folga, compras maiores, eventos (2000-5000 moedas)',
              Icons.celebration,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _categoriaSelected == value;

    return InkWell(
      onTap: () {
        setState(() {
          _categoriaSelected = value;
          _atualizarCustoSugerido();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _categoriaSelected,
              onChanged: (newValue) {
                setState(() {
                  _categoriaSelected = newValue!;
                  _atualizarCustoSugerido();
                });
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
