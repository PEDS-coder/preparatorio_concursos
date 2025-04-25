import 'package:preparatorio_concursos/core/data/models/models.dart';

/// Classe com dados de mock para testes dos serviços de extração de dados
class MockData {
  /// Cria um PlanoEstudo de mock para testes
  static PlanoEstudo criarPlanoEstudoMock({
    String? id,
    Map<String, dynamic>? metadados,
  }) {
    return PlanoEstudo(
      id: id ?? 'plano_teste_123',
      titulo: 'Plano de Estudos Teste',
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 30)),
      cargoIds: ['cargo_teste_123'],
      metadados: metadados ?? {},
    );
  }

  /// Cria um Edital de mock para testes
  static Edital criarEditalMock({
    String? id,
    Map<String, dynamic>? dadosOriginais,
    DadosExtraidos? dadosExtraidos,
  }) {
    return Edital(
      id: id ?? 'edital_teste_123',
      nomeConcurso: 'Concurso Teste',
      nomeArquivo: 'edital_teste.pdf',
      dataUpload: DateTime.now(),
      textoCompleto: 'Texto completo do edital de teste',
      dadosOriginais: dadosOriginais ?? {
        'concurso': {
          'titulo': 'Concurso Teste Original',
          'orgao': 'Órgão Teste Original',
          'banca': 'Banca Teste Original',
          'prova': {
            'data': '2025-12-31',
            'local': 'Local Teste Original',
            'formato': ['Objetiva', 'Discursiva'],
            'total_questoes': 100,
            'duracao': '5 horas',
            'criterios_aprovacao': 'Nota mínima 70%',
            'criterios_reprovacao': 'Nota abaixo de 70%',
            'criterios_desempate': ['Idade', 'Tempo de serviço'],
            'tema_discursiva': 'Tema Teste Original',
          },
          'inscricoes': {
            'periodo': '01/01/2025 a 31/01/2025',
            'taxa': 120.50,
          },
          'cotas': [
            {'nome': 'PcD', 'percentual': '10%'},
            {'nome': 'Negros', 'percentual': '20%'},
          ],
        }
      },
      dadosExtraidos: dadosExtraidos ?? DadosExtraidos(
        titulo: 'Concurso Teste Extraído',
        orgao: 'Órgão Teste Extraído',
        banca: 'Banca Teste Extraída',
        dataProva: DateTime(2025, 12, 31),
        localProva: 'Local Teste Extraído',
        valorTaxa: 120.50,
        inicioInscricao: DateTime(2025, 1, 1),
        fimInscricao: DateTime(2025, 1, 31),
        cotas: [
          Cota(nome: 'PcD', percentual: 10),
          Cota(nome: 'Negros', percentual: 20),
        ],
        cargos: [
          Cargo(
            id: 'cargo_teste_123',
            nome: 'Cargo Teste',
            nivel: 'Superior',
            salario: 10000.0,
            vagas: 10,
            conteudoProgramatico: [
              ConteudoProgramatico(
                nome: 'Matéria Teste',
                topicos: ['Tópico 1', 'Tópico 2'],
              ),
            ],
          ),
        ],
        dadosProva: DadosProva(
          formato: ['Objetiva', 'Discursiva'],
          dataRealizacao: DateTime(2025, 12, 31),
          totalQuestoes: 100,
          duracao: '5 horas',
          criteriosAprovacao: 'Nota mínima 70%',
          criteriosReprovacao: 'Nota abaixo de 70%',
          criteriosDesempate: ['Idade', 'Tempo de serviço'],
          temaDiscursiva: 'Tema Teste Extraído',
        ),
        concurso: {
          'titulo': 'Concurso Teste Extraído',
          'orgao': 'Órgão Teste Extraído',
          'banca': 'Banca Teste Extraída',
        },
        prova: {
          'data': '2025-12-31',
          'local': 'Local Teste Extraído',
          'formato': ['Objetiva', 'Discursiva'],
        },
      ),
    );
  }

  /// Cria um PlanoEstudo com metadados para testes
  static PlanoEstudo criarPlanoEstudoComMetadados() {
    return criarPlanoEstudoMock(
      metadados: {
        'titulo': 'Concurso Teste Metadados',
        'orgao': 'Órgão Teste Metadados',
        'banca': 'Banca Teste Metadados',
        'dataProva': '2025-12-31',
        'localProva': 'Local Teste Metadados',
        'formatoProva': ['Objetiva', 'Discursiva'],
        'totalQuestoes': '100',
        'duracaoProva': '5 horas',
        'criteriosAprovacao': 'Nota mínima 70%',
        'criteriosReprovacao': 'Nota abaixo de 70%',
        'criteriosDesempate': ['Idade', 'Tempo de serviço'],
        'temaProvaSubjetiva': 'Tema Teste Metadados',
        'valorInscricao': '120,50',
        'periodoInscricao': '01/01/2025 a 31/01/2025',
        'planoEstudos': {
          'titulo': 'Concurso Teste Aninhado',
          'orgao': 'Órgão Teste Aninhado',
        },
        'concurso': {
          'titulo': 'Concurso Teste Aninhado',
          'orgao': 'Órgão Teste Aninhado',
        },
        'prova': {
          'formato': ['Objetiva', 'Discursiva'],
          'data': '2025-12-31',
        },
      },
    );
  }
}
