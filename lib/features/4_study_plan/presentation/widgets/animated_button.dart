import 'package:flutter/material.dart';

/// Botão animado que suporta estado de carregamento
class CalendarSyncButton extends StatelessWidget {
  /// Função chamada quando o botão é pressionado
  final dynamic onPressed;

  /// Indica se o botão está em estado de carregamento
  final bool isLoading;

  /// Indica se o botão está habilitado
  final bool isEnabled;

  /// Cor de fundo do botão
  final Color color;

  /// Cor do texto do botão
  final Color textColor;

  /// Elevação do botão
  final double elevation;

  /// Raio da borda do botão
  final BorderRadius borderRadius;

  /// Widget filho do botão
  final Widget child;

  /// Construtor
  const CalendarSyncButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.color = Colors.blue,
    this.textColor = Colors.white,
    this.elevation = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: isEnabled ? color : color.withOpacity(0.6),
        elevation: isEnabled ? elevation : 0,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}
