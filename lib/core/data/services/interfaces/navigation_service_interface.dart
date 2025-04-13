import 'package:flutter/material.dart';
import 'package:preparatorio_concursos/core/navigation/animated_route.dart';

/// Interface para o serviço de navegação
abstract class INavigationService {
  /// Chave global para o navegador
  GlobalKey<NavigatorState> get navigatorKey;
  
  /// Navega para uma nova tela
  Future<T?> navigateTo<T>(
    String routeName, {
    Object? arguments,
    AnimationType animationType,
    Duration duration,
    Curve curve,
    bool replace,
    bool clearStack,
  });
  
  /// Navega para uma nova tela com uma rota personalizada
  Future<T?> navigateToRoute<T>(
    Widget page, {
    String? routeName,
    AnimationType animationType,
    Duration duration,
    Curve curve,
    bool replace,
    bool clearStack,
  });
  
  /// Volta para a tela anterior
  void goBack<T>({T? result});
  
  /// Volta para uma tela específica
  void goBackToRoute(String routeName);
  
  /// Volta para a tela inicial
  void goBackToRoot();
}
