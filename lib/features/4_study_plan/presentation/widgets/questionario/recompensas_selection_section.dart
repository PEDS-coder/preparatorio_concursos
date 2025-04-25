import 'package:flutter/material.dart';
import '../../../../../core/data/models/models.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para seleção de recompensas
class RecompensasSelectionSection extends StatelessWidget {
  final List<RecompensaConfig> recompensas;
  final Function(List<RecompensaConfig>) onRecompensasChanged;

  const RecompensasSelectionSection({
    Key? key,
    required this.recompensas,
    required this.onRecompensasChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recompensas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure recompensas para manter sua motivação. Cada 1 hora de estudo rende 20 Moedas.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecompensasList(context),
        const SizedBox(height: 16),
        _buildAddRecompensaButton(context),
      ],
    );
  }

  Widget _buildRecompensasList(BuildContext context) {
    if (recompensas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a2240),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a3050)),
        ),
        child: const Center(
          child: Text(
            'Nenhuma recompensa configurada',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Agrupar recompensas por tipo
    final Map<String, List<RecompensaConfig>> recompensasPorTipo = {};
    for (var recompensa in recompensas) {
      if (!recompensasPorTipo.containsKey(recompensa.tipoRecompensa)) {
        recompensasPorTipo[recompensa.tipoRecompensa] = [];
      }
      recompensasPorTipo[recompensa.tipoRecompensa]!.add(recompensa);
    }

    // Ordem dos tipos de recompensa
    final tiposOrdenados = [
      'bronze',
      'prata',
      'ouro',
      'platina',
      'diamante',
      'lendario',
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1a2240),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2a3050)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações sobre Recompensas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Você poderá alterar, excluir ou adicionar novas recompensas posteriormente na tela de Recompensas.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...tiposOrdenados.map((tipo) {
          if (!recompensasPorTipo.containsKey(tipo) || recompensasPorTipo[tipo]!.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: Text(
                  _getTipoRecompensaFormatado(tipo),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildRecompensasGrid(context, recompensasPorTipo[tipo]!),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecompensasGrid(BuildContext context, List<RecompensaConfig> recompensasList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recompensasList.length,
      itemBuilder: (context, index) {
        return _buildRecompensaItem(context, recompensasList[index]);
      },
    );
  }

  Widget _buildRecompensaItem(BuildContext context, RecompensaConfig recompensa) {
    final tipoRecompensa = _getTipoRecompensaFormatado(recompensa.tipoRecompensa);
    final String emoji = _getEmojiRecompensa(recompensa.tipoRecompensa);
    final bool selecionada = recompensa.selecionada;

    return InkWell(
      onTap: () {
        // Alternar o estado de seleção da recompensa
        final novasRecompensas = List<RecompensaConfig>.from(recompensas);
        final index = novasRecompensas.indexWhere(
          (r) => r.descricaoRecompensa == recompensa.descricaoRecompensa &&
                r.tipoRecompensa == recompensa.tipoRecompensa
        );

        if (index != -1) {
          novasRecompensas[index] = recompensa.copyWith(selecionada: !selecionada);
          onRecompensasChanged(novasRecompensas);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionada ? const Color(0xFF1a2240).withOpacity(0.8) : const Color(0xFF1a2240),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionada ? const Color(0xFFf43f7d) : const Color(0xFF2a3050),
            width: selecionada ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selecionada
                        ? const Color(0xFFf43f7d).withOpacity(0.3)
                        : const Color(0xFFf43f7d).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                if (selecionada)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFf43f7d),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recompensa.descricaoRecompensa,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipoRecompensa,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: () => _editarRecompensa(context, recompensa),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecompensaButton(BuildContext context) {
    return InkWell(
      onTap: () => _adicionarRecompensa(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a2240),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a3050)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⭐', style: TextStyle(fontSize: 24)),  // Emoji de estrela
            SizedBox(width: 12),
            Text(
              'Adicionar Recompensa',
              style: TextStyle(
                color: Color(0xFFf43f7d),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarRecompensa(BuildContext context) {
    _mostrarDialogoRecompensa(
      context: context,
      titulo: 'Adicionar Recompensa',
      botaoAcao: 'Adicionar',
      onSave: (descricao, tipo, selecionada) {
        final novaRecompensa = RecompensaConfig(
          tipoRecompensa: tipo,
          descricaoRecompensa: descricao,
          selecionada: selecionada,
        );

        final novasRecompensas = List<RecompensaConfig>.from(recompensas);
        novasRecompensas.add(novaRecompensa);
        onRecompensasChanged(novasRecompensas);
      },
    );
  }

  void _editarRecompensa(BuildContext context, RecompensaConfig recompensa) {
    _mostrarDialogoRecompensa(
      context: context,
      titulo: 'Editar Recompensa',
      botaoAcao: 'Salvar',
      descricaoInicial: recompensa.descricaoRecompensa,
      tipoInicial: recompensa.tipoRecompensa,
      selecionadaInicial: recompensa.selecionada,
      onSave: (descricao, tipo, selecionada) {
        final recompensaEditada = RecompensaConfig(
          tipoRecompensa: tipo,
          descricaoRecompensa: descricao,
          selecionada: selecionada,
        );

        final novasRecompensas = List<RecompensaConfig>.from(recompensas);
        final index = novasRecompensas.indexWhere(
          (r) => r.descricaoRecompensa == recompensa.descricaoRecompensa &&
                r.tipoRecompensa == recompensa.tipoRecompensa
        );

        if (index != -1) {
          novasRecompensas[index] = recompensaEditada;
          onRecompensasChanged(novasRecompensas);
        }
      },
    );
  }

  void _mostrarDialogoRecompensa({
    required BuildContext context,
    required String titulo,
    required String botaoAcao,
    required Function(String descricao, String tipo, bool selecionada) onSave,
    String? descricaoInicial,
    String? tipoInicial,
    bool? selecionadaInicial,
  }) {
    final TextEditingController descricaoController = TextEditingController(text: descricaoInicial);
    String tipoSelecionado = tipoInicial ?? 'bronze';
    bool selecionada = selecionadaInicial ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1a2240),
          title: Text(
            titulo,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descrição da Recompensa',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descricaoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: Pausa de 15 min para Redes Sociais (15 Moedas)',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF13192b),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2a3050)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2a3050)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFf43f7d)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tipo de Recompensa',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              _buildTipoRecompensaSelector(
                tipoSelecionado,
                (tipo) => setState(() => tipoSelecionado = tipo),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: selecionada,
                    onChanged: (value) => setState(() => selecionada = value ?? false),
                    activeColor: const Color(0xFFf43f7d),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Selecionar esta recompensa',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf43f7d),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (descricaoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, informe a descrição da recompensa')),
                  );
                  return;
                }

                onSave(descricaoController.text.trim(), tipoSelecionado, selecionada);
                Navigator.pop(context);
              },
              child: Text(botaoAcao),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoRecompensaSelector(String tipoSelecionado, Function(String) onTipoChanged) {
    final tipos = [
      {'id': 'bronze', 'nome': 'Bronze', 'emoji': '☕'},  // Café
      {'id': 'prata', 'nome': 'Prata', 'emoji': '🎮'},  // Videogame
      {'id': 'ouro', 'nome': 'Ouro', 'emoji': '🎬'},  // Filme
      {'id': 'platina', 'nome': 'Platina', 'emoji': '📺'},  // TV
      {'id': 'diamante', 'nome': 'Diamante', 'emoji': '🎉'},  // Festa
      {'id': 'lendario', 'nome': 'Lendário', 'emoji': '🏆'},  // Troféu
    ];

    // Dividir em duas linhas para melhor visualização
    final primeiraLinha = tipos.sublist(0, 3); // Bronze, Prata, Ouro
    final segundaLinha = tipos.sublist(3); // Platina, Diamante, Lendário

    return Column(
      children: [
        // Primeira linha
        Row(
          children: primeiraLinha.map((tipo) {
            final selecionado = tipo['id'] == tipoSelecionado;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTipoChanged(tipo['id']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selecionado ? const Color(0xFFf43f7d) : const Color(0xFF13192b),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selecionado ? const Color(0xFFf43f7d) : const Color(0xFF2a3050),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tipo['emoji']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tipo['nome']!,
                          style: TextStyle(
                            color: selecionado ? Colors.white : Colors.white70,
                            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Segunda linha
        Row(
          children: segundaLinha.map((tipo) {
            final selecionado = tipo['id'] == tipoSelecionado;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTipoChanged(tipo['id']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selecionado ? const Color(0xFFf43f7d) : const Color(0xFF13192b),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selecionado ? const Color(0xFFf43f7d) : const Color(0xFF2a3050),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tipo['emoji']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tipo['nome']!,
                          style: TextStyle(
                            color: selecionado ? Colors.white : Colors.white70,
                            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getTipoRecompensaFormatado(String tipo) {
    switch (tipo) {
      case 'bronze':
        return 'Nível Bronze (5-15 Moedas)';
      case 'prata':
        return 'Nível Prata (25-40 Moedas)';
      case 'ouro':
        return 'Nível Ouro (60-100 Moedas)';
      case 'platina':
        return 'Nível Platina (120-200 Moedas)';
      case 'diamante':
        return 'Nível Diamante (300-500 Moedas)';
      case 'lendario':
        return 'Nível Lendário (800+ Moedas)';
      // Manter compatibilidade com valores antigos
      case 'diaria':
        return 'Recompensa Diária';
      case 'semanal':
        return 'Recompensa Semanal';
      case 'mensal':
        return 'Recompensa Mensal';
      default:
        return 'Recompensa';
    }
  }

  String _getEmojiRecompensa(String tipo) {
    switch (tipo) {
      case 'bronze':
        return '☕'; // Café
      case 'prata':
        return '🎮'; // Videogame
      case 'ouro':
        return '🎬'; // Filme
      case 'platina':
        return '📺'; // TV
      case 'diamante':
        return '🎉'; // Festa
      case 'lendario':
        return '🏆'; // Troféu
      // Manter compatibilidade com valores antigos
      case 'diaria':
        return '☕'; // Café
      case 'semanal':
        return '🎬'; // Filme
      case 'mensal':
        return '🏆'; // Troféu
      default:
        return '⭐'; // Estrela
    }
  }
}
