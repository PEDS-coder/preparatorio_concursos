import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/navigation/navigation_service.dart';

/// Widget para implementar gestos intuitivos para navegação
class GestureDetectorScreen extends StatefulWidget {
  final Widget child;
  final bool enableSwipeBack;
  final bool enableSwipeForward;
  final bool enableSwipeUp;
  final bool enableSwipeDown;
  final VoidCallback? onSwipeBack;
  final VoidCallback? onSwipeForward;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  
  const GestureDetectorScreen({
    Key? key,
    required this.child,
    this.enableSwipeBack = true,
    this.enableSwipeForward = false,
    this.enableSwipeUp = false,
    this.enableSwipeDown = false,
    this.onSwipeBack,
    this.onSwipeForward,
    this.onSwipeUp,
    this.onSwipeDown,
  }) : super(key: key);
  
  @override
  _GestureDetectorScreenState createState() => _GestureDetectorScreenState();
}

class _GestureDetectorScreenState extends State<GestureDetectorScreen> {
  // Posição inicial do gesto
  Offset? _startPosition;
  
  // Distância mínima para considerar um gesto
  static const double _minDistance = 50.0;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragStart: _onDragStart,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: widget.child,
    );
  }
  
  /// Registra o início do gesto
  void _onDragStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
  }
  
  /// Processa o fim do gesto horizontal
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_startPosition == null) return;
    
    final endPosition = details.velocity.pixelsPerSecond;
    final dx = endPosition.dx;
    
    // Verificar se a distância é suficiente
    if (dx.abs() < _minDistance) return;
    
    // Gesto para a direita (voltar)
    if (dx > 0 && widget.enableSwipeBack) {
      if (widget.onSwipeBack != null) {
        widget.onSwipeBack!();
      } else {
        final navigationService = Provider.of<NavigationService>(context, listen: false);
        navigationService.goBack();
      }
    }
    
    // Gesto para a esquerda (avançar)
    else if (dx < 0 && widget.enableSwipeForward) {
      if (widget.onSwipeForward != null) {
        widget.onSwipeForward!();
      }
    }
    
    // Limpar a posição inicial
    _startPosition = null;
  }
  
  /// Processa o fim do gesto vertical
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_startPosition == null) return;
    
    final endPosition = details.velocity.pixelsPerSecond;
    final dy = endPosition.dy;
    
    // Verificar se a distância é suficiente
    if (dy.abs() < _minDistance) return;
    
    // Gesto para cima
    if (dy < 0 && widget.enableSwipeUp) {
      if (widget.onSwipeUp != null) {
        widget.onSwipeUp!();
      }
    }
    
    // Gesto para baixo
    else if (dy > 0 && widget.enableSwipeDown) {
      if (widget.onSwipeDown != null) {
        widget.onSwipeDown!();
      }
    }
    
    // Limpar a posição inicial
    _startPosition = null;
  }
}
