import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/data/repositories/base_repository.dart';
import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/error_handling_extension.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class PlanoEstudoRepository extends BaseRepository {
  static const String _tag = 'PlanoEstudoRepository';
  static const String _planosKey = 'planos_estudo';
  static const String _currentPlanoKey = 'current_plano';

  PlanoEstudoRepository({
    required Logger logger,
    // Temporariamente removido para evitar problemas de injeção de dependência
    // required ErrorHandlerService errorHandler,
  }) : super(
          logger: logger,
          // errorHandler: errorHandler,
          tag: _tag,
        );

  /// Obtém todos os planos de estudo salvos
  Future<List<PlanoEstudo>> getPlanos() async {
    return runWithErrorHandlingExt<List<PlanoEstudo>>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final planosJson = prefs.getStringList(_planosKey) ?? [];

        return planosJson
            .map((jsonStr) => PlanoEstudo.fromJson(json.decode(jsonStr)))
            .toList();
      },
      context: 'getPlanos',
    );
  }

  /// Salva um plano de estudo
  Future<void> savePlano(PlanoEstudo plano) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final planos = await getPlanos();

        // Verificar se o plano já existe
        final index = planos.indexWhere((p) => p.id == plano.id);
        if (index >= 0) {
          planos[index] = plano;
        } else {
          planos.add(plano);
        }

        // Salvar a lista atualizada
        final planosJson = planos.map((p) => json.encode(p.toJson())).toList();
        await prefs.setStringList(_planosKey, planosJson);
      },
      context: 'savePlano',
    );
  }

  /// Remove um plano de estudo
  Future<void> removePlano(String planoId) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final planos = await getPlanos();

        // Remover o plano
        planos.removeWhere((p) => p.id == planoId);

        // Salvar a lista atualizada
        final planosJson = planos.map((p) => json.encode(p.toJson())).toList();
        await prefs.setStringList(_planosKey, planosJson);

        // Se o plano atual foi removido, limpar a referência
        final currentPlanoId = prefs.getString(_currentPlanoKey);
        if (currentPlanoId == planoId) {
          await prefs.remove(_currentPlanoKey);
        }
      },
      context: 'removePlano',
    );
  }

  /// Obtém um plano de estudo pelo ID
  Future<PlanoEstudo?> getPlanoById(String planoId) async {
    return runWithErrorHandlingExt<PlanoEstudo?>(
      () async {
        final planos = await getPlanos();
        return planos.firstWhere(
          (p) => p.id == planoId,
          orElse: () => throw Exception('Plano não encontrado'),
        );
      },
      context: 'getPlanoById',
    );
  }

  /// Define o plano de estudo atual
  Future<void> setCurrentPlano(String planoId) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentPlanoKey, planoId);
      },
      context: 'setCurrentPlano',
    );
  }

  /// Obtém o plano de estudo atual
  Future<PlanoEstudo?> getCurrentPlano() async {
    return runWithErrorHandlingExt<PlanoEstudo?>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final currentPlanoId = prefs.getString(_currentPlanoKey);

        if (currentPlanoId == null) {
          return null;
        }

        return getPlanoById(currentPlanoId);
      },
      context: 'getCurrentPlano',
    );
  }

  /// Obtém planos de estudo por edital
  Future<List<PlanoEstudo>> getPlanosByEdital(String editalId) async {
    return runWithErrorHandlingExt<List<PlanoEstudo>>(
      () async {
        final planos = await getPlanos();
        return planos.where((p) => p.editalId == editalId).toList();
      },
      context: 'getPlanosByEdital',
    );
  }
}
