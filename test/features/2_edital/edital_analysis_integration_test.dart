import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:preparatorio_concursos/core/data/models/edital.dart';
import 'package:preparatorio_concursos/core/data/services/edital_service.dart';
import 'package:preparatorio_concursos/core/data/services/ia_service.dart';
import 'package:preparatorio_concursos/core/utils/edital_analyzer.dart';
import 'package:preparatorio_concursos/core/utils/pdf_processor.dart';

import 'edital_analysis_integration_test.mocks.dart';

@GenerateMocks([IAService, PdfProcessor])
void main() {
  group('Fluxo de Análise de Edital', () {
    late MockIAService mockIaService;
    late MockPdfProcessor mockPdfProcessor;
    late EditalService editalService;
    late EditalAnalyzer editalAnalyzer;

    setUp(() {
      mockIaService = MockIAService();
      mockPdfProcessor = MockPdfProcessor();
      editalService = EditalService();
      editalAnalyzer = EditalAnalyzer(
        iaService: mockIaService,
        pdfProcessor: mockPdfProcessor,
      );
    });

    test('Fluxo completo de análise de edital deve funcionar corretamente', () async {
      // Arrange
      final pdfBytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final extractedText = 'Conteúdo do edital para teste';
      
      // Mock do processamento de PDF
      when(mockPdfProcessor.extractTextFromPdf(pdfBytes))
          .thenAnswer((_) async => PdfProcessingResult(
                text: extractedText,
                pageCount: 10,
              ));
      
      // Mock da resposta da IA para informações básicas
      when(mockIaService.analisarEditalBasico(any, any))
          .thenAnswer((_) async => {
                'nome_concurso': 'Concurso Teste',
                'organizadora': 'Banca Teste',
                'data_prova': '01/01/2023',
                'taxa_inscricao': 'R\$ 100,00',
                'cargos': [
                  {
                    'nome': 'Analista',
                    'vagas': 5,
                    'salario': 'R\$ 5.000,00',
                    'escolaridade': 'Superior',
                  }
                ],
              });
      
      // Mock da resposta da IA para conteúdo programático
      when(mockIaService.analisarEditalConteudo(any, any))
          .thenAnswer((_) async => {
                'cargos': [
                  {
                    'nome': 'Analista',
                    'conteudo_programatico': [
                      {
                        'nome': 'Português',
                        'tipo': 'comum',
                        'topicos': ['Interpretação de texto', 'Gramática'],
                      },
                      {
                        'nome': 'Conhecimentos Específicos',
                        'tipo': 'específico',
                        'topicos': ['Administração', 'Gestão de Projetos'],
                      },
                    ],
                  }
                ],
              });
      
      // Act
      final resultado = await editalAnalyzer.analisarEdital(pdfBytes);
      
      // Assert
      expect(resultado, isA<Edital>());
      expect(resultado.nome, 'Concurso Teste');
      expect(resultado.organizadora, 'Banca Teste');
      expect(resultado.dataProva, '01/01/2023');
      expect(resultado.taxaInscricao, 'R\$ 100,00');
      expect(resultado.cargos.length, 1);
      expect(resultado.cargos[0].nome, 'Analista');
      expect(resultado.cargos[0].vagas, 5);
      expect(resultado.cargos[0].conteudoProgramatico.length, 2);
      expect(resultado.cargos[0].conteudoProgramatico[0].nome, 'Português');
      expect(resultado.cargos[0].conteudoProgramatico[0].topicos.length, 2);
      
      // Verificar se os métodos foram chamados corretamente
      verify(mockPdfProcessor.extractTextFromPdf(pdfBytes)).called(1);
      verify(mockIaService.analisarEditalBasico(extractedText, any)).called(1);
      verify(mockIaService.analisarEditalConteudo(extractedText, any)).called(1);
    });

    test('Deve lidar com erros durante a análise do edital', () async {
      // Arrange
      final pdfBytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      
      // Mock do processamento de PDF com erro
      when(mockPdfProcessor.extractTextFromPdf(pdfBytes))
          .thenThrow(Exception('Erro ao processar PDF'));
      
      // Act & Assert
      expect(
        () => editalAnalyzer.analisarEdital(pdfBytes),
        throwsException,
      );
    });
  });
}
