import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../../domain/services/cargo_grouping_service.dart';

/// Widget que exibe a aba de cargos do edital
class CargosTabWidget extends StatelessWidget {
  final Edital edital;
  final Function(String) onCargoSelected;

  const CargosTabWidget({
    Key? key,
    required this.edital,
    required this.onCargoSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupar cargos
    final gruposCargos = CargoGroupingService.agruparCargos(edital, null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cargos Disponíveis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Verificar se há cargos disponíveis
          if (gruposCargos.isEmpty)
            _buildNoCargosMessage()
          else
            // Construir grupos de cargos
            ...gruposCargos.entries.map((entry) => _buildGrupoCard(context, entry.key, entry.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildNoCargosMessage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum cargo encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foram encontrados cargos neste edital. Isso pode ocorrer se o edital não contiver informações sobre cargos ou se a análise não conseguiu extrair essas informações.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrupoCard(BuildContext context, String grupo, List<Cargo> cargos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do grupo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CargoGroupingService.getIconForGrupo(grupo),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    grupo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Text(
                  '${cargos.length} ${cargos.length == 1 ? 'cargo' : 'cargos'}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Lista de cargos
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cargos.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildCargoItem(context, cargos[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoItem(BuildContext context, Cargo cargo) {
    return InkWell(
      onTap: () => onCargoSelected(cargo.nome),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cargo.nome,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCargoInfoChip(
                  'Vagas: ${cargo.vagas}',
                  Icons.people,
                  Colors.blue.shade100,
                  Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                _buildCargoInfoChip(
                  'R\$ ${_formatarSalario(cargo.salario)}',
                  Icons.attach_money,
                  Colors.green.shade100,
                  Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCargoInfoChip(
              cargo.escolaridade,
              Icons.school,
              Colors.purple.shade100,
              Colors.purple.shade700,
            ),
            if (cargo.dataProva != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildCargoInfoChip(
                  'Prova: ${DateFormat('dd/MM/yyyy').format(cargo.dataProva!)}',
                  Icons.calendar_today,
                  Colors.orange.shade100,
                  Colors.orange.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoInfoChip(String label, IconData icon, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: fgColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarSalario(double salario) {
    if (salario <= 0) return '0,00';

    // Formatar o salário com separador de milhares e duas casas decimais
    final valorInteiro = salario.floor();
    final valorDecimal = ((salario - valorInteiro) * 100).round();

    // Formatar a parte inteira com separadores de milhar
    String valorInteiroStr = valorInteiro.toString();
    String resultado = '';

    for (int i = 0; i < valorInteiroStr.length; i++) {
      if (i > 0 && (valorInteiroStr.length - i) % 3 == 0) {
        resultado += '.';
      }
      resultado += valorInteiroStr[i];
    }

    // Adicionar a parte decimal
    return '$resultado,${valorDecimal.toString().padLeft(2, '0')}';
  }
}
