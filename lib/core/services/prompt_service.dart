import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

/// Serviço para gerenciar prompts utilizados nas requisições à LLM
class PromptService {
  // Mapa para armazenar os prompts carregados em memória
  final Map<String, String> _promptCache = {};

  // Singleton
  static final PromptService _instance = PromptService._internal();
  factory PromptService() => _instance;
  PromptService._internal();

  /// Carrega um prompt a partir do arquivo especificado usando o AssetBundle
  Future<String> loadPrompt(String promptPath) async {
    // Limpar o cache para garantir que sempre carregue a versão mais recente
    // Comentar esta linha em produção para melhorar o desempenho
    _promptCache.clear();

    // Verificar se o prompt já está em cache
    if (_promptCache.containsKey(promptPath)) {
      return _promptCache[promptPath]!;
    }

    try {
      // Carregar o prompt do arquivo
      final String promptContent = await rootBundle.loadString(promptPath);

      // Armazenar em cache para uso futuro
      _promptCache[promptPath] = promptContent;

      return promptContent;
    } catch (e) {
      print('Erro ao carregar prompt de $promptPath: $e');
      throw Exception('Não foi possível carregar o prompt: $e');
    }
  }

  /// Carrega um arquivo de prompt a partir do caminho do arquivo
  Future<String> loadFile(String filePath) async {
    // Verificar se o arquivo já está em cache
    if (_promptCache.containsKey(filePath)) {
      return _promptCache[filePath]!;
    }

    try {
      // Tentar carregar usando o AssetBundle primeiro
      try {
        final String content = await rootBundle.loadString(filePath);
        _promptCache[filePath] = content;
        return content;
      } catch (assetError) {
        // Se falhar, tentar carregar diretamente do sistema de arquivos
        final File file = File(filePath);
        if (await file.exists()) {
          final String content = await file.readAsString();
          _promptCache[filePath] = content;
          return content;
        } else {
          throw Exception('Arquivo não encontrado: $filePath');
        }
      }
    } catch (e) {
      print('Erro ao carregar arquivo de $filePath: $e');
      throw Exception('Não foi possível carregar o arquivo: $e');
    }
  }

  /// Carrega um prompt para análise comparativa de edital
  Future<String> loadComparativeEditalAnalysisPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/comparative_prompt.txt');
  }

  /// Métodos obsoletos removidos:
  /// - loadTraditionalEditalAnalysisPrompt()
  /// - loadSimpleEditalAnalysisPrompt()
  /// - loadYamlEditalAnalysisPrompt()

  /// Carrega um prompt para análise de edital em formato JSON
  Future<String> loadJsonEditalAnalysisPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/json_prompt.txt');
  }

  /// Carrega um prompt para análise direta de PDF de edital
  Future<String> loadPdfEditalAnalysisPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/pdf_prompt.txt');
  }

  /// Carrega um prompt para extração de informações básicas do edital
  Future<String> loadBasicInfoEditalPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/basic_info_prompt.txt');
  }

  /// Carrega um prompt para extração de conteúdo programático de um cargo específico
  Future<String> loadContentEditalPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/content_prompt.txt');
  }

  /// Carrega um prompt para extração de conteúdo programático em formato JSON
  Future<String> loadContentJsonPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/content_json_prompt.txt');
  }

  /// Carrega um prompt para extração apenas dos cargos do edital
  @deprecated
  Future<String> loadCargosEditalPrompt() async {
    // Este método está obsoleto e não deve mais ser utilizado.
    throw UnimplementedError('Use loadCargosDetalhadosPrompt() para garantir extração completa dos cargos.');
  }

  /// Carrega um prompt para extração detalhada dos cargos do edital
  Future<String> loadCargosDetalhadosPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/cargos_detalhados_prompt.txt');
  }

  /// Carrega um prompt para extração de dados do concurso e conteúdo programático
  Future<String> loadConcursoConteudoPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/concurso_conteudo_prompt.txt');
  }

  /// Carrega um prompt para análise comparativa de edital em texto simples
  Future<String> loadSimpleComparativeEditalAnalysisPrompt() async {
    return await loadPrompt('lib/core/prompts/edital_analysis/simple_comparative_prompt.txt');
  }

  /// Carrega um prompt para geração de resumos
  Future<String> loadSummaryGenerationPrompt() async {
    return await loadPrompt('lib/core/prompts/summary_generation.txt');
  }

  /// Carrega um prompt para geração de flashcards
  Future<String> loadFlashcardGenerationPrompt() async {
    return await loadPrompt('lib/core/prompts/flashcard_generation.txt');
  }

  /// Carrega um prompt para geração de mapas mentais
  Future<String> loadMindmapGenerationPrompt() async {
    return await loadPrompt('lib/core/prompts/mindmap_generation.txt');
  }

  /// Carrega um prompt para geração de questões
  Future<String> loadQuestionGenerationPrompt() async {
    return await loadPrompt('lib/core/prompts/question_generation.txt');
  }

  /// Carrega um prompt para geração de plano de estudos
  Future<String> loadStudyPlanGenerationPrompt() async {
    return await loadPrompt('lib/core/prompts/study_plan_generation.txt');
  }

  /// Carrega o novo prompt para geração de plano de estudos
  Future<String> loadNewStudyPlanGenerationPrompt() async {
    return await loadFile('lib/core/prompts/study_plan_generation_new.txt');
  }

  /// Carrega o prompt para geração de plano de estudos com ciclos
  Future<String> loadStudyPlanCycleGenerationPrompt() async {
    return await loadFile('lib/core/prompts/study_plan_cycle_generation.txt');
  }

  /// Carrega um prompt para geração de plano de estudos (alias para compatibilidade)
  Future<String> loadStudyPlanPrompt() async {
    // Usar o prompt de ciclos por padrão
    return await loadStudyPlanCycleGenerationPrompt();
  }

  /// Carrega um prompt para análise básica de informações em fallback
  Future<String> loadFallbackBasicInfoPrompt() async {
    return '''Você é um especialista em análise de editais de concursos públicos brasileiros.
    Extraia as informações básicas do edital (título, órgão, banca, datas de inscrição, taxa).
    Responda APENAS em formato JSON com os seguintes campos:
    {
      "titulo": "Nome do concurso",
      "orgao": "Nome do órgão",
      "banca": "Nome da banca organizadora",
      "inicioInscricao": "DD/MM/YYYY",
      "fimInscricao": "DD/MM/YYYY",
      "valorTaxa": 123.45,
      "dataProva": "DD/MM/YYYY",
      "localProva": "Local da prova"
    }''';
  }

  /// Carrega um prompt para análise de cargos em fallback
  Future<String> loadFallbackCargoInfoPrompt() async {
    return '''Você é um especialista em análise de editais de concursos públicos brasileiros.
    Extraia as informações sobre os cargos mencionados no edital.
    Responda APENAS em formato JSON com uma lista de cargos:
    [
      {
        "nome": "Nome do cargo",
        "vagas": 10,
        "salario": 5000.00,
        "escolaridade": "Nível de escolaridade exigido",
        "conteudoProgramatico": ["Disciplina 1", "Disciplina 2"]
      }
    ]''';
  }

  /// Personaliza um prompt com variáveis específicas
  String customizePrompt(String promptTemplate, Map<String, String> variables) {
    String customizedPrompt = promptTemplate;

    // Substituir cada variável no template
    variables.forEach((key, value) {
      customizedPrompt = customizedPrompt.replaceAll('{{$key}}', value);
    });

    return customizedPrompt;
  }
}
