import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/services/ia_service.dart';
import '../data/models/materia.dart';
import '../data/models/assunto.dart';

/// Serviço para classificar documentos e identificar matéria/assunto
class DocumentClassifierService {
  final IAService _iaService;

  DocumentClassifierService(this._iaService);

  /// Identifica a matéria e assunto de um documento
  Future<Map<String, dynamic>> identificarMateriaAssunto(String texto) async {
    if (!_iaService.isConfigured) {
      throw Exception('Serviço de IA não configurado');
    }

    try {
      // Preparar o prompt para classificação
      final prompt = '''
      Você é um especialista em classificação de documentos para concursos públicos. Analise o texto fornecido e identifique:

      1. A matéria principal do texto (ex: Direito Constitucional, Direito Administrativo, Português, Matemática, etc.)
      2. O assunto específico dentro dessa matéria (ex: Princípios Constitucionais, Atos Administrativos, etc.)

      Retorne apenas um objeto JSON com o seguinte formato:
      {
        "materia": "Nome da matéria",
        "assunto": "Nome do assunto",
        "confianca": 0.95 // Nível de confiança da classificação (0.0 a 1.0)
      }

      Texto para análise:
      ${texto.length > 5000 ? texto.substring(0, 5000) + "..." : texto}
      ''';

      // Chamar a API usando o método público
      final resposta = await _iaService.callApiWithPrompt(prompt);

      // Extrair o JSON da resposta
      final jsonStr = _extrairJsonDaResposta(resposta);

      // Converter para Map
      final Map<String, dynamic> resultado = json.decode(jsonStr);

      return resultado;
    } catch (e) {
      print('Erro ao identificar matéria/assunto: $e');
      return {
        'materia': 'Não identificado',
        'assunto': 'Não identificado',
        'confianca': 0.0
      };
    }
  }

  /// Identifica a matéria e assunto de um documento PDF
  Future<Map<String, dynamic>> identificarMateriaAssuntoPdf(Uint8List pdfBytes, String textoExtraido) async {
    // Usar o texto extraído para identificar a matéria e assunto
    return await identificarMateriaAssunto(textoExtraido);
  }

  /// Extrai o JSON da resposta da API
  String _extrairJsonDaResposta(String resposta) {
    // Procurar por um objeto JSON na resposta
    final regExp = RegExp(r'\{[\s\S]*\}');
    final match = regExp.firstMatch(resposta);

    if (match != null) {
      return match.group(0)!;
    }

    // Se não encontrar um objeto JSON, retornar um objeto padrão
    return '{"materia": "Não identificado", "assunto": "Não identificado", "confianca": 0.0}';
  }

  /// Sugere matérias e assuntos com base em um texto
  Future<List<Map<String, dynamic>>> sugerirMateriasAssuntos(String texto) async {
    if (!_iaService.isConfigured) {
      throw Exception('Serviço de IA não configurado');
    }

    try {
      // Preparar o prompt para sugestão de múltiplas matérias/assuntos
      final prompt = '''
      Você é um especialista em classificação de documentos para concursos públicos. Analise o texto fornecido e identifique:

      1. As principais matérias presentes no texto
      2. Os assuntos específicos dentro de cada matéria

      Retorne apenas um array JSON com o seguinte formato:
      [
        {
          "materia": "Nome da matéria 1",
          "assunto": "Nome do assunto 1",
          "confianca": 0.95
        },
        {
          "materia": "Nome da matéria 2",
          "assunto": "Nome do assunto 2",
          "confianca": 0.85
        }
      ]

      Limite a resposta a no máximo 5 matérias/assuntos mais relevantes.

      Texto para análise:
      ${texto.length > 5000 ? texto.substring(0, 5000) + "..." : texto}
      ''';

      // Chamar a API usando o método público
      final resposta = await _iaService.callApiWithPrompt(prompt);

      // Extrair o JSON da resposta
      final jsonStr = _extrairArrayJsonDaResposta(resposta);

      // Converter para List<Map>
      final List<dynamic> resultado = json.decode(jsonStr);

      return resultado.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erro ao sugerir matérias/assuntos: $e');
      return [
        {
          'materia': 'Não identificado',
          'assunto': 'Não identificado',
          'confianca': 0.0
        }
      ];
    }
  }

  /// Extrai o array JSON da resposta da API
  String _extrairArrayJsonDaResposta(String resposta) {
    // Procurar por um array JSON na resposta
    final regExp = RegExp(r'\[[\s\S]*\]');
    final match = regExp.firstMatch(resposta);

    if (match != null) {
      return match.group(0)!;
    }

    // Se não encontrar um array JSON, retornar um array padrão
    return '[{"materia": "Não identificado", "assunto": "Não identificado", "confianca": 0.0}]';
  }
}
