import 'package:flutter/material.dart';
import 'package:preparatorio_concursos/core/di/service_locator.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/navigation_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Extensões para facilitar a navegação na aplicação
extension NavigationExtensions on BuildContext {
  /// Navega para uma rota nomeada com tratamento de erros
  Future<T?> navigateTo<T>(
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    try {
      final navigationService = getIt<INavigationService>();
      return await navigationService.navigateTo<T>(
        routeName,
        arguments: arguments,
        replace: replace,
        clearStack: clearStack,
      );
    } catch (e) {
      // Fallback para navegação direta
      print('Erro ao usar NavigationService: $e');

      if (clearStack) {
        return Navigator.pushNamedAndRemoveUntil(
          this,
          routeName,
          (route) => false,
          arguments: arguments,
        ) as T?;
      } else if (replace) {
        return Navigator.pushReplacementNamed(
          this,
          routeName,
          arguments: arguments,
        ) as T?;
      } else {
        return Navigator.pushNamed(
          this,
          routeName,
          arguments: arguments,
        ) as T?;
      }
    }
  }

  /// Navega para uma rota com widget com tratamento de erros
  Future<T?> navigateToRoute<T>(
    Widget page, {
    String? routeName,
    bool replace = false,
    bool clearStack = false,
  }) async {
    try {
      final navigationService = getIt<INavigationService>();
      return await navigationService.navigateToRoute<T>(
        page,
        routeName: routeName ?? page.runtimeType.toString(),
        replace: replace,
        clearStack: clearStack,
      );
    } catch (e) {
      // Fallback para navegação direta
      print('Erro ao usar NavigationService: $e');

      final route = MaterialPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: routeName ?? page.runtimeType.toString()),
      );

      if (clearStack) {
        return Navigator.pushAndRemoveUntil<T>(
          this,
          route,
          (route) => false,
        );
      } else if (replace) {
        return Navigator.pushReplacement<dynamic, T>(this, route);
      } else {
        return Navigator.push<T>(this, route);
      }
    }
  }

  /// Volta para a tela anterior com tratamento de erros
  void goBack<T>({T? result}) {
    try {
      final navigationService = getIt<INavigationService>();
      navigationService.goBack<T>(result: result);
    } catch (e) {
      // Fallback para navegação direta
      print('Erro ao usar NavigationService: $e');
      Navigator.pop(this, result);
    }
  }

  /// Volta para uma rota específica com tratamento de erros
  void goBackToRoute(String routeName) {
    try {
      final navigationService = getIt<INavigationService>();
      navigationService.goBackToRoute(routeName);
    } catch (e) {
      // Fallback para navegação direta
      print('Erro ao usar NavigationService: $e');
      Navigator.popUntil(this, ModalRoute.withName(routeName));
    }
  }

  /// Volta para a tela inicial com tratamento de erros
  void goBackToRoot() {
    try {
      final navigationService = getIt<INavigationService>();
      navigationService.goBackToRoot();
    } catch (e) {
      // Fallback para navegação direta
      print('Erro ao usar NavigationService: $e');
      Navigator.popUntil(this, (route) => route.isFirst);
    }
  }
}
