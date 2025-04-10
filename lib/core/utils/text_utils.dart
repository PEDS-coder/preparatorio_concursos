import 'dart:typed_data';

class TextUtils {
  // Método para extrair texto de um PDF
  static Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    // Implementação futura
    return "";
  }

  // Método para limpar o texto (remover caracteres especiais, etc)
  static String cleanText(String text) {
    // Remover caracteres especiais, espaços extras, etc.
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Método para normalizar caracteres especiais
  static String normalizeText(String text) {
    // Mapeamento de caracteres problemáticos para suas versões corretas
    final Map<String, String> charMap = {
      'Ð': 'D', // Ð -> D
      'Ã': 'Ã', // Ã com problemas de codificação
      'Â': 'Â', // Â com problemas de codificação
      'Á': 'Á', // Á com problemas de codificação
      'É': 'É', // É com problemas de codificação
      'Í': 'Í', // Í com problemas de codificação
      'Ó': 'Ó', // Ó com problemas de codificação
      'Ú': 'Ú', // Ú com problemas de codificação
      'ã': 'ã', // ã com problemas de codificação
      'â': 'â', // â com problemas de codificação
      'á': 'á', // á com problemas de codificação
      'é': 'é', // é com problemas de codificação
      'í': 'í', // í com problemas de codificação
      'ó': 'ó', // ó com problemas de codificação
      'ú': 'ú', // ú com problemas de codificação
      'ç': 'ç', // ç com problemas de codificação
      'Ç': 'Ç', // Ç com problemas de codificação
      'õ': 'õ', // õ com problemas de codificação
      'Õ': 'Õ', // Õ com problemas de codificação
      'ª': 'ª', // ª com problemas de codificação
      'º': 'º', // º com problemas de codificação
      '§': '§', // § com problemas de codificação
      '°': '°', // ° com problemas de codificação
    };

    String normalizedText = text;
    charMap.forEach((key, value) {
      normalizedText = normalizedText.replaceAll(key, value);
    });

    // Corrigir padrões específicos observados
    normalizedText = normalizedText
      .replaceAll('MinistÃ\u0090rio', 'Ministério')
      .replaceAll('PÃºblico', 'Público')
      .replaceAll('UniÃ£o', 'União')
      .replaceAll('NÃ£o', 'Não')
      .replaceAll('PaÃ\u00ads', 'País')
      .replaceAll('TÃ\u0090cnico', 'Técnico')
      .replaceAll('NÃ\u00advel', 'Nível');

    // Aplicar normalização de termos em português
    normalizedText = normalizePortugueseTerms(normalizedText);

    return normalizedText;
  }

  // Método para normalizar termos em português
  static String normalizePortugueseTerms(String text) {
    // Mapeamento de termos incorretos para suas versões corretas
    final Map<String, String> termMap = {
      'Nogoes': 'Noções',
      'nogoes': 'noções',
      'Nocoes': 'Noções',
      'nocoes': 'noções',
      'Nocao': 'Noção',
      'nocao': 'noção',
      'Nogao': 'Noção',
      'nogao': 'noção',
      'Informacao': 'Informação',
      'informacao': 'informação',
      'Informacoes': 'Informações',
      'informacoes': 'informações',
      'Legislacao': 'Legislação',
      'legislacao': 'legislação',
      'Administracao': 'Administração',
      'administracao': 'administração',
      'Constituicao': 'Constituição',
      'constituicao': 'constituição',
      'Atencao': 'Atenção',
      'atencao': 'atenção',
      'Relacoes': 'Relações',
      'relacoes': 'relações',
      'Funcoes': 'Funções',
      'funcoes': 'funções',
      'Operacoes': 'Operações',
      'operacoes': 'operações',
      'Redacao': 'Redação',
      'redacao': 'redação',
      'Comunicacao': 'Comunicação',
      'comunicacao': 'comunicação',
      'Educacao': 'Educação',
      'educacao': 'educação',
      'Organizacao': 'Organização',
      'organizacao': 'organização',
    };

    String normalizedText = text;
    termMap.forEach((key, value) {
      normalizedText = normalizedText.replaceAll(key, value);
    });

    return normalizedText;
  }

  // Método para dividir o texto em parágrafos
  static List<String> splitIntoParagraphs(String text) {
    return text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
  }

  // Método para extrair palavras-chave de um texto
  static List<String> extractKeywords(String text) {
    // Implementação futura - usar NLP ou regex para extrair palavras-chave
    return [];
  }

  // Método para estimar o número de tokens em um texto
  // Esta é uma estimativa aproximada, pois a tokenização exata depende do modelo
  static int estimateTokenCount(String text, {String modelType = 'gemini'}) {
    // Diferentes modelos têm diferentes taxas de tokenização
    double charsPerToken;

    if (modelType == 'gemini') {
      // Para o Gemini, usamos uma estimativa mais conservadora para português
      charsPerToken = 3.5;
    } else if (modelType == 'openai') {
      // Para o OpenAI, a estimativa é um pouco diferente
      charsPerToken = 4.0;
    } else {
      // Valor padrão para outros modelos
      charsPerToken = 3.5;
    }

    return (text.length / charsPerToken).ceil();
  }

  // Método para dividir um texto longo em partes menores
  static List<String> splitLongText(String text, {int maxTokensPerChunk = 900000, String modelType = 'gemini'}) {
    // Ajustar o tamanho máximo de tokens com base no modelo
    int adjustedMaxTokens = maxTokensPerChunk;

    // Definir limites de contexto para diferentes modelos
    if (modelType == 'gemini') {
      // Gemini 2.0 Flash suporta até 1 milhão de tokens
      int geminiContextLimit = 1000000;
      adjustedMaxTokens = maxTokensPerChunk > geminiContextLimit ? geminiContextLimit : maxTokensPerChunk;
    } else if (modelType == 'openai') {
      // GPT-3.5 Turbo suporta até 16k tokens
      int openaiContextLimit = 16000;
      adjustedMaxTokens = maxTokensPerChunk > openaiContextLimit ? openaiContextLimit : maxTokensPerChunk;
    }

    // Estimar o tamanho do texto em tokens
    int estimatedTokens = estimateTokenCount(text, modelType: modelType);
    print('Tamanho estimado do edital: ~$estimatedTokens tokens para o modelo $modelType');

    // Verificar se o modelo é Gemini 2.0 Flash (que suporta até 1 milhão de tokens)
    if (modelType == 'gemini') {
      // Para o Gemini, não dividir a menos que seja realmente necessário
      if (estimatedTokens <= 900000) {
        print('Texto dentro do limite de tokens para Gemini, processando como um único chunk');
        return [text];
      }
    } else {
      // Para outros modelos, usar o limite ajustado
      if (estimatedTokens <= adjustedMaxTokens) {
        print('Texto dentro do limite de tokens, processando como um único chunk');
        return [text];
      }
    }

    // Se chegou aqui, o texto precisa ser dividido
    print('Texto muito longo, dividindo em chunks menores');

    // Dividir o texto em parágrafos
    final paragraphs = splitIntoParagraphs(text);
    final List<String> chunks = [];
    String currentChunk = "";
    int currentTokenCount = 0;

    for (final paragraph in paragraphs) {
      final paragraphTokens = estimateTokenCount(paragraph);

      // Se um único parágrafo for maior que o limite, precisamos dividi-lo
      if (paragraphTokens > maxTokensPerChunk) {
        // Se já temos conteúdo no chunk atual, finalize-o primeiro
        if (currentTokenCount > 0) {
          chunks.add(currentChunk);
          currentChunk = "";
          currentTokenCount = 0;
        }

        // Dividir o parágrafo grande em frases
        final sentences = paragraph.split(RegExp(r'(?<=[.!?])\s+'));
        String sentenceChunk = "";
        int sentenceTokenCount = 0;

        for (final sentence in sentences) {
          final sentenceTokens = estimateTokenCount(sentence);

          if (sentenceTokenCount + sentenceTokens <= maxTokensPerChunk) {
            sentenceChunk += sentence + " ";
            sentenceTokenCount += sentenceTokens;
          } else {
            if (sentenceChunk.isNotEmpty) {
              chunks.add(sentenceChunk.trim());
            }

            // Se uma única frase for muito grande, divida-a em partes
            if (sentenceTokens > maxTokensPerChunk) {
              final words = sentence.split(' ');
              String wordChunk = "";
              int wordTokenCount = 0;

              for (final word in words) {
                final wordTokens = estimateTokenCount(word + " ");

                if (wordTokenCount + wordTokens <= maxTokensPerChunk) {
                  wordChunk += word + " ";
                  wordTokenCount += wordTokens;
                } else {
                  chunks.add(wordChunk.trim());
                  wordChunk = word + " ";
                  wordTokenCount = wordTokens;
                }
              }

              if (wordChunk.isNotEmpty) {
                chunks.add(wordChunk.trim());
              }
            } else {
              sentenceChunk = sentence + " ";
              sentenceTokenCount = sentenceTokens;
            }
          }
        }

        if (sentenceChunk.isNotEmpty) {
          chunks.add(sentenceChunk.trim());
        }
      }
      // Caso normal: adicionar parágrafo ao chunk atual se couber
      else if (currentTokenCount + paragraphTokens <= maxTokensPerChunk) {
        currentChunk += paragraph + "\n\n";
        currentTokenCount += paragraphTokens;
      }
      // Se não couber, finalize o chunk atual e comece um novo
      else {
        chunks.add(currentChunk.trim());
        currentChunk = paragraph + "\n\n";
        currentTokenCount = paragraphTokens;
      }
    }

    // Adicionar o último chunk se não estiver vazio
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }
}
