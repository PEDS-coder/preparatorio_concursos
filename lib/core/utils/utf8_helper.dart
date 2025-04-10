/// Utilitário para corrigir problemas de codificação UTF-8
class UTF8Helper {
  /// Corrige problemas de codificação UTF-8 em textos
  static String corrigirCodificacaoUTF8(String texto) {
    // Mapeamento de caracteres especiais comuns que podem estar mal codificados
    final Map<String, String> mapaCorrecoes = {
      'Ã£': 'ã', // ã
      'Ã¡': 'á', // á
      'Ã©': 'é', // é
      'Ã­': 'í', // í
      'Ã³': 'ó', // ó
      'Ãº': 'ú', // ú
      'Ã§': 'ç', // ç
      'Ãµ': 'õ', // õ
      'Ã¢': 'â', // â
      'Ãª': 'ê', // ê
      'Ã´': 'ô', // ô
      'Ã': 'Á', // Á
      'Ã‡': 'Ç', // Ç
      'Ãš': 'Ú', // Ú
      'Ã"': 'Ó', // Ó
      'Ã‰': 'É', // É
      'Ã€': 'À', // À
      'Ãƒ': 'Ã', // Ã
      'PÃº': 'Pú', // Pú
      'Ã§Ã£': 'çã', // çã
      'Ã§Ãµ': 'çõ', // çõ
    };
    
    String resultado = texto;
    
    // Aplicar correções
    mapaCorrecoes.forEach((chave, valor) {
      resultado = resultado.replaceAll(chave, valor);
    });
    
    return resultado;
  }
}
