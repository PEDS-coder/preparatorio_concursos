import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/models/usuario.dart';
import 'package:preparatorio_concursos/core/data/repositories/base_repository.dart';
import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/error_handling_extension.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class UserRepository extends BaseRepository {
  static const String _tag = 'UserRepository';
  static const String _userKey = 'user_data';

  UserRepository({
    required Logger logger,
    required ErrorHandlerService errorHandler,
  }) : super(
          logger: logger,
          errorHandler: errorHandler,
          tag: _tag,
        );

  /// Obtém os dados do usuário
  Future<Usuario?> getUser() async {
    return runWithErrorHandlingExt<Usuario?>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(_userKey);

        if (userJson == null) {
          return null;
        }

        return Usuario.fromJson(userJson);
      },
      context: 'getUser',
    );
  }

  /// Salva os dados do usuário
  Future<void> saveUser(Usuario user) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, user.toJson());
      },
      context: 'saveUser',
    );
  }

  /// Remove os dados do usuário
  Future<void> removeUser() async {
    return runWithErrorHandlingExt<void>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_userKey);
      },
      context: 'removeUser',
    );
  }

  /// Atualiza os dados do usuário
  Future<void> updateUser(Usuario user) async {
    return runWithErrorHandlingExt<void>(
      () async {
        await saveUser(user);
      },
      context: 'updateUser',
    );
  }

  /// Verifica se o usuário está logado
  Future<bool> isUserLoggedIn() async {
    return runWithErrorHandlingExt<bool>(
      () async {
        final user = await getUser();
        return user != null;
      },
      context: 'isUserLoggedIn',
    );
  }

  /// Atualiza as moedas do usuário
  Future<void> updateCoins(int coins) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final user = await getUser();
        if (user == null) {
          throw Exception('Usuário não encontrado');
        }

        final updatedUser = user.copyWith(pontosGamificacao: coins);
        await saveUser(updatedUser);
      },
      context: 'updateCoins',
    );
  }

  /// Adiciona moedas ao usuário
  Future<void> addCoins(int amount) async {
    return runWithErrorHandlingExt<void>(
      () async {
        final user = await getUser();
        if (user == null) {
          throw Exception('Usuário não encontrado');
        }

        final updatedUser = user.copyWith(pontosGamificacao: user.pontosGamificacao + amount);
        await saveUser(updatedUser);
      },
      context: 'addCoins',
    );
  }

  /// Remove moedas do usuário
  Future<bool> removeCoins(int amount) async {
    return runWithErrorHandlingExt<bool>(
      () async {
        final user = await getUser();
        if (user == null) {
          throw Exception('Usuário não encontrado');
        }

        if (user.pontosGamificacao < amount) {
          return false;
        }

        final updatedUser = user.copyWith(pontosGamificacao: user.pontosGamificacao - amount);
        await saveUser(updatedUser);
        return true;
      },
      context: 'removeCoins',
    );
  }
}
