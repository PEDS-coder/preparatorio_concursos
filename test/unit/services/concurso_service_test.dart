import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/data/models/models.dart';
import 'package:preparatorio_concursos/features/4_study_plan/domain/services/concurso_service.dart';
import 'extractors/mock_data.dart';

void main() {
  group('ConcursoService', () {
    late PlanoEstudo planoSemMetadados;
    late PlanoEstudo planoComMetadados;
    late Edital edital;

    setUp(() {
      planoSemMetadados = MockData.criarPlanoEstudoMock();
      planoComMetadados = MockData.criarPlanoEstudoComMetadados();
      edital = MockData.criarEditalMock();
    });

    group('obterTitulo', () {
      test('deve retornar o título dos metadados do plano quando disponível', () {
        final resultado = ConcursoService.obterTitulo(planoComMetadados, edital);
        expect(resultado, 'Concurso Teste Metadados');
      });

      test('deve retornar o título do edital quando não há metadados no plano', () {
        final resultado = ConcursoService.obterTitulo(planoSemMetadados, edital);
        expect(resultado, 'Concurso Teste Extraído');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ConcursoService.obterTitulo(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterOrgao', () {
      test('deve retornar o órgão dos metadados do plano quando disponível', () {
        final resultado = ConcursoService.obterOrgao(planoComMetadados, edital);
        expect(resultado, 'Órgão Teste Metadados');
      });

      test('deve retornar o órgão do edital quando não há metadados no plano', () {
        final resultado = ConcursoService.obterOrgao(planoSemMetadados, edital);
        expect(resultado, 'Órgão Teste Extraído');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ConcursoService.obterOrgao(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterBanca', () {
      test('deve retornar a banca dos metadados do plano quando disponível', () {
        final resultado = ConcursoService.obterBanca(planoComMetadados, edital);
        expect(resultado, 'Banca Teste Metadados');
      });

      test('deve retornar a banca do edital quando não há metadados no plano', () {
        final resultado = ConcursoService.obterBanca(planoSemMetadados, edital);
        expect(resultado, 'Banca Teste Extraída');
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = ConcursoService.obterBanca(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });
  });
}
