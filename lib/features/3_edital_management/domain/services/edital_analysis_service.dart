import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/services/edital_service.dart';
import '../../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../../core/data/services/interfaces/ia_service_interface_extension.dart';
import '../../../../core/data/models/edital.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/logger_static.dart';
import '../../../../core/data/services/interfaces/navigation_service_interface.dart';
import '../../../../core/di/service_locator.dart';
import '../../presentation/screens/cargo_select_screen.dart';

/// Serviço responsável por gerenciar a análise de editais
///
/// Este serviço implementa o fluxo padrão de análise de editais na aplicação:
/// 1. O usuário seleciona um arquivo PDF de edital
/// 2. O serviço envia o PDF para a API (primeira chamada) para extrair informações básicas e cargos
/// 3. O usuário seleciona um cargo
/// 4. O serviço envia o PDF e o cargo selecionado para a API (segunda chamada) para extrair informações detalhadas
/// 5. O usuário preenche o questionário do plano de estudos
/// 6. O serviço gera o plano de estudos com base nas informações do questionário
///
/// IMPORTANTE: Este é o serviço padrão para análise de editais. Todas as implementações alternativas
/// foram movidas para a pasta de código obsoleto.
class EditalAnalysisService {
  // Método removido: processarDadosExemplo

  /// Analisa o edital a partir dos arquivos PDF selecionados
  static Future<void> analisarEdital({
    required BuildContext context,
    required List<PlatformFile> selectedFiles,
    required Function(String, double) onProgress,
  }) async {
    try {
      final iaService = Provider.of<IAServiceInterface>(context, listen: false);
      final editalService = Provider.of<EditalService>(context, listen: false);

      // Verificar se o IAService está configurado
      if (!iaService.isConfigured) {
        throw Exception('Serviço de IA não configurado');
      }

      // Atualizar progresso
      onProgress('Preparando arquivos para análise...', 0.1);

      // Gerar ID único para o edital
      final String editalId = const Uuid().v4();

      // Preparar arquivos para envio
      List<File> files = [];
      Uint8List? pdfBytes;
      for (var file in selectedFiles) {
        if (file.path != null) {
          final fileObj = File(file.path!);
          files.add(fileObj);
          // Armazenar os bytes do primeiro PDF para uso posterior
          pdfBytes ??= await fileObj.readAsBytes();
        }
      }

      if (files.isEmpty) {
        throw Exception('Nenhum arquivo válido selecionado');
      }

      // Atualizar progresso
      onProgress('Enviando arquivos para análise...', 0.2);

      // Realizar a primeira chamada à API para análise do edital
      final Map<String, dynamic> resultado = await iaService.analisarEditalPrimeiraChamada(
        files,
        (message, progress) {
          onProgress(message, 0.2 + (progress * 0.7)); // Mapear progresso de 0.2 a 0.9
        },
      );

      // Verificar se o resultado contém as informações necessárias
      if ((!resultado.containsKey('titulo') && !resultado.containsKey('titulo_concurso')) ||
          !resultado.containsKey('cargos')) {
        throw Exception('Resposta da API não contém informações básicas do edital');
      }

      // Verificar e processar os dados dos cargos
      if (resultado.containsKey('cargos') && resultado['cargos'] is List) {
        // Log para depuração
        Logger.debug('Processando ${resultado['cargos'].length} cargos da resposta da API');

        // Verificar cada cargo para garantir que os dados estão corretos
        for (var i = 0; i < resultado['cargos'].length; i++) {
          var cargo = resultado['cargos'][i];

          // Log para depuração
          Logger.debug('Cargo ${i+1}: ${cargo['nome']} - Salário: ${cargo['salario']} - Escolaridade: ${cargo['escolaridade']}');

          // Garantir que o salário seja processado corretamente
          if (cargo['salario'] != null && cargo['salario'] is String) {
            try {
              // Remover caracteres não numéricos, exceto ponto e vírgula
              String cleanedString = cargo['salario'].toString().replaceAll(RegExp(r'[^0-9.,]'), '');
              // Substituir vírgula por ponto para o parse
              cleanedString = cleanedString.replaceAll(',', '.');
              // Remover pontos extras (milhares) se houver mais de um ponto decimal
              if (cleanedString.split('.').length > 2) {
                cleanedString = cleanedString.replaceAll(RegExp(r'\.(?=.*\.)'), ''); // Remove todos os pontos exceto o último
              }

              // Tentar converter para double
              double salario = double.parse(cleanedString);
              cargo['salario'] = salario;

              // Log para depuração
              Logger.debug('Salário convertido: $salario');
            } catch (e) {
              Logger.error('Erro ao converter salário: $e');
            }
          }
        }
      }

      // Atualizar progresso
      onProgress('Processando resultados da análise...', 0.9);

      // Criar objeto Edital a partir dos resultados
      final Edital edital = Edital(
        id: editalId,
        userId: 'user_atual',
        nomeConcurso: resultado['titulo_concurso'] ?? resultado['titulo'] ?? 'Edital sem título',
        dataUpload: DateTime.now(),
        textoCompleto: resultado['texto_completo'] ?? '',
        dadosExtraidos: DadosExtraidos.fromMap(resultado),
        dadosOriginais: resultado,
        pdfBytes: pdfBytes, // Armazenar os bytes do PDF para uso posterior
      );

      // Salvar edital no serviço
      await editalService.addEdital(
        'user_atual',
        edital.nomeConcurso,
        edital.textoCompleto ?? '',
        edital.dadosExtraidos,
        dadosOriginais: edital.dadosOriginais,
        id: editalId, // Passar o ID gerado anteriormente
        pdfBytes: pdfBytes, // Passar os bytes do PDF
        nomeArquivo: selectedFiles.isNotEmpty ? selectedFiles[0].name : null, // Passar o nome do arquivo
      );

      // Atualizar progresso
      onProgress('Concluindo análise...', 0.95);

      // Navegar para a tela de seleção de cargos
      try {
        final navigationService = getIt<INavigationService>();
        // Usar a rota nomeada definida no AppRouter
        navigationService.navigateTo(
          '/cargo/select',
          arguments: {'editalId': editalId},
        );
      } catch (e) {
        print('Erro ao usar NavigationService: $e');
        // Fallback para navegação direta
        Navigator.pushNamed(
          context,
          '/cargo/select',
          arguments: {'editalId': editalId},
        );
      }
    } catch (e) {
      Logger.error('Erro ao analisar edital: $e');
      rethrow;
    }
  }
}
