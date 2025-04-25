import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/data/models/edital.dart';
import 'cargo_info_item_widget.dart';

/// Widget que exibe um card de cargo com suas informações
class CargoCardWidget extends StatelessWidget {
  final Cargo cargo;
  final bool isSelecionado;
  final bool showPopupButtons;
  final VoidCallback onTap;
  final VoidCallback? onCriarPlanoPressed;
  final bool isLoading;

  const CargoCardWidget({
    Key? key,
    required this.cargo,
    required this.isSelecionado,
    required this.showPopupButtons,
    required this.onTap,
    this.onCriarPlanoPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelecionado ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelecionado ? AppTheme.primaryColor : Colors.grey.shade400,
          width: isSelecionado ? 2 : 1,
        ),
      ),
      color: isSelecionado ? Colors.blue.shade50 : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cargo.nome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelecionado ? AppTheme.primaryColor : Colors.black,
                      ),
                    ),
                  ),
                  if (isSelecionado)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),

              // Botões pop-up quando o cargo está selecionado
              if (isSelecionado && showPopupButtons)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Center(
                    // Botão para continuar para o plano de estudo
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : onCriarPlanoPressed,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Criar Plano', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              
              // Informações do cargo
              CargoInfoItemWidget(
                label: 'Salário', 
                value: 'R\$ ${_formatarSalario(cargo.salario)}', 
                icon: Icons.attach_money
              ),
              CargoInfoItemWidget(
                label: 'Escolaridade', 
                value: cargo.escolaridade, 
                icon: Icons.school
              ),
              if (cargo.dataProva != null)
                CargoInfoItemWidget(
                  label: 'Data da Prova', 
                  value: DateFormat('dd/MM/yyyy').format(cargo.dataProva!), 
                  icon: Icons.calendar_today
                ),
              if (cargo.horarioProva != null && cargo.horarioProva!.isNotEmpty)
                CargoInfoItemWidget(
                  label: 'Horário da Prova', 
                  value: cargo.horarioProva!, 
                  icon: Icons.access_time
                ),
              if (cargo.requisitos != 'Não informado')
                CargoInfoItemWidget(
                  label: 'Requisitos', 
                  value: cargo.requisitos, 
                  icon: Icons.assignment_ind
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
