import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget para seleção de horários por dia da semana
class HorariosSelectionSection extends StatelessWidget {
  final Map<String, int> horasPorDia;
  final Map<String, List<int>> horasSelecionadas;
  final Function(String, List<int>) onHorasSelecionadasChanged;

  const HorariosSelectionSection({
    Key? key,
    required this.horasPorDia,
    required this.horasSelecionadas,
    required this.onHorasSelecionadasChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidade Semanal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione os horários disponíveis para estudo em cada dia da semana',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        _buildDiasSemana(context),
        const SizedBox(height: 16),
        _buildTotalHoras(),
      ],
    );
  }

  Widget _buildDiasSemana(BuildContext context) {
    final diasSemana = [
      {'dia': 'Segunda', 'nome': 'Segunda-feira'},
      {'dia': 'Terça', 'nome': 'Terça-feira'},
      {'dia': 'Quarta', 'nome': 'Quarta-feira'},
      {'dia': 'Quinta', 'nome': 'Quinta-feira'},
      {'dia': 'Sexta', 'nome': 'Sexta-feira'},
      {'dia': 'Sábado', 'nome': 'Sábado'},
      {'dia': 'Domingo', 'nome': 'Domingo'},
    ];

    return Column(
      children: diasSemana.map((dia) => _buildDiaItem(context, dia['dia'] as String, dia['nome'] as String)).toList(),
    );
  }

  Widget _buildDiaItem(BuildContext context, String dia, String nomeDia) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nomeDia,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${horasPorDia[dia]} horas',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selecionarHorasDoDia(context, dia, nomeDia),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1a2240),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2a3050)),
              ),
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFFf43f7d), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: horasSelecionadas[dia]!.isEmpty
                        ? const Text(
                            'Clique para selecionar horários',
                            style: TextStyle(color: Colors.white70),
                          )
                        : Text(
                            _formatarHorasSelecionadas(horasSelecionadas[dia]!),
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalHoras() {
    final totalHoras = horasPorDia.values.fold<int>(0, (sum, horas) => sum + horas);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2240),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2a3050)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total de horas semanais:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '$totalHoras horas',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFf43f7d),
            ),
          ),
        ],
      ),
    );
  }

  void _selecionarHorasDoDia(BuildContext context, String dia, String nomeDia) {
    // Criar uma cópia da lista de horas selecionadas para este dia
    List<int> horasSelecionadasTemp = List.from(horasSelecionadas[dia] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1a2240),
          title: Text(
            'Selecione as horas para $nomeDia',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Marque as horas que você pretende estudar:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(24, (index) {
                        // Usar horários de 01:00 a 24:00 em vez de 00:00 a 23:00
                        final hora = index + 1; // Começar de 1 (01:00) até 24 (24:00)
                        final selecionada = horasSelecionadasTemp.contains(hora);
                        // Formatação para exibir o horário
                        final String horaFormatada = hora == 24 ? '24:00' : '${hora.toString().padLeft(2, '0')}:00';
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selecionada) {
                                horasSelecionadasTemp.remove(hora);
                              } else {
                                horasSelecionadasTemp.add(hora);
                              }
                            });
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width > 600 ? 70 : 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selecionada ? const Color(0xFFf43f7d) : const Color(0xFF13192b),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFf43f7d)),
                            ),
                            child: Center(
                              child: Text(
                                horaFormatada,
                                style: TextStyle(
                                  color: selecionada ? Colors.white : Colors.white70,
                                  fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
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
                // Atualizar as horas selecionadas e calcular o total
                onHorasSelecionadasChanged(dia, horasSelecionadasTemp);
                Navigator.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarHorasSelecionadas(List<int> horas) {
    if (horas.isEmpty) return 'Nenhum horário selecionado';

    // Ordenar as horas
    horas.sort();

    // Agrupar horas consecutivas
    List<String> grupos = [];
    if (horas.isNotEmpty) {
      int inicio = horas[0];
      int fim = horas[0];

      for (int i = 1; i < horas.length; i++) {
        if (horas[i] == fim + 1) {
          fim = horas[i];
        } else {
          // Adicionar grupo anterior
          if (inicio == fim) {
            grupos.add('${_formatarHora(inicio)}');
          } else {
            grupos.add('${_formatarHora(inicio)}-${_formatarHora(fim)}');
          }
          inicio = horas[i];
          fim = horas[i];
        }
      }

      // Adicionar o último grupo
      if (inicio == fim) {
        grupos.add('${_formatarHora(inicio)}');
      } else {
        grupos.add('${_formatarHora(inicio)}-${_formatarHora(fim)}');
      }
    }

    return grupos.join(', ');
  }

  String _formatarHora(int hora) {
    return hora == 24 ? '24:00' : '${hora.toString().padLeft(2, '0')}:00';
  }
}
