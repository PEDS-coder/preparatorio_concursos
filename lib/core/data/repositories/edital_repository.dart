import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/models/edital.dart';
import 'package:preparatorio_concursos/core/data/repositories/base_repository.dart';
import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/error_handling_extension.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class EditalRepository extends BaseRepository {
  static const String _tag = 'EditalRepository';
  static const String _editaisKey = 'editais';
  static const String _currentEditalKey = 'current_edital';

  EditalRepository({
    required Logger logger,
    // Temporariamente removido para evitar problemas de injeção de dependência
    // required ErrorHandlerService errorHandler,
  }) : super(
          logger: logger,
          // errorHandler: errorHandler,
          tag: _tag,
        );

  /// Obtém todos os editais salvos
  Future<List<Edital>> getEditais() async {
    return runWithErrorHandlingExt<List<Edital>>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final editaisJson = prefs.getStringList(_editaisKey) ?? [];

        return editaisJson
            .map((jsonStr) => Edital.fromJson(json.decode(jsonStr)))
            .toList();
      },
      context: 'getEditais',
    );
  }

  /// Salva um edital
  Future<void> saveEdital(Edital edital) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final editais = await getEditais();

        // Verificar se o edital já existe
        final index = editais.indexWhere((e) => e.id == edital.id);
        if (index >= 0) {
          editais[index] = edital;
        } else {
          editais.add(edital);
        }

        // Salvar a lista atualizada
        final editaisJson = editais.map((e) => json.encode(e.toJson())).toList();
        await prefs.setStringList(_editaisKey, editaisJson);
      },
      context: 'saveEdital',
    );
  }

  /// Remove um edital
  Future<void> removeEdital(String editalId) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final editais = await getEditais();

        // Remover o edital
        editais.removeWhere((e) => e.id == editalId);

        // Salvar a lista atualizada
        final editaisJson = editais.map((e) => json.encode(e.toJson())).toList();
        await prefs.setStringList(_editaisKey, editaisJson);

        // Se o edital atual foi removido, limpar a referência
        final currentEditalId = prefs.getString(_currentEditalKey);
        if (currentEditalId == editalId) {
          await prefs.remove(_currentEditalKey);
        }
      },
      context: 'removeEdital',
    );
  }

  /// Obtém um edital pelo ID
  Future<Edital?> getEditalById(String editalId) async {
    return runWithErrorHandlingExt<Edital?>(
      () async {
        final editais = await getEditais();
        return editais.firstWhere(
          (e) => e.id == editalId,
          orElse: () => throw Exception('Edital não encontrado'),
        );
      },
      context: 'getEditalById',
    );
  }

  /// Define o edital atual
  Future<void> setCurrentEdital(String editalId) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentEditalKey, editalId);
      },
      context: 'setCurrentEdital',
    );
  }

  /// Obtém o edital atual
  Future<Edital?> getCurrentEdital() async {
    return runWithErrorHandlingExt<Edital?>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final currentEditalId = prefs.getString(_currentEditalKey);

        if (currentEditalId == null) {
          return null;
        }

        return getEditalById(currentEditalId);
      },
      context: 'getCurrentEdital',
    );
  }

  /// Salva o conteúdo binário de um edital (PDF)
  Future<void> saveEditalContent(String editalId, Uint8List content) async {
    // Implementação para salvar o conteúdo binário do edital
    // Pode usar o file_system ou outro mecanismo de armazenamento
  }

  /// Obtém o conteúdo binário de um edital (PDF)
  Future<Uint8List?> getEditalContent(String editalId) async {
    // Implementação para obter o conteúdo binário do edital
    // Pode usar o file_system ou outro mecanismo de armazenamento
    return null;
  }
}
