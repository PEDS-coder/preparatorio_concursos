import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Serviço para formatação de valores e datas
class FormatadorService {
  /// Formata um valor numérico para exibição
  static String formatarValor(dynamic valor) {
    if (valor == null) return 'Não informado';

    if (valor is num) {
      return valor.toString();
    } else if (valor is String) {
      return valor;
    }

    return 'Não informado';
  }

  /// Formata o formato da prova para exibição
  static String formatarFormatoProva(dynamic formato) {
    if (formato == null) return 'Não informado';

    if (formato is List) {
      return formato.join(', ');
    } else if (formato is String) {
      // Verificar se é uma string JSON
      if (formato.startsWith('[') && formato.endsWith(']')) {
        try {
          List<dynamic> formatoList = jsonDecode(formato);
          return formatoList.map((item) => item.toString()).join(', ');
        } catch (e) {
          // Não é um JSON válido, tratar como string normal
        }
      }

      // Verificar se é uma lista separada por vírgulas
      if (formato.contains(',')) {
        return formato.split(',').map((item) => item.trim()).join(', ');
      }

      return formato;
    }

    return formato.toString();
  }

  /// Extrai um valor numérico de uma string
  static double extrairValorNumericoDeString(String valor) {
    if (valor == 'Não informado') return 0.0;

    // Remover símbolos de moeda e substituir vírgula por ponto
    String valorLimpo = valor.replaceAll(RegExp(r'[R$\s]'), '').replaceAll(',', '.');

    // Tentar extrair um número
    try {
      return double.parse(valorLimpo);
    } catch (e) {
      // Tentar extrair usando regex
      final regex = RegExp(r'(\d+[.,]?\d*)');
      final match = regex.firstMatch(valorLimpo);

      if (match != null) {
        try {
          return double.parse(match.group(1)!.replaceAll(',', '.'));
        } catch (e) {
          debugPrint('Erro ao extrair valor numérico: $e');
        }
      }

      return 0.0;
    }
  }

  /// Formata um valor monetário para exibição (R$ 0,00)
  static String formatarValorMonetario(dynamic valor) {
    if (valor == null) return 'Não informado';

    try {
      double valorNumerico;

      if (valor is num) {
        valorNumerico = valor.toDouble();
      } else if (valor is String) {
        // Remover símbolos de moeda e substituir vírgula por ponto
        String valorLimpo = valor.replaceAll(RegExp(r'[R$\s]'), '').replaceAll(',', '.');
        valorNumerico = double.tryParse(valorLimpo) ?? 0.0;
      } else {
        return 'Não informado';
      }

      // Formatar com R$ e duas casas decimais
      final formatador = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      );

      return formatador.format(valorNumerico);
    } catch (e) {
      debugPrint('Erro ao formatar valor monetário: $e');
      return valor.toString();
    }
  }

  /// Formata uma data para exibição (dd/MM/yyyy)
  static String formatarData(dynamic data) {
    if (data == null) return 'Não informado';

    try {
      DateTime dataDateTime;

      if (data is DateTime) {
        dataDateTime = data;
      } else if (data is String) {
        // Tentar parsear a data
        try {
          dataDateTime = DateTime.parse(data);
        } catch (e) {
          // Verificar se é formato DD/MM/YYYY
          final regexBarra = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
          final matchBarra = regexBarra.firstMatch(data);
          if (matchBarra != null) {
            final dia = int.parse(matchBarra.group(1)!);
            final mes = int.parse(matchBarra.group(2)!);
            final ano = int.parse(matchBarra.group(3)!);
            dataDateTime = DateTime(ano, mes, dia);
          } else {
            return data;
          }
        }
      } else {
        return 'Não informado';
      }

      // Formatar a data
      final formatador = DateFormat('dd/MM/yyyy', 'pt_BR');
      return formatador.format(dataDateTime);
    } catch (e) {
      debugPrint('Erro ao formatar data: $e');
      return data.toString();
    }
  }

  /// Formata a duração da prova para exibição
  static String formatarDuracaoProva(String duracao) {
    if (duracao == 'Não informado') return duracao;

    // Verificar se já está formatado
    if (duracao.contains('hora') || duracao.contains('minuto')) {
      return duracao;
    }

    // Tentar extrair horas e minutos
    final regexHoras = RegExp(r'(\d+)h');
    final regexMinutos = RegExp(r'(\d+)min');

    final matchHoras = regexHoras.firstMatch(duracao);
    final matchMinutos = regexMinutos.firstMatch(duracao);

    if (matchHoras != null || matchMinutos != null) {
      final horas = matchHoras != null ? int.parse(matchHoras.group(1)!) : 0;
      final minutos = matchMinutos != null ? int.parse(matchMinutos.group(1)!) : 0;

      String resultado = '';
      if (horas > 0) {
        resultado += '$horas hora${horas > 1 ? 's' : ''}';
      }

      if (minutos > 0) {
        if (resultado.isNotEmpty) resultado += ' e ';
        resultado += '$minutos minuto${minutos > 1 ? 's' : ''}';
      }

      return resultado.isNotEmpty ? resultado : duracao;
    }

    // Verificar se é apenas um número (assumir que são horas)
    final regexNumero = RegExp(r'^(\d+)$');
    final matchNumero = regexNumero.firstMatch(duracao);

    if (matchNumero != null) {
      final horas = int.parse(matchNumero.group(1)!);
      return '$horas hora${horas > 1 ? 's' : ''}';
    }

    return duracao;
  }
}
