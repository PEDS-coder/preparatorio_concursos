import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import '../../domain/services/cargo_grouping_service.dart';

/// Widget que representa a lista de grupos de cargos
class GrupoCargosWidget extends StatelessWidget {
  final Map<String, List<Cargo>> gruposCargos;
  final String? grupoExpandido;
  final Function(String?) onGrupoExpandidoChanged;
  final Function(String) onCargoSelecionado;

  const GrupoCargosWidget({
    Key? key,
    required this.gruposCargos,
    required this.grupoExpandido,
    required this.onGrupoExpandidoChanged,
    required this.onCargoSelecionado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (gruposCargos.isEmpty) {
      return const Center(
        child: Text('Nenhum cargo encontrado'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gruposCargos.length,
      itemBuilder: (context, index) {
        final grupo = gruposCargos.keys.elementAt(index);
        final cargos = gruposCargos[grupo]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              if (grupoExpandido == grupo) {
                onGrupoExpandidoChanged(null);
              } else {
                onGrupoExpandidoChanged(grupo);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // Cabeçalho do grupo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: grupoExpandido == grupo ? Radius.zero : const Radius.circular(12),
                      bottomRight: grupoExpandido == grupo ? Radius.zero : const Radius.circular(12),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '${cargos.length} cargos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark ?
                                 Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        grupoExpandido == grupo
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),

                // Lista de cargos (se expandido)
                if (grupoExpandido == grupo)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cargos.length,
                    itemBuilder: (context, index) {
                      final cargo = cargos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            cargo.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ?
                                     Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ?
                                           Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Vagas: ${cargo.vagas}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ?
                                             Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ?
                                           Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Salário: R\$ ${cargo.salario.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ?
                                             Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ?
                                           Colors.grey.shade300 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Escolaridade: ${cargo.escolaridade}',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ?
                                               Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                            child: const Icon(Icons.work, color: AppTheme.secondaryColor),
                          ),
                          onTap: () => onCargoSelecionado(cargo.nome),
                          // Removido o ícone de seta para evitar confusão na navegação
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
