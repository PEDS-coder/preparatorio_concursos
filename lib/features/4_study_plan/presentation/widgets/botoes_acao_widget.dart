import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';

/// Widget para exibir os botões de ação
class BotoesAcaoWidget extends StatelessWidget {
  final VoidCallback onIniciarJornada;

  const BotoesAcaoWidget({
    Key? key,
    required this.onIniciarJornada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientButton.withText(
      text: 'Iniciar Jornada',
      onPressed: onIniciarJornada,
      gradient: AppTheme.primaryGradient,
      icon: const Icon(Icons.play_arrow, color: Colors.white),
      fullWidth: true,
    );
  }
}
