import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../data/models/edital.dart';
import 'pdf_processor_simple.dart';

/// Classe para extração local de dados de editais de concursos públicos
/// Utiliza o sistema de extração Python implementado localmente
class LocalEditalExtractor {
  // Callback para reportar progresso
  final Function(double progress, String message)? onProgress;

  // Construtor
  LocalEditalExtractor({this.onProgress});

  /// Analisa um edital usando o extrator local
  Future<DadosExtraidos> analisarEdital(Uint8List pdfBytes) async {
    _reportProgress(0.1, 'Iniciando extração local de dados do edital...');

    try {
      // Criar o processador de PDF
      final pdfProcessor = PdfProcessorSimple(
        onProgress: (progress, message) {
          _reportProgress(0.1 + progress * 0.7, message);
        },
      );

      // Extrair texto do PDF
      final String textoExtraido = await pdfProcessor.extractTextFromPdfBytes(pdfBytes);

      _reportProgress(0.8, 'Processando dados extraídos...');

      // Extrair informações básicas do edital
      final String titulo = _extrairTituloEdital(textoExtraido);
      final String banca = _detectarBanca(textoExtraido);
      final String orgao = _extrairOrgao(textoExtraido);
      final String dataInscricaoInicio = _extrairDataInscricaoInicio(textoExtraido);
      final String dataInscricaoFim = _extrairDataInscricaoFim(textoExtraido);
      final String taxaInscricao = _extrairTaxaInscricao(textoExtraido);
      final String dataProva = _extrairDataProva(textoExtraido);
      final String localProva = _extrairLocalProva(textoExtraido);

      // Extrair cargos e conteúdo programático
      final List<Map<String, dynamic>> cargos = _extrairCargos(textoExtraido);
      final List<Map<String, dynamic>> conhecimentosBasicos = _extrairConhecimentosBasicos(textoExtraido);

      // Criar um mapa com os dados extraídos
      final Map<String, dynamic> result = {
        'identificacao': {
          'titulo': titulo,
          'banca': banca,
          'orgao': orgao,
        },
        'inscricao': {
          'periodo_inicio': dataInscricaoInicio,
          'periodo_fim': dataInscricaoFim,
          'taxa': taxaInscricao,
        },
        'prova': {
          'data': dataProva,
          'local': localProva,
        },
        'cargos': cargos,
        'conteudo_programatico': {
          'conhecimentos_basicos': conhecimentosBasicos,
          'conhecimentos_especificos': {},
        },
      };

      // Converter os dados extraídos para o formato DadosExtraidos
      final dadosExtraidos = _converterParaDadosExtraidos(result);

      _reportProgress(1.0, 'Extração concluída com sucesso!');

      return dadosExtraidos;
    } catch (e) {
      _log('Erro ao analisar edital: $e');
      throw Exception('Falha na extração de dados do edital: $e');
    }
  }

  /// Executa o script Python de extração de dados
  Future<Map<String, dynamic>> _executarExtratorPython(String pdfPath) async {
    try {
      _reportProgress(0.3, 'Iniciando processo de extração...');

      // Caminho para o script Python
      final scriptPath = 'extrair_edital.py';

      // Diretório de saída para os dados extraídos
      final tempDir = await getTemporaryDirectory();
      final outputDir = '${tempDir.path}/edital_output';

      // Criar diretório de saída se não existir
      final outputDirFile = Directory(outputDir);
      if (!await outputDirFile.exists()) {
        await outputDirFile.create(recursive: true);
      }

      // Comando para executar o script Python
      final command = 'python';
      final arguments = [
        scriptPath,
        pdfPath,
        '-o',
        outputDir,
      ];

      _reportProgress(0.4, 'Executando extrator de dados...');

      // Executar o comando
      ProcessResult processResult;
      if (Platform.isWindows) {
        processResult = await Process.run(command, arguments);
      } else {
        processResult = await Process.run('python3', arguments);
      }

      // Verificar se o processo foi executado com sucesso
      if (processResult.exitCode != 0) {
        _log('Erro ao executar o extrator: ${processResult.stderr}');
        throw Exception('Falha ao executar o extrator de dados: ${processResult.stderr}');
      }

      _reportProgress(0.6, 'Lendo dados extraídos...');

      // Ler o arquivo JSON com os dados extraídos
      final jsonFile = File('$outputDir/dados_extraidos.json');
      if (!await jsonFile.exists()) {
        throw Exception('Arquivo de dados extraídos não encontrado');
      }

      final jsonString = await jsonFile.readAsString();
      final Map<String, dynamic> result = json.decode(jsonString);

      _reportProgress(0.7, 'Dados extraídos com sucesso!');

      return result;
    } catch (e) {
      _log('Erro ao executar extrator Python: $e');
      throw Exception('Falha ao executar o extrator de dados: $e');
    }
  }

  /// Converte os dados extraídos para o formato DadosExtraidos
  DadosExtraidos _converterParaDadosExtraidos(Map<String, dynamic> dados) {
    try {
      // Extrair informações básicas
      final String titulo = dados['identificacao']?['titulo'] ?? 'Edital Analisado';
      final String banca = dados['identificacao']?['banca'] ?? 'Não especificado';

      // Extrair datas de inscrição
      DateTime? inicioInscricao;
      DateTime? fimInscricao;

      if (dados['inscricao'] != null) {
        if (dados['inscricao']['periodo_inicio'] != null) {
          inicioInscricao = _parseData(dados['inscricao']['periodo_inicio']);
        }

        if (dados['inscricao']['periodo_fim'] != null) {
          fimInscricao = _parseData(dados['inscricao']['periodo_fim']);
        }
      }

      // Extrair taxa de inscrição
      double valorTaxa = 0.0;
      if (dados['inscricao'] != null && dados['inscricao']['taxa'] != null) {
        valorTaxa = _parseValorMonetario(dados['inscricao']['taxa']);
      }

      // Extrair local da prova (se disponível)
      final String localProva = dados['localProva'] ?? 'Não especificado';

      // Extrair cargos
      List<Cargo> cargos = [];

      // Processar cargos
      if (dados['cargos'] != null && dados['cargos'] is List) {
        final List<dynamic> cargosList = dados['cargos'];

        for (var cargoData in cargosList) {
          // Extrair informações do cargo
          final String nome = cargoData['nome'] ?? 'Cargo não especificado';

          // Extrair vagas
          int vagas = 0;
          if (dados['vagas'] != null && dados['vagas'][nome] != null) {
            vagas = dados['vagas'][nome]['total'] ?? 0;
          }

          // Extrair salário
          double salario = 0.0;
          if (cargoData['remuneracao'] != null) {
            salario = _parseValorMonetario(cargoData['remuneracao']);
          }

          // Extrair escolaridade/requisitos
          final String escolaridade = cargoData['requisitos'] ?? 'Não especificado';

          // Extrair conteúdo programático
          List<ConteudoProgramatico> conteudoProgramatico = [];

          // Adicionar conhecimentos básicos
          if (dados['conteudo_programatico'] != null &&
              dados['conteudo_programatico']['conhecimentos_basicos'] != null) {

            final List<dynamic> conhecimentosBasicos =
                dados['conteudo_programatico']['conhecimentos_basicos'];

            for (var disciplina in conhecimentosBasicos) {
              conteudoProgramatico.add(
                ConteudoProgramatico(
                  nome: disciplina['disciplina'] ?? 'Disciplina não especificada',
                  tipo: 'comum',
                  topicos: List<String>.from(disciplina['topicos'] ?? []),
                )
              );
            }
          }

          // Adicionar conhecimentos específicos
          if (dados['conteudo_programatico'] != null &&
              dados['conteudo_programatico']['conhecimentos_especificos'] != null &&
              dados['conteudo_programatico']['conhecimentos_especificos'][nome] != null) {

            final List<dynamic> conhecimentosEspecificos =
                dados['conteudo_programatico']['conhecimentos_especificos'][nome];

            for (var disciplina in conhecimentosEspecificos) {
              conteudoProgramatico.add(
                ConteudoProgramatico(
                  nome: disciplina['disciplina'] ?? 'Disciplina não especificada',
                  tipo: 'específico',
                  topicos: List<String>.from(disciplina['topicos'] ?? []),
                )
              );
            }
          }

          // Se não houver conteúdo programático, adicionar disciplinas padrão
          if (conteudoProgramatico.isEmpty) {
            conteudoProgramatico = [
              ConteudoProgramatico(
                nome: 'Língua Portuguesa',
                tipo: 'comum',
                topicos: ['Interpretação de texto', 'Gramática', 'Ortografia'],
              ),
              ConteudoProgramatico(
                nome: 'Matemática',
                tipo: 'comum',
                topicos: ['Raciocínio lógico', 'Operações básicas'],
              ),
              ConteudoProgramatico(
                nome: 'Conhecimentos Gerais',
                tipo: 'comum',
                topicos: ['Atualidades', 'História', 'Geografia'],
              ),
            ];
          }

          // Criar objeto Cargo
          cargos.add(
            Cargo(
              id: DateTime.now().millisecondsSinceEpoch.toString() + nome,
              nome: nome,
              vagas: vagas,
              salario: salario,
              escolaridade: escolaridade,
              dataProva: null, // Será preenchido depois se disponível
              conteudoProgramatico: conteudoProgramatico,
            )
          );
        }
      }

      // Se não houver cargos, criar um cargo genérico
      if (cargos.isEmpty) {
        cargos = [
          Cargo(
            id: 'cargo_generico_${DateTime.now().millisecondsSinceEpoch}',
            nome: 'Cargo Genérico',
            vagas: 1,
            salario: 0.0,
            escolaridade: 'Não especificado',
            dataProva: null,
            conteudoProgramatico: [
              ConteudoProgramatico(
                nome: 'Língua Portuguesa',
                tipo: 'comum',
                topicos: ['Interpretação de texto', 'Gramática', 'Ortografia'],
              ),
              ConteudoProgramatico(
                nome: 'Matemática',
                tipo: 'comum',
                topicos: ['Raciocínio lógico', 'Operações básicas'],
              ),
              ConteudoProgramatico(
                nome: 'Conhecimentos Gerais',
                tipo: 'comum',
                topicos: ['Atualidades', 'História', 'Geografia'],
              ),
            ],
          )
        ];
      }

      // Criar e retornar o objeto DadosExtraidos
      return DadosExtraidos(
        titulo: titulo,
        banca: banca,
        inicioInscricao: inicioInscricao,
        fimInscricao: fimInscricao,
        valorTaxa: valorTaxa,
        localProva: localProva,
        cargos: cargos,
      );
    } catch (e) {
      _log('Erro ao converter dados extraídos: $e');
      throw Exception('Falha ao processar dados extraídos: $e');
    }
  }

  /// Converte uma string de data para DateTime
  DateTime? _parseData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) {
      return null;
    }

    try {
      // Verificar formato DD/MM/AAAA
      final RegExp regexDataBarra = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
      final matchBarra = regexDataBarra.firstMatch(dataStr);

      if (matchBarra != null) {
        final int dia = int.parse(matchBarra.group(1)!);
        final int mes = int.parse(matchBarra.group(2)!);
        final int ano = int.parse(matchBarra.group(3)!);
        return DateTime(ano, mes, dia);
      }

      // Verificar formato DD-MM-AAAA
      final RegExp regexDataTraco = RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})');
      final matchTraco = regexDataTraco.firstMatch(dataStr);

      if (matchTraco != null) {
        final int dia = int.parse(matchTraco.group(1)!);
        final int mes = int.parse(matchTraco.group(2)!);
        final int ano = int.parse(matchTraco.group(3)!);
        return DateTime(ano, mes, dia);
      }

      // Verificar formato por extenso
      final RegExp regexDataExtenso = RegExp(r'(\d{1,2})\s+de\s+([a-zA-Z]+)\s+de\s+(\d{4})');
      final matchExtenso = regexDataExtenso.firstMatch(dataStr);

      if (matchExtenso != null) {
        final int dia = int.parse(matchExtenso.group(1)!);
        final String mesStr = matchExtenso.group(2)!.toLowerCase();
        final int ano = int.parse(matchExtenso.group(3)!);

        // Converter nome do mês para número
        final meses = {
          'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4, 'maio': 5, 'junho': 6,
          'julho': 7, 'agosto': 8, 'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12,
        };

        final int? mes = meses[mesStr];
        if (mes != null) {
          return DateTime(ano, mes, dia);
        }
      }

      // Tentar converter diretamente (formato ISO)
      return DateTime.parse(dataStr);
    } catch (e) {
      _log('Erro ao converter data: $e');
      return null;
    }
  }

  /// Converte uma string de valor monetário para double
  double _parseValorMonetario(String? valorStr) {
    if (valorStr == null || valorStr.isEmpty) {
      return 0.0;
    }

    try {
      // Remover caracteres não numéricos, exceto pontos e vírgulas
      String valor = valorStr.replaceAll(RegExp(r'[^0-9\.,]'), '');

      // Tratar formato brasileiro (1.234,56)
      if (valor.contains(',')) {
        // Se tem vírgula, assume formato brasileiro
        // Primeiro remove pontos (separadores de milhar) e depois substitui vírgula por ponto
        valor = valor.replaceAll('.', '').replaceAll(',', '.');
      }

      return double.parse(valor);
    } catch (e) {
      _log('Erro ao converter valor monetário: $e');
      return 0.0;
    }
  }

  /// Extrai o título do edital
  String _extrairTituloEdital(String texto) {
    // Padrões comuns para títulos de editais
    final List<RegExp> padroesTitulo = [
      // Padrão 1: EDITAL Nº XX/YYYY
      RegExp(r'EDITAL\s+(?:DE\s+)?(?:N[\u00ba\.]|N[\u00da]MERO)?\s*(\d+[\s\-\/]*\d*\s*(?:de\s+)?\d{4})[^\n]*', caseSensitive: false),

      // Padrão 2: CONCURSO PÚBLICO PARA...
      RegExp(r'CONCURSO\s+P[\u00da]BLICO\s+(?:PARA|DE)\s+([^\n\.]{10,100})', caseSensitive: false),

      // Padrão 3: PROCESSO SELETIVO PARA...
      RegExp(r'PROCESSO\s+SELETIVO\s+(?:PARA|DE)\s+([^\n\.]{10,100})', caseSensitive: false),
    ];

    // Tentar cada padrão
    for (final regex in padroesTitulo) {
      final match = regex.firstMatch(texto);
      if (match != null) {
        String titulo = match.group(0) ?? '';
        if (titulo.length > 10) {
          return titulo.trim();
        }
      }
    }

    // Se não encontrou com os padrões, tentar extrair as primeiras linhas
    final List<String> linhas = texto.split('\n');
    for (int i = 0; i < Math.min(10, linhas.length); i++) {
      final linha = linhas[i].trim();
      if (linha.length > 10 &&
          (linha.toUpperCase().contains('EDITAL') ||
           linha.toUpperCase().contains('CONCURSO') ||
           linha.toUpperCase().contains('SELETIVO'))) {
        return linha;
      }
    }

    return 'Edital de Concurso Público';
  }

  /// Extrai o órgão responsavel pelo concurso
  String _extrairOrgao(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para órgãos
    final List<RegExp> padroesOrgao = [
      // Padrão 1: PREFEITURA MUNICIPAL DE XXX
      RegExp(r'PREFEITURA\s+MUNICIPAL\s+DE\s+([\p{L}\s]{3,50})', caseSensitive: false, unicode: true),

      // Padrão 2: TRIBUNAL XXX
      RegExp(r'TRIBUNAL\s+(?:REGIONAL\s+)?(?:DE\s+)?([\p{L}\s]{3,50})', caseSensitive: false, unicode: true),

      // Padrão 3: SECRETARIA XXX
      RegExp(r'SECRETARIA\s+(?:DE\s+)?(?:ESTADO\s+(?:DE\s+)?)?([\p{L}\s]{3,50})', caseSensitive: false, unicode: true),

      // Padrão 4: MINISTÉRIO XXX
      RegExp(r'MINIST[\u00c9E]RIO\s+(?:DE\s+)?([\p{L}\s]{3,50})', caseSensitive: false, unicode: true),
    ];

    // Tentar cada padrão
    for (final regex in padroesOrgao) {
      final match = regex.firstMatch(texto);
      if (match != null) {
        String orgao = match.group(0) ?? '';
        if (orgao.length > 5) {
          return orgao.trim();
        }
      }
    }

    // Lista de órgãos comuns para verificar
    final List<String> orgaosComuns = [
      'Prefeitura', 'Tribunal', 'Secretaria', 'Ministério', 'Assembleia', 'Câmara',
      'Polícia Federal', 'Polícia Civil', 'Polícia Militar', 'Corpo de Bombeiros',
      'INSS', 'Receita Federal', 'Banco do Brasil', 'Caixa Econômica Federal',
      'Petrobras', 'Eletrobras', 'Correios', 'Detran', 'Universidade', 'Instituto',
    ];

    for (final orgao in orgaosComuns) {
      if (texto_lower.contains(orgao.toLowerCase())) {
        // Tentar extrair o contexto ao redor do órgão
        final int posicao = texto_lower.indexOf(orgao.toLowerCase());
        if (posicao != -1) {
          final int inicio = Math.max(0, posicao - 20);
          final int fim = Math.min(texto.length, posicao + orgao.length + 50);
          final String trecho = texto.substring(inicio, fim);

          // Extrair uma linha completa
          final RegExp regexLinha = RegExp(r'[^\n]*' + orgao + r'[^\n]*', caseSensitive: false);
          final match = regexLinha.firstMatch(trecho);
          if (match != null) {
            return match.group(0)?.trim() ?? orgao;
          }
        }
        return orgao;
      }
    }

    return 'Não especificado';
  }

  /// Detecta a banca organizadora do concurso
  String _detectarBanca(String texto) {
    final texto_lower = texto.toLowerCase();

    // Mapa de bancas e seus identificadores
    final Map<String, List<String>> bancas = {
      'FGV': ['fgv', 'fundação getúlio vargas'],
      'CEBRASPE': ['cebraspe', 'cespe', 'centro brasileiro', 'unb'],
      'FCC': ['fcc', 'fundação carlos chagas'],
      'VUNESP': ['vunesp', 'fundação vunesp'],
      'CESGRANRIO': ['cesgranrio', 'fundação cesgranrio'],
      'QUADRIX': ['quadrix', 'instituto quadrix'],
      'IADES': ['iades', 'instituto americano'],
      'IBFC': ['ibfc', 'instituto brasileiro'],
      'AOCP': ['aocp', 'associação organização de concursos'],
      'IDECAN': ['idecan', 'instituto para o desenvolvimento'],
      'INSTITUTO ACESSO': ['acesso', 'instituto acesso'],
      'FUNDATEC': ['fundatec', 'fundação universidade empresa'],
      'CONSULPLAN': ['consulplan', 'consultoria planejamento'],
      'REDENTOR': ['redentor', 'instituto redentor'],
      'OBJETIVA': ['objetiva', 'objetiva concursos'],
      'LEGALLE': ['legalle', 'legalle concursos'],
      'AVALIA': ['avalia', 'avaliação'],
    };

    // Verificar cada banca
    for (final entry in bancas.entries) {
      for (final identificador in entry.value) {
        if (texto_lower.contains(identificador)) {
          return entry.key;
        }
      }
    }

    // Tentar encontrar a banca usando padrões comuns
    final RegExp regexBanca = RegExp(
      r'(?:banca|organizadora|realiza[\u00e7c][\u00e3a]o)\s*(?::|\-|\.)\s*([\p{L}\s]{3,50})',
      caseSensitive: false,
      unicode: true
    );

    final match = regexBanca.firstMatch(texto_lower);
    if (match != null) {
      final String bancaEncontrada = match.group(1)?.trim() ?? '';
      if (bancaEncontrada.length > 2) {
        return bancaEncontrada.split(' ').map((palavra) {
          if (palavra.isEmpty) return '';
          return palavra[0].toUpperCase() + (palavra.length > 1 ? palavra.substring(1).toLowerCase() : '');
        }).join(' ');
      }
    }

    return 'Não identificada';
  }

  /// Extrai a data de início das inscrições
  String _extrairDataInscricaoInicio(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para datas de inscrição
    final RegExp regexPeriodo = RegExp(
      r'(?:per[ií]odo|prazo)\s+(?:de|para)\s+inscri[çc][ãa]o\s+(?:ser[áa]|[ée])\s+(?:de|a partir de)\s+(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})',
      caseSensitive: false
    );

    final RegExp regexInicio = RegExp(
      r'inscri[çc][õo]es\s+(?:estar[ãa]o abertas|come[çc]a[mr]|inicia[mr]|ser[ãa]o realizadas)\s+(?:a partir\s+)?(?:de|em)\s+(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})',
      caseSensitive: false
    );

    final match1 = regexPeriodo.firstMatch(texto_lower);
    final match2 = regexInicio.firstMatch(texto_lower);

    if (match1 != null) {
      return match1.group(1) ?? '';
    } else if (match2 != null) {
      return match2.group(1) ?? '';
    }

    return '';
  }

  /// Extrai a data de fim das inscrições
  String _extrairDataInscricaoFim(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para datas de fim de inscrição
    final RegExp regexPeriodo = RegExp(
      r'(?:per[ií]odo|prazo)\s+(?:de|para)\s+inscri[çc][ãa]o\s+(?:ser[áa]|[ée])\s+(?:de\s+\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\s+(?:a|at[ée])\s+)(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})',
      caseSensitive: false
    );

    final RegExp regexFim = RegExp(
      r'inscri[çc][õo]es\s+(?:estar[ãa]o abertas|ser[ãa]o recebidas)\s+at[ée]\s+(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})',
      caseSensitive: false
    );

    // Novos padrões adicionais
    final RegExp regexAte = RegExp(
      r'(?:inscri[çc][õo]es)\s*(?:at[ée]|encerram?(?:-se)?)\s*(?:o\s+dia|dia)?\s*(\d{1,2}\s*(?:de\s+)?\s*(?:janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*(?:de\s+)?\s*\d{2,4})',
      caseSensitive: false
    );

    final RegExp regexPeriodo2 = RegExp(
      r'(?:per[í]odo|prazo)\s*(?:de|para)\s*inscri[çc][õo]es?\s*(?::|\-|\.)\s*(?:\d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4})\s*(?:a|at[ée]|e)\s*(\d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4})',
      caseSensitive: false
    );

    final RegExp regexPeriodo3 = RegExp(
      r'inscri[çc][õo]es\s*(?:de|no per[í]odo de)\s*\d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4}\s*(?:a|at[ée]|e)\s*(\d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4})',
      caseSensitive: false
    );

    // Tentar cada padrão
    final match1 = regexPeriodo.firstMatch(texto_lower);
    final match2 = regexFim.firstMatch(texto_lower);
    final match3 = regexAte.firstMatch(texto_lower);
    final match4 = regexPeriodo2.firstMatch(texto_lower);
    final match5 = regexPeriodo3.firstMatch(texto_lower);

    if (match1 != null) {
      return match1.group(1) ?? '';
    } else if (match2 != null) {
      return match2.group(1) ?? '';
    } else if (match3 != null) {
      return match3.group(1) ?? '';
    } else if (match4 != null) {
      return match4.group(1) ?? '';
    } else if (match5 != null) {
      return match5.group(1) ?? '';
    }

    return '';
  }

  /// Extrai a taxa de inscrição
  String _extrairTaxaInscricao(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para valores de taxa de inscrição
    final RegExp regexTaxa = RegExp(
      r'(?:taxa|valor)\s+(?:de|da)\s+inscri[çc][ãa]o\s+(?:[ée]|ser[áa])\s+(?:de\s+)?(R\$\s?\d{1,3}(?:\.\d{3})*,\d{2})',
      caseSensitive: false
    );

    final match = regexTaxa.firstMatch(texto_lower);

    if (match != null) {
      return match.group(1) ?? '';
    }

    return '';
  }

  /// Extrai os cargos do edital
  List<Map<String, dynamic>> _extrairCargos(String texto) {
    final texto_lower = texto.toLowerCase();
    final List<Map<String, dynamic>> cargos = [];

    // Lista de padrões para encontrar cargos
    final List<RegExp> padroesCargos = [
      // Padrão 1: Cargo/Função de NOME_DO_CARGO
      RegExp(
        r'(?:cargo|fun[çc][ãa]o)\s+(?:de|do)\s+(\p{Lu}[\p{L}\s]{3,50})',
        caseSensitive: false,
        unicode: true
      ),

      // Padrão 2: NOME_DO_CARGO - Requisitos/Atribuições
      RegExp(
        r'(\p{Lu}[\p{Lu}\s]{3,50})\s*[-:]\s*(?:requisitos|atribui[çc][\u00f5o]es|descri[çc][\u00e3a]o)',
        caseSensitive: false,
        unicode: true
      ),

      // Padrão 3: Código XXX - NOME_DO_CARGO
      RegExp(
        r'c[\u00f3o]digo\s+\d+\s*[-:]\s*(\p{Lu}[\p{L}\s]{3,50})',
        caseSensitive: false,
        unicode: true
      ),

      // Padrão 4: Tabelas com cargos (busca por linhas com salário)
      RegExp(
        r'(\p{Lu}[\p{L}\s]{5,50})\s+(?:\d+|-)\s+(?:R\$\s?\d{1,3}(?:\.\d{3})*,\d{2})',
        caseSensitive: false,
        unicode: true
      ),
    ];

    // Conjunto para evitar duplicação de cargos
    final Set<String> cargoSet = {};

    // Tentar cada padrão
    for (final regex in padroesCargos) {
      final matches = regex.allMatches(texto);

      for (final match in matches) {
        String nomeCargo = match.group(1)?.trim() ?? '';

        // Limpar e normalizar o nome do cargo
        nomeCargo = _normalizarNomeCargo(nomeCargo);

        // Ignorar cargos muito curtos, muito longos ou já encontrados
        if (nomeCargo.length > 3 && nomeCargo.length < 50 && !cargoSet.contains(nomeCargo)) {
          cargoSet.add(nomeCargo);

          // Extrair informações adicionais
          final String requisitos = _extrairRequisitos(texto, nomeCargo);
          final String remuneracao = _extrairRemuneracao(texto, nomeCargo);
          final int vagas = _extrairVagas(texto, nomeCargo);

          cargos.add({
            'nome': nomeCargo,
            'requisitos': requisitos,
            'remuneracao': remuneracao,
            'vagas': vagas,
          });
        }
      }
    }

    // Buscar por cargos comuns se nenhum foi encontrado
    if (cargos.isEmpty) {
      final List<String> cargosComuns = [
        'Analista Administrativo',
        'Técnico Administrativo',
        'Analista Judiciário',
        'Técnico Judiciário',
        'Auditor Fiscal',
        'Agente Administrativo',
        'Assistente Administrativo',
        'Escrivão',
        'Delegado',
        'Perito',
        'Agente de Polícia',
        'Professor',
      ];

      for (final cargo in cargosComuns) {
        if (texto_lower.contains(cargo.toLowerCase())) {
          cargos.add({
            'nome': cargo,
            'requisitos': _extrairRequisitos(texto, cargo),
            'remuneracao': _extrairRemuneracao(texto, cargo),
            'vagas': _extrairVagas(texto, cargo),
          });
        }
      }
    }

    // Se ainda não encontrou cargos, criar cargos genéricos baseados no tipo de concurso
    if (cargos.isEmpty) {
      if (texto_lower.contains('tribunal') || texto_lower.contains('judiciário')) {
        cargos.add({
          'nome': 'Analista Judiciário',
          'requisitos': 'Nível Superior',
          'remuneracao': _extrairRemuneracaoGeral(texto),
          'vagas': 1,
        });
        cargos.add({
          'nome': 'Técnico Judiciário',
          'requisitos': 'Nível Médio',
          'remuneracao': _extrairRemuneracaoGeral(texto),
          'vagas': 1,
        });
      } else if (texto_lower.contains('prefeitura') || texto_lower.contains('municipal')) {
        cargos.add({
          'nome': 'Assistente Administrativo',
          'requisitos': 'Nível Médio',
          'remuneracao': _extrairRemuneracaoGeral(texto),
          'vagas': 1,
        });
      } else {
        cargos.add({
          'nome': 'Analista',
          'requisitos': 'Nível Superior',
          'remuneracao': _extrairRemuneracaoGeral(texto),
          'vagas': 1,
        });
      }
    }

    return cargos;
  }

  /// Extrai os requisitos para um cargo específico
  String _extrairRequisitos(String texto, String cargo) {
    final texto_lower = texto.toLowerCase();
    final cargo_lower = cargo.toLowerCase();

    // Tentar encontrar requisitos próximos ao nome do cargo
    final int posicaoCargo = texto_lower.indexOf(cargo_lower);

    if (posicaoCargo != -1) {
      // Buscar em um trecho após o nome do cargo
      final String trecho = texto_lower.substring(
        posicaoCargo,
        posicaoCargo + 500 > texto_lower.length ? texto_lower.length : posicaoCargo + 500
      );

      // Padrões comuns para requisitos
      final RegExp regexRequisitos = RegExp(
        r'(?:requisitos?|escolaridade|forma[çc][ãa]o)\s*(?:m[íi]nima?|exigida?|necess[áa]ria?)?\s*(?::|\-|\.)\s*([^\n\.]{5,150})',
        caseSensitive: false
      );

      final match = regexRequisitos.firstMatch(trecho);

      if (match != null) {
        return match.group(1)?.trim() ?? 'Não especificado';
      }
    }

    return 'Não especificado';
  }

  /// Normaliza o nome do cargo (remove caracteres especiais, corrige capitalização)
  String _normalizarNomeCargo(String nomeCargo) {
    // Remover caracteres especiais e espaços extras
    String normalizado = nomeCargo.replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ');
    normalizado = normalizado.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Corrigir capitalização (primeira letra de cada palavra maiúscula)
    normalizado = normalizado.split(' ').map((palavra) {
      if (palavra.isEmpty) return '';
      return palavra[0].toUpperCase() + (palavra.length > 1 ? palavra.substring(1).toLowerCase() : '');
    }).join(' ');

    return normalizado;
  }

  /// Extrai o número de vagas para um cargo específico
  int _extrairVagas(String texto, String cargo) {
    final texto_lower = texto.toLowerCase();
    final cargo_lower = cargo.toLowerCase();

    // Tentar encontrar informações sobre vagas próximas ao nome do cargo
    final int posicaoCargo = texto_lower.indexOf(cargo_lower);

    if (posicaoCargo != -1) {
      // Buscar em um trecho após o nome do cargo
      final String trecho = texto_lower.substring(
        posicaoCargo,
        posicaoCargo + 300 > texto_lower.length ? texto_lower.length : posicaoCargo + 300
      );

      // Padrões comuns para número de vagas
      final List<RegExp> regexVagas = [
        RegExp(r'\b(\d+)\s+(?:vagas?|posi[\u00e7c][\u00f5o]es)\b', caseSensitive: false),
        RegExp(r'(?:vagas?|posi[\u00e7c][\u00f5o]es)\s*(?::|\-|\.)\s*(\d+)', caseSensitive: false),
        RegExp(r'\b(\d+)\s+(?:vagas?|posi[\u00e7c][\u00f5o]es)\b', caseSensitive: false),
      ];

      for (final regex in regexVagas) {
        final match = regex.firstMatch(trecho);
        if (match != null) {
          final vagasStr = match.group(1);
          if (vagasStr != null) {
            try {
              return int.parse(vagasStr);
            } catch (e) {
              // Ignorar erro de conversão
            }
          }
        }
      }
    }

    // Buscar vagas em todo o texto
    final RegExp regexVagasGeral = RegExp(
      r'total\s+de\s+(\d+)\s+(?:vagas?|posi[\u00e7c][\u00f5o]es)',
      caseSensitive: false
    );

    final match = regexVagasGeral.firstMatch(texto_lower);
    if (match != null) {
      final vagasStr = match.group(1);
      if (vagasStr != null) {
        try {
          return int.parse(vagasStr);
        } catch (e) {
          // Ignorar erro de conversão
        }
      }
    }

    return 0; // Valor padrão se não encontrar
  }

  /// Extrai a remuneração geral mencionada no edital
  String _extrairRemuneracaoGeral(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para remuneração
    final List<RegExp> regexRemuneracao = [
      RegExp(
        r'(?:remunera[\u00e7c][\u00e3a]o|vencimentos?|sal[\u00e1a]rio|vencimento\s+b[\u00e1a]sico)\s*(?::|\-|\.)\s*(R\$\s?\d{1,3}(?:\.\d{3})*,\d{2})',
        caseSensitive: false
      ),
      RegExp(
        r'(R\$\s?\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:de\s+)?(?:remunera[\u00e7c][\u00e3a]o|vencimentos?|sal[\u00e1a]rio)',
        caseSensitive: false
      ),
    ];

    for (final regex in regexRemuneracao) {
      final match = regex.firstMatch(texto_lower);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }

    return '';
  }

  /// Extrai a remuneração para um cargo específico
  String _extrairRemuneracao(String texto, String cargo) {
    final texto_lower = texto.toLowerCase();
    final cargo_lower = cargo.toLowerCase();

    // Tentar encontrar remuneração próxima ao nome do cargo
    final int posicaoCargo = texto_lower.indexOf(cargo_lower);

    if (posicaoCargo != -1) {
      // Buscar em um trecho após o nome do cargo
      final String trecho = texto_lower.substring(
        posicaoCargo,
        posicaoCargo + 500 > texto_lower.length ? texto_lower.length : posicaoCargo + 500
      );

      // Padrões comuns para remuneração
      final List<RegExp> regexRemuneracao = [
        RegExp(
          r'(?:remunera[\u00e7c][\u00e3a]o|vencimentos?|sal[\u00e1a]rio|vencimento\s+b[\u00e1a]sico)\s*(?::|\-|\.)\s*(R\$\s?\d{1,3}(?:\.\d{3})*,\d{2})',
          caseSensitive: false
        ),
        RegExp(
          r'(R\$\s?\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:de\s+)?(?:remunera[\u00e7c][\u00e3a]o|vencimentos?|sal[\u00e1a]rio)',
          caseSensitive: false
        ),
      ];

      for (final regex in regexRemuneracao) {
        final match = regex.firstMatch(trecho);
        if (match != null) {
          return match.group(1)?.trim() ?? '';
        }
      }
    }

    // Se não encontrou remuneração específica, tentar encontrar remuneração geral
    return _extrairRemuneracaoGeral(texto);
  }

  /// Extrai conhecimentos básicos do edital
  List<Map<String, dynamic>> _extrairConhecimentosBasicos(String texto) {
    final List<Map<String, dynamic>> conhecimentos = [];
    final texto_lower = texto.toLowerCase();

    // Lista de disciplinas comuns em conhecimentos básicos
    final List<Map<String, String>> disciplinasComuns = [
      {'nome': 'Língua Portuguesa', 'alias': 'portugu[\u00ea]s|l[\u00ed]ngua\s+portuguesa|comunica[\u00e7c][\u00e3a]o|reda[\u00e7c][\u00e3a]o'},
      {'nome': 'Matemática', 'alias': 'matem[\u00e1a]tica|c[\u00e1a]lculo|estat[\u00ed]stica'},
      {'nome': 'Raciocínio Lógico', 'alias': 'racioc[\u00ed]nio\s+l[\u00f3o]gico|l[\u00f3o]gica'},
      {'nome': 'Informática', 'alias': 'inform[\u00e1a]tica|computa[\u00e7c][\u00e3a]o|tecnologia\s+da\s+informa[\u00e7c][\u00e3a]o|ti'},
      {'nome': 'Atualidades', 'alias': 'atualidades|conhecimentos\s+atuais|temas\s+atuais'},
      {'nome': 'Conhecimentos Gerais', 'alias': 'conhecimentos\s+gerais|cultura\s+geral'},
      {'nome': 'Legislação', 'alias': 'legisla[\u00e7c][\u00e3a]o|leis|normas'},
      {'nome': 'Direito Constitucional', 'alias': 'direito\s+constitucional|constitui[\u00e7c][\u00e3a]o'},
      {'nome': 'Direito Administrativo', 'alias': 'direito\s+administrativo|administra[\u00e7c][\u00e3a]o\s+p[\u00fa]blica'},
      {'nome': 'Noções de Administração', 'alias': 'no[\u00e7c][\u00f5o]es\s+de\s+administra[\u00e7c][\u00e3a]o|administra[\u00e7c][\u00e3a]o\s+geral'},
      {'nome': 'Ética no Serviço Público', 'alias': '[\u00e9e]tica|conduta|servi[\u00e7c]o\s+p[\u00fa]blico'},
      {'nome': 'Direito Civil', 'alias': 'direito\s+civil|c[\u00f3o]digo\s+civil'},
      {'nome': 'Direito Penal', 'alias': 'direito\s+penal|c[\u00f3o]digo\s+penal'},
      {'nome': 'Direito Processual', 'alias': 'direito\s+processual|processo'},
      {'nome': 'Direito Tributário', 'alias': 'direito\s+tribut[\u00e1a]rio|tributos|impostos'},
      {'nome': 'Contabilidade', 'alias': 'contabilidade|contabiliza[\u00e7c][\u00e3a]o|auditoria'},
      {'nome': 'Economia', 'alias': 'economia|finan[\u00e7c]as|mercado'},
      {'nome': 'Administração Pública', 'alias': 'administra[\u00e7c][\u00e3a]o\s+p[\u00fa]blica|gest[\u00e3a]o\s+p[\u00fa]blica'},
      {'nome': 'Administração Financeira', 'alias': 'administra[\u00e7c][\u00e3a]o\s+financeira|finan[\u00e7c]as\s+p[\u00fa]blicas'},
      {'nome': 'Administração de Recursos Humanos', 'alias': 'recursos\s+humanos|gest[\u00e3a]o\s+de\s+pessoas'},
      {'nome': 'Administração de Materiais', 'alias': 'administra[\u00e7c][\u00e3a]o\s+de\s+materiais|log[\u00ed]stica'},
      {'nome': 'Administração de Sistemas de Informação', 'alias': 'sistemas\s+de\s+informa[\u00e7c][\u00e3a]o|gest[\u00e3a]o\s+da\s+informa[\u00e7c][\u00e3a]o'},
      {'nome': 'Inglês', 'alias': 'ingl[\u00ea]s|l[\u00ed]ngua\s+inglesa'},
      {'nome': 'Espanhol', 'alias': 'espanhol|l[\u00ed]ngua\s+espanhola'},
    ];

    // Buscar disciplinas no texto usando expressões regulares
    for (final disciplina in disciplinasComuns) {
      final RegExp regex = RegExp(disciplina['alias']!, caseSensitive: false);
      if (regex.hasMatch(texto_lower)) {
        conhecimentos.add({
          'disciplina': disciplina['nome']!,
          'topicos': _extrairTopicos(texto, disciplina['nome']!),
        });
      }
    }

    // Buscar por seções de conteúdo programático
    final RegExp regexSecao = RegExp(
      r'(?:conte[\u00fa]do\s+program[\u00e1a]tico|programa\s+das\s+provas|disciplinas|mat[\u00e9e]rias)\s*(?::|\-|\.)\s*([^\n]+)',
      caseSensitive: false
    );

    final match = regexSecao.firstMatch(texto_lower);
    if (match != null) {
      final String secao = match.group(1) ?? '';
      final List<String> partes = secao.split(RegExp(r'[,;]'));

      for (final parte in partes) {
        final String disciplina = parte.trim();
        if (disciplina.length > 3 && !conhecimentos.any((k) => k['disciplina'].toString().toLowerCase() == disciplina.toLowerCase())) {
          conhecimentos.add({
            'disciplina': disciplina.split(' ').map((palavra) {
              if (palavra.isEmpty) return '';
              return palavra[0].toUpperCase() + (palavra.length > 1 ? palavra.substring(1).toLowerCase() : '');
            }).join(' '),
            'topicos': _extrairTopicos(texto, disciplina),
          });
        }
      }
    }

    // Se não encontrou nenhuma disciplina, adicionar algumas padrão
    if (conhecimentos.isEmpty) {
      conhecimentos.add({
        'disciplina': 'Língua Portuguesa',
        'topicos': ['Interpretação de texto', 'Gramática', 'Ortografia', 'Pontuação', 'Acentuação'],
      });

      conhecimentos.add({
        'disciplina': 'Matemática',
        'topicos': ['Raciocínio lógico', 'Operações básicas', 'Porcentagem', 'Juros', 'Proporção'],
      });

      conhecimentos.add({
        'disciplina': 'Conhecimentos Gerais',
        'topicos': ['Atualidades', 'História', 'Geografia', 'Política', 'Meio Ambiente'],
      });

      conhecimentos.add({
        'disciplina': 'Legislação',
        'topicos': ['Constituição Federal', 'Direito Administrativo', 'Direito Constitucional'],
      });
    }

    return conhecimentos;
  }

  /// Extrai tópicos para uma disciplina específica
  List<String> _extrairTopicos(String texto, String disciplina) {
    final texto_lower = texto.toLowerCase();
    final disciplina_lower = disciplina.toLowerCase();

    // Tentar encontrar tópicos próximos ao nome da disciplina
    final int posicaoDisciplina = texto_lower.indexOf(disciplina_lower);
    final List<String> topicos = [];

    if (posicaoDisciplina != -1) {
      // Buscar em um trecho após o nome da disciplina
      final String trecho = texto_lower.substring(
        posicaoDisciplina,
        posicaoDisciplina + 1000 > texto_lower.length ? texto_lower.length : posicaoDisciplina + 1000
      );

      // Dividir em linhas e procurar por marcadores de lista
      final List<String> linhas = trecho.split('\n');
      bool emTopicos = false;

      for (final linha in linhas) {
        final String linhaLimpa = linha.trim();

        // Verificar se é um tópico (começa com marcador de lista ou número)
        if (linhaLimpa.startsWith('-') ||
            linhaLimpa.startsWith('•') ||
            linhaLimpa.startsWith('*') ||
            RegExp(r'^\d+[\.\)]').hasMatch(linhaLimpa) ||
            RegExp(r'^[a-z][\.\)]').hasMatch(linhaLimpa)) {

          // Extrair o texto do tópico (remover o marcador)
          final String textoTopico = linhaLimpa.replaceFirst(RegExp(r'^[\-•*\d]+[\.\)\s]+'), '').trim();

          if (textoTopico.isNotEmpty && textoTopico.length > 3) {
            // Normalizar o tópico (primeira letra maiúscula)
            final String topicoNormalizado = _normalizarTopico(textoTopico);

            if (!topicos.contains(topicoNormalizado)) {
              topicos.add(topicoNormalizado);
              emTopicos = true;
            }
          }
        }
        // Se estamos em uma lista de tópicos e encontramos uma linha em branco, pode ser o fim da lista
        else if (emTopicos && linhaLimpa.isEmpty) {
          emTopicos = false;
        }
        // Se encontramos o nome de outra disciplina, parar
        else if (disciplinasContains(linhaLimpa)) {
          break;
        }
      }
    }

    // Se não encontrou tópicos, adicionar alguns genéricos
    if (topicos.isEmpty) {
      if (disciplina_lower.contains('português') || disciplina_lower.contains('lingua')) {
        topicos.addAll(['Interpretação de texto', 'Gramática', 'Ortografia', 'Pontuação', 'Acentuação']);
      } else if (disciplina_lower.contains('matemática')) {
        topicos.addAll(['Raciocínio lógico', 'Operações básicas', 'Porcentagem', 'Juros', 'Proporção']);
      } else if (disciplina_lower.contains('conhecimentos gerais') || disciplina_lower.contains('atualidades')) {
        topicos.addAll(['Atualidades', 'História', 'Geografia', 'Política', 'Meio Ambiente']);
      } else if (disciplina_lower.contains('raciocínio')) {
        topicos.addAll(['Lógica proposicional', 'Argumentação lógica', 'Sequências lógicas', 'Silogismos']);
      } else if (disciplina_lower.contains('informática')) {
        topicos.addAll(['Windows', 'Linux', 'Pacote Office', 'Internet', 'Segurança da informação']);
      } else if (disciplina_lower.contains('constitucional')) {
        topicos.addAll(['Constituição Federal', 'Princípios fundamentais', 'Direitos e garantias fundamentais']);
      } else if (disciplina_lower.contains('administrativo')) {
        topicos.addAll(['Administração Pública', 'Princípios administrativos', 'Atos administrativos']);
      } else if (disciplina_lower.contains('legislação')) {
        topicos.addAll(['Constituição Federal', 'Leis específicas', 'Estatutos', 'Regulamentos']);
      } else if (disciplina_lower.contains('direito')) {
        topicos.addAll(['Princípios', 'Legislação específica', 'Jurisprudência', 'Doutrina']);
      } else {
        topicos.addAll(['Conceitos básicos', 'Fundamentos', 'Aplicações práticas']);
      }
    }

    return topicos;
  }

  /// Verifica se uma string contém o nome de alguma disciplina comum
  bool disciplinasContains(String texto) {
    final List<String> disciplinasComuns = [
      'Língua Portuguesa',
      'Matemática',
      'Raciocínio Lógico',
      'Informática',
      'Atualidades',
      'Conhecimentos Gerais',
      'Legislação',
      'Direito Constitucional',
      'Direito Administrativo',
      'Noções de Administração',
      'Ética no Serviço Público',
      'Direito Civil',
      'Direito Penal',
      'Direito Processual',
      'Direito Tributário',
      'Contabilidade',
      'Economia',
      'Administração Pública',
      'Administração Financeira',
      'Administração de Recursos Humanos',
      'Administração de Materiais',
      'Administração de Sistemas de Informação',
      'Inglês',
      'Espanhol',
    ];

    final texto_lower = texto.toLowerCase();
    for (final disciplina in disciplinasComuns) {
      if (texto_lower.contains(disciplina.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Reporta o progresso da extração
  void _reportProgress(double progress, String message) {
    if (onProgress != null) {
      onProgress!(progress, message);
    }
  }

  /// Registra mensagens de log
  void _log(String message) {
    debugPrint('[LocalEditalExtractor] $message');
  }

  /// Normaliza o texto do tópico (primeira letra maiúscula, etc)
  String _normalizarTopico(String topico) {
    if (topico.isEmpty) return topico;

    // Normalizar o tópico (primeira letra maiúscula de cada palavra)
    return topico.split(' ').map((palavra) {
      if (palavra.isEmpty) return '';
      return palavra[0].toUpperCase() + (palavra.length > 1 ? palavra.substring(1).toLowerCase() : '');
    }).join(' ');
  }

  /// Extrai a data da prova
  String _extrairDataProva(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para datas de prova
    final List<RegExp> padroesDataProva = [
      // Padrão 1: prova será realizada no dia XX de MES de ANO
      RegExp(
        r'(?:prova|provas)\s*(?:ser[\u00e1a]o?|est[\u00e1a]o?)?\s*(?:realizada|aplicada|prevista)\s*(?:para|no)\s*(?:o\s+)?dia\s*(\d{1,2}\s*(?:de\s+)?\s*(?:janeiro|fevereiro|mar[\u00e7c]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*(?:de\s+)?\s*\d{2,4})',
        caseSensitive: false
      ),

      // Padrão 2: data da prova: XX/XX/XXXX
      RegExp(
        r'(?:data|dia)\s*(?:da|de)\s*(?:prova|aplica[\u00e7c][\u00e3a]o)\s*(?::|\-|\.)\s*(\d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4})',
        caseSensitive: false
      ),

      // Padrão 3: provas objetivas: XX/XX/XXXX
      RegExp(
        r'(?:provas?|etapas?)\s*(?:objetivas?|escritas?|discursivas?)\s*(?::|\-|\.)\s*(\d{1,2}[\.\/]\d{1,2}[\.\/]\d{2,4})',
        caseSensitive: false
      ),
    ];

    // Tentar cada padrão
    for (final regex in padroesDataProva) {
      final match = regex.firstMatch(texto_lower);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }

    return '';
  }

  /// Extrai o local da prova
  String _extrairLocalProva(String texto) {
    final texto_lower = texto.toLowerCase();

    // Padrões comuns para local de prova
    final List<RegExp> padroesLocalProva = [
      // Padrão 1: provas serão realizadas na cidade de XXX
      RegExp(
        r'(?:provas?|etapas?)\s*(?:ser[\u00e1a]o?|est[\u00e1a]o?)?\s*(?:realizada|aplicada)\s*(?:na|no|em)\s*(?:cidade|munic[\u00ed]pio)\s*(?:de)?\s*([\p{L}\s]{3,50})',
        caseSensitive: false,
        unicode: true
      ),

      // Padrão 2: local de prova: XXX
      RegExp(
        r'(?:local|locais)\s*(?:da|de)\s*(?:prova|aplica[\u00e7c][\u00e3a]o|realiza[\u00e7c][\u00e3a]o)\s*(?::|\-|\.)\s*([\p{L}\s]{3,50})',
        caseSensitive: false,
        unicode: true
      ),
    ];

    // Tentar cada padrão
    for (final regex in padroesLocalProva) {
      final match = regex.firstMatch(texto_lower);
      if (match != null) {
        String local = match.group(1)?.trim() ?? '';
        if (local.length > 3) {
          // Normalizar o nome do local (primeira letra maiúscula)
          return local.split(' ').map((palavra) {
            if (palavra.isEmpty) return '';
            return palavra[0].toUpperCase() + (palavra.length > 1 ? palavra.substring(1).toLowerCase() : '');
          }).join(' ');
        }
      }
    }

    // Buscar por cidades comuns
    final List<String> cidadesComuns = [
      'Brasília', 'São Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Salvador',
      'Fortaleza', 'Recife', 'Porto Alegre', 'Curitiba', 'Manaus', 'Belém',
      'Goiânia', 'Guarulhos', 'Campinas', 'São Luís', 'São Gonçalo',
      'Maceió', 'Duque de Caxias', 'Natal', 'Campo Grande', 'Teresina',
    ];

    for (final cidade in cidadesComuns) {
      if (texto_lower.contains(cidade.toLowerCase())) {
        return cidade;
      }
    }

    return '';
  }
}
