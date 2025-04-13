import 'package:flutter/material.dart';

/// Tipos de animação para transições de tela
enum AnimationType {
  /// Fade in/out
  fade,
  
  /// Slide from right
  slideRight,
  
  /// Slide from left
  slideLeft,
  
  /// Slide from bottom
  slideUp,
  
  /// Slide from top
  slideDown,
  
  /// Scale up/down
  scale,
  
  /// Rotate
  rotate,
  
  /// Combination of fade and scale
  fadeScale,
  
  /// Combination of fade and slide
  fadeSlide,
  
  /// No animation
  none,
}

/// Classe para criar rotas com animações
class AnimatedRoute extends PageRouteBuilder {
  final Widget page;
  final AnimationType animationType;
  final Duration duration;
  final Curve curve;
  
  AnimatedRoute({
    required this.page,
    this.animationType = AnimationType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );
            
            switch (animationType) {
              case AnimationType.fade:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                );
              
              case AnimationType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              
              case AnimationType.slideLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              
              case AnimationType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              
              case AnimationType.slideDown:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              
              case AnimationType.scale:
                return ScaleTransition(
                  scale: curvedAnimation,
                  child: child,
                );
              
              case AnimationType.rotate:
                return RotationTransition(
                  turns: curvedAnimation,
                  child: child,
                );
              
              case AnimationType.fadeScale:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.8,
                      end: 1.0,
                    ).animate(curvedAnimation),
                    child: child,
                  ),
                );
              
              case AnimationType.fadeSlide:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(curvedAnimation),
                    child: child,
                  ),
                );
              
              case AnimationType.none:
                return child;
            }
          },
        );
}
