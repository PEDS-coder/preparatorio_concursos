import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget para seleção de datas de início e fim do plano
class DataSelectionSection extends StatelessWidget {
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final Function(DateTime) onDataInicioChanged;
  final Function(DateTime) onDataFimChanged;

  const DataSelectionSection({
    Key? key,
    required this.dataInicio,
    required this.dataFim,
    required this.onDataInicioChanged,
    required this.onDataFimChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período de Estudo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context,
                'Data de Início',
                dataInicio,
                onDataInicioChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                context,
                'Data de Término',
                dataFim,
                onDataFimChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateChanged,
  ) {
    final displayDate = selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(selectedDate)
        : 'Selecione uma data';

    return InkWell(
      onTap: () => _selecionarData(context, selectedDate, onDateChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1a2240),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2a3050)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayDate,
              style: const TextStyle(color: Colors.white),
            ),
            const Icon(Icons.calendar_today, color: Color(0xFFf43f7d), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarData(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime) onDateChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFf43f7d),
              onPrimary: Colors.white,
              surface: Color(0xFF1a2240),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF13192b),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      onDateChanged(picked);
    }
  }
}
