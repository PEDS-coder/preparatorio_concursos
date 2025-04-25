import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/navigation_service_interface.dart';
import 'package:preparatorio_concursos/core/navigation/animated_route.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para gerenciar a navegação no aplicativo
@singleton
class NavigationService implements INavigationService {
  static const String _tag = 'NavigationService';

  final Logger _logger;
  final IAnalyticsService _analyticsService;
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Construtor
  NavigationService(this._logger, this._analyticsService);

  /// Navega para uma nova tela
  @override
  Future<T?> navigateTo<T>(
    String routeName, {
    Object? arguments,
    AnimationType animationType = AnimationType.fadeSlide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    bool replace = false,
    bool clearStack = false,
  }) async {
    try {
      // Registrar evento de navegação
      _analyticsService.logEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': routeName,
          'animation_type': animationType.toString(),
        },
      );

      _logger.debug('Navegando para: $routeName', tag: _tag);

      if (clearStack) {
        return await navigatorKey.currentState!.pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else if (replace) {
        return await navigatorKey.currentState!.pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      } else {
        return await navigatorKey.currentState!.pushNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      _logger.error('Erro ao navegar para: $routeName', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro de navegação');
      return null;
    }
  }

  /// Navega para uma nova tela com uma rota personalizada
  @override
  Future<T?> navigateToRoute<T>(
    Widget page, {
    String? routeName,
    AnimationType animationType = AnimationType.fadeSlide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    bool replace = false,
    bool clearStack = false,
  }) async {
    try {
      // Registrar evento de navegação
      _analyticsService.logEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': routeName ?? page.runtimeType.toString(),
          'animation_type': animationType.toString(),
        },
      );

      _logger.debug('Navegando para: ${routeName ?? page.runtimeType}', tag: _tag);

      final route = AnimatedRoute<T>(
        page: page,
        animationType: animationType,
        duration: duration,
        curve: curve,
        settings: RouteSettings(name: routeName ?? page.runtimeType.toString()),
      );

      if (clearStack) {
        return await navigatorKey.currentState!.pushAndRemoveUntil<T>(
          route,
          (route) => false,
        );
      } else if (replace) {
        return await navigatorKey.currentState!.pushReplacement<dynamic, T>(route);
      } else {
        return await navigatorKey.currentState!.push<T>(route);
      }
    } catch (e) {
      _logger.error('Erro ao navegar para: ${routeName ?? page.runtimeType}', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro de navegação');
      return null;
    }
  }

  /// Volta para a tela anterior
  @override
  void goBack<T>({T? result}) {
    try {
      if (navigatorKey.currentState!.canPop()) {
        _logger.debug('Voltando para a tela anterior', tag: _tag);
        navigatorKey.currentState!.pop(result);
      } else {
        _logger.warning('Não é possível voltar, não há telas na pilha', tag: _tag);
      }
    } catch (e) {
      _logger.error('Erro ao voltar para a tela anterior', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro de navegação');
    }
  }

  /// Volta para uma tela específica
  @override
  void goBackToRoute(String routeName) {
    try {
      _logger.debug('Voltando para a tela: $routeName', tag: _tag);
      navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
    } catch (e) {
      _logger.error('Erro ao voltar para a tela: $routeName', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro de navegação');
    }
  }

  /// Volta para a tela inicial
  @override
  void goBackToRoot() {
    try {
      _logger.debug('Voltando para a tela inicial', tag: _tag);
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    } catch (e) {
      _logger.error('Erro ao voltar para a tela inicial', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro de navegação');
    }
  }
}
