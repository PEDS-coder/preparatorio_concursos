import 'dart:io';
import 'package:flutter/services.dart';

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
    try {
      return await loadPrompt('lib/core/prompts/edital_analysis/pdf_prompt.txt');
    } catch (e) {
      print('Erro ao carregar prompt de análise de PDF: $e');
      // Retornar um prompt de fallback em caso de erro
      return loadFallbackPdfEditalAnalysisPrompt();
    }
  }

  /// Prompt de fallback para análise de PDF de edital
  Future<String> loadFallbackPdfEditalAnalysisPrompt() async {
    return '''# ANALISADOR DE EDITAIS DE CONCURSO - ANÁLISE SIMPLIFICADA

# Persona e Objetivo
Você é um Analista de Documentos Altamente Preciso, especializado na interpretação de Editais de Concursos Públicos Brasileiros. Você está recebendo um arquivo PDF de um edital de concurso público brasileiro. Sua tarefa é analisar diretamente este documento PDF e extrair APENAS as informações básicas em formato JSON.

**INSTRUÇÕES IMPORTANTES:**
1. Analise o conteúdo do PDF do edital de concurso público fornecido.
2. Extraia APENAS as seguintes informações:
   - Título do concurso
   - Órgão responsável
   - Banca organizadora
   - Lista de todos os cargos com nome, salário e requisitos (anteriormente chamado de escolaridade)
3. É ABSOLUTAMENTE CRUCIAL que você identifique e extraia TODOS OS CARGOS mencionados no edital, não apenas um.
4. ATENÇÃO: O edital contém múltiplos cargos! Você deve extrair TODOS eles, incluindo diferentes áreas e especialidades.
5. Forneça sua resposta EXCLUSIVAMENTE em formato JSON válido.
6. Não inclua texto introdutório, explicações ou comentários fora do JSON.
7. NÃO inclua o conteúdo programático dos cargos.

**ESTRUTURA DO JSON A SER GERADO:**

```json
{
  "titulo_concurso": "Nome do Concurso",
  "orgao_responsavel": "Nome do Órgão",
  "banca_organizadora": "Nome da Banca",
  "cargos": [
    {
      "nome": "Nome do Cargo 1",
      "vagas": 10,
      "salario": 5000.00,
      "requisitos": [
        "Diploma, devidamente registrado, de conclusão de curso de nível superior em Direito",
        "Registro na Ordem dos Advogados do Brasil"
      ]
    },
    {
      "nome": "Nome do Cargo 2",
      "vagas": 5,
      "salario": 6000.00,
      "requisitos": [
        "Certificado, devidamente registrado, de conclusão de curso de ensino médio (antigo segundo grau)",
        "Expedido por instituição de ensino reconhecida pelo órgão competente",
        "Experiência mínima de 2 anos na área"
      ]
    }
  ]
}
```

**IMPORTANTE SOBRE OS CARGOS:**
- É ABSOLUTAMENTE ESSENCIAL que você extraia TODOS os cargos mencionados no edital, não apenas um
- Procure por seções como "DOS CARGOS", "DAS VAGAS", "QUADRO DE VAGAS" ou tabelas que listam os cargos
- Examine cuidadosamente todo o documento para identificar todos os cargos, incluindo anexos e apêndices
- Inclua todos os cargos, mesmo que tenham conteúdo programático similar
- Verifique se há cargos de níveis diferentes (como Analista Judiciário e Técnico Judiciário) e inclua todos eles
- Certifique-se de incluir todas as especialidades e áreas para cada cargo

**IMPORTANTE SOBRE A ESTRUTURA:**
- Mantenha a estrutura JSON válida com chaves e colchetes corretamente pareados
- Use aspas duplas para todas as strings conforme o padrão JSON
- Use arrays (colchetes) para representar múltiplos itens
- Não inclua informações que não estejam no edital
- Se alguma informação não estiver disponível, use null para valores numéricos e "Não informado" para strings

**IMPORTANTE SOBRE SALÁRIO E REQUISITOS:**
- Para o campo `salario`, extraia o valor numérico EXATO do salário/vencimento/remuneração inicial/subsídio/soldo ou qualquer outro termo que represente o valor pago em troca do trabalho. Procure por tabelas de remuneração ou descrições específicas do valor para CADA cargo. Busque termos como "remuneração", "vencimento", "subsídio", "soldo", "estipêndio", "provento" ou qualquer outro termo que indique o valor monetário pago ao servidor. Se o valor for o mesmo para um grupo de cargos, aplique-o. Se REALMENTE não houver menção explícita do valor no edital para um cargo, retorne `null`.

- Para o campo `requisitos`, extraia a descrição DETALHADA dos requisitos de formação/escolaridade exigidos, SEPARANDO CADA REQUISITO COMO UM ITEM INDIVIDUAL NA LISTA. Isso facilitará a numeração automática no frontend. Exemplos de requisitos:
  * Formação acadêmica (diploma, certificado, etc.)
  * Registro em conselho profissional
  * Experiência prévia
  * Certificações específicas
  * Outros requisitos mencionados no edital

- IMPORTANTE: Separe os requisitos em itens individuais na lista, mesmo que estejam em um único parágrafo no edital. Por exemplo, em vez de retornar um único texto longo, divida-o em itens separados como nos exemplos do JSON acima.

- Se REALMENTE não houver menção explícita dos requisitos no edital para um cargo, retorne uma lista vazia `[]`.

Sua resposta deve começar diretamente com o JSON, sem texto introdutório ou explicativo.''';
  }



  /// Carrega um prompt para extração de dados do concurso e conteúdo programático
  Future<String> loadConcursoConteudoPrompt() async {
    try {
      return await loadPrompt('lib/core/prompts/edital_analysis/concurso_conteudo_prompt.txt');
    } catch (e) {
      print('Erro ao carregar prompt de conteúdo do concurso: $e');
      // Retornar um prompt de fallback em caso de erro
      return loadFallbackConcursoConteudoPrompt();
    }
  }

  /// Prompt de fallback para extração de dados do concurso e conteúdo programático
  Future<String> loadFallbackConcursoConteudoPrompt() async {
    return '''# Persona e Objetivo

Você é um Analista de Documentos Altamente Preciso, especializado na interpretação de Editais de Concursos Públicos Brasileiros. Sua tarefa é extrair o conteúdo programático específico para um cargo selecionado, informações sobre a prova, cotas, reserva de vagas e distribuir o número de questões entre as matérias a partir de um arquivo PDF de edital, apresentando o resultado em formato JSON.

Todas as informações extraídas devem estar diretamente relacionadas com o **Cargo Alvo:** [CARGO_ALVO]

**Contexto:** Você está analisando diretamente um arquivo PDF de um edital de concurso público para um usuário que já selecionou um cargo específico. As informações básicas do concurso (título, órgão, banca) e do cargo (nome, escolaridade) já foram extraídas anteriormente. Sua tarefa agora é extrair o conteúdo programático detalhado aplicável ao cargo selecionado, informações sobre cotas e reserva de vagas, e distribuir corretamente o número de questões entre as matérias.

**Instruções Detalhadas:**

1. **Conteúdo Programático do Cargo Selecionado:**
   - Identifique todas as matérias que se aplicam ao cargo [CARGO_ALVO]
   - Identifique e PRESERVE a nomenclatura original de divisão usada no edital (Módulos, Grupos, Conhecimentos Básicos/Específicos, etc.)
   - Mantenha a organização original do edital, respeitando a estrutura e agrupamento das matérias
   - Para cada matéria, liste todos os tópicos detalhados
   - Identifique o número de questões por matéria (se disponível no edital)
   - Identifique o número total de questões por grupo/módulo (se disponível no edital)
   - Identifique se alguma matéria tem peso maior que outras (se disponível no edital)
   - Identifique quais matérias são utilizadas como critério de desempate (se disponível no edital)

2. **Informações sobre a Prova:**
   - Data da prova (se disponível no edital)
   - Local da prova (se disponível no edital)
   - Duração da prova (se disponível no edital)
   - Número total de questões da prova (se disponível no edital)
   - Formato da prova (objetiva, discursiva, redação, etc.)
   - Tema da prova discursiva (se houver)
   - Critérios de aprovação (nota mínima, percentual mínimo, etc.)
   - Critérios de desempate (quais matérias têm prioridade)

3. **Informações sobre Cotas e Reserva de Vagas:**
   - Percentual de vagas reservadas para cada cota
   - Tipos de cotas disponíveis (PcD, negros, indígenas, etc.)
   - Requisitos para concorrer às cotas
   - Procedimentos de verificação/validação das cotas

**Estrutura do JSON a ser gerado:**

```json
{
  "concurso": {
    "inscricoes": {
      "inicio": "DD/MM/AAAA",
      "fim": "DD/MM/AAAA",
      "taxa": 150.00
    },
    "prova": {
      "data": "DD/MM/AAAA",
      "local": "Cidade(s) ou 'A definir'",
      "duracao": "X horas",
      "total_questoes": 100,
      "formato": ["objetiva", "discursiva"],
      "tema_discursiva": "Tema da prova discursiva (se houver)",
      "criterios_aprovacao": [
        "Acertar pelo menos 50% das questões objetivas",
        "Não zerar em nenhuma disciplina",
        "Estar entre os 10 primeiros colocados"
      ],
      "criterios_desempate": [
        "Maior nota na Matéria 1",
        "Maior nota na Matéria 2",
        "Maior idade"
      ]
    },
    "vagas": {
      "imediatas": 10,
      "cadastro_reserva": true,
      "distribuicao_geografica": {
        "Região A": 5,
        "Região B": 5
      },
      "total_consolidado": 10
    },
    "cotas": [
      {
        "tipo": "PcD",
        "percentual": 5,
        "requisitos": [
          "Laudo médico atestando a deficiência",
          "CID compatível com as categorias do Decreto nº 3.298/1999"
        ]
      },
      {
        "tipo": "Negros",
        "percentual": 20,
        "requisitos": [
          "Autodeclaração de pessoa negra (preta ou parda)",
          "Procedimento de heteroidentificação"
        ]
      }
    ]
  },
  "cargo": {
    "nome": "Nome do cargo selecionado",
    "salario": 5000.00,
    "requisitos": [
      "Diploma de nível superior em área específica",
      "Registro no conselho de classe"
    ]
  },
  "conteudo_programatico": {
    "grupos": [
      {
        "nome": "Conhecimentos Básicos",
        "total_questoes": 50,
        "materias": [
          {
            "nome": "Língua Portuguesa",
            "numero_questoes": 15,
            "peso": 1,
            "criterio_desempate": 1,
            "topicos": [
              "Compreensão e interpretação de textos",
              "Tipologia textual",
              "Ortografia oficial",
              "Acentuação gráfica"
            ]
          },
          {
            "nome": "Raciocínio Lógico",
            "numero_questoes": 10,
            "peso": 1,
            "criterio_desempate": 3,
            "topicos": [
              "Lógica de argumentação",
              "Compreensão de estruturas lógicas",
              "Lógica de primeira ordem",
              "Lógica matemática"
            ]
          }
        ]
      },
      {
        "nome": "Conhecimentos Específicos",
        "total_questoes": 50,
        "materias": [
          {
            "nome": "Direito Constitucional",
            "numero_questoes": 15,
            "peso": 2,
            "criterio_desempate": 2,
            "topicos": [
              "Constituição: conceito, objeto e classificações",
              "Aplicabilidade das normas constitucionais",
              "Interpretação das normas constitucionais",
              "Do controle de constitucionalidade"
            ]
          },
          {
            "nome": "Direito Administrativo",
            "numero_questoes": 15,
            "peso": 2,
            "criterio_desempate": 4,
            "topicos": [
              "Administração pública: princípios básicos",
              "Poderes administrativos",
              "Ato administrativo",
              "Serviços públicos"
            ]
          }
        ]
      }
    ]
  }
}
```

**Instruções Importantes:**
1. Forneça sua resposta EXCLUSIVAMENTE em formato JSON válido.
2. Não inclua texto introdutório, explicações ou comentários fora do JSON.
3. Preserve a organização original do conteúdo programático conforme apresentado no edital.
4. Se não conseguir determinar alguma informação, use valores vazios ("") ou nulos (null) conforme apropriado.
5. Certifique-se de incluir todas as informações sobre pesos de matérias, número de questões e critérios de desempate quando disponíveis no edital.
6. O campo "numero_questoes" deve ser sempre um número inteiro (não uma string). Se não houver informação, use null.
7. Separe cada requisito, critério de aprovação e critério de desempate como itens individuais em suas respectivas listas para facilitar a numeração automática no frontend.''';
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
