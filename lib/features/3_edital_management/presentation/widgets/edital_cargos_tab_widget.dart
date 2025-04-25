import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/edital_formatter_service.dart';
import 'cargo_detail_item_widget.dart';
import '../screens/cargo_select_screen.dart';

/// Widget que representa a aba de cargos do edital
class EditalCargosTabWidget extends StatelessWidget {
  final Edital edital;
  final String editalId;

  const EditalCargosTabWidget({
    Key? key,
    required this.edital,
    required this.editalId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cargos = edital.dadosExtraidos.cargos;

    return cargos.isEmpty
        ? _buildEmptyCargosMessage()
        : _buildCargosList(cargos, context);
  }

  Widget _buildEmptyCargosMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Nenhum cargo encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Não foram encontrados cargos neste edital.'),
        ],
      ),
    );
  }

  Widget _buildCargosList(List<Cargo> cargos, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cargos.length,
      itemBuilder: (context, index) {
        final cargo = cargos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              cargo.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Salário: R\$ ${cargo.salario.toStringAsFixed(2)}',
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.work, color: AppTheme.primaryColor),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CargoDetailItemWidget(
                      label: 'Escolaridade',
                      value: cargo.escolaridade,
                    ),
                    const SizedBox(height: 8),
                    CargoDetailItemWidget(
                      label: 'Data da Prova',
                      value: cargo.dataProva != null
                          ? EditalFormatterService.formatDate(cargo.dataProva)
                          : 'A definir',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Conteúdo Programático',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...cargo.conteudoProgramatico.map((materia) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(materia.nome)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CargoSelectScreen(editalId: editalId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_chart),
                      label: const Text('Criar Plano para este Cargo'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
