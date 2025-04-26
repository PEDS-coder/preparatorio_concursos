import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  ///
  /// Retorna o ID do edital criado
  static Future<String> analisarEdital({
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

      // Log para depuração
      Logger.debug('Preparando ${selectedFiles.length} arquivo(s) para análise');

      for (var file in selectedFiles) {
        if (kIsWeb) {
          // Na plataforma web, usamos os bytes diretamente
          if (file.bytes != null) {
            Logger.debug('Arquivo web: ${file.name} (${file.bytes!.length} bytes)');
            pdfBytes ??= file.bytes!;
            // Não podemos adicionar ao files, pois precisamos de File, não de bytes
            // Vamos tratar isso mais abaixo
          } else {
            Logger.warning('Arquivo web sem bytes: ${file.name}');
          }
        } else {
          // Em plataformas nativas, usamos o caminho do arquivo
          if (file.path != null) {
            final fileObj = File(file.path!);
            files.add(fileObj);
            // Armazenar os bytes do primeiro PDF para uso posterior
            pdfBytes ??= await fileObj.readAsBytes();
            Logger.debug('Arquivo nativo: ${file.name} (${file.path})');
          } else {
            Logger.warning('Arquivo nativo sem caminho: ${file.name}');
          }
        }
      }

      // Verificar se temos bytes do PDF (para web) ou arquivos (para nativo)
      if (files.isEmpty && pdfBytes == null) {
        throw Exception('Nenhum arquivo válido selecionado');
      }

      // Se estamos na web e temos bytes, mas não temos arquivos, precisamos criar uma implementação especial
      if (kIsWeb && files.isEmpty && pdfBytes != null) {
        Logger.debug('Usando implementação especial para web com ${pdfBytes.length} bytes');

        // Criar um método para processar diretamente os bytes do PDF
        final Map<String, dynamic> resultado = await _processarPdfBytesWeb(
          iaService,
          pdfBytes,
          selectedFiles.first.name,
          (message, progress) {
            onProgress(message, 0.2 + (progress * 0.7)); // Mapear progresso de 0.2 a 0.9
          },
        );

        // Continuar o processamento com o resultado obtido
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

        // Retornar o ID do edital
        return editalId;
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
      // Retornar o ID do edital para que a tela de análise possa navegar para a próxima tela
      return editalId;
    } catch (e) {
      Logger.error('Erro ao analisar edital: $e');
      rethrow;
    }
  }

  /// Processa os bytes do PDF diretamente na plataforma web
  ///
  /// Este método é usado apenas na plataforma web, onde não temos acesso ao sistema de arquivos
  /// e precisamos processar os bytes do PDF diretamente.
  static Future<Map<String, dynamic>> _processarPdfBytesWeb(
    IAServiceInterface iaService,
    Uint8List pdfBytes,
    String fileName,
    Function(String, double) onProgress,
  ) async {
    try {
      // Informar progresso
      onProgress('Preparando arquivo para análise...', 0.1);

      // Log para depuração
      Logger.debug('Processando PDF web: $fileName (${pdfBytes.length} bytes)');

      // Informar progresso
      onProgress('Enviando PDF para análise com IA...', 0.3);

      // Chamar a API para analisar o PDF diretamente com os bytes
      final String resposta = await iaService.analisarEditalPdf(pdfBytes, pdfName: fileName);

      // Informar progresso
      onProgress('Processando resultados da análise...', 0.7);

      // Processar a resposta da API
      Map<String, dynamic> resultado;
      try {
        // Tentar processar como JSON
        resultado = json.decode(resposta);
        Logger.debug('Resposta da API processada como JSON');
      } catch (e) {
        // Se falhar, tentar extrair o JSON da resposta
        Logger.warning('Erro ao processar resposta como JSON: $e');

        try {
          // Tentar extrair o JSON da resposta usando expressão regular
          final RegExp jsonRegex = RegExp(r'\{[\s\S]*\}');
          final match = jsonRegex.firstMatch(resposta);

          if (match != null) {
            final jsonString = match.group(0);
            resultado = json.decode(jsonString!);
            Logger.debug('JSON extraído da resposta com regex');
          } else {
            throw Exception('Não foi possível extrair JSON da resposta');
          }
        } catch (regexError) {
          Logger.error('Erro ao extrair JSON da resposta: $regexError');
          throw Exception('Falha ao processar resposta da API: $regexError');
        }
      }

      // Informar progresso
      onProgress('Análise concluída com sucesso', 0.9);

      return resultado;
    } catch (e) {
      Logger.error('Erro ao processar PDF web: $e');
      rethrow;
    }
  }
}
