import 'dart:convert';
import 'package:intl/intl.dart';

/// Serviço para formatação de dados no resumo do plano
class FormatadorService {
  /// Formata uma data para o formato dd/MM/yyyy
  static String formatarData(DateTime data) {
    try {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(data);
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// Formata um valor numérico para o formato de moeda (R$)
  static String formatarValor(dynamic valor) {
    if (valor == null) return 'Não informado';

    if (valor is String) {
      try {
        valor = double.parse(valor);
      } catch (e) {
        return valor;
      }
    }

    if (valor is num) {
      return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
    }

    return valor.toString();
  }

  /// Formata o formato da prova (corrigir minúsculas e colchetes)
  static String formatarFormatoProva(String formato) {
    if (formato.isEmpty || formato.toLowerCase() == 'null' || formato == 'não informado') {
      return 'Não informado';
    }
    
    // Se for uma lista JSON, tentar converter
    if (formato.startsWith('[') && formato.endsWith(']')) {
      try {
        final List<dynamic> formatos = json.decode(formato);
        return formatos.map((f) => f.toString()).join(', ');
      } catch (e) {
        // Ignorar erro e continuar com o processamento normal
      }
    }
    
    // Remover colchetes, chaves e parênteses se existirem
    if ((formato.startsWith('[') && formato.endsWith(']')) ||
        (formato.startsWith('{') && formato.endsWith('}')) ||
        (formato.startsWith('(') && formato.endsWith(')'))) {
      formato = formato.substring(1, formato.length - 1);
    }
    
    // Capitalizar cada palavra
    List<String> palavras = formato.split(',');
    palavras = palavras.map((p) {
      p = p.trim();
      if (p.isNotEmpty) {
        return capitalizarPalavra(p);
      }
      return p;
    }).toList();
    
    return palavras.join(', ');
  }

  /// Método auxiliar para capitalizar palavras
  static String capitalizarPalavra(String palavra) {
    if (palavra.isEmpty) return '';

    // Remover aspas se existirem
    if (palavra.startsWith('"') && palavra.endsWith('"')) {
      palavra = palavra.substring(1, palavra.length - 1);
    }

    palavra = palavra.trim();
    if (palavra.isEmpty) return '';

    // Capitalizar cada palavra
    List<String> palavras = palavra.split(' ');
    palavras = palavras.map((p) {
      p = p.trim();
      if (p.isNotEmpty) {
        // Verificar se é uma sigla (todas maiúsculas)
        if (p.toUpperCase() == p && p.length <= 5) {
          return p;
        }
        return p[0].toUpperCase() + p.substring(1).toLowerCase();
      }
      return p;
    }).toList();

    return palavras.join(' ');
  }

  /// Extrai valor numérico de uma string
  static double extrairValorNumericoDeString(String valorStr) {
    // Remover R$ e outros caracteres não numéricos, exceto ponto e vírgula
    final valorLimpo = valorStr.replaceAll(RegExp(r'[^0-9,.]'), '');
    // Substituir vírgula por ponto
    final valorPonto = valorLimpo.replaceAll(',', '.');
    // Converter para double
    return double.tryParse(valorPonto) ?? 0.0;
  }
}
