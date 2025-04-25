import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/data/models/models.dart';
import 'package:preparatorio_concursos/features/4_study_plan/domain/services/prova_service.dart';
import 'extractors/mock_data.dart';

void main() {
  group('ProvaService', () {
    late PlanoEstudo planoSemMetadados;
    late PlanoEstudo planoComMetadados;
    late Edital edital;

    setUp(() {
      planoSemMetadados = MockData.criarPlanoEstudoMock();
      planoComMetadados = MockData.criarPlanoEstudoComMetadados();
      edital = MockData.criarEditalMock();
    });

    group('obterFormato', () {
      test('deve retornar o formato da prova dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterFormato(planoComMetadados, edital);
        expect(resultado, contains('Objetiva'));
        expect(resultado, contains('Discursiva'));
      });

      test('deve retornar o formato da prova do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterFormato(planoSemMetadados, edital);
        expect(resultado, contains('Objetiva'));
        expect(resultado, contains('Discursiva'));
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterFormato(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterData', () {
      test('deve retornar a data da prova dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterData(planoComMetadados, edital);
        expect(resultado, '2025-12-31');
      });

      test('deve retornar a data da prova do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterData(planoSemMetadados, edital);
        expect(resultado, contains('31/12/2025'));
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterData(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterLocal', () {
      test('deve retornar o local da prova dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterLocal(planoComMetadados, edital);
        expect(resultado, 'Local Teste Metadados');
      });

      test('deve retornar o local da prova do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterLocal(planoSemMetadados, edital);
        expect(resultado, 'Local Teste Extraído');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterLocal(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterTotalQuestoes', () {
      test('deve retornar o total de questões dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterTotalQuestoes(planoComMetadados, edital);
        expect(resultado, '100');
      });

      test('deve retornar o total de questões do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterTotalQuestoes(planoSemMetadados, edital);
        expect(resultado, '100');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterTotalQuestoes(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterDuracao', () {
      test('deve retornar a duração da prova dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterDuracao(planoComMetadados, edital);
        expect(resultado, '5 horas');
      });

      test('deve retornar a duração da prova do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterDuracao(planoSemMetadados, edital);
        expect(resultado, '5 horas');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterDuracao(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterCriteriosAprovacao', () {
      test('deve retornar os critérios de aprovação dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterCriteriosAprovacao(planoComMetadados, edital);
        expect(resultado, 'Nota mínima 70%');
      });

      test('deve retornar os critérios de aprovação do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterCriteriosAprovacao(planoSemMetadados, edital);
        expect(resultado, 'Nota mínima 70%');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterCriteriosAprovacao(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterCriteriosReprovacao', () {
      test('deve retornar os critérios de reprovação dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterCriteriosReprovacao(planoComMetadados, edital);
        expect(resultado, 'Nota abaixo de 70%');
      });

      test('deve retornar os critérios de reprovação do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterCriteriosReprovacao(planoSemMetadados, edital);
        expect(resultado, 'Nota abaixo de 70%');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterCriteriosReprovacao(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterCriteriosDesempate', () {
      test('deve retornar os critérios de desempate dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterCriteriosDesempate(planoComMetadados, edital);
        expect(resultado, contains('Idade'));
        expect(resultado, contains('Tempo de serviço'));
      });

      test('deve retornar os critérios de desempate do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterCriteriosDesempate(planoSemMetadados, edital);
        expect(resultado, contains('Idade'));
        expect(resultado, contains('Tempo de serviço'));
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterCriteriosDesempate(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterTemaProvaSubjetiva', () {
      test('deve retornar o tema da prova subjetiva dos metadados do plano quando disponível', () {
        final resultado = ProvaService.obterTemaProvaSubjetiva(planoComMetadados, edital);
        expect(resultado, 'Tema Teste Metadados');
      });

      test('deve retornar o tema da prova subjetiva do edital quando não há metadados no plano', () {
        final resultado = ProvaService.obterTemaProvaSubjetiva(planoSemMetadados, edital);
        expect(resultado, 'Tema Teste Extraído');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ProvaService.obterTemaProvaSubjetiva(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });
  });
}
