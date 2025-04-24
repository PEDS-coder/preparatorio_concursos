import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/formatador_service.dart';

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
        Padding(
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
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Período', '${FormatadorService.formatarData(plano.dataInicio)} a ${FormatadorService.formatarData(plano.dataFim)}'),
                SizedBox(height: 8),
                _buildInfoRow('Duração', '${_calcularDuracaoEmDias(plano.dataInicio, plano.dataFim)} dias'),
                SizedBox(height: 8),
                _buildInfoRow('Sessões de Estudo', '${plano.sessoesEstudo.length}'),
                SizedBox(height: 8),
                _buildInfoRow('Horas Semanais', '${_calcularTotalHorasSemanais(plano.horasSemanais)} horas'),
                SizedBox(height: 16),
                Text(
                  'Disponibilidade Semanal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                _buildHorasSemanais(plano.horasSemanais),
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
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    return Column(
      children: diasSemana.entries.map((entry) {
        final dia = entry.key;
        final nomeDia = entry.value;
        final horas = horasSemanais[dia] ?? 0;

        return Padding(
          padding: EdgeInsets.only(bottom: 8),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              SizedBox(width: 8),
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
    horasSemanais.forEach((dia, horas) {
      total += horas;
    });
    return total;
  }
}
