import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../core/data/models/edital.dart';
import '../../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../../core/utils/edital_analyzer.dart';
import '../../../../../core/utils/cache_manager.dart';

/// Serviço para análise de editais
class EditalAnalyzerService {
  final IAServiceInterface iaService;
  final Function(double progress, String message) onProgress;

  EditalAnalyzerService({
    required this.iaService,
    required this.onProgress,
  });

  /// Analisa um edital a partir dos bytes do PDF
  Future<Map<String, dynamic>> analisarEdital(Uint8List pdfBytes) async {
    onProgress(0.05, 'Verificando texto do edital...');

    // Criar o analisador de edital
    final editalAnalyzer = EditalAnalyzer(
      iaService: iaService,
      onProgress: onProgress,
    );

    onProgress(0.2, 'Preparando PDF para análise...');

    // Analisar o edital enviando o PDF diretamente para a LLM (primeira etapa: informações básicas)
    final DadosExtraidos dadosExtraidos = await editalAnalyzer.analisarEdital(null, pdfBytes);

    // Salvar os bytes do PDF no cache
    final cacheManager = CacheManager();
    final String editalId = DateTime.now().millisecondsSinceEpoch.toString();
    await cacheManager.savePdfBytes(editalId, pdfBytes);

    // Converter para Map para manter compatibilidade com o restante do código
    final Map<String, dynamic> dadosMap = {
      'titulo': dadosExtraidos.titulo ?? 'Edital Analisado',
      'banca': dadosExtraidos.banca ?? 'Não especificado',
      // Tratar datas com segurança para evitar erros de formato
      'inicioInscricao': dadosExtraidos.inicioInscricao != null ?
          dadosExtraidos.inicioInscricao!.toIso8601String() : null,
      'fimInscricao': dadosExtraidos.fimInscricao != null ?
          dadosExtraidos.fimInscricao!.toIso8601String() : null,
      'valorTaxa': dadosExtraidos.valorTaxa,
      'localProva': dadosExtraidos.localProva,
      'cargos': dadosExtraidos.cargos.map((cargo) => {
        'nome': cargo.nome,
        'vagas': cargo.vagas,
        'salario': cargo.salario,
        'escolaridade': cargo.escolaridade,
        'dataProva': cargo.dataProva != null ?
            cargo.dataProva!.toIso8601String() : null,
        // Não incluir conteúdo programático na primeira etapa
        'conteudoProgramatico': [],
      }).toList(),
      // Preservar uma referência ao PDF para a segunda etapa
      'pdfBytesReference': 'PDF_BYTES_REFERENCE_$editalId',
      'editalId': editalId,
    };

    onProgress(1.0, 'Análise concluída!');

    return dadosMap;
  }

  /// Gera dados de exemplo para testes
  Map<String, dynamic> gerarDadosExemplo() {
    // Criar dados de exemplo com informações mais completas
    final Map<String, dynamic> dadosExemplo = {
      'titulo': 'Concurso Público para Analista do Tribunal Regional do Trabalho da 10ª Região',
      'banca': 'CESPE',
      // Usar formato ISO 8601 para datas
      'inicioInscricao': '2023-05-01T00:00:00.000',
      'fimInscricao': '2023-05-30T00:00:00.000',
      'valorTaxa': 120.0,
      'localProva': 'Brasília/DF',
      'dataProva': '2023-07-15T00:00:00.000',
      'cargos': [
        {
          'nome': 'Analista Judiciário - Área Administrativa',
          'vagas': 10,
          'salario': 13994.78,
          'escolaridade': 'Nível Superior em Contabilidade',
          'materias': ['Contabilidade Pública', 'Administração Financeira e Orçamentária', 'Legislação Tributária Aplicada às Contratações Públicas', 'Auditoria Governamental']
        },
        {
          'nome': 'Analista Judiciário - Área Arquitetura',
          'vagas': 5,
          'salario': 13994.78,
          'escolaridade': 'Nível Superior em Arquitetura',
          'materias': ['Conceitos fundamentais sobre arquitetura, urbanismo e paisagismo', 'Elaboração de projeto de arquitetura', 'Zoneamento das atividades', 'Materiais, técnicas, processos e sistemas inovadores de construção', 'Conforto ambiental', 'Noções básicas de acústica', 'Ergonomia nas edificações e mobiliários', 'Acessibilidade a edificações', 'Compatibilização de projeto arquitetônico e instalações prediais', 'Projeto de reforma', 'Manutenção predial', 'Projetos complementares', 'Projeto de áreas livres', 'Administração de projetos e obras', 'Informática aplicada a arquitetura', 'Gestão ambiental em edificações', 'Legislação urbanística aplicável a edificações', 'Legislação do exercício profissional do arquiteto', 'Legislação ambiental aplicada à construção civil', 'Normas de segurança do trabalho aplicadas à construção civil', 'Legislação aplicada a economia de recursos naturais e sustentabilidade nas edificações', 'Normas do Judiciário aplicadas a serviços de engenharia e arquitetura', 'Gestão de Contratos']
        },
        {
          'nome': 'Analista Judiciário - Área Arquivologia',
          'vagas': 3,
          'salario': 13994.78,
          'escolaridade': 'Nível Superior em Arquivologia',
          'materias': ['Arquivologia', 'Gestão de Contratos']
        }
      ]
    };

    return dadosExemplo;
  }
}
