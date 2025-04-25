import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/data/models/models.dart';
import 'package:preparatorio_concursos/features/4_study_plan/domain/services/inscricao_service.dart';
import 'extractors/mock_data.dart';

void main() {
  group('InscricaoService', () {
    late PlanoEstudo planoSemMetadados;
    late PlanoEstudo planoComMetadados;
    late Edital edital;

    setUp(() {
      planoSemMetadados = MockData.criarPlanoEstudoMock();
      planoComMetadados = MockData.criarPlanoEstudoComMetadados();
      edital = MockData.criarEditalMock();
    });

    group('obterValor', () {
      test('deve retornar o valor da inscrição dos metadados do plano quando disponível', () {
        final resultado = InscricaoService.obterValor(planoComMetadados, edital);
        expect(resultado, '120,50');
      });

      test('deve retornar o valor da inscrição do edital quando não há metadados no plano', () {
        final resultado = InscricaoService.obterValor(planoSemMetadados, edital);
        expect(resultado, contains('120'));
      });

      test('deve retornar "Não informado" quando não há metadados nem edital', () {
        final resultado = InscricaoService.obterValor(planoSemMetadados, null);
        expect(resultado, 'Não informado');
      });
    });

    group('obterPeriodo', () {
      test('deve retornar o período de inscrição do edital quando disponível', () {
        final resultado = InscricaoService.obterPeriodo(edital);
        expect(resultado, contains('01/01/2025'));
        expect(resultado, contains('31/01/2025'));
      });

      test('deve retornar "Não informado" quando não há edital', () {
        final resultado = InscricaoService.obterPeriodo(null);
        expect(resultado, 'Não informado');
      });
    });
  });
}
