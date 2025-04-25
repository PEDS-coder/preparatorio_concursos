import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/data/models/models.dart';
import 'package:preparatorio_concursos/features/4_study_plan/domain/services/cotas_service.dart';
import 'extractors/mock_data.dart';

void main() {
  group('CotasService', () {
    late Edital edital;
    late Edital editalSemCotas;

    setUp(() {
      edital = MockData.criarEditalMock();

      // Criar edital sem cotas
      editalSemCotas = MockData.criarEditalMock(
        dadosExtraidos: DadosExtraidos(
          titulo: 'Concurso Teste Sem Cotas',
          orgao: 'Órgão Teste',
          banca: 'Banca Teste',
          cargos: [],
        ),
        dadosOriginais: {},
      );
    });

    group('obterInformacoes', () {
      test('deve retornar as informações de cotas do edital quando disponíveis', () {
        final resultado = CotasService.obterInformacoes(edital);
        expect(resultado, contains('PcD'));
        expect(resultado, contains('10%'));
        expect(resultado, contains('Negros'));
        expect(resultado, contains('20%'));
      });

      test('deve retornar "Não informado" quando não há cotas no edital', () {
        final resultado = CotasService.obterInformacoes(editalSemCotas);
        expect(resultado, 'Não informado');
      });

      test('deve retornar "Não informado" quando não há edital', () {
        final resultado = CotasService.obterInformacoes(null);
        expect(resultado, 'Não informado');
      });
    });
  });
}
