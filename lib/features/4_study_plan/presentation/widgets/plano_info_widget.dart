import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/formatador_service.dart';
import '../../domain/services/calendario_service.dart';
import '../screens/plano_resumo_screen.dart';

/// Widget para exibir informações do plano de estudos
class PlanoInfoWidget extends StatelessWidget {
  final PlanoEstudo plano;

  const PlanoInfoWidget({
    Key? key,
    required this.plano,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Plano de Estudos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Período', '${FormatadorService.formatarData(plano.dataInicio)} a ${FormatadorService.formatarData(plano.dataFim)}'),
                const SizedBox(height: 8),
                _buildInfoRow('Duração', '${_calcularDuracaoEmDias(plano.dataInicio, plano.dataFim)} dias'),
                const SizedBox(height: 8),
                _buildInfoRow('Sessões de Estudo', '${plano.sessoesEstudo.isEmpty ? "0 (Clique em 'Gerar Sessões' abaixo)" : plano.sessoesEstudo.length}'),
                const SizedBox(height: 8),
                _buildInfoRow('Horas Semanais', '${_calcularTotalHorasSemanais(plano.horasSemanais)} horas'),
                const SizedBox(height: 16),
                const Text(
                  'Disponibilidade Semanal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildHorasSemanais(plano.horasSemanais),

                // Botão para gerar sessões de estudo
                if (plano.sessoesEstudo.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _gerarSessoesEstudo(context),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Gerar Sessões de Estudo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorasSemanais(Map<String, int> horasSemanais) {
    final diasSemana = {
      'Segunda': 'Segunda-feira',
      'Terça': 'Terça-feira',
      'Quarta': 'Quarta-feira',
      'Quinta': 'Quinta-feira',
      'Sexta': 'Sexta-feira',
      'Sábado': 'Sábado',
      'Domingo': 'Domingo',
      // Manter compatibilidade com chaves em minúsculas
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    // Criar uma lista de dias da semana na ordem correta
    final diasOrdenados = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];

    return Column(
      children: diasOrdenados.map((dia) {
        final nomeDia = diasSemana[dia] ?? dia;
        // Tentar obter horas com a chave original ou com a versão em minúsculas
        // Garantir que horas nunca seja nulo
        final int horas = horasSemanais[dia] ??
                      horasSemanais[dia.toLowerCase()] ??
                      (dia == 'Terça' ? horasSemanais['terca'] ?? 0 : 0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(nomeDia),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: horas / 8, // Considerando 8h como máximo
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Text('$horas h'),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _calcularDuracaoEmDias(DateTime inicio, DateTime fim) {
    return fim.difference(inicio).inDays + 1;
  }

  int _calcularTotalHorasSemanais(Map<String, int> horasSemanais) {
    int total = 0;

    // Lista de possíveis chaves para cada dia da semana
    final diasPossiveis = [
      ['Segunda', 'segunda'],
      ['Terça', 'Terca', 'terca'],
      ['Quarta', 'quarta'],
      ['Quinta', 'quinta'],
      ['Sexta', 'sexta'],
      ['Sábado', 'Sabado', 'sabado'],
      ['Domingo', 'domingo'],
    ];

    // Para cada conjunto de chaves possíveis
    for (var chaves in diasPossiveis) {
      // Verificar se alguma das chaves existe no mapa
      for (var chave in chaves) {
        if (horasSemanais.containsKey(chave)) {
          total += horasSemanais[chave]!;
          break; // Sair do loop interno após encontrar uma chave válida
        }
      }
    }

    // Se o total ainda for zero, usar o método antigo como fallback
    if (total == 0) {
      horasSemanais.forEach((dia, horas) {
        total += horas;
      });
    }

    return total;
  }

  /// Gera sessões de estudo para o plano
  void _gerarSessoesEstudo(BuildContext context) {
    // Obter o CalendarioService
    final calendarioService = Provider.of<CalendarioService>(context, listen: false);

    // Mostrar diálogo de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando sessões de estudo...'),
          ],
        ),
      ),
    );

    // Gerar sessões de estudo
    calendarioService.gerarSessoesEstudo(
      plano,
      (planoAtualizado) {
        // Fechar diálogo de carregamento
        Navigator.of(context).pop();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessões de estudo geradas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Recarregar a tela
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PlanoResumoScreen(planoId: plano.id),
          ),
        );
      },
    );
  }
}
