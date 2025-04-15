import 'dart:async';
import 'package:flutter/material.dart';

/// Tipos de feedback visual
enum FeedbackType {
  /// Feedback de sucesso
  success,

  /// Feedback de erro
  error,

  /// Feedback de informação
  info,

  /// Feedback de aviso
  warning,
}

/// Widget para exibir um feedback visual para ações do usuário
class FeedbackOverlay {
  /// Exibe um feedback visual para ações do usuário
  static Future<void> show({
    required BuildContext context,
    required String message,
    FeedbackType type = FeedbackType.success,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
    bool dismissible = true,
    Widget? icon,
    bool showProgress = false,
  }) async {
    // Cores para cada tipo de feedback
    final Map<FeedbackType, Color> colors = {
      FeedbackType.success: Colors.green,
      FeedbackType.error: Colors.red,
      FeedbackType.info: Colors.blue,
      FeedbackType.warning: Colors.orange,
    };

    // Ícones para cada tipo de feedback
    final Map<FeedbackType, IconData> icons = {
      FeedbackType.success: Icons.check_circle,
      FeedbackType.error: Icons.error,
      FeedbackType.info: Icons.info,
      FeedbackType.warning: Icons.warning,
    };

    // Criar o overlay
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Definir a função de dismiss
    void dismissOverlay() {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        if (onDismiss != null) {
          onDismiss();
        }
      }
    }

    // Criar a entrada do overlay
    overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _FeedbackCard(
                message: message,
                color: colors[type]!,
                icon: icon ?? Icon(icons[type]!, color: Colors.white),
                onDismiss: dismissOverlay,
                dismissible: dismissible,
                showProgress: showProgress,
              ),
            ),
          ),
        ),
      ),
    );

    // Inserir o overlay
    overlayState.insert(overlayEntry);

    // Remover o overlay após o tempo especificado
    if (!showProgress) {
      await Future.delayed(duration);
      dismissOverlay();
    }
  }

  /// Exibe um feedback de sucesso
  static Future<void> success({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) async {
    return show(
      context: context,
      message: message,
      type: FeedbackType.success,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Exibe um feedback de erro
  static Future<void> error({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) async {
    return show(
      context: context,
      message: message,
      type: FeedbackType.error,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Exibe um feedback de informação
  static Future<void> info({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) async {
    return show(
      context: context,
      message: message,
      type: FeedbackType.info,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Exibe um feedback de aviso
  static Future<void> warning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) async {
    return show(
      context: context,
      message: message,
      type: FeedbackType.warning,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Exibe um feedback de carregamento
  static OverlayEntry loading({
    required BuildContext context,
    String message = 'Carregando...',
  }) {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10.0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16.0),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    return overlayEntry;
  }
}

/// Widget para exibir um card de feedback
class _FeedbackCard extends StatefulWidget {
  final String message;
  final Color color;
  final Widget icon;
  final VoidCallback onDismiss;
  final bool dismissible;
  final bool showProgress;

  const _FeedbackCard({
    Key? key,
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
    this.dismissible = true,
    this.showProgress = false,
  }) : super(key: key);

  @override
  _FeedbackCardState createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Configurar a animação
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Iniciar a animação
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.dismissible ? widget.onDismiss : null,
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_animation),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10.0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                widget.icon,
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                if (widget.showProgress) ...[
                  const SizedBox(width: 12.0),
                  const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  ),
                ],
                if (widget.dismissible) ...[
                  const SizedBox(width: 12.0),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
