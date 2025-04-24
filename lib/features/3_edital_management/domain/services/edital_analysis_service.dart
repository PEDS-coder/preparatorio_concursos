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
      final String editalId = Uuid().v4();

      // Preparar arquivos para envio
      List<File> files = [];
      Uint8List? pdfBytes;
      for (var file in selectedFiles) {
        if (file.path != null) {
          final fileObj = File(file.path!);
          files.add(fileObj);
          // Armazenar os bytes do primeiro PDF para uso posterior
          if (pdfBytes == null) {
            pdfBytes = await fileObj.readAsBytes();
          }
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
      );

      // Atualizar progresso
      onProgress('Concluindo análise...', 0.95);

      // Navegar para a tela de seleção de cargos
      try {
        final navigationService = getIt<INavigationService>();
        navigationService.navigateToRoute(
          CargoSelectScreen(editalId: editalId),
          routeName: 'CargoSelectScreen',
        );
      } catch (e) {
        print('Erro ao usar NavigationService: $e');
        // Fallback para navegação direta
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CargoSelectScreen(
              editalId: editalId,
            ),
          ),
        );
      }
    } catch (e) {
      Logger.error('Erro ao analisar edital: $e');
      rethrow;
    }
  }
}
