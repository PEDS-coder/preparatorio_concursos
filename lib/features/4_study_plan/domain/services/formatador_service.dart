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

  /// Padroniza o estilo de escrita das informações
  static String padronizarEstiloEscrita(String texto) {
    if (texto.isEmpty || texto.toLowerCase() == 'null' || texto == 'não informado') {
      return 'Não informado';
    }

    // Remover espaços extras
    texto = texto.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Dividir por pontos, vírgulas ou outros separadores de frases
    List<String> frases = texto.split(RegExp(r'([.!?])\s*'));

    // Capitalizar cada frase
    List<String> frasesCapitalizadas = [];
    for (int i = 0; i < frases.length; i++) {
      String frase = frases[i].trim();
      if (frase.isNotEmpty) {
        // Capitalizar a primeira letra da frase
        frase = frase[0].toUpperCase() + frase.substring(1);
        frasesCapitalizadas.add(frase);
      }
    }

    // Juntar as frases novamente
    return frasesCapitalizadas.join('. ').replaceAll('. .', '.');
  }

  /// Formata a duração da prova
  static String formatarDuracaoProva(String duracao) {
    if (duracao.isEmpty || duracao.toLowerCase() == 'null' || duracao == 'não informado') {
      return 'Não informado';
    }

    // Verificar se a duração já está em um formato legível
    if (duracao.toLowerCase().contains('hora') || duracao.toLowerCase().contains('minuto')) {
      return capitalizarPalavra(duracao);
    }

    // Tentar extrair horas e minutos
    RegExp regexHorasMinutos = RegExp(r'(\d+)[^\d]*hora[^\d]*(\d+)[^\d]*minuto', caseSensitive: false);
    RegExp regexHoras = RegExp(r'(\d+)[^\d]*hora', caseSensitive: false);
    RegExp regexMinutos = RegExp(r'(\d+)[^\d]*minuto', caseSensitive: false);

    // Verificar se contém horas e minutos
    var match = regexHorasMinutos.firstMatch(duracao);
    if (match != null) {
      int horas = int.parse(match.group(1)!);
      int minutos = int.parse(match.group(2)!);
      return '$horas ${horas == 1 ? 'hora' : 'horas'} e $minutos ${minutos == 1 ? 'minuto' : 'minutos'}';
    }

    // Verificar se contém apenas horas
    match = regexHoras.firstMatch(duracao);
    if (match != null) {
      int horas = int.parse(match.group(1)!);
      return '$horas ${horas == 1 ? 'hora' : 'horas'}';
    }

    // Verificar se contém apenas minutos
    match = regexMinutos.firstMatch(duracao);
    if (match != null) {
      int minutos = int.parse(match.group(1)!);
      return '$minutos ${minutos == 1 ? 'minuto' : 'minutos'}';
    }

    // Tentar extrair números
    RegExp regexNumeros = RegExp(r'(\d+)');
    match = regexNumeros.firstMatch(duracao);
    if (match != null) {
      int valor = int.parse(match.group(1)!);

      // Verificar se o valor parece ser em minutos ou horas
      if (valor > 0 && valor <= 12) {
        return '$valor ${valor == 1 ? 'hora' : 'horas'}';
      } else if (valor > 12 && valor <= 300) {
        return '$valor ${valor == 1 ? 'minuto' : 'minutos'}';
      }
    }

    // Se não conseguir extrair, retornar o valor original
    return duracao;
  }

  /// Numera itens em um texto ou lista, separando por ponto e vírgula, vírgula ou ponto
  static String numerarItens(dynamic textoOuLista) {
    if (textoOuLista == null ||
        (textoOuLista is String && (textoOuLista.isEmpty || textoOuLista.toLowerCase() == 'null' || textoOuLista.trim().toLowerCase() == 'não informado')) ||
        (textoOuLista is List && textoOuLista.isEmpty)) {
      return 'Não informado';
    }

    List<String> itens = [];
    // Se for lista, usar diretamente
    if (textoOuLista is List) {
      itens = textoOuLista.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e.toLowerCase() != 'não informado').toList();
    } else if (textoOuLista is String) {
      // Remover colchetes, chaves e parênteses se existirem
      String texto = textoOuLista;
      if ((texto.startsWith('[') && texto.endsWith(']')) ||
          (texto.startsWith('{') && texto.endsWith('}')) ||
          (texto.startsWith('(') && texto.endsWith(')'))) {
        texto = texto.substring(1, texto.length - 1);
      }
      // Tratar casos onde o texto contém ":" que separa categorias de requisitos
      if (texto.contains(":")) {
        List<String> categorias = texto.split(":");
        if (categorias.length >= 2) {
          String categoria = categorias[0].trim();
          String conteudo = categorias[1].trim();
          List<String> itensConteudo = conteudo.split(RegExp(r'[;\n,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && e.toLowerCase() != 'não informado')
              .toList();
          if (itensConteudo.length > 1) {
            List<String> itensNumerados = _numerarListaItens(itensConteudo);
            return "$categoria: ${itensNumerados.join('; ')}";
          } else {
            return texto;
          }
        }
      }
      // Extrair itens do texto
      itens = texto.split(RegExp(r'[;\n,]')).map((e) => e.trim()).where((e) => e.isNotEmpty && e.toLowerCase() != 'não informado').toList();
    }
    // Se houver apenas um item, retornar o texto original (ou o único item)
    if (itens.length <= 1) {
      return itens.isNotEmpty ? itens.first : 'Não informado';
    }
    // Numerar os itens
    List<String> itensNumerados = _numerarListaItens(itens);
    return itensNumerados.join('; ');
  }

  /// Extrai itens de um texto, separando por ponto e vírgula, vírgula ou ponto
  static List<String> _extrairItens(String texto) {
    // Primeiro tentar separar por ponto e vírgula
    List<String> itensPontoVirgula = texto.split(';');
    if (itensPontoVirgula.length > 1) {
      return itensPontoVirgula.where((item) {
        final trimmed = item.trim();
        return trimmed.isNotEmpty && trimmed.toLowerCase() != 'e' && !trimmed.toLowerCase().startsWith('e ');
      }).toList();
    }

    // Se não houver ponto e vírgula, tentar separar por vírgula
    List<String> itensVirgula = texto.split(',');
    if (itensVirgula.length > 1) {
      return itensVirgula.where((item) {
        final trimmed = item.trim();
        return trimmed.isNotEmpty && trimmed.toLowerCase() != 'e' && !trimmed.toLowerCase().startsWith('e ');
      }).toList();
    }

    // Se não houver vírgula, tentar separar por ponto
    List<String> itensPonto = texto.split('.');
    return itensPonto.where((item) {
      final trimmed = item.trim();
      return trimmed.isNotEmpty && trimmed.toLowerCase() != 'e' && !trimmed.toLowerCase().startsWith('e ');
    }).toList();
  }

  /// Numera uma lista de itens
  static List<String> _numerarListaItens(List<String> itens) {
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
    return itensNumerados;
  }
}
