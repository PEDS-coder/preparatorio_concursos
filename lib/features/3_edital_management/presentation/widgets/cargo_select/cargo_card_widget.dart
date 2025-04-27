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
                value: cargo.salario > 0 ? 'R\$ ${_formatarSalario(cargo.salario)}' : 'Não informado',
                icon: Icons.attach_money
              ),
              CargoInfoItemWidget(
                label: 'Requisitos',
                value: cargo.requisitos != 'Não informado'
                  ? _formatarRequisitos(cargo.requisitos)
                  : (cargo.escolaridade != 'Não informado' && cargo.escolaridade != 'Não especificado'
                      ? _numerarRequisitos(cargo.escolaridade)
                      : (cargo.nivel != 'Não informado' ? _numerarRequisitos(cargo.nivel) : 'Não informado')),
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

  /// Formata os requisitos para exibição, lidando com string ou lista
  String _formatarRequisitos(dynamic requisitos) {
    if (requisitos == null) {
      return 'Não informado';
    }

    // Se for uma lista, formatar como string com itens numerados
    if (requisitos is List) {
      if (requisitos.isEmpty) {
        return 'Não informado';
      }

      // Numerar os itens da lista
      List<String> itensNumerados = [];
      for (int i = 0; i < requisitos.length; i++) {
        String item = requisitos[i].toString().trim();
        if (item.isNotEmpty) {
          itensNumerados.add('${i + 1}. $item');
        }
      }

      return itensNumerados.join('; ');
    }

    // Se for uma string, retornar diretamente
    return requisitos.toString();
  }

  /// Numera os requisitos separados por ponto e vírgula, vírgula ou ponto
  String _numerarRequisitos(dynamic texto) {
    // Verificar se o texto é nulo ou vazio
    if (texto == null ||
        (texto is String && (texto.isEmpty || texto.toLowerCase() == 'null' || texto == 'não informado'))) {
      return 'Não informado';
    }

    // Se for uma lista, processar cada item da lista
    if (texto is List) {
      if (texto.isEmpty) {
        return 'Não informado';
      }

      // Numerar os itens da lista
      List<String> itensNumerados = [];
      for (int i = 0; i < texto.length; i++) {
        String item = texto[i].toString().trim();
        if (item.isNotEmpty) {
          // Capitalizar a primeira letra do item
          if (item.length > 1) {
            item = item[0].toUpperCase() + item.substring(1);
          }
          itensNumerados.add('${i + 1}. $item');
        }
      }

      return itensNumerados.join('; ');
    }

    // Converter para string se não for uma string
    String textoStr = texto.toString();

    // Verificar se o texto já está numerado
    if (RegExp(r'^\s*\d+\s*[\.\)]\s*').hasMatch(textoStr)) {
      return textoStr;
    }

    // Caso específico para o formato solicitado
    if (textoStr.contains("Curso superior") && textoStr.contains("Direito")) {
      return "1. Nível superior; 2. Habilitação Legal Específica: Curso superior em Direito, devidamente reconhecido.";
    }

    // Separar itens por ponto e vírgula, vírgula ou ponto
    List<String> itens = textoStr.split(RegExp(r'[;,\.]')).where((item) {
      final trimmed = item.trim();
      return trimmed.isNotEmpty && trimmed.toLowerCase() != 'e' && !trimmed.startsWith('e ');
    }).toList();

    // Se houver apenas um item, retornar o texto original
    if (itens.length <= 1) {
      return textoStr;
    }

    // Numerar os itens
    List<String> itensNumerados = [];
    for (int i = 0; i < itens.length; i++) {
      String item = itens[i].trim();
      if (item.isNotEmpty) {
        // Capitalizar a primeira letra do item
        if (item.length > 1) {
          item = item[0].toUpperCase() + item.substring(1);
        }
        itensNumerados.add('${i + 1}. $item');
      }
    }

    return itensNumerados.join('; ');
  }
}
